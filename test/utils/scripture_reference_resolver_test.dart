import 'package:flutter_test/flutter_test.dart';
import 'package:seminary_sidekick/data/scriptures_data.dart';
import 'package:seminary_sidekick/utils/scripture_reference_resolver.dart';

/// Looks up the real ID for [reference] so tests don't hardcode data ordering.
String idFor(String reference) =>
    allScriptures.firstWhere((s) => s.reference == reference).id;

void main() {
  group('findScriptureIdByReference', () {
    test('matches exact reference', () {
      expect(findScriptureIdByReference('Alma 39:9'), idFor('Alma 39:9'));
    });

    test('is case-insensitive', () {
      expect(findScriptureIdByReference('alma 39:9'), idFor('Alma 39:9'));
    });

    test('returns null for unknown reference', () {
      expect(findScriptureIdByReference('Not A Verse 1:1'), isNull);
    });

    test('does not let "D&C 13" swallow "D&C 130:22–23"', () {
      expect(
        findScriptureIdByReference('D&C 130:22–23'),
        idFor('D&C 130:22–23'),
      );
    });

    test('matches a partial verse range against the full reference', () {
      expect(
        findScriptureIdByReference('D&C 130:22'),
        idFor('D&C 130:22–23'),
      );
    });

    test('still matches "D&C 13" exactly', () {
      expect(findScriptureIdByReference('D&C 13'), idFor('D&C 13'));
    });
  });

  group('findScriptureIdInText', () {
    test('finds a reference inside free-form text', () {
      expect(
        findScriptureIdInText('Spend 2 minutes reviewing Alma 39:9 today.'),
        idFor('Alma 39:9'),
      );
    });

    test('returns null when no reference is present', () {
      expect(findScriptureIdInText('Keep up the great work today!'), isNull);
    });

    test('resolves a D&C range reference in text to the right scripture', () {
      expect(
        findScriptureIdInText('Take a look at D&C 130:22–23 this morning.'),
        idFor('D&C 130:22–23'),
      );
    });
  });

  group('resolveScriptureId', () {
    test('prefers valid explicit scriptureId', () {
      expect(
        resolveScriptureId(
          scriptureId: idFor('Alma 39:9'),
          suggestionText: 'Review Mosiah 3:19',
        ),
        idFor('Alma 39:9'),
      );
    });

    test('falls back to reference parsed from suggestion text', () {
      expect(
        resolveScriptureId(
          suggestionText:
              'Spend 2 minutes reviewing Alma 39:9 to build on your recent quiz.',
        ),
        idFor('Alma 39:9'),
      );
    });

    test('ignores invalid scriptureId and parses suggestion instead', () {
      expect(
        resolveScriptureId(
          scriptureId: 'Alma 39:9',
          suggestionText: 'Spend 2 minutes reviewing Alma 39:9.',
        ),
        idFor('Alma 39:9'),
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
