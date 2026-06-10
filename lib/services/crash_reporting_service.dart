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
class CrashReportingService {
  CrashReportingService._();

  static const String _dsn =
      String.fromEnvironment('SENTRY_DSN', defaultValue: '');

  /// Whether crash reporting is active for this build.
  static bool get isEnabled => isDsnConfigured(_dsn);

  /// True when [dsn] is a usable (non-blank) DSN. Split out for testability.
  @visibleForTesting
  static bool isDsnConfigured(String dsn) => dsn.trim().isNotEmpty;

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
        options.attachViewHierarchy = false;
        // Crash analytics only — no performance tracing for now.
        options.tracesSampleRate = null;
        // Keep enough breadcrumbs to reconstruct the path to a crash.
        options.maxBreadcrumbs = 60;
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
