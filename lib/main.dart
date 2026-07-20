import 'dart:developer' as developer;
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'providers/activity_provider.dart';
import 'providers/announcement_provider.dart';
import 'providers/goals_provider.dart';
import 'providers/journal_provider.dart';
import 'providers/mastery_dates_provider.dart';
import 'providers/notes_provider.dart';
import 'providers/onboarding_provider.dart';
import 'providers/progress_provider.dart';
import 'providers/scripture_scope_provider.dart';
import 'providers/spaced_repetition_provider.dart';
import 'providers/sidekick_provider.dart';
import 'providers/subscription_provider.dart';
import 'providers/study_streak_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/user_preferences_provider.dart';
import 'services/audio_service.dart';
import 'services/crash_reporting_service.dart';
import 'services/nickname_validator.dart';

void main() async {
  // Crash reporting wraps the entire bootstrap so that uncaught Flutter,
  // async Dart, and native errors are all captured. With no SENTRY_DSN
  // dart-define, this is a pass-through (no-op, no network).
  await CrashReportingService.init(_bootstrap);
}

Future<void> _bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize local storage
  await Hive.initFlutter();

  // Lock to portrait for consistent game experience
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Status bar style — theme-dependent overlays are handled by the
  // MaterialApp, but we still set the status bar to transparent.
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
    ),
  );

  final container = ProviderContainer();
  // Load persisted data before app starts
  await container.read(progressProvider.notifier).init();
  await container.read(notesProvider.notifier).init();
  await container.read(masteryDatesProvider.notifier).init();
  await container.read(spacedRepetitionProvider.notifier).init();
  await container.read(activityProvider.notifier).init();
  await container.read(onboardingProvider.notifier).init();
  await container.read(themeProvider.notifier).init();

  // Configure RevenueCat BEFORE subscription init, so the background sync in
  // SubscriptionNotifier.init() sees a configured SDK and can read the real
  // entitlement state. No-op (free tier) if no API key dart-define is set.
  await _maybeInitPurchases();
  await container.read(subscriptionProvider.notifier).init();

  // Tag crash reports with premium status (no-op when reporting is disabled).
  // fireImmediately covers the initial value; the listener tracks changes
  // (upgrade, restore, expiry) for the rest of the session.
  container.listen<bool>(
    isPremiumProvider,
    (_, isPremium) => CrashReportingService.setPremiumTag(isPremium),
    fireImmediately: true,
  );

  await container.read(journalProvider.notifier).init();
  await container.read(audioProvider.notifier).init();
  await container.read(userPreferencesProvider.notifier).init();
  await container.read(studyStreakProvider.notifier).init();
  await container.read(scriptureScopeProvider.notifier).init();

  // Initialize Goals (loads persisted goals from Hive).
  await container.read(goalsProvider.notifier).init();

  // Initialize Sidekick AI (loads cache; auto-refreshes if premium).
  // Non-blocking — the app starts immediately, sidekick loads in background.
  container.read(sidekickProvider.notifier).init();

  // Preload the nickname profanity wordlist. Fire-and-forget — the validator
  // fails open until the asset finishes loading, so the only consequence of
  // skipping the await is a missed profanity hit on the first lobby visit.
  NicknameValidator.preload();

  // Restore announcement dismissals (Hive) before Supabase comes up.
  await container.read(announcementProvider.notifier).init();

  // Initialize Supabase for Group Play multiplayer + announcements.
  // Credentials come from --dart-define at build/run time:
  //   --dart-define=SUPABASE_URL=...
  //   --dart-define=SUPABASE_ANON_KEY=...
  // If either is missing, group play / announcements are gracefully
  // unavailable but the rest of the app still works (solo mastery loop has
  // no Supabase dependency).
  await _maybeInitSupabase();

  // Pull latest announcements after the anon session exists (best-effort).
  container.read(announcementProvider.notifier).refresh();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const SeminarySidekickApp(),
    ),
  );
}

