import 'package:flutter_test/flutter_test.dart';
import 'package:seminary_sidekick/models/enums.dart';
import 'package:seminary_sidekick/models/scripture_mastery.dart';
import 'package:seminary_sidekick/models/scripture_scope.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('ScriptureScope JSON round-trip', () {
    test('ScopeAll round-trips', () {
      const scope = ScopeAll();
      final restored = ScriptureScope.fromJson(scope.toJson());
      expect(restored, isA<ScopeAll>());
      expect(restored, equals(scope));
    });

    test('ScopeBooks round-trips with multiple books', () {
      const scope = ScopeBooks({
        ScriptureBook.oldTestament,
        ScriptureBook.bookOfMormon,
      });
      final restored = ScriptureScope.fromJson(scope.toJson());
      expect(restored, isA<ScopeBooks>());
      expect((restored as ScopeBooks).books, equals(scope.books));
    });

    test('ScopeBooks with empty set still round-trips', () {
      const scope = ScopeBooks({});
      final restored = ScriptureScope.fromJson(scope.toJson());
      expect(restored, isA<ScopeBooks>());
      expect((restored as ScopeBooks).books, isEmpty);
    });

    test('ScopeScriptureIds preserves order', () {
      const scope = ScopeScriptureIds(['c', 'a', 'b']);
      final restored = ScriptureScope.fromJson(scope.toJson());
      expect(restored, isA<ScopeScriptureIds>());
      expect((restored as ScopeScriptureIds).ids, ['c', 'a', 'b']);
    });

    test('ScopeNeedsReview round-trips', () {
      const scope = ScopeNeedsReview();
      final restored = ScriptureScope.fromJson(scope.toJson());
      expect(restored, isA<ScopeNeedsReview>());
    });

    test('ScopeNearlyMastered round-trips', () {
      const scope = ScopeNearlyMastered();
      final restored = ScriptureScope.fromJson(scope.toJson());
      expect(restored, isA<ScopeNearlyMastered>());
    });

    test('Unknown type falls back to ScopeAll', () {
      final restored = ScriptureScope.fromJson({'type': 'martian'});
      expect(restored, isA<ScopeAll>());
    });

    test('Missing type falls back to ScopeAll', () {
      final restored = ScriptureScope.fromJson({});
      expect(restored, isA<ScopeAll>());
    });
  });

  group('ScriptureScope.resolve', () {
    final all = testScriptures;
    // Fixture: 5 scriptures across 4 books — test-1 (BoM), test-2 (NT),
    // test-3 (OT), test-4 (D&C), test-5 (BoM).

    test('ScopeAll returns every scripture, in order', () {
      const scope = ScopeAll();
      expect(scope.resolve(all), equals(all));
    });

    test('ScopeBooks filters to the selected books', () {
      const scope = ScopeBooks({ScriptureBook.bookOfMormon});
      final out = scope.resolve(all);
      expect(out.map((s) => s.id).toList(), ['test-1', 'test-5']);
    });

    test('ScopeBooks with multiple books unions', () {
      const scope = ScopeBooks({
        ScriptureBook.newTestament,
        ScriptureBook.oldTestament,
      });
      final out = scope.resolve(all);
      expect(out.map((s) => s.id).toSet(), {'test-2', 'test-3'});
    });

    test('ScopeBooks with empty set resolves to empty', () {
      const scope = ScopeBooks({});
      expect(scope.resolve(all), isEmpty);
    });

    test('ScopeScriptureIds returns scriptures in the listed order', () {
      const scope = ScopeScriptureIds(['test-4', 'test-1']);
      final out = scope.resolve(all);
      expect(out.map((s) => s.id).toList(), ['test-4', 'test-1']);
    });

    test('ScopeScriptureIds silently drops unknown ids', () {
      const scope = ScopeScriptureIds(['test-1', 'missing', 'test-3']);
      final out = scope.resolve(all);
      expect(out.map((s) => s.id).toList(), ['test-1', 'test-3']);
    });

    test('ScopeNeedsReview resolves to empty when no lookup provided', () {
      const scope = ScopeNeedsReview();
      expect(scope.resolve(all), isEmpty);
    });

    test('ScopeNeedsReview filters via the mastery lookup', () {
      final flagged = {'test-2', 'test-4'};
      ScriptureMastery? lookup(String id) => _mastery(
            id: id,
            level: MasteryLevel.familiar,
            subProgress: 0.2,
            needsReview: flagged.contains(id),
          );
      const scope = ScopeNeedsReview();
      final out = scope.resolve(all, masteryLookup: lookup);
      expect(out.map((s) => s.id).toSet(), {'test-2', 'test-4'});
    });

    test('ScopeNearlyMastered excludes Mastered/Eternal regardless of subProgress',
        () {
      ScriptureMastery? lookup(String id) {
        if (id == 'test-1') {
          return _mastery(
              id: id,
              level: MasteryLevel.mastered,
              subProgress: 0.9,
              needsReview: false);
        }
        if (id == 'test-2') {
          return _mastery(
              id: id,
              level: MasteryLevel.memorized,
              subProgress: 0.8,
              needsReview: false);
        }
        // Everything else is well below threshold.
        return _mastery(
            id: id,
            level: MasteryLevel.learning,
            subProgress: 0.1,
            needsReview: false);
      }
      const scope = ScopeNearlyMastered();
      final out = scope.resolve(all, masteryLookup: lookup);
      // test-1 is already mastered → excluded
      // test-2 has subProgress 0.8 below mastered → included
      expect(out.map((s) => s.id).toList(), ['test-2']);
    });
  });

  group('ScriptureScope equality', () {
    test('ScopeBooks equality is set-based, not order-based', () {
      const a = ScopeBooks({
        ScriptureBook.oldTestament,
        ScriptureBook.newTestament,
      });
      const b = ScopeBooks({
        ScriptureBook.newTestament,
        ScriptureBook.oldTestament,
      });
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('ScopeScriptureIds equality is order-sensitive', () {
      const a = ScopeScriptureIds(['a', 'b']);
      const b = ScopeScriptureIds(['b', 'a']);
      expect(a == b, isFalse);
    });
  });
}

ScriptureMastery _mastery({
  required String id,
  required MasteryLevel level,
  required double subProgress,
  required bool needsReview,
}) {
  return ScriptureMastery(
    scriptureId: id,
    level: level,
    subProgress: subProgress,
    needsReview: needsReview,
    lastPracticedAny: null,
    highestDifficultyPerGame: const {},
    overallAccuracy: 0,
    totalAttemptsAllGames: 0,
    nextLevelRequirements: const [],
    gameTypesAttempted: 0,
    gameTypesWithCorrect: 0,
  );
}
