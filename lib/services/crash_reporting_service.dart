import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Centralized crash reporting, backed by Sentry.
///
/// **Configuration**: the DSN comes from `--dart-define=SENTRY_DSN=...` at
/// build/run time (same pattern as the Supabase credentials). When the DSN is
/// absent — local dev, CI, tests — every method here is a silent no-op and no
/// network calls are made.
///
/// **Privacy rules** (TASK-063):
/// - `sendDefaultPii` is off; no screenshots or view hierarchy are attached.
/// - Never put user-generated content in breadcrumbs, tags, or contexts:
///   no journal entries, scripture notes, chat messages, or nicknames.
/// - Allowed context: current tab/route names, premium status, scripture IDs
///   (they identify one of the 100 public scriptures, not the user).
///
/// **Transient HTTP noise** (FLUTTER-6): Sentry's default failed-request
/// capture treats every 5xx as `HTTPClientError`. Upstream overload codes
/// (429 / 502 / 503 / 529) from Sidekick / xAI are expected and already
/// handled in-app — [shouldDropTransientHttpClientError] filters them out
/// so they do not open crash issues.
///
/// **Expected entitlement gate** (FLUTTER-7): `sidekick-proxy` returns 403
/// when premium is missing/unverifiable. The client maps that to
/// `SidekickEntitlementException` and a Refresh/upgrade UX — not a crash.
/// [shouldDropExpectedSidekickEntitlementError] drops those events if they
/// still reach Sentry (legacy `recordError` or other capture paths).
class CrashReportingService {
  CrashReportingService._();

  static const String _dsn =
      String.fromEnvironment('SENTRY_DSN', defaultValue: '');

  /// HTTP statuses that mean "try again shortly", not an app defect.
  @visibleForTesting
  static const Set<int> transientHttpStatusCodes = {429, 502, 503, 529};

  static final RegExp _httpClientStatusRe = RegExp(
    r'HTTP Client Error with status code:\s*(\d+)',
  );

  /// Whether crash reporting is active for this build.
  static bool get isEnabled => isDsnConfigured(_dsn);

  /// True when [dsn] is a usable (non-blank) DSN. Split out for testability.
  @visibleForTesting
  static bool isDsnConfigured(String dsn) => dsn.trim().isNotEmpty;

  /// True when [status] is a transient upstream / gateway overload code.
  @visibleForTesting
  static bool isTransientHttpStatus(int? status) =>
      status != null && transientHttpStatusCodes.contains(status);

  /// Drop Sentry auto-captured HTTP client failures for transient statuses.
  ///
  /// Matches both Dart (`SentryHttpClientError`) and native iOS
  /// (`HTTPClientError`) failed-request events whose message embeds the
  /// status code.
  @visibleForTesting
  static bool shouldDropTransientHttpClientError(SentryEvent event) {
    final exceptions = event.exceptions;
    if (exceptions == null || exceptions.isEmpty) return false;

    for (final ex in exceptions) {
      final type = ex.type ?? '';
      final value = ex.value ?? '';
      final isHttpClientError = type == 'HTTPClientError' ||
          type == 'SentryHttpClientError' ||
          value.contains('HTTP Client Error with status code:');
      if (!isHttpClientError) continue;

      final match = _httpClientStatusRe.firstMatch(value);
      if (match == null) continue;
      final status = int.tryParse(match.group(1)!);
      if (isTransientHttpStatus(status)) return true;
    }
    return false;
  }

