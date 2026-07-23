import 'dart:async';

import 'package:seminary_sidekick/theme/google_fonts_bootstrap.dart';

/// Runs before every test file in this suite (flutter_test convention).
///
/// Disables google_fonts runtime fetching globally so no theme/widget test
/// can silently hit fonts.gstatic.com — bundled assets or bust (FLUTTER-8).
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  configureBundledGoogleFonts();
  await testMain();
}
