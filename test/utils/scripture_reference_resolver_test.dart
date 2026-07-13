import 'package:flutter_test/flutter_test.dart';
import 'package:seminary_sidekick/utils/scripture_reference_resolver.dart';

void main() {
  group('findScriptureIdByReference', () {
    test('matches exact reference', () {
      expect(findScriptureIdByReference('Alma 39:9'), '63');
    });

    test('is case-insensitive', () {
      expect(findScriptureIdByReference('alma 39:9'), '63');
    });

    test('returns null for unknown reference', () {
      expect(findScriptureIdByReference('Not A Verse 1:1'), isNull);
    });
  });

  group('resolveScriptureId', () {
    test('prefers valid explicit scriptureId', () {
      expect(
        resolveScriptureId(
          scriptureId: '63',
          suggestionText: 'Review Mosiah 3:19',
        ),
        '63',
      );
    });

    test('falls back to reference parsed from suggestion text', () {
      expect(
        resolveScriptureId(
          suggestionText:
              'Spend 2 minutes reviewing Alma 39:9 to build on your recent quiz.',
        ),
        '63',
      );
    });

    test('ignores invalid scriptureId and parses suggestion instead', () {
      expect(
        resolveScriptureId(
          scriptureId: 'Alma 39:9',
          suggestionText: 'Spend 2 minutes reviewing Alma 39:9.',
        ),
        '63',
      );
    });

    test('returns null when nothing resolves', () {
      expect(
        resolveScriptureId(suggestionText: 'Keep up the great work today!'),
        isNull,
      );
    });
  });
}