/// Configure RevenueCat from platform-specific public SDK keys passed via
/// --dart-define at build/run time:
///   --dart-define=REVENUECAT_IOS_KEY=appl_xxx       (iOS / macOS)
///   --dart-define=REVENUECAT_ANDROID_KEY=goog_xxx   (Android)
///
/// If the key for the current platform is missing, RevenueCat is left
/// unconfigured: every Purchases call in SubscriptionNotifier is guarded and
/// the app simply runs on the free tier. This mirrors the Supabase pattern —
/// the app must work without paid-feature credentials (dev/CI/tests).
///
/// Failures are logged + reported but never crash the app.
Future<void> _maybeInitPurchases() async {
  const iosKey = String.fromEnvironment('REVENUECAT_IOS_KEY', defaultValue: '');
  const androidKey =
      String.fromEnvironment('REVENUECAT_ANDROID_KEY', defaultValue: '');

  String apiKey = '';
  if (Platform.isIOS || Platform.isMacOS) {
    apiKey = iosKey;
  } else if (Platform.isAndroid) {
    apiKey = androidKey;
  }

  if (apiKey.isEmpty) {
    developer.log(
      'RevenueCat not configured — set --dart-define=REVENUECAT_IOS_KEY '
      'and/or --dart-define=REVENUECAT_ANDROID_KEY to enable in-app '
      'purchases. The app runs on the free tier without it.',
      name: 'main',
    );
    return;
  }

  try {
    await Purchases.setLogLevel(LogLevel.warn);
    await Purchases.configure(PurchasesConfiguration(apiKey));
    developer.log('RevenueCat configured.', name: 'main');
  } catch (e, st) {
    developer.log(
      'RevenueCat init failed; purchases will be unavailable.',
      name: 'main',
      error: e,
      stackTrace: st,
    );
    await CrashReportingService.recordError(
      e,
      st,
      hint: 'RevenueCat configure failed',
    );
  }
}

/// Read Supabase credentials from --dart-define and initialize the client.
/// Also performs an anonymous sign-in if there's no existing session, so the
/// rest of the app can assume `Supabase.instance.client.auth.currentUser`
/// is non-null when group play is reachable.
///
/// Failures are logged but do not crash the app — solo features have no
/// Supabase dependency. Group play screens check session validity at the
/// service layer before issuing any DB calls.
Future<void> _maybeInitSupabase() async {
  const url = String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  const anonKey = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

  if (url.isEmpty || anonKey.isEmpty) {
    developer.log(
      'Supabase not configured — set --dart-define=SUPABASE_URL and '
      '--dart-define=SUPABASE_ANON_KEY to enable Group Play.',
      name: 'main',
    );
    return;
  }

  try {
    await Supabase.initialize(
      url: url,
      // Accepts both legacy anon JWTs and new sb_publishable_ keys; the
      // SUPABASE_ANON_KEY dart-define name is kept so existing build
      // commands and SUPABASE_SETUP.md stay valid.
      publishableKey: anonKey,
      // Realtime is on by default; explicit no-op kept here for clarity.
      realtimeClientOptions: const RealtimeClientOptions(
        logLevel: RealtimeLogLevel.warn,
      ),
    );

    final auth = Supabase.instance.client.auth;

    // If a stale session was restored from local storage, force-refresh it
    // synchronously so we discover a bad refresh token NOW (rather than
    // asynchronously after init returns — that race used to leave us
    // "signed in" until the first DB call rejected us).
    if (auth.currentSession != null) {
      try {
        await auth.refreshSession();
      } on AuthException catch (e) {
        developer.log(
          'Cached Supabase session was unusable (${e.code}); wiping.',
          name: 'main',
        );
        try {
          await auth.signOut();
        } catch (_) {
          // signOut may fail if the refresh token is already invalidated
          // server-side. Either way, the local session is gone.
        }
      }
    }

    if (auth.currentUser == null) {
      await auth.signInAnonymously();
      developer.log(
        'Anonymous Supabase session created: ${auth.currentUser?.id}',
        name: 'main',
      );
    } else {
      developer.log(
        'Reusing Supabase session: ${auth.currentUser!.id}',
        name: 'main',
      );
    }

    // Safety net: if the session gets cleared later (e.g. another tab
    // invalidated the refresh token, or background refresh failed), sign
    // back in anonymously so group play doesn't quietly stop working.
    auth.onAuthStateChange.listen((data) {
      final event = data.event;
      if (event == AuthChangeEvent.signedOut ||
          event == AuthChangeEvent.tokenRefreshed && auth.currentUser == null) {
        developer.log(
          'Supabase session cleared (${event.name}); re-signing in anonymously.',
          name: 'main',
        );
        auth.signInAnonymously().catchError((e) {
          developer.log(
            'Anonymous re-sign-in failed: $e',
            name: 'main',
          );
          // Return a placeholder AuthResponse to satisfy the type system —
          // callers don't observe the future from this listener.
          throw e;
        });
      }
    });
  } catch (e, st) {
    developer.log(
      'Supabase init failed; group play will be unavailable.',
      name: 'main',
      error: e,
      stackTrace: st,
    );
    // Non-fatal, but worth field visibility — a broken Supabase init means
    // Group Play is silently unavailable for that user.
    await CrashReportingService.recordError(
      e,
      st,
      hint: 'Supabase init failed; group play unavailable',
    );
  }
}