  /// Drop expected Sidekick premium-gate 403s (`FunctionException`).
  ///
  /// These are handled in-app as `SidekickEntitlementException` (TASK-067 /
  /// FLUTTER-7). Other FunctionExceptions (non-403, non-entitlement) still
  /// report.
  @visibleForTesting
  static bool shouldDropExpectedSidekickEntitlementError(SentryEvent event) {
    final exceptions = event.exceptions;
    if (exceptions == null || exceptions.isEmpty) return false;

    for (final ex in exceptions) {
      final type = ex.type ?? '';
      final value = ex.value ?? '';
      final isFunctionException = type == 'FunctionException' ||
          value.contains('FunctionException');
      if (!isFunctionException) continue;
      // Proxy gate copy from sidekick-proxy; match status + message so other
      // FunctionException 403s (if any) still surface in Sentry.
      final lower = value.toLowerCase();
      final looksLike403 = value.contains('status: 403') ||
          value.contains('status:403') ||
          lower.contains('forbidden');
      if (looksLike403 &&
          lower.contains('premium subscription is required')) {
        return true;
      }
    }
    return false;
  }

  /// True when [event] is expected Sidekick noise that must not open issues.
  @visibleForTesting
  static bool shouldDropExpectedSidekickNoise(SentryEvent event) =>
      shouldDropTransientHttpClientError(event) ||
      shouldDropExpectedSidekickEntitlementError(event);

  /// Initialize Sentry and run [appRunner] inside its error-capturing zone.
  ///
  /// Captures, automatically:
  /// - Flutter framework errors (`FlutterError.onError`)
  /// - Uncaught async Dart errors (`PlatformDispatcher.onError`)
  /// - Native crashes (Java/Kotlin on Android, Objective-C/Swift on iOS)
  ///
  /// With no DSN configured this just runs [appRunner] directly.
  static Future<void> init(FutureOr<void> Function() appRunner) async {
    if (!isEnabled) {
      await appRunner();
      return;
    }

    await SentryFlutter.init(
      (options) {
        options.dsn = _dsn;
        options.environment = kReleaseMode ? 'production' : 'development';
        options.release = const String.fromEnvironment(
          'APP_RELEASE',
          defaultValue: 'seminary_sidekick@unversioned',
        );
        // Privacy: never collect PII, screenshots, or widget trees — the
        // screen can contain journal entries and scripture notes.
        options.sendDefaultPii = false;
        options.attachScreenshot = false;
        // Intentionally disabling an experimental Sentry option for privacy; the
        // screen can contain journal/scripture text.
        // ignore: experimental_member_use
        options.attachViewHierarchy = false;
        // Crash analytics only — no performance tracing for now.
        options.tracesSampleRate = null;
        // Keep enough breadcrumbs to reconstruct the path to a crash.
        options.maxBreadcrumbs = 60;
        // Native iOS failed-request capture duplicates handled Sidekick /
        // Supabase 5xx noise (FLUTTER-6). Dart-side capture stays on;
        // beforeSend still drops known-transient statuses from either path.
        options.captureNativeFailedRequests = false;
        options.beforeSend = (event, hint) {
          if (shouldDropExpectedSidekickNoise(event)) return null;
          return event;
        };
      },
      appRunner: appRunner,
    );
  }

  /// Record a handled (non-fatal) exception, e.g. from a `catch` block that
  /// recovers gracefully but where we still want field visibility.
  static Future<void> recordError(
    Object error,
    StackTrace? stackTrace, {
    String? hint,
  }) async {
    if (!isEnabled) return;
    await Sentry.captureException(
      error,
      stackTrace: stackTrace,
      hint: hint == null ? null : Hint.withMap({'note': hint}),
    );
  }

  /// Leave a breadcrumb describing a user action or app event.
  /// [message] must never contain user-generated content.
  static void addBreadcrumb(String message, {String category = 'app'}) {
    if (!isEnabled) return;
    Sentry.addBreadcrumb(Breadcrumb(message: message, category: category));
  }

  /// Tag every future event with the user's premium status. Helps separate
  /// "crashes in the free mastery loop" from "crashes in Sidekick AI".
  static void setPremiumTag(bool isPremium) {
    if (!isEnabled) return;
    Sentry.configureScope(
      (scope) => scope.setTag('premium', isPremium ? 'true' : 'false'),
    );
  }
}
