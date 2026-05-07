import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'providers/activity_provider.dart';
import 'providers/goals_provider.dart';
import 'providers/journal_provider.dart';
import 'providers/mastery_dates_provider.dart';
import 'providers/notes_provider.dart';
import 'providers/onboarding_provider.dart';
import 'providers/progress_provider.dart';
import 'providers/spaced_repetition_provider.dart';
import 'providers/sidekick_provider.dart';
import 'providers/subscription_provider.dart';
import 'providers/study_streak_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/user_preferences_provider.dart';
import 'services/audio_service.dart';
import 'services/nickname_validator.dart';

void main() async {
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
  await container.read(subscriptionProvider.notifier).init();
  await container.read(journalProvider.notifier).init();
  await container.read(audioProvider.notifier).init();
  await container.read(userPreferencesProvider.notifier).init();
  await container.read(studyStreakProvider.notifier).init();

  // Initialize Goals (loads persisted goals from Hive).
  await container.read(goalsProvider.notifier).init();

  // Initialize Sidekick AI (loads cache; auto-refreshes if premium).
  // Non-blocking — the app starts immediately, sidekick loads in background.
  container.read(sidekickProvider.notifier).init();

  // Preload the nickname profanity wordlist. Fire-and-forget — the validator
  // fails open until the asset finishes loading, so the only consequence of
  // skipping the await is a missed profanity hit on the first lobby visit.
  NicknameValidator.preload();

  // Initialize Supabase for Group Play multiplayer.
  // Credentials come from --dart-define at build/run time:
  //   --dart-define=SUPABASE_URL=...
  //   --dart-define=SUPABASE_ANON_KEY=...
  // If either is missing, group play is gracefully unavailable but the rest
  // of the app still works (solo mastery loop has no Supabase dependency).
  await _maybeInitSupabase();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const SeminarySidekickApp(),
    ),
  );
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
      anonKey: anonKey,
      // Realtime is on by default; explicit no-op kept here for clarity.
      realtimeClientOptions: const RealtimeClientOptions(
        logLevel: RealtimeLogLevel.warn,
      ),
    );

    final auth = Supabase.instance.client.auth;
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
  } catch (e, st) {
    developer.log(
      'Supabase init failed; group play will be unavailable.',
      name: 'main',
      error: e,
      stackTrace: st,
    );
  }
}
