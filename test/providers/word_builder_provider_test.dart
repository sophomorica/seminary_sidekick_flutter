import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seminary_sidekick/providers/word_builder_provider.dart';
import 'package:seminary_sidekick/models/enums.dart';
import 'package:seminary_sidekick/models/scripture.dart';
import 'package:seminary_sidekick/models/scripture.dart' as scripture_model;

import '../helpers/test_helpers.dart';

void main() {
  late ProviderContainer container;
  late WordBuilderNotifier notifier;

  setUp(() {
    container = ProviderContainer();
    notifier = container.read(wordBuilderProvider.notifier);
  });

  tearDown(() {
    container.dispose();
  });

  group('Word Builder — Chunk-Tap Mode', () {
    test('startGame beginner — mode is chunkTap, chunks are size 3', () {
      notifier.startGame(difficulty: DifficultyLevel.beginner);

      expect(notifier.state.mode, WordBuilderMode.chunkTap);
      expect(notifier.state.difficulty, DifficultyLevel.beginner);
      expect(notifier.state.scriptureQueue.length,
          DifficultyLevel.beginner.scriptureCount);

      // Check chunk size
      for (final chunk in notifier.state.targetChunks) {
        expect(chunk.wordCount, lessThanOrEqualTo(3));
      }
    });

    test('startGame intermediate — mode is chunkTap, chunks are size 2', () {
      notifier.startGame(difficulty: DifficultyLevel.intermediate);

      expect(notifier.state.mode, WordBuilderMode.chunkTap);
      expect(notifier.state.difficulty, DifficultyLevel.intermediate);
      expect(notifier.state.scriptureQueue.length,
          DifficultyLevel.intermediate.scriptureCount);

      // Check chunk size
      for (final chunk in notifier.state.targetChunks) {
        expect(chunk.wordCount, lessThanOrEqualTo(2));
      }
    });

    test('Chunk count — ceil(wordCount / chunkSize) chunks created', () {
      final scripture = testScriptures[0]; // 24 words
      notifier.startGame(
          difficulty: DifficultyLevel.beginner, scriptures: [scripture]);

      // Beginner: chunk size 3, 24 words = 8 chunks
      expect(notifier.state.targetChunks.length, 8);

      notifier = WordBuilderNotifier(); // Reset
      notifier.startGame(
          difficulty: DifficultyLevel.intermediate, scriptures: [scripture]);

      // Intermediate: chunk size 2, 24 words = 12 chunks
      expect(notifier.state.targetChunks.length, 12);
    });

    test(
        'Intermediate has distractors — availablePool.length > targetChunks.length',
        () {
      notifier.startGame(difficulty: DifficultyLevel.intermediate);

      expect(notifier.state.availablePool.length,
          greaterThan(notifier.state.targetChunks.length));
    });

    test(
        'Beginner has no distractors — availablePool.length == targetChunks.length',
        () {
      notifier.startGame(difficulty: DifficultyLevel.beginner);

      expect(notifier.state.availablePool.length,
          equals(notifier.state.targetChunks.length));
    });

    test(
        'selectChunk — correct — chunk placed, removed from pool, correctPlacements increments',
        () {
      final scripture = testScriptures[0];
      notifier.startGame(
          difficulty: DifficultyLevel.beginner, scriptures: [scripture]);

      final initialPoolSize = notifier.state.availablePool.length;
      final initialCorrect = notifier.state.correctPlacements;

      // Find the first correct chunk in the pool
      int correctIndex = -1;
      for (int i = 0; i < notifier.state.availablePool.length; i++) {
        if (!notifier.state.availablePool[i].isDistractor &&
            notifier.state.availablePool[i].startIndex == 0) {
          correctIndex = i;
          break;
        }
      }
      expect(correctIndex, isNot(-1), reason: 'Should find correct chunk');

      notifier.selectChunk(correctIndex);

      expect(notifier.state.availablePool.length, initialPoolSize - 1);
      expect(notifier.state.correctPlacements, initialCorrect + 1);
      expect(notifier.state.placedChunks[0], isNotNull);
      expect(notifier.state.lastFeedback, 'correct');
    });

    test('selectChunk — wrong — incorrectAttempts increments, pool unchanged',
        () {
      notifier.startGame(
          difficulty: DifficultyLevel.intermediate); // Has distractors

      final initialPoolSize = notifier.state.availablePool.length;
      final initialIncorrect = notifier.state.incorrectAttempts;

      // Find a distractor
      int distractorIndex = -1;
      for (int i = 0; i < notifier.state.availablePool.length; i++) {
        if (notifier.state.availablePool[i].isDistractor) {
          distractorIndex = i;
          break;
        }
      }
      if (distractorIndex == -1) {
        // No distractors, find wrong correct chunk
        for (int i = 0; i < notifier.state.availablePool.length; i++) {
          if (!notifier.state.availablePool[i].isDistractor &&
              notifier.state.availablePool[i].startIndex != 0) {
            distractorIndex = i;
            break;
          }
        }
      }

      notifier.selectChunk(distractorIndex);

      expect(notifier.state.availablePool.length, initialPoolSize);
      expect(notifier.state.incorrectAttempts, initialIncorrect + 1);
      expect(notifier.state.lastFeedback, 'incorrect');
    });

    test('Scripture complete — isScriptureComplete true when all chunks placed',
        () {
      final scripture = testScriptures[0];
      notifier.startGame(
          difficulty: DifficultyLevel.beginner, scriptures: [scripture]);

      // Place all chunks correctly
      while (!notifier.state.isScriptureComplete) {
        // Find next correct chunk
        int correctIndex = -1;
        final nextSlot = notifier.state.nextChunkIndex;
        for (int i = 0; i < notifier.state.availablePool.length; i++) {
          if (!notifier.state.availablePool[i].isDistractor &&
              notifier.state.availablePool[i].startIndex == nextSlot * 3) {
            correctIndex = i;
            break;
          }
        }
        if (correctIndex == -1) break; // No more correct chunks
        notifier.selectChunk(correctIndex);
      }

      expect(notifier.state.isScriptureComplete, isTrue);
    });

    test(
        'Multi-scripture progression — nextScripture() loads next, index increments',
        () {
      final scriptures = [testScriptures[0], testScriptures[1]];
      notifier.startGame(
          difficulty: DifficultyLevel.beginner, scriptures: scriptures);

      final firstScripture = notifier.state.currentScripture;
      expect(notifier.state.currentIndex, 0);

      notifier.nextScripture();

      expect(notifier.state.currentIndex, 1);
      expect(notifier.state.currentScripture, isNot(equals(firstScripture)));
    });

    test('All scriptures done — isComplete true, completionTime set', () {
      final scriptures = [testScriptures[0]];
      notifier.startGame(
          difficulty: DifficultyLevel.beginner, scriptures: scriptures);

      // Complete the scripture
      while (!notifier.state.isScriptureComplete) {
        int correctIndex = -1;
        final nextSlot = notifier.state.nextChunkIndex;
        for (int i = 0; i < notifier.state.availablePool.length; i++) {
          if (!notifier.state.availablePool[i].isDistractor &&
              notifier.state.availablePool[i].startIndex == nextSlot * 3) {
            correctIndex = i;
            break;
          }
        }
        if (correctIndex == -1) break;
        notifier.selectChunk(correctIndex);
      }

      notifier.nextScripture();

      expect(notifier.state.isComplete, isTrue);
      expect(notifier.state.completionTime, isNotNull);
    });

    test('Color indices assigned — each chunk has sequential colorIndex', () {
      notifier.startGame(difficulty: DifficultyLevel.beginner);

      for (int i = 0; i < notifier.state.targetChunks.length; i++) {
        expect(notifier.state.targetChunks[i].colorIndex, i % 8);
      }
    });
  });

  group('Word Builder — Typing Mode', () {
    test('startGame advanced — mode is typing, targetText is fullText', () {
      notifier.startGame(difficulty: DifficultyLevel.advanced);

      expect(notifier.state.mode, WordBuilderMode.typing);
      expect(notifier.state.difficulty, DifficultyLevel.advanced);
      expect(notifier.state.targetText, isNotEmpty);
      expect(notifier.state.targetText,
          equals(notifier.state.currentScripture!.fullText));
    });

    test('startGame master — mode is typing', () {
      notifier.startGame(difficulty: DifficultyLevel.master);

      expect(notifier.state.mode, WordBuilderMode.typing);
      expect(notifier.state.difficulty, DifficultyLevel.master);
    });

    test(
        'onType — correct character — typedChars grows, char marked isCorrect: true',
        () {
      notifier.startGame(difficulty: DifficultyLevel.advanced);

      final firstChar = notifier.state.targetText[0];
      notifier.onType(firstChar);

      expect(notifier.state.typedText, firstChar);
      expect(notifier.state.typedChars.length, 1);
      expect(notifier.state.typedChars[0].char, firstChar);
      expect(notifier.state.typedChars[0].isCorrect, isTrue);
      expect(notifier.state.correctPlacements, 1);
    });

    test(
        'onType — wrong character (advanced) — char marked isCorrect: false, hasActiveError true',
        () {
      notifier.startGame(difficulty: DifficultyLevel.advanced);

      final correctChar = notifier.state.targetText[0];
      notifier.onType(correctChar); // Type correct first
      notifier.onType(correctChar + 'x'); // Then wrong

      expect(notifier.state.typedChars[1].isCorrect, isFalse);
      expect(notifier.state.hasActiveError, isTrue);
      expect(notifier.state.incorrectAttempts, 1);
      expect(notifier.state.lastFeedback, 'incorrect');
    });

    test(
        'onType — blocked when error active (advanced) — new chars ignored until error deleted',
        () {
      notifier.startGame(difficulty: DifficultyLevel.advanced);

      final correctChar = notifier.state.targetText[0];
      notifier.onType(correctChar); // Correct
      notifier.onType(correctChar + 'x'); // Wrong - now has error
      expect(notifier.state.hasActiveError, isTrue);

      // Try to type more - should be blocked
      final blockedText = correctChar + 'x' + notifier.state.targetText[1];
      notifier.onType(blockedText);
      expect(notifier.state.typedText, correctChar + 'x'); // Should not change
    });

    test(
        'onType — backspace (advanced) — last char removed, hasActiveError recalculated',
        () {
      notifier.startGame(difficulty: DifficultyLevel.advanced);

      final correctChar = notifier.state.targetText[0];
      notifier.onType(correctChar); // Correct
      notifier.onType(correctChar + 'x'); // Wrong

      expect(notifier.state.hasActiveError, isTrue);
      expect(notifier.state.typedChars.length, 2);

      // Backspace to remove error
      notifier.onType(correctChar);
      expect(notifier.state.hasActiveError, isFalse);
      expect(notifier.state.typedChars.length, 1);
      expect(notifier.state.typedChars[0].isCorrect, isTrue);
    });

    test(
        'onType — wrong character (master) — full reset: typedText empty, resetCount increments',
        () {
      notifier.startGame(difficulty: DifficultyLevel.master);

      final correctChar = notifier.state.targetText[0];
      notifier.onType(correctChar); // Correct first
      expect(notifier.state.correctPlacements, 1);

      notifier.onType(correctChar + 'x'); // Then wrong

      expect(notifier.state.typedText, isEmpty);
      expect(notifier.state.typedChars, isEmpty);
      expect(notifier.state.resetCount, 1);
      expect(notifier.state.correctPlacements, 0); // Reset to 0
      expect(notifier.state.correctUnitsAcrossAll, 0); // Undone
      expect(notifier.state.lastFeedback, 'reset');
    });

    test('onType — backspace (master) — ignored (returns early)', () {
      notifier.startGame(difficulty: DifficultyLevel.master);

      final char = notifier.state.targetText[0];
      notifier.onType(char);

      final lengthBefore = notifier.state.typedText.length;
      notifier.onType(''); // Simulate backspace

      expect(notifier.state.typedText.length, lengthBefore);
    });

    test('Case insensitive matching — \'a\' matches \'A\'', () {
      final scripture = Scripture(
        id: 'case-test',
        book: ScriptureBook.bookOfMormon,
        volume: 'Test',
        reference: 'Test 1:1',
        name: 'Case Test',
        keyPhrase: 'Test',
        fullText: 'Hello World',
      );
      notifier.startGame(
          difficulty: DifficultyLevel.advanced, scriptures: [scripture]);

      notifier.onType('h'); // lowercase
      expect(notifier.state.typedChars[0].isCorrect, isTrue);

      notifier.onType('hE'); // mixed case
      expect(notifier.state.typedChars[1].isCorrect, isTrue);
    });

    test('Typing completion — isScriptureComplete true when all chars typed',
        () {
      notifier.startGame(difficulty: DifficultyLevel.advanced);

      notifier.onType(notifier.state.targetText);

      expect(notifier.state.isScriptureComplete, isTrue);
      expect(notifier.state.lastFeedback, 'correct');
    });

    test(
        'correctUnitsAcrossAll tracking — increments across multiple scriptures',
        () {
      final scriptures = [testScriptures[0], testScriptures[1]];
      notifier.startGame(
          difficulty: DifficultyLevel.advanced, scriptures: scriptures);

      final firstChar = notifier.state.targetText[0];
      notifier.onType(firstChar);

      final afterFirst = notifier.state.correctUnitsAcrossAll;

      notifier.nextScripture();

      final secondChar = notifier.state.targetText[0];
      notifier.onType(secondChar);

      expect(notifier.state.correctUnitsAcrossAll, afterFirst + 1);
    });

    test(
        'Master reset undoes correctUnitsAcrossAll — count decremented by correctPlacements on reset',
        () {
      notifier.startGame(difficulty: DifficultyLevel.master);

      // Type some correct chars incrementally
      final chars = notifier.state.targetText.substring(0, 3).split('');
      for (int i = 0; i < chars.length; i++) {
        final partial = notifier.state.targetText.substring(0, i + 1);
        notifier.onType(partial);
      }
      expect(notifier.state.correctPlacements, 3);
      final correctAcrossBefore = notifier.state.correctUnitsAcrossAll;
      expect(correctAcrossBefore, 3);

      // Type wrong to trigger reset
      notifier.onType(notifier.state.targetText.substring(0, 3) + 'x');

      expect(notifier.state.correctUnitsAcrossAll, correctAcrossBefore - 3);
    });

    test('Star rating — 0 errors=3, 1-3 errors=2, 4+ errors=1', () {
      notifier.startGame(difficulty: DifficultyLevel.advanced);

      // 0 errors
      expect(notifier.state.starRating, 3);

      // Add 1 error
      notifier.onType('x');
      expect(notifier.state.starRating, 2);

      // Backspace to clear error, then add another error
      notifier.onType('');
      notifier.onType('x');
      expect(notifier.state.incorrectAttempts, 2);
      expect(notifier.state.starRating, 2);

      // Backspace and add third error
      notifier.onType('');
      notifier.onType('x');
      expect(notifier.state.incorrectAttempts, 3);
      expect(notifier.state.starRating, 2);

      // Backspace and add fourth error
      notifier.onType('');
      notifier.onType('x');
      expect(notifier.state.incorrectAttempts, 4);
      expect(notifier.state.starRating, 1);
    });
  });
}
