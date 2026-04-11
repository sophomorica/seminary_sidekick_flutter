import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

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

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const SeminarySidekickApp(),
    ),
  );
}
