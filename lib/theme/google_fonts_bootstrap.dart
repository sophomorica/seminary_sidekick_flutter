import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

bool _licensesRegistered = false;

/// Offline-safe Google Fonts setup for Seminary Sidekick.
///
/// Inter and Merriweather are bundled under `assets/google_fonts/`. Disabling
/// runtime fetching prevents FLUTTER-8 crashes when `fonts.gstatic.com` is
/// unreachable (offline, captive portal, DNS failure).
///
/// Also registers both fonts' SIL OFL license texts with [LicenseRegistry] so
/// they appear in Flutter's licenses UI (Settings → About → Licenses), as the
/// OFL asks when redistributing the font binaries. Registration is guarded so
/// repeated calls (app bootstrap + every test suite) add the entries once.
void configureBundledGoogleFonts() {
  GoogleFonts.config.allowRuntimeFetching = false;

  if (_licensesRegistered) return;
  _licensesRegistered = true;
  LicenseRegistry.addLicense(() async* {
    const ofls = <String, String>{
      'Inter': 'assets/google_fonts/OFL-Inter.txt',
      'Merriweather': 'assets/google_fonts/OFL-Merriweather.txt',
    };
    for (final entry in ofls.entries) {
      final text = await rootBundle.loadString(entry.value);
      yield LicenseEntryWithLineBreaks(['google_fonts', entry.key], text);
    }
  });
}
