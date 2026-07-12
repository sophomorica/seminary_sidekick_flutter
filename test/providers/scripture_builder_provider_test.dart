import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seminary_sidekick/providers/scripture_builder_provider.dart';
import 'package:seminary_sidekick/models/enums.dart';
import 'package:seminary_sidekick/models/scripture.dart';

import '../helpers/test_helpers.dart';

void main() {
  late ProviderContainer container;
  late ScriptureBuilderNotifier notifier;

  setUp(() {
    container = ProviderContainer();
    notifier = container.read(scriptureBuilderProvider.notifier);
  });

  tearDown(() {
    container.dispose();
  });

  group('Scripture Builder — Chunk-Tap Mode', () {
    test('startGame beginner — mode is chunkTap, chunks are size 3', () {
      notifier.startGame(difficulty: DifficultyLevel.beginner);

      expect(notifier.state.mode, ScriptureBuilderMode.chunkTap);
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

      expect(notifier.state.mode, ScriptureBuilderMode.chunkTap);
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

      notifier = ScriptureBuilderNotifier(); // Reset
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
        'selectChunk — correct — chunk placed, marked used (pool length unchanged), correctPlacements increments',
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

      // Pool length stays the same so Wrap layout doesn't reflow — the
      // chunk is tracked as "used" instead of being removed.
      expect(notifier.state.availablePool.length, initialPoolSize);
      expect(notifier.state.usedPoolIndices.contains(correctIndex), isTrue);
      expect(notifier.state.correctPlacements, initialCorrect + 1);
      expect(notifier.state.placedChunks[0], isNotNull);
      expect(notifier.state.lastFeedback, 'correct');
    });

    test('selectChunk — tapping already-used chunk is a no-op', () {
      final scripture = testScriptures[0];
      notifier.startGame(
          difficulty: DifficultyLevel.beginner, scriptures: [scripture]);

      // Find and place the first correct chunk.
      int correctIndex = -1;
      for (int i = 0; i < notifier.state.availablePool.length; i++) {
        if (!notifier.state.availablePool[i].isDistractor &&
            notifier.state.availablePool[i].startIndex == 0) {
          correctIndex = i;
          break;
        }
      }
      notifier.selectChunk(correctIndex);

      final placedSnapshot =
          List<WordChunk?>.from(notifier.state.placedChunks);
      final correctSnapshot = notifier.state.correctPlacements;
      final incorrectSnapshot = notifier.state.incorrectAttempts;
      final nextIdxSnapshot = notifier.state.nextChunkIndex;

      // Tapping the same (already-used) index again must do nothing.
      notifier.selectChunk(correctIndex);

      expect(notifier.state.placedChunks, equals(placedSnapshot));
      expect(notifier.state.correctPlacements, correctSnapshot);
      expect(notifier.state.incorrectAttempts, incorrectSnapshot);
      expect(notifier.state.nextChunkIndex, nextIdxSnapshot);
    });

    test(
        'selectChunk — identical duplicate chunks are interchangeable (text match, not startIndex)',
        () {
      // 6 words → two identical beginner chunks: "words of God" at
      // startIndex 0 and startIndex 3.
      final scripture = Scripture(
        id: 'test-dup',
        book: ScriptureBook.bookOfMormon,
        volume: '2 Nephi',
        reference: '2 Nephi 32:3',
        name: 'Duplicate Chunks',
        keyPhrase: 'words of God',
        fullText: 'words of God words of God',
      );
      notifier.startGame(
          difficulty: DifficultyLevel.beginner, scriptures: [scripture]);

      expect(notifier.state.targetChunks.length, 2);
      expect(notifier.state.targetChunks[0].text,
          notifier.state.targetChunks[1].text);

      // Slot 0 expects startIndex 0 — deliberately tap the duplicate tile
      // whose startIndex differs (3) but whose text matches.
      final expectedStart = notifier.state.targetChunks[0].startIndex;
      int dupIndex = -1;
      for (int i = 0; i < notifier.state.availablePool.length; i++) {
        final c = notifier.state.availablePool[i];
        if (!c.isDistractor && c.startIndex != expectedStart) {
          dupIndex = i;
          break;
        }
      }
      expect(dupIndex, isNot(-1), reason: 'Should find the duplicate tile');

      notifier.selectChunk(dupIndex);

      expect(notifier.state.lastFeedback, 'correct');
      expect(notifier.state.placedChunks[0], isNotNull);
      expect(notifier.state.placedChunks[0]!.text, 'words of God');
      expect(notifier.state.usedPoolIndices.contains(dupIndex), isTrue);
      expect(notifier.state.correctPlacements, 1);
      expect(notifier.state.incorrectAttempts, 0);
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

  group('Scripture Builder — Typing Mode', () {
    test('startGame advanced — mode is typing, targetText is fullText', () {
      notifier.startGame(
          difficulty: DifficultyLevel.advanced,
          scriptures: [testScriptures[0]]);

      expect(notifier.state.mode, ScriptureBuilderMode.typing);
      expect(notifier.state.difficulty, DifficultyLevel.advanced);
      expect(notifier.state.targetText, isNotEmpty);
      expect(notifier.state.targetText,
          equals(notifier.state.currentScripture!.fullText));
    });

    test('startGame master — mode is typing', () {
      notifier.startGame(
          difficulty: DifficultyLevel.master, scriptures: [testScriptures[0]]);

      expect(notifier.state.mode, ScriptureBuilderMode.typing);
      expect(notifier.state.difficulty, DifficultyLevel.master);
    });

    test(
        'onType — correct character — typedChars grows, char marked isCorrect: true',
        () {
      // Use a scripture without punctuation at the start to keep assertions simple
      notifier.startGame(
          difficulty: DifficultyLevel.advanced,
          scriptures: [testScriptures[0]]);

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
      notifier.startGame(
          difficulty: DifficultyLevel.advanced,
          scriptures: [testScriptures[0]]);

      final correctChar = notifier.state.targetText[0];
      notifier.onType(correctChar); // Type correct first
      notifier.onType('${correctChar}x'); // Then wrong

      expect(notifier.state.typedChars[1].isCorrect, isFalse);
      expect(notifier.state.hasActiveError, isTrue);
      expect(notifier.state.incorrectAttempts, 1);
      expect(notifier.state.lastFeedback, 'incorrect');
    });

    test(
        'onType — blocked when error active (advanced) — new chars ignored until error deleted',
        () {
      notifier.startGame(
          difficulty: DifficultyLevel.advanced,
          scriptures: [testScriptures[0]]);

      final correctChar = notifier.state.targetText[0];
      notifier.onType(correctChar); // Correct
      notifier.onType('${correctChar}x'); // Wrong - now has error
      expect(notifier.state.hasActiveError, isTrue);

      // Try to type more - should be blocked
      final blockedText = '${correctChar}x${notifier.state.targetText[1]}';
      notifier.onType(blockedText);
      expect(notifier.state.typedText, '${correctChar}x'); // Should not change
    });

    test(
        'onType — backspace (advanced) — last char removed, hasActiveError recalculated',
        () {
      notifier.startGame(
          difficulty: DifficultyLevel.advanced,
          scriptures: [testScriptures[0]]);

      final correctChar = notifier.state.targetText[0];
      notifier.onType(correctChar); // Correct
      notifier.onType('${correctChar}x'); // Wrong

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
      notifier.startGame(
          difficulty: DifficultyLevel.master, scriptures: [testScriptures[0]]);

      final correctChar = notifier.state.targetText[0];
      notifier.onType(correctChar); // Correct first
      expect(notifier.state.correctPlacements, 1);

      notifier.onType('${correctChar}x'); // Then wrong

      expect(notifier.state.typedText, isEmpty);
      expect(notifier.state.typedChars, isEmpty);
      expect(notifier.state.resetCount, 1);
      expect(notifier.state.correctPlacements, 0); // Reset to 0
      expect(notifier.state.correctUnitsAcrossAll, 0); // Undone
      expect(notifier.state.lastFeedback, 'reset');
    });

    test('onType — backspace (master) — ignored (returns early)', () {
      notifier.startGame(
          difficulty: DifficultyLevel.master, scriptures: [testScriptures[0]]);

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
      // Use a short scripture without punctuation for clean incremental typing
      final scripture = Scripture(
        id: 'completion-test',
        book: ScriptureBook.bookOfMormon,
        volume: 'Test',
        reference: 'Test 1:1',
        name: 'Completion Test',
        keyPhrase: 'Test',
        fullText: 'Be still',
      );
      notifier.startGame(
          difficulty: DifficultyLevel.advanced, scriptures: [scripture]);

      // Type each character incrementally (how onType actually works)
      final target = notifier.state.targetText;
      for (int i = 0; i < target.length; i++) {
        notifier.onType(target.substring(0, i + 1));
      }

      expect(notifier.state.isScriptureComplete, isTrue);
      expect(notifier.state.lastFeedback, 'correct');
    });

    test(
        'correctUnitsAcrossAll tracking — increments across multiple scriptures',
        () {
      // Use scriptures without punctuation for predictable counts
      final scriptures = [testScriptures[0], testScriptures[2]];
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
      // Use a scripture without punctuation for predictable counts
      notifier.startGame(
          difficulty: DifficultyLevel.master, scriptures: [testScriptures[0]]);

      // Type some correct chars incrementally
      final chars = notifier.state.targetText.substring(0, 3).split('');
      for (int i = 0; i < chars.length; i++) {
        final partial = notifier.state.targetText.substring(0, i + 1);
        notifier.onType(partial);
      }
      // 3 typed chars + 1 auto-filled trailing space after 'd' in "And "
      expect(notifier.state.correctPlacements, 4);
      final correctAcrossBefore = notifier.state.correctUnitsAcrossAll;
      expect(correctAcrossBefore, 4);

      // Type wrong to trigger reset
      notifier.onType('${notifier.state.targetText.substring(0, 3)}x');

      expect(notifier.state.correctUnitsAcrossAll, correctAcrossBefore - 4);
    });

    test('Star rating — 0 errors=3, 1-3 errors=2, 4+ errors=1', () {
      notifier.startGame(
          difficulty: DifficultyLevel.advanced,
          scriptures: [testScriptures[0]]);

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

  group('Scripture Builder — Punctuation Auto-Fill', () {
    test('Punctuation is auto-filled when next expected char is punctuation',
        () {
      // "In the beginning was the Word, and the Word was with God, ..."
      notifier.startGame(
          difficulty: DifficultyLevel.advanced,
          scriptures: [shortPunctuatedScripture]);

      final target = notifier.state.targetText;
      // Target: "In the beginning was the Word, and ..."
      // Find the comma after "Word" — type up to 'd' in "Word"
      final commaIndex = target.indexOf(',');
      expect(commaIndex, greaterThan(0),
          reason: 'Test scripture must have a comma');

      // Type each char up to two before the comma (before 'd')
      String typed = '';
      for (int i = 0; i < commaIndex - 1; i++) {
        typed += target[i];
        notifier.onType(typed);
      }

      // Before typing 'd', comma is not yet auto-filled
      expect(notifier.state.typedChars.length, commaIndex - 1);

      // Type 'd' — the trailing comma should be auto-filled immediately
      typed += target[commaIndex - 1];
      notifier.onType(typed);

      // typedChars should include: all typed chars + auto-filled comma + auto-filled space
      expect(notifier.state.typedChars.length, commaIndex + 2);
      // The comma should be auto-filled and marked correct
      expect(notifier.state.typedChars[commaIndex].char, ',');
      expect(notifier.state.typedChars[commaIndex].isCorrect, isTrue);
      // The space after the comma should also be auto-filled
      expect(notifier.state.typedChars[commaIndex + 1].char, ' ');
      expect(notifier.state.typedChars[commaIndex + 1].isCorrect, isTrue);
    });

    test(
        'Speech-to-text simulation — typing without punctuation completes scripture',
        () {
      // Use a short scripture: "In the beginning was the Word, and the Word was with God, and the Word was God."
      notifier.startGame(
          difficulty: DifficultyLevel.advanced,
          scriptures: [shortPunctuatedScripture]);

      final target = notifier.state.targetText;

      // Simulate speech-to-text: type only non-punctuation characters
      String typed = '';
      for (int i = 0; i < target.length; i++) {
        final ch = target[i];
        // Skip punctuation chars (they'll be auto-filled)
        if (RegExp(r'''[,;:!?\-\—\–\.\'\"\'\'\"\"\(\)\[\]]''').hasMatch(ch)) {
          continue;
        }
        typed += ch;
        notifier.onType(typed);

        // If scripture is complete, stop
        if (notifier.state.isScriptureComplete) break;
      }

      expect(notifier.state.isScriptureComplete, isTrue);
      // All chars in typedChars should be correct (including auto-filled punctuation)
      expect(
        notifier.state.typedChars.every((tc) => tc.isCorrect),
        isTrue,
        reason: 'All chars including auto-filled punctuation should be correct',
      );
      expect(notifier.state.typedChars.length, target.length);
    });

    test(
        'User-typed punctuation is ignored in advanced mode — no error, no reset',
        () {
      // Regression: typing a natural "Word," (with the comma) used to count
      // the comma as a wrong character.
      notifier.startGame(
          difficulty: DifficultyLevel.advanced,
          scriptures: [shortPunctuatedScripture]);

      final target = notifier.state.targetText;
      final commaIndex = target.indexOf(',');

      // Type every char up to and including the char before the comma
      String typed = '';
      for (int i = 0; i < commaIndex; i++) {
        typed += target[i];
        notifier.onType(typed);
      }
      final placedBefore = notifier.state.typedChars.length;
      expect(notifier.state.hasActiveError, isFalse);

      // Now the user types the comma itself — it must be ignored, not flagged
      typed += ',';
      notifier.onType(typed);

      expect(notifier.state.hasActiveError, isFalse,
          reason: 'User-typed punctuation must not register as an error');
      expect(notifier.state.incorrectAttempts, 0);
      expect(notifier.state.typedChars.length, placedBefore,
          reason: 'Ignored punctuation adds nothing to typedChars');

      // And typing continues normally afterwards
      final nextLetterIndex = notifier.state.typedChars.length;
      typed += target[nextLetterIndex];
      notifier.onType(typed);
      expect(notifier.state.hasActiveError, isFalse);
      expect(notifier.state.typedChars.every((tc) => tc.isCorrect), isTrue);
    });

    test('User-typed punctuation does NOT trigger a master reset', () {
      // Regression: on Master difficulty a typed comma caused a full reset.
      notifier.startGame(
          difficulty: DifficultyLevel.master,
          scriptures: [shortPunctuatedScripture]);

      final target = notifier.state.targetText;
      final commaIndex = target.indexOf(',');

      String typed = '';
      for (int i = 0; i < commaIndex; i++) {
        typed += target[i];
        notifier.onType(typed);
      }
      final placedBefore = notifier.state.typedChars.length;
      expect(placedBefore, greaterThan(0));

      // User types the comma — previously wiped all progress
      typed += ',';
      notifier.onType(typed);

      expect(notifier.state.resetCount, 0,
          reason: 'Typed punctuation must not reset a Master run');
      expect(notifier.state.typedChars.length, placedBefore);
      expect(notifier.state.incorrectAttempts, 0);
    });

    test('Trailing punctuation is auto-filled after last real character', () {
      // "...was God." — the period at the end should auto-fill
      notifier.startGame(
          difficulty: DifficultyLevel.advanced,
          scriptures: [shortPunctuatedScripture]);

      final target = notifier.state.targetText;
      expect(target.endsWith('.'), isTrue,
          reason: 'Scripture should end with period');

      // Type everything except punctuation
      String typed = '';
      for (int i = 0; i < target.length; i++) {
        final ch = target[i];
        if (RegExp(r'''[,;:!?\-\—\–\.\'\"\'\'\"\"\(\)\[\]]''').hasMatch(ch)) {
          continue;
        }
        typed += ch;
        notifier.onType(typed);
        if (notifier.state.isScriptureComplete) break;
      }

      // The trailing period should have been auto-filled
      expect(notifier.state.isScriptureComplete, isTrue);
      expect(notifier.state.typedChars.last.char, '.');
      expect(notifier.state.typedChars.last.isCorrect, isTrue);
    });

    test('Punctuation auto-fill counts toward correctPlacements and progress',
        () {
      notifier.startGame(
          difficulty: DifficultyLevel.advanced,
          scriptures: [shortPunctuatedScripture]);

      final target = notifier.state.targetText;
      final commaIndex = target.indexOf(',');

      // Type up to two chars before the comma (before 'd')
      String typed = '';
      for (int i = 0; i < commaIndex - 1; i++) {
        typed += target[i];
        notifier.onType(typed);
      }
      final placementsBefore = notifier.state.correctPlacements;

      // Type 'd' — comma and space auto-fill as trailing non-letters (+1 for 'd', +1 for comma, +1 for space)
      typed += target[commaIndex - 1];
      notifier.onType(typed);

      // Should have gained 3: typed 'd' + auto-filled comma + auto-filled space
      expect(notifier.state.correctPlacements, placementsBefore + 3);
    });

    test('Backspace removes auto-filled punctuation in advanced mode', () {
      notifier.startGame(
          difficulty: DifficultyLevel.advanced,
          scriptures: [shortPunctuatedScripture]);

      final target = notifier.state.targetText;
      final commaIndex = target.indexOf(',');

      // Type up to and past the comma (auto-filled)
      String typed = '';
      for (int i = 0; i < commaIndex; i++) {
        typed += target[i];
        notifier.onType(typed);
      }
      // Type the space after comma — comma auto-fills
      typed += target[commaIndex + 1];
      notifier.onType(typed);
      final charsAfterCommaFill = notifier.state.typedChars.length;

      // Now backspace — should remove the space AND the auto-filled comma
      typed = typed.substring(0, typed.length - 1);
      notifier.onType(typed);

      expect(notifier.state.typedChars.length, charsAfterCommaFill - 2,
          reason:
              'Backspace should remove typed char + auto-filled punctuation');
    });

    test('Master reset works correctly with punctuation in scripture', () {
      notifier.startGame(
          difficulty: DifficultyLevel.master,
          scriptures: [shortPunctuatedScripture]);

      final target = notifier.state.targetText;
      final commaIndex = target.indexOf(',');

      // Type up to the comma, then past it
      String typed = '';
      for (int i = 0; i < commaIndex; i++) {
        typed += target[i];
        notifier.onType(typed);
      }
      // Type the char after comma to trigger auto-fill of comma
      typed += target[commaIndex + 1];
      notifier.onType(typed);
      expect(notifier.state.typedChars.length, greaterThan(commaIndex));

      // Now type a wrong character to trigger master reset
      typed += 'x';
      notifier.onType(typed);

      expect(notifier.state.typedText, isEmpty);
      expect(notifier.state.typedChars, isEmpty);
      expect(notifier.state.resetCount, 1);
      expect(notifier.state.correctPlacements, 0);
    });

    test('Progress calculation uses typedChars length (includes auto-filled)',
        () {
      notifier.startGame(
          difficulty: DifficultyLevel.advanced,
          scriptures: [shortPunctuatedScripture]);

      final target = notifier.state.targetText;
      final commaIndex = target.indexOf(',');

      // Type up to comma
      String typed = '';
      for (int i = 0; i < commaIndex; i++) {
        typed += target[i];
        notifier.onType(typed);
      }
      // Type char after comma — comma auto-fills
      typed += target[commaIndex + 1];
      notifier.onType(typed);

      // Progress should account for auto-filled punctuation
      final expectedProgress = notifier.state.typedChars.length / target.length;
      expect(notifier.state.typingProgress, closeTo(expectedProgress, 0.001));
      // typedChars should be 1 more than typedText due to auto-filled comma
      expect(notifier.state.typedChars.length,
          greaterThan(notifier.state.typedText.length));
    });

    test('Multiple consecutive punctuation chars are all auto-filled', () {
      // Scripture with em-dash: "faith—faith"
      notifier.startGame(
          difficulty: DifficultyLevel.advanced,
          scriptures: [punctuatedScripture]);

      final target = notifier.state.targetText;
      // Find the em-dash
      final dashIndex = target.indexOf('—');
      expect(dashIndex, greaterThan(0),
          reason: 'Punctuated scripture should contain em-dash');

      // Type up to two before the dash, skipping punctuation (auto-filled by provider)
      final punctRegex = RegExp(r'''[,;:!?\-\—\–\.\'\"\'\'\"\"\.\(\)\[\]]''');
      String typed = '';
      for (int i = 0; i <= dashIndex - 2; i++) {
        if (punctRegex.hasMatch(target[i])) continue;
        typed += target[i];
        notifier.onType(typed);
      }
      final charsBefore = notifier.state.typedChars.length;

      // Type 'h' (last char before em-dash) — dash should auto-fill as trailing
      typed += target[dashIndex - 1]; // 'h' in "faith"
      notifier.onType(typed);

      // Should have typed 'h' + auto-filled em-dash
      expect(notifier.state.typedChars.length, charsBefore + 2);
      expect(notifier.state.typedChars[dashIndex].char, '—');
      expect(notifier.state.typedChars[dashIndex].isCorrect, isTrue);
    });
  });

  group('Scripture Builder — Speech-to-text', () {
    test(
        'Master: partial prefix of first word does not reset (regression)',
        () {
      // Bug: STT partials like "a" while targeting "And" were treated as wrong
      // words, immediately resetting Master and stopping the mic — speech
      // appeared to never activate the game.
      notifier.startGame(
        difficulty: DifficultyLevel.master,
        scriptures: [testScriptures[0]],
      );

      final didReset = notifier.onSpeechInput(
        'a',
        baselineCharCount: 0,
        isFinal: false,
      );

      expect(didReset, isFalse);
      expect(notifier.state.resetCount, 0);
      expect(notifier.state.typedChars, isEmpty);
      expect(notifier.state.lastFeedback, isNull);
    });

    test('Master: growing partials then final commit progress', () {
      notifier.startGame(
        difficulty: DifficultyLevel.master,
        scriptures: [testScriptures[0]],
      );

      // Simulate recognizer revising in place: "a" → "and" → "and it"
      notifier.onSpeechInput('a', baselineCharCount: 0, isFinal: false);
      expect(notifier.state.typedChars, isEmpty);

      notifier.onSpeechInput('and', baselineCharCount: 0, isFinal: false);
      expect(notifier.state.typedChars.isNotEmpty, isTrue);
      expect(notifier.state.resetCount, 0);
      final afterAnd = notifier.state.typedChars.length;

      notifier.onSpeechInput('and it', baselineCharCount: 0, isFinal: false);
      expect(notifier.state.typedChars.length, greaterThan(afterAnd));
      expect(notifier.state.resetCount, 0);

      notifier.onSpeechInput('and it', baselineCharCount: 0, isFinal: true);
      expect(notifier.state.typedChars.length, greaterThan(afterAnd));
      expect(notifier.state.resetCount, 0);
    });

    test('Master: wrong final word resets', () {
      notifier.startGame(
        difficulty: DifficultyLevel.master,
        scriptures: [testScriptures[0]],
      );

      final didReset = notifier.onSpeechInput(
        'Nope',
        baselineCharCount: 0,
        isFinal: true,
      );

      expect(didReset, isTrue);
      expect(notifier.state.resetCount, 1);
      expect(notifier.state.typedChars, isEmpty);
      expect(notifier.state.lastFeedback, 'reset');
    });

    test('Master: full correct speech completes scripture', () {
      notifier.startGame(
        difficulty: DifficultyLevel.master,
        scriptures: [testScriptures[0]],
      );

      // Strip punctuation from target for spoken words
      final spoken = notifier.state.targetText
          .replaceAll(RegExp(r'''[,;:!?\-\—\–\.\'\"\'\'\"\"\(\)\[\]]'''), '')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();

      final didReset = notifier.onSpeechInput(
        spoken,
        baselineCharCount: 0,
        isFinal: true,
      );

      expect(didReset, isFalse);
      expect(notifier.state.isScriptureComplete, isTrue);
      expect(notifier.state.resetCount, 0);
    });

    test('Master: speech continues from typed baseline', () {
      notifier.startGame(
        difficulty: DifficultyLevel.master,
        scriptures: [testScriptures[0]],
      );

      // Type first word "And" manually
      String typed = '';
      for (final ch in 'And'.split('')) {
        typed += ch;
        notifier.onType(typed);
      }
      final baseline = notifier.state.typedChars.length;
      expect(baseline, greaterThan(0));

      notifier.onSpeechInput(
        'it came',
        baselineCharCount: baseline,
        isFinal: true,
      );

      expect(notifier.state.resetCount, 0);
      expect(notifier.state.typedChars.length, greaterThan(baseline));
      expect(
        notifier.state.typedText.toLowerCase().startsWith('and it came'),
        isTrue,
      );
    });

    test('Master: homophone four/for accepted', () {
      // Target starts "For God..." (test-2)
      notifier.startGame(
        difficulty: DifficultyLevel.master,
        scriptures: [testScriptures[1]],
      );

      final didReset = notifier.onSpeechInput(
        'four God',
        baselineCharCount: 0,
        isFinal: true,
      );

      expect(didReset, isFalse);
      expect(notifier.state.resetCount, 0);
      expect(notifier.state.typedChars.isNotEmpty, isTrue);
    });
  });
}
