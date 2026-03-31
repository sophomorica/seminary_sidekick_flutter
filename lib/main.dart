import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'providers/mastery_dates_provider.dart';
import 'providers/notes_provider.dart';
import 'providers/progress_provider.dart';
import 'providers/theme_provider.dart';
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
  await container.read(themeProvider.notifier).init();
  await container.read(audioProvider.notifier).init();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const SeminarySidekickApp(),
    ),
  );
}
