import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seminary_sidekick/theme/google_fonts_bootstrap.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('configureBundledGoogleFonts', () {
    test('disables runtime fetching from fonts.gstatic.com', () {
      GoogleFonts.config.allowRuntimeFetching = true;
      configureBundledGoogleFonts();
      expect(GoogleFonts.config.allowRuntimeFetching, isFalse);
    });

    test('registers OFL license texts for Inter and Merriweather', () async {
      configureBundledGoogleFonts();
      final licenses = await LicenseRegistry.licenses.toList();
      bool hasFont(String name) => licenses.any(
            (l) =>
                l.packages.contains('google_fonts') &&
                l.packages.contains(name),
          );
      expect(hasFont('Inter'), isTrue,
          reason: 'OFL-Inter.txt must be registered with LicenseRegistry');
      expect(hasFont('Merriweather'), isTrue,
          reason:
              'OFL-Merriweather.txt must be registered with LicenseRegistry');
    });
  });

  group('bundled google_fonts assets', () {
    // Weights/styles actually requested by AppTheme + a few screens.
    // Merriweather w600 closest-matches to Bold in google_fonts metadata.
    const requiredFonts = <String>[
      'Inter-Regular.ttf',
      'Inter-Medium.ttf',
      'Inter-SemiBold.ttf',
      'Inter-Bold.ttf',
      'Merriweather-Regular.ttf',
      'Merriweather-Italic.ttf',
      'Merriweather-Bold.ttf',
      'Merriweather-BoldItalic.ttf',
    ];

    test('assets include every Inter/Merriweather file AppTheme needs',
        () async {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final assets = manifest.listAssets();

      for (final fontFile in requiredFonts) {
        expect(
          assets.any((path) => path.endsWith(fontFile)),
          isTrue,
          reason: '$fontFile must be listed under assets/google_fonts/ '
              'so offline GoogleFonts loads do not hit the network '
              '(Sentry FLUTTER-8)',
        );
      }
    });

    test(
        'every AppTheme font variant actually loads from bundled assets '
        'with fetching disabled', () async {
      configureBundledGoogleFonts();

      final styles = <TextStyle>[
        GoogleFonts.inter(),
        GoogleFonts.inter(fontWeight: FontWeight.w500),
        GoogleFonts.inter(fontWeight: FontWeight.w600),
        GoogleFonts.inter(fontWeight: FontWeight.w700),
        GoogleFonts.merriweather(),
        GoogleFonts.merriweather(fontStyle: FontStyle.italic),
        // w600 must closest-match to the bundled Bold files, not fetch.
        GoogleFonts.merriweather(fontWeight: FontWeight.w600),
        GoogleFonts.merriweather(
          fontWeight: FontWeight.w600,
          fontStyle: FontStyle.italic,
        ),
        GoogleFonts.merriweather(fontWeight: FontWeight.w700),
        GoogleFonts.merriweather(
          fontWeight: FontWeight.w700,
          fontStyle: FontStyle.italic,
        ),
      ];

      // pendingFonts throws if any variant would require a network fetch —
      // this is the regression test for FLUTTER-8.
      await expectLater(GoogleFonts.pendingFonts(styles), completes);
    });
  });
}
