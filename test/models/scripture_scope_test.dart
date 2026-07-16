import 'package:flutter_test/flutter_test.dart';
import 'package:seminary_sidekick/models/enums.dart';
import 'package:seminary_sidekick/models/scripture_mastery.dart';
import 'package:seminary_sidekick/models/scripture_scope.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('ScriptureScope JSON round-trip', () {
    test('empty filter round-trips', () {
      const scope = ScriptureScope();
      final restored = ScriptureScope.fromJson(scope.toJson());
      expect(restored, equals(scope));
      expect(restored.isUnfiltered, isTrue);
    });

    test('books + status + ids round-trip', () {
      const scope = ScriptureScope(
        books: {
          ScriptureBook.oldTestament,
          ScriptureBook.bookOfMormon,
        },
        needsReview: true,
        nearlyMastered: true,
        specificIds: ['a', 'b'],
      );
      final restored = ScriptureScope.fromJson(scope.toJson());
      expect(restored, equals(scope));
    });

    test('legacy ScopeAll migrates to empty filter', () {
      final restored = ScriptureScope.fromJson({'type': 'all'});
      expect(restored.isUnfiltered, isTrue);
    });

    test('legacy ScopeBooks migrates', () {
      final restored = ScriptureScope.fromJson({
        'type': 'books',
        'books': ['bookOfMormon', 'oldTestament'],
      });
      expect(restored.books, {
        ScriptureBook.bookOfMormon,
        ScriptureBook.oldTestament,
      });
      expect(restored.hasStatusFilter, isFalse);
    });

    test('legacy ScopeScriptureIds migrates and preserves order', () {
      final restored = ScriptureScope.fromJson({
        'type': 'ids',
        'ids': ['c', 'a', 'b'],
      });
      expect(restored.specificIds, ['c', 'a', 'b']);
    });

    test('legacy NeedsReview migrates', () {
      final restored = ScriptureScope.fromJson({'type': 'needsReview'});
      expect(restored.needsReview, isTrue);
      expect(restored.nearlyMastered, isFalse);
    });

    test('legacy NearlyMastered migrates', () {
      final restored = ScriptureScope.fromJson({'type': 'nearlyMastered'});
      expect(restored.nearlyMastered, isTrue);
    });

    test('Unknown type falls back to empty filter', () {
      final restored = ScriptureScope.fromJson({'type': 'martian'});
      expect(restored.isUnfiltered, isTrue);
    });
  });

  group('ScriptureScope.resolve', () {
    final all = testScriptures;
    // Fixture: 5 scriptures across 4 books — test-1 (BoM), test-2 (NT),
    // test-3 (OT), test-4 (D&C), test-5 (BoM).

    test('empty filter returns every scripture, in order', () {
      const scope = ScriptureScope();
      expect(scope.resolve(all), equals(all));
    });

    test('books filter unions selected volumes', () {
      const scope = ScriptureScope(books: {
        ScriptureBook.newTestament,
        ScriptureBook.oldTestament,
      });
      final out = scope.resolve(all);
      expect(out.map((s) => s.id).toSet(), {'test-2', 'test-3'});
    });

    test('empty books set means all books (not none)', () {
      const scope = ScriptureScope(books: {});
      expect(scope.resolve(all), equals(all));
    });

    test('specific ids preserve order and drop unknowns', () {
      const scope = ScriptureScope(specificIds: ['test-4', 'missing', 'test-1']);
      final out = scope.resolve(all);
      expect(out.map((s) => s.id).toList(), ['test-4', 'test-1']);
    });

    test('needsReview with no lookup matches nothing', () {
      const scope = ScriptureScope(needsReview: true);
      expect(scope.resolve(all), isEmpty);
    });

    test('needsReview filters via the mastery lookup', () {
      final flagged = {'test-2', 'test-4'};
      ScriptureMastery? lookup(String id) => _mastery(
            id: id,
            level: MasteryLevel.familiar,
            subProgress: 0.2,
            needsReview: flagged.contains(id),
          );
      const scope = ScriptureScope(needsReview: true);
      final out = scope.resolve(all, masteryLookup: lookup);
      expect(out.map((s) => s.id).toSet(), {'test-2', 'test-4'});
    });

    test('book + needsReview ANDs together', () {
      final flagged = {'test-1', 'test-2'}; // BoM + NT
      ScriptureMastery? lookup(String id) => _mastery(
            id: id,
            level: MasteryLevel.familiar,
            subProgress: 0.2,
            needsReview: flagged.contains(id),
          );
      const scope = ScriptureScope(
        books: {ScriptureBook.bookOfMormon},
        needsReview: true,
      );
      final out = scope.resolve(all, masteryLookup: lookup);
      expect(out.map((s) => s.id).toList(), ['test-1']);
    });

    test('needsReview OR nearlyMastered within status filters', () {
      ScriptureMastery? lookup(String id) {
        if (id == 'test-1') {
          return _mastery(
            id: id,
            level: MasteryLevel.familiar,
            subProgress: 0.2,
            needsReview: true,
          );
        }
        if (id == 'test-2') {
          return _mastery(
            id: id,
            level: MasteryLevel.memorized,
            subProgress: 0.8,
            needsReview: false,
          );
        }
        return _mastery(
          id: id,
          level: MasteryLevel.learning,
          subProgress: 0.1,
          needsReview: false,
        );
      }

      const scope = ScriptureScope(needsReview: true, nearlyMastered: true);
      final out = scope.resolve(all, masteryLookup: lookup);
      expect(out.map((s) => s.id).toSet(), {'test-1', 'test-2'});
    });

    test('nearlyMastered excludes Mastered/Eternal', () {
      ScriptureMastery? lookup(String id) {
        if (id == 'test-1') {
          return _mastery(
            id: id,
            level: MasteryLevel.mastered,
            subProgress: 0.9,
            needsReview: false,
          );
        }
        if (id == 'test-2') {
          return _mastery(
            id: id,
            level: MasteryLevel.memorized,
            subProgress: 0.8,
            needsReview: false,
          );
        }
        return _mastery(
          id: id,
          level: MasteryLevel.learning,
          subProgress: 0.1,
          needsReview: false,
        );
      }

      const scope = ScriptureScope(nearlyMastered: true);
      final out = scope.resolve(all, masteryLookup: lookup);
      expect(out.map((s) => s.id).toList(), ['test-2']);
    });

    test('specific ids are constrained to the filtered pool', () {
      const scope = ScriptureScope(
        books: {ScriptureBook.bookOfMormon},
        specificIds: ['test-1', 'test-2', 'test-5'],
      );
      final out = scope.resolve(all);
      // test-2 is NT — outside the BoM filter — dropped.
      expect(out.map((s) => s.id).toList(), ['test-1', 'test-5']);
    });

    test('prunedToFilter drops ids outside the new pool', () {
      const scope = ScriptureScope(
        books: {ScriptureBook.bookOfMormon},
        specificIds: ['test-1', 'test-2'],
      );
      final pruned = scope.prunedToFilter(all);
      expect(pruned.specificIds, ['test-1']);
    });
  });

  group('ScriptureScope equality', () {
    test('books equality is set-based, not order-based', () {
      const a = ScriptureScope(books: {
        ScriptureBook.oldTestament,
        ScriptureBook.newTestament,
      });
      const b = ScriptureScope(books: {
        ScriptureBook.newTestament,
        ScriptureBook.oldTestament,
      });
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('specificIds equality is order-sensitive', () {
      const a = ScriptureScope(specificIds: ['a', 'b']);
      const b = ScriptureScope(specificIds: ['b', 'a']);
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
