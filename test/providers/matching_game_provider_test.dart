import 'package:flutter_test/flutter_test.dart';
import 'package:seminary_sidekick/providers/matching_game_provider.dart';
import 'package:seminary_sidekick/models/enums.dart';
import 'package:seminary_sidekick/data/scriptures_data.dart';

void main() {
  late MatchingGameNotifier notifier;

  setUp(() {
    notifier = MatchingGameNotifier();
  });

  group('startGame', () {
    test('beginner creates 4 pairs', () {
      notifier.startGame(difficulty: DifficultyLevel.beginner);

      expect(notifier.state.pairs.length, 4);
      expect(notifier.state.totalPairs, 4);
      expect(notifier.state.difficulty, DifficultyLevel.beginner);
    });

    test('intermediate creates 8 pairs', () {
      notifier.startGame(difficulty: DifficultyLevel.intermediate);

      expect(notifier.state.pairs.length, 8);
      expect(notifier.state.totalPairs, 8);
      expect(notifier.state.difficulty, DifficultyLevel.intermediate);
    });

    test('advanced creates 4 pairs', () {
      notifier.startGame(difficulty: DifficultyLevel.advanced);

      expect(notifier.state.pairs.length, 4);
      expect(notifier.state.totalPairs, 4);
    });

    test('master creates 4 pairs', () {
      notifier.startGame(difficulty: DifficultyLevel.master);

      expect(notifier.state.pairs.length, 4);
      expect(notifier.state.totalPairs, 4);
    });

    test('shuffledReferences and shuffledPhrases have correct length', () {
      notifier.startGame(difficulty: DifficultyLevel.beginner);

      expect(notifier.state.shuffledReferences.length, 4);
      expect(notifier.state.shuffledPhrases.length, 4);
    });

    test('shuffled lists contain same IDs as pairs', () {
      notifier.startGame(difficulty: DifficultyLevel.beginner);

      final pairIds =
          notifier.state.pairs.map((p) => p.scripture.id).toSet();
      final phraseIds = notifier.state.shuffledPhrases.toSet();
      final refIds = notifier.state.shuffledReferences.toSet();

      expect(phraseIds, pairIds);
      expect(refIds, pairIds);
    });

    test('book filter restricts scriptures to that book', () {
      notifier.startGame(
        difficulty: DifficultyLevel.beginner,
        bookFilter: ScriptureBook.bookOfMormon,
      );

      for (final pair in notifier.state.pairs) {
        expect(pair.scripture.book, ScriptureBook.bookOfMormon);
      }
      expect(notifier.state.bookFilter, ScriptureBook.bookOfMormon);
    });

    test('pair count capped by available scriptures when filtered', () {
      // Intermediate wants 8 pairs, but a single book may have fewer.
      // Just verify the pair count does not exceed what's available.
      final bomCount =
          allScriptures.where((s) => s.book == ScriptureBook.oldTestament).length;

      notifier.startGame(
        difficulty: DifficultyLevel.intermediate,
        bookFilter: ScriptureBook.oldTestament,
      );

      expect(notifier.state.pairs.length, lessThanOrEqualTo(bomCount));
      expect(notifier.state.pairs.length, notifier.state.totalPairs);
    });

    test('all pairs start unmatched', () {
      notifier.startGame(difficulty: DifficultyLevel.beginner);

      for (final pair in notifier.state.pairs) {
        expect(pair.isMatched, false);
      }
    });

    test('game state is reset on new startGame call', () {
      notifier.startGame(difficulty: DifficultyLevel.beginner);
      // Manually make a match to dirty the state
      final id = notifier.state.pairs.first.scripture.id;
      notifier.selectPhrase(id);
      notifier.selectReference(id);

      // Start a new game — state should be fresh
      notifier.startGame(difficulty: DifficultyLevel.intermediate);

      expect(notifier.state.correctMatches, 0);
      expect(notifier.state.incorrectAttempts, 0);
      expect(notifier.state.isComplete, false);
      expect(notifier.state.selectedPhraseId, isNull);
      expect(notifier.state.selectedReferenceId, isNull);
      expect(notifier.state.lastFeedback, isNull);
      expect(notifier.state.lastMatchedId, isNull);
    });

    test('initial state has zero matches and no selections', () {
      notifier.startGame(difficulty: DifficultyLevel.beginner);

      expect(notifier.state.correctMatches, 0);
      expect(notifier.state.incorrectAttempts, 0);
      expect(notifier.state.isComplete, false);
      expect(notifier.state.selectedPhraseId, isNull);
      expect(notifier.state.selectedReferenceId, isNull);
      expect(notifier.state.completionTime, isNull);
    });
  });

  group('selectPhrase', () {
    test('sets selectedPhraseId in state', () {
      notifier.startGame(difficulty: DifficultyLevel.beginner);
      final id = notifier.state.pairs.first.scripture.id;

      notifier.selectPhrase(id);

      expect(notifier.state.selectedPhraseId, id);
      expect(notifier.state.selectedReferenceId, isNull);
    });

    test('does nothing if pair is already matched', () {
      notifier.startGame(difficulty: DifficultyLevel.beginner);
      final id = notifier.state.pairs.first.scripture.id;

      // Match the pair first
      notifier.selectPhrase(id);
      notifier.selectReference(id);
      expect(notifier.state.correctMatches, 1);

      // Try to select the matched phrase again
      notifier.selectPhrase(id);

      // selectedPhraseId should remain null (cleared after match)
      expect(notifier.state.selectedPhraseId, isNull);
    });

    test('clears previous feedback on new selection', () {
      notifier.startGame(difficulty: DifficultyLevel.beginner);
      final ids = notifier.state.pairs.map((p) => p.scripture.id).toList();

      // Create a wrong match to set feedback
      notifier.selectPhrase(ids[0]);
      notifier.selectReference(ids[1]);
      expect(notifier.state.lastFeedback, 'incorrect');

      // Select a new phrase — feedback should clear
      notifier.selectPhrase(ids[0]);
      expect(notifier.state.lastFeedback, isNull);
    });
  });

  group('selectReference', () {
    test('sets selectedReferenceId in state', () {
      notifier.startGame(difficulty: DifficultyLevel.beginner);
      final id = notifier.state.pairs.first.scripture.id;

      notifier.selectReference(id);

      expect(notifier.state.selectedReferenceId, id);
      expect(notifier.state.selectedPhraseId, isNull);
    });

    test('does nothing if pair is already matched', () {
      notifier.startGame(difficulty: DifficultyLevel.beginner);
      final id = notifier.state.pairs.first.scripture.id;

      // Match the pair
      notifier.selectPhrase(id);
      notifier.selectReference(id);

      // Try to select the matched reference again
      notifier.selectReference(id);
      expect(notifier.state.selectedReferenceId, isNull);
    });
  });

  group('matching — correct', () {
    test('phrase then reference with same ID is correct match', () {
      notifier.startGame(difficulty: DifficultyLevel.beginner);
      final id = notifier.state.pairs.first.scripture.id;

      notifier.selectPhrase(id);
      notifier.selectReference(id);

      expect(notifier.state.correctMatches, 1);
      expect(notifier.state.lastFeedback, 'correct');
      expect(notifier.state.lastMatchedId, id);
      expect(notifier.state.selectedPhraseId, isNull);
      expect(notifier.state.selectedReferenceId, isNull);
    });

    test('reference then phrase with same ID is correct match', () {
      notifier.startGame(difficulty: DifficultyLevel.beginner);
      final id = notifier.state.pairs[1].scripture.id;

      notifier.selectReference(id);
      notifier.selectPhrase(id);

      expect(notifier.state.correctMatches, 1);
      expect(notifier.state.lastFeedback, 'correct');
      expect(notifier.state.lastMatchedId, id);
    });

    test('correct match marks pair as matched', () {
      notifier.startGame(difficulty: DifficultyLevel.beginner);
      final id = notifier.state.pairs.first.scripture.id;

      notifier.selectPhrase(id);
      notifier.selectReference(id);

      expect(notifier.isMatched(id), true);
    });

    test('correct match does not increment incorrectAttempts', () {
      notifier.startGame(difficulty: DifficultyLevel.beginner);
      final id = notifier.state.pairs.first.scripture.id;

      notifier.selectPhrase(id);
      notifier.selectReference(id);

      expect(notifier.state.incorrectAttempts, 0);
    });
  });

  group('matching — incorrect', () {
    test('mismatched IDs increment incorrectAttempts', () {
      notifier.startGame(difficulty: DifficultyLevel.beginner);
      final ids = notifier.state.pairs.map((p) => p.scripture.id).toList();

      notifier.selectPhrase(ids[0]);
      notifier.selectReference(ids[1]);

      expect(notifier.state.incorrectAttempts, 1);
      expect(notifier.state.lastFeedback, 'incorrect');
      expect(notifier.state.correctMatches, 0);
    });

    test('incorrect match clears selections', () {
      notifier.startGame(difficulty: DifficultyLevel.beginner);
      final ids = notifier.state.pairs.map((p) => p.scripture.id).toList();

      notifier.selectPhrase(ids[0]);
      notifier.selectReference(ids[1]);

      expect(notifier.state.selectedPhraseId, isNull);
      expect(notifier.state.selectedReferenceId, isNull);
    });

    test('incorrect match does not mark any pair as matched', () {
      notifier.startGame(difficulty: DifficultyLevel.beginner);
      final ids = notifier.state.pairs.map((p) => p.scripture.id).toList();

      notifier.selectPhrase(ids[0]);
      notifier.selectReference(ids[1]);

      for (final pair in notifier.state.pairs) {
        expect(pair.isMatched, false);
      }
    });

    test('multiple incorrect attempts accumulate', () {
      notifier.startGame(difficulty: DifficultyLevel.beginner);
      final ids = notifier.state.pairs.map((p) => p.scripture.id).toList();

      notifier.selectPhrase(ids[0]);
      notifier.selectReference(ids[1]);
      notifier.selectPhrase(ids[0]);
      notifier.selectReference(ids[1]);
      notifier.selectPhrase(ids[0]);
      notifier.selectReference(ids[1]);

      expect(notifier.state.incorrectAttempts, 3);
    });
  });

  group('attemptDragMatch', () {
    test('correct drag match works same as tap match', () {
      notifier.startGame(difficulty: DifficultyLevel.beginner);
      final id = notifier.state.pairs.first.scripture.id;

      notifier.attemptDragMatch(draggedId: id, targetId: id);

      expect(notifier.state.correctMatches, 1);
      expect(notifier.state.lastFeedback, 'correct');
      expect(notifier.isMatched(id), true);
    });

    test('incorrect drag match works same as tap mismatch', () {
      notifier.startGame(difficulty: DifficultyLevel.beginner);
      final ids = notifier.state.pairs.map((p) => p.scripture.id).toList();

      notifier.attemptDragMatch(draggedId: ids[0], targetId: ids[1]);

      expect(notifier.state.incorrectAttempts, 1);
      expect(notifier.state.lastFeedback, 'incorrect');
    });
  });

  group('game completion', () {
    test('matching all pairs sets isComplete to true', () {
      notifier.startGame(difficulty: DifficultyLevel.beginner);
      final ids = notifier.state.pairs.map((p) => p.scripture.id).toList();

      for (final id in ids) {
        notifier.selectPhrase(id);
        notifier.selectReference(id);
      }

      expect(notifier.state.isComplete, true);
      expect(notifier.state.correctMatches, ids.length);
    });

    test('completion sets completionTime', () {
      notifier.startGame(difficulty: DifficultyLevel.beginner);
      final ids = notifier.state.pairs.map((p) => p.scripture.id).toList();

      expect(notifier.state.completionTime, isNull);

      for (final id in ids) {
        notifier.selectPhrase(id);
        notifier.selectReference(id);
      }

      expect(notifier.state.completionTime, isNotNull);
    });

    test('not complete until all pairs matched', () {
      notifier.startGame(difficulty: DifficultyLevel.beginner);
      final ids = notifier.state.pairs.map((p) => p.scripture.id).toList();

      // Match all but the last pair
      for (int i = 0; i < ids.length - 1; i++) {
        notifier.selectPhrase(ids[i]);
        notifier.selectReference(ids[i]);
      }

      expect(notifier.state.isComplete, false);
      expect(notifier.state.correctMatches, ids.length - 1);

      // Match the last pair
      notifier.selectPhrase(ids.last);
      notifier.selectReference(ids.last);

      expect(notifier.state.isComplete, true);
    });
  });

  group('star rating', () {
    test('0 incorrect attempts gives 3 stars', () {
      notifier.startGame(difficulty: DifficultyLevel.beginner);
      final ids = notifier.state.pairs.map((p) => p.scripture.id).toList();

      for (final id in ids) {
        notifier.selectPhrase(id);
        notifier.selectReference(id);
      }

      expect(notifier.state.incorrectAttempts, 0);
      expect(notifier.state.starRating, 3);
    });

    test('1 incorrect attempt gives 2 stars', () {
      notifier.startGame(difficulty: DifficultyLevel.beginner);
      final ids = notifier.state.pairs.map((p) => p.scripture.id).toList();

      // One wrong match
      notifier.selectPhrase(ids[0]);
      notifier.selectReference(ids[1]);

      // Then match all correctly
      for (final id in ids) {
        notifier.selectPhrase(id);
        notifier.selectReference(id);
      }

      expect(notifier.state.incorrectAttempts, 1);
      expect(notifier.state.starRating, 2);
    });

    test('2 incorrect attempts gives 2 stars', () {
      notifier.startGame(difficulty: DifficultyLevel.beginner);
      final ids = notifier.state.pairs.map((p) => p.scripture.id).toList();

      // Two wrong matches
      notifier.selectPhrase(ids[0]);
      notifier.selectReference(ids[1]);
      notifier.selectPhrase(ids[0]);
      notifier.selectReference(ids[1]);

      // Then match all correctly
      for (final id in ids) {
        notifier.selectPhrase(id);
        notifier.selectReference(id);
      }

      expect(notifier.state.incorrectAttempts, 2);
      expect(notifier.state.starRating, 2);
    });

    test('3 or more incorrect attempts gives 1 star', () {
      notifier.startGame(difficulty: DifficultyLevel.beginner);
      final ids = notifier.state.pairs.map((p) => p.scripture.id).toList();

      // Three wrong matches
      notifier.selectPhrase(ids[0]);
      notifier.selectReference(ids[1]);
      notifier.selectPhrase(ids[0]);
      notifier.selectReference(ids[1]);
      notifier.selectPhrase(ids[0]);
      notifier.selectReference(ids[1]);

      // Then match all correctly
      for (final id in ids) {
        notifier.selectPhrase(id);
        notifier.selectReference(id);
      }

      expect(notifier.state.incorrectAttempts, 3);
      expect(notifier.state.starRating, 1);
    });
  });

  group('clearFeedback', () {
    test('clears lastFeedback and lastMatchedId', () {
      notifier.startGame(difficulty: DifficultyLevel.beginner);
      final id = notifier.state.pairs.first.scripture.id;

      notifier.selectPhrase(id);
      notifier.selectReference(id);
      expect(notifier.state.lastFeedback, 'correct');
      expect(notifier.state.lastMatchedId, id);

      notifier.clearFeedback();
      expect(notifier.state.lastFeedback, isNull);
      expect(notifier.state.lastMatchedId, isNull);
    });
  });

  group('getScripture', () {
    test('returns scripture for valid ID in current game', () {
      notifier.startGame(difficulty: DifficultyLevel.beginner);
      final id = notifier.state.pairs.first.scripture.id;

      final scripture = notifier.getScripture(id);

      expect(scripture, isNotNull);
      expect(scripture!.id, id);
    });

    test('returns null for ID not in current game', () {
      notifier.startGame(difficulty: DifficultyLevel.beginner);

      final scripture = notifier.getScripture('nonexistent-id');

      expect(scripture, isNull);
    });
  });

  group('isMatched', () {
    test('returns false for unmatched pair', () {
      notifier.startGame(difficulty: DifficultyLevel.beginner);
      final id = notifier.state.pairs.first.scripture.id;

      expect(notifier.isMatched(id), false);
    });

    test('returns true after pair is correctly matched', () {
      notifier.startGame(difficulty: DifficultyLevel.beginner);
      final id = notifier.state.pairs.first.scripture.id;

      notifier.selectPhrase(id);
      notifier.selectReference(id);

      expect(notifier.isMatched(id), true);
    });

    test('returns false for IDs not in the game', () {
      notifier.startGame(difficulty: DifficultyLevel.beginner);

      expect(notifier.isMatched('nonexistent-id'), false);
    });
  });

  group('accuracy', () {
    test('accuracy is 0 initially', () {
      notifier.startGame(difficulty: DifficultyLevel.beginner);

      expect(notifier.state.accuracy, 0.0);
    });

    test('accuracy is 1.0 with all correct and no incorrect', () {
      notifier.startGame(difficulty: DifficultyLevel.beginner);
      final ids = notifier.state.pairs.map((p) => p.scripture.id).toList();

      for (final id in ids) {
        notifier.selectPhrase(id);
        notifier.selectReference(id);
      }

      expect(notifier.state.accuracy, 1.0);
    });

    test('accuracy accounts for incorrect attempts', () {
      notifier.startGame(difficulty: DifficultyLevel.beginner);
      final ids = notifier.state.pairs.map((p) => p.scripture.id).toList();

      // One incorrect attempt
      notifier.selectPhrase(ids[0]);
      notifier.selectReference(ids[1]);

      // Then one correct
      notifier.selectPhrase(ids[0]);
      notifier.selectReference(ids[0]);

      // 1 correct / (1 correct + 1 incorrect) = 0.5
      expect(notifier.state.accuracy, 0.5);
    });
  });
}
