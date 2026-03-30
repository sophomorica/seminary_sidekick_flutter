import 'package:flutter_test/flutter_test.dart';
import 'package:seminary_sidekick/models/enums.dart';

void main() {
  group('ScriptureBook', () {
    test('has exactly 4 values', () {
      expect(ScriptureBook.values.length, equals(4));
    });

    test('contains expected values', () {
      expect(ScriptureBook.values, contains(ScriptureBook.oldTestament));
      expect(ScriptureBook.values, contains(ScriptureBook.newTestament));
      expect(ScriptureBook.values, contains(ScriptureBook.bookOfMormon));
      expect(
          ScriptureBook.values, contains(ScriptureBook.doctrineAndCovenants));
    });

    test('all displayNames are non-empty', () {
      for (final book in ScriptureBook.values) {
        expect(book.displayName, isNotEmpty,
            reason: '${book.name} has empty displayName');
      }
    });

    test('all abbreviations are non-empty', () {
      for (final book in ScriptureBook.values) {
        expect(book.abbreviation, isNotEmpty,
            reason: '${book.name} has empty abbreviation');
      }
    });
  });

  group('MasteryLevel', () {
    test('has exactly 5 values', () {
      expect(MasteryLevel.values.length, equals(5));
    });

    test('ordering by index matches progression', () {
      expect(MasteryLevel.newScripture.index,
          lessThan(MasteryLevel.learning.index));
      expect(
          MasteryLevel.learning.index, lessThan(MasteryLevel.familiar.index));
      expect(MasteryLevel.familiar.index,
          lessThan(MasteryLevel.memorized.index));
      expect(
          MasteryLevel.memorized.index, lessThan(MasteryLevel.mastered.index));
    });

    test('minAccuracy is non-decreasing across progression', () {
      // newScripture and learning both have 0.0, then it increases
      expect(MasteryLevel.newScripture.minAccuracy,
          lessThanOrEqualTo(MasteryLevel.learning.minAccuracy));
      expect(MasteryLevel.learning.minAccuracy,
          lessThanOrEqualTo(MasteryLevel.familiar.minAccuracy));
      expect(MasteryLevel.familiar.minAccuracy,
          lessThanOrEqualTo(MasteryLevel.memorized.minAccuracy));
      expect(MasteryLevel.memorized.minAccuracy,
          lessThanOrEqualTo(MasteryLevel.mastered.minAccuracy));
    });

    test('mastered has highest minAccuracy', () {
      for (final level in MasteryLevel.values) {
        if (level != MasteryLevel.mastered) {
          expect(level.minAccuracy,
              lessThanOrEqualTo(MasteryLevel.mastered.minAccuracy),
              reason: '${level.name} has higher minAccuracy than mastered');
        }
      }
    });

    test('all labels are non-empty', () {
      for (final level in MasteryLevel.values) {
        expect(level.label, isNotEmpty,
            reason: '${level.name} has empty label');
      }
    });

    test('all descriptions are non-empty', () {
      for (final level in MasteryLevel.values) {
        expect(level.description, isNotEmpty,
            reason: '${level.name} has empty description');
      }
    });
  });

  group('GameType', () {
    test('has exactly 3 values', () {
      expect(GameType.values.length, equals(3));
    });

    test('contains expected values', () {
      expect(GameType.values, contains(GameType.matching));
      expect(GameType.values, contains(GameType.wordOrder));
      expect(GameType.values, contains(GameType.quiz));
    });

    test('all displayNames are non-empty', () {
      for (final game in GameType.values) {
        expect(game.displayName, isNotEmpty,
            reason: '${game.name} has empty displayName');
      }
    });

    test('all descriptions are non-empty', () {
      for (final game in GameType.values) {
        expect(game.description, isNotEmpty,
            reason: '${game.name} has empty description');
      }
    });
  });

  group('DifficultyLevel', () {
    test('has exactly 4 values', () {
      expect(DifficultyLevel.values.length, equals(4));
    });

    test('contains expected values', () {
      expect(DifficultyLevel.values, contains(DifficultyLevel.beginner));
      expect(DifficultyLevel.values, contains(DifficultyLevel.intermediate));
      expect(DifficultyLevel.values, contains(DifficultyLevel.advanced));
      expect(DifficultyLevel.values, contains(DifficultyLevel.master));
    });

    test('all labels are non-empty', () {
      for (final level in DifficultyLevel.values) {
        expect(level.label, isNotEmpty,
            reason: '${level.name} has empty label');
      }
    });

    test('all descriptions are non-empty', () {
      for (final level in DifficultyLevel.values) {
        expect(level.description, isNotEmpty,
            reason: '${level.name} has empty description');
      }
    });

    test('scriptureCount is always positive', () {
      for (final level in DifficultyLevel.values) {
        expect(level.scriptureCount, greaterThan(0),
            reason: '${level.name} has non-positive scriptureCount');
      }
    });

    test('intermediate has highest scriptureCount', () {
      // intermediate = 8, others = 4
      expect(DifficultyLevel.intermediate.scriptureCount,
          greaterThan(DifficultyLevel.beginner.scriptureCount));
    });

    test('only intermediate has extra distractors', () {
      expect(DifficultyLevel.beginner.extraDistractors, equals(0));
      expect(
          DifficultyLevel.intermediate.extraDistractors, greaterThan(0));
      expect(DifficultyLevel.advanced.extraDistractors, equals(0));
      expect(DifficultyLevel.master.extraDistractors, equals(0));
    });

    test('beginner does not have timer', () {
      expect(DifficultyLevel.beginner.hasTimer, isFalse);
    });

    test('all non-beginner levels have timer', () {
      expect(DifficultyLevel.intermediate.hasTimer, isTrue);
      expect(DifficultyLevel.advanced.hasTimer, isTrue);
      expect(DifficultyLevel.master.hasTimer, isTrue);
    });

    test('beginner and intermediate allow retry', () {
      expect(DifficultyLevel.beginner.allowRetry, isTrue);
      expect(DifficultyLevel.intermediate.allowRetry, isTrue);
    });

    test('advanced and master do not allow retry', () {
      expect(DifficultyLevel.advanced.allowRetry, isFalse);
      expect(DifficultyLevel.master.allowRetry, isFalse);
    });
  });

  group('DifficultyLevel — descriptionForGame', () {
    test('returns non-empty descriptions for all game/difficulty combos', () {
      for (final difficulty in DifficultyLevel.values) {
        for (final game in GameType.values) {
          final desc = difficulty.descriptionForGame(game);
          expect(desc, isNotEmpty,
              reason:
                  '${difficulty.name} x ${game.name} has empty description');
        }
      }
    });

    test('matching descriptions differ from wordOrder descriptions', () {
      for (final difficulty in DifficultyLevel.values) {
        final matchingDesc =
            difficulty.descriptionForGame(GameType.matching);
        final wordOrderDesc =
            difficulty.descriptionForGame(GameType.wordOrder);
        expect(matchingDesc, isNot(equals(wordOrderDesc)),
            reason:
                '${difficulty.name}: matching and wordOrder have same description');
      }
    });
  });
}
