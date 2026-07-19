import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seminary_sidekick/providers/scripture_builder_provider.dart';
import 'package:seminary_sidekick/models/enums.dart';
import 'package:seminary_sidekick/models/scripture.dart';
import 'package:seminary_sidekick/data/scriptures_data.dart';

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
    test('startGame beginner — mode is chunkTap, chunks respect adaptive size', () {
      notifier.startGame(difficulty: DifficultyLevel.beginner);

      expect(notifier.state.mode, ScriptureBuilderMode.chunkTap);
      expect(notifier.state.difficulty, DifficultyLevel.beginner);
      expect(notifier.state.scriptureQueue.length,
          DifficultyLevel.beginner.scriptureCount);

      final verseWords =
          notifier.state.currentScripture!.wordsForVerse(0);
      final maxSize = adaptiveChunkSize(
        wordCount: verseWords.length,
        difficulty: DifficultyLevel.beginner,
      );
      for (final chunk in notifier.state.targetChunks) {
        expect(chunk.wordCount, lessThanOrEqualTo(maxSize));
      }
    });

    test('startGame intermediate — mode is chunkTap, chunks respect adaptive size',
        () {
      notifier.startGame(difficulty: DifficultyLevel.intermediate);

      expect(notifier.state.mode, ScriptureBuilderMode.chunkTap);
      expect(notifier.state.difficulty, DifficultyLevel.intermediate);
      expect(notifier.state.scriptureQueue.length,
          DifficultyLevel.intermediate.scriptureCount);

      final verseWords =
          notifier.state.currentScripture!.wordsForVerse(0);
      final maxSize = adaptiveChunkSize(
        wordCount: verseWords.length,
        difficulty: DifficultyLevel.intermediate,
      );
      for (final chunk in notifier.state.targetChunks) {
        expect(chunk.wordCount, lessThanOrEqualTo(maxSize));
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

    group('Verse-gated chunk progression', () {
      Scripture multiVerseFixture() =>
          testScriptures.firstWhere((s) => s.id == 'test-multi-verse');

      /// Place the next correct chunk by matching expected tile text.
      bool placeNextCorrectChunk() {
        final next = notifier.state.nextChunkIndex;
        if (next < 0 || next >= notifier.state.targetChunks.length) {
          return false;
        }
        final expected = notifier.state.targetChunks[next].text;
        for (var i = 0; i < notifier.state.availablePool.length; i++) {
          if (notifier.state.usedPoolIndices.contains(i)) continue;
          final chunk = notifier.state.availablePool[i];
          if (!chunk.isDistractor && chunk.text == expected) {
            notifier.selectChunk(i);
            return true;
          }
        }
        return false;
      }

      void completeCurrentVerse() {
        final target = notifier.state.targetChunks.length;
        for (var i = 0; i < target; i++) {
          expect(placeNextCorrectChunk(), isTrue,
              reason: 'Could not place chunk $i of current verse');
        }
      }

      test('starts on verse 0 with only that verse in the pool', () {
        final multiVerse = multiVerseFixture();
        notifier.startGame(
          difficulty: DifficultyLevel.beginner,
          scriptures: [multiVerse],
        );

        expect(notifier.state.currentVerseIndex, 0);
        expect(notifier.state.completedVerseChunks, isEmpty);
        expect(notifier.state.isScriptureComplete, isFalse);

        final verse0Words = multiVerse.wordsForVerse(0);
        final size = adaptiveChunkSize(
          wordCount: verse0Words.length,
          difficulty: DifficultyLevel.beginner,
        );
        final expectedChunks = (verse0Words.length + size - 1) ~/ size;
        expect(notifier.state.targetChunks, hasLength(expectedChunks));
        expect(
          notifier.state.targetChunks.map((c) => c.text).join(' '),
          equals(verse0Words.join(' ')),
        );
        expect(notifier.state.passageChunkTotal, greaterThan(expectedChunks));
      });

      test('completing a verse advances pool without scripture-complete', () {
        final multiVerse = multiVerseFixture();
        notifier.startGame(
          difficulty: DifficultyLevel.beginner,
          scriptures: [multiVerse],
        );

        completeCurrentVerse();

        expect(notifier.state.isScriptureComplete, isFalse);
        expect(notifier.state.currentVerseIndex, 1);
        expect(notifier.state.completedVerseChunks, isNotEmpty);
        expect(
          notifier.state.targetChunks.map((c) => c.words).expand((w) => w).join(' '),
          equals(multiVerse.wordsForVerse(1).join(' ')),
        );
        // Progress bar is whole-passage — first verse done is partial.
        expect(notifier.state.chunkProgress, greaterThan(0));
        expect(notifier.state.chunkProgress, lessThan(1));
      });

      test('last verse triggers isScriptureComplete only', () {
        final multiVerse = multiVerseFixture();
        notifier.startGame(
          difficulty: DifficultyLevel.beginner,
          scriptures: [multiVerse],
        );

        while (!notifier.state.isScriptureComplete) {
          expect(placeNextCorrectChunk(), isTrue);
        }

        expect(notifier.state.currentVerseIndex, multiVerse.verses.length - 1);
        expect(notifier.state.chunkProgress, equals(1.0));
        expect(notifier.state.isScriptureComplete, isTrue);
      });

      test('adaptive sizing uses current verse word count, not passage', () {
        // Three short verses — each should keep base chunk size 3, not grow
        // as if the joined passage were one blob.
        final multiVerse = multiVerseFixture();
        notifier.startGame(
          difficulty: DifficultyLevel.beginner,
          scriptures: [multiVerse],
        );
        final size = adaptiveChunkSize(
          wordCount: multiVerse.wordsForVerse(0).length,
          difficulty: DifficultyLevel.beginner,
        );
        expect(size, equals(3));
        expect(
          notifier.state.targetChunks.every((c) => c.wordCount <= size),
          isTrue,
        );
      });

      test('wrong tap still only increments misses (no verse reset)', () {
        final multiVerse = multiVerseFixture();
        notifier.startGame(
          difficulty: DifficultyLevel.beginner,
          scriptures: [multiVerse],
        );
        placeNextCorrectChunk();
        final placedBefore = notifier.state.chunksPlaced;
        final verseBefore = notifier.state.currentVerseIndex;

        // Tap a wrong pool tile if one exists; otherwise tap a used-incorrect
        // path by picking a non-matching unused tile.
        var tappedWrong = false;
        final expected = notifier.state.targetChunks[notifier.state.nextChunkIndex].text;
        for (var i = 0; i < notifier.state.availablePool.length; i++) {
          if (notifier.state.usedPoolIndices.contains(i)) continue;
          if (notifier.state.availablePool[i].text != expected) {
            notifier.selectChunk(i);
            tappedWrong = true;
            break;
          }
        }
        expect(tappedWrong, isTrue);
        expect(notifier.state.incorrectAttempts, 1);
        expect(notifier.state.chunksPlaced, placedBefore);
        expect(notifier.state.currentVerseIndex, verseBefore);
      });
    });

    group('Adaptive chunk size', () {
      Scripture scriptureWithWordCount(int count, {String id = 'n'}) {
        final words = List.generate(count, (i) => 'w$i');
        return Scripture(
          id: id,
          book: ScriptureBook.bookOfMormon,
          volume: 'Test',
          reference: 'Test $count',
          name: 'Adaptive fixture',
          keyPhrase: 'fixture',
          fullText: words.join(' '),
        );
      }

      test('formula — ≤56 words keeps historic 3 / 2 sizes', () {
        expect(
          adaptiveChunkSize(
              wordCount: 56, difficulty: DifficultyLevel.beginner),
          3,
        );
        expect(
          adaptiveChunkSize(
              wordCount: 56, difficulty: DifficultyLevel.intermediate),
          2,
        );
        expect(
          adaptiveChunkSize(
              wordCount: 1, difficulty: DifficultyLevel.beginner),
          3,
        );
        expect(
          adaptiveChunkSize(
              wordCount: 24, difficulty: DifficultyLevel.intermediate),
          2,
        );
      });

      test('formula — grows then clamps at maxSize', () {
        // First Intermediate bump: ceil(57/28)=3
        expect(
          adaptiveChunkSize(
              wordCount: 57, difficulty: DifficultyLevel.intermediate),
          3,
        );
        // Beginner still 3 at 57; bumps at 58: ceil(58/19)=4
        expect(
          adaptiveChunkSize(
              wordCount: 57, difficulty: DifficultyLevel.beginner),
          3,
        );
        expect(
          adaptiveChunkSize(
              wordCount: 58, difficulty: DifficultyLevel.beginner),
          4,
        );
        // Long passage hits max
        expect(
          adaptiveChunkSize(
              wordCount: 270, difficulty: DifficultyLevel.beginner),
          8,
        );
        expect(
          adaptiveChunkSize(
              wordCount: 270, difficulty: DifficultyLevel.intermediate),
          6,
        );
        expect(
          adaptiveChunkSize(
              wordCount: 297, difficulty: DifficultyLevel.beginner),
          8,
        );
      });

      test('56-word baseline (1 Nephi 3:7 scale) — 19 beginner / 28 intermediate chunks',
          () {
        final scripture = scriptureWithWordCount(56, id: 'baseline-56');

        notifier.startGame(
            difficulty: DifficultyLevel.beginner, scriptures: [scripture]);
        expect(notifier.state.targetChunks.length, 19);
        for (final chunk in notifier.state.targetChunks) {
          expect(chunk.wordCount, lessThanOrEqualTo(3));
        }

        notifier = ScriptureBuilderNotifier();
        notifier.startGame(
            difficulty: DifficultyLevel.intermediate, scriptures: [scripture]);
        expect(notifier.state.targetChunks.length, 28);
        for (final chunk in notifier.state.targetChunks) {
          expect(chunk.wordCount, lessThanOrEqualTo(2));
        }
      });

      test('first passage over baseline (57 words) — Intermediate grows, Beginner unchanged',
          () {
        final scripture = scriptureWithWordCount(57, id: 'over-57');

        notifier.startGame(
            difficulty: DifficultyLevel.beginner, scriptures: [scripture]);
        expect(
          adaptiveChunkSize(
              wordCount: 57, difficulty: DifficultyLevel.beginner),
          3,
        );
        expect(notifier.state.targetChunks.length, 19); // ceil(57/3)

        notifier = ScriptureBuilderNotifier();
        notifier.startGame(
            difficulty: DifficultyLevel.intermediate, scriptures: [scripture]);
        expect(
          adaptiveChunkSize(
              wordCount: 57, difficulty: DifficultyLevel.intermediate),
          3,
        );
        expect(notifier.state.targetChunks.length, 19); // ceil(57/3)
        for (final chunk in notifier.state.targetChunks) {
          expect(chunk.wordCount, lessThanOrEqualTo(3));
        }
      });

      test('longest passage scale (270 words) — fewer taps via maxSize chunks',
          () {
        final scripture = scriptureWithWordCount(270, id: 'long-270');

        notifier.startGame(
            difficulty: DifficultyLevel.beginner, scriptures: [scripture]);
        expect(
          adaptiveChunkSize(
              wordCount: 270, difficulty: DifficultyLevel.beginner),
          8,
        );
        expect(notifier.state.targetChunks.length, 34); // ceil(270/8)
        expect(notifier.state.targetChunks.length, lessThan(90)); // old fixed-3
        for (final chunk in notifier.state.targetChunks) {
          expect(chunk.wordCount, lessThanOrEqualTo(8));
        }

        notifier = ScriptureBuilderNotifier();
        notifier.startGame(
            difficulty: DifficultyLevel.intermediate, scriptures: [scripture]);
        expect(
          adaptiveChunkSize(
              wordCount: 270, difficulty: DifficultyLevel.intermediate),
          6,
        );
        expect(notifier.state.targetChunks.length, 45); // ceil(270/6)
        expect(notifier.state.targetChunks.length, lessThan(135)); // old fixed-2
        for (final chunk in notifier.state.targetChunks) {
          expect(chunk.wordCount, lessThanOrEqualTo(6));
        }
      });

      test('corpus — 1 Nephi 3:7, Alma 39:9, Exodus 20:3–17 on both tiers', () {
        final baseline =
            allScriptures.firstWhere((s) => s.reference == '1 Nephi 3:7');
        final firstOver =
            allScriptures.firstWhere((s) => s.reference == 'Alma 39:9');
        final longest =
            allScriptures.firstWhere((s) => s.reference == 'Exodus 20:3–17');

        expect(baseline.wordCount, 56);
        expect(firstOver.wordCount, 57);
        expect(longest.wordCount, greaterThanOrEqualTo(270));
        expect(baseline.verses, hasLength(1));
        expect(firstOver.verses, hasLength(1));
        expect(longest.verses.length, greaterThan(1));

        for (final difficulty in [
          DifficultyLevel.beginner,
          DifficultyLevel.intermediate,
        ]) {
          for (final scripture in [baseline, firstOver, longest]) {
            var passageTotal = 0;
            for (var v = 0; v < scripture.verses.length; v++) {
              final verseWords = scripture.wordsForVerse(v);
              final verseSize = adaptiveChunkSize(
                wordCount: verseWords.length,
                difficulty: difficulty,
              );
              passageTotal += (verseWords.length / verseSize).ceil();
            }

            final verse0Size = adaptiveChunkSize(
              wordCount: scripture.wordsForVerse(0).length,
              difficulty: difficulty,
            );
            final verse0Count =
                (scripture.wordsForVerse(0).length / verse0Size).ceil();

            notifier = ScriptureBuilderNotifier();
            notifier.startGame(
                difficulty: difficulty, scriptures: [scripture]);
            // Pool is verse 0 only; passageChunkTotal covers every verse.
            expect(notifier.state.targetChunks.length, verse0Count);
            expect(notifier.state.passageChunkTotal, passageTotal);
            for (final chunk in notifier.state.targetChunks) {
              expect(chunk.wordCount, lessThanOrEqualTo(verse0Size));
            }
          }
        }
      });
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
        'onType — wrong word committed (master) — full reset: typedText empty, resetCount increments',
        () {
      // testScriptures[0] starts "And it came to pass..."
      notifier.startGame(
          difficulty: DifficultyLevel.master, scriptures: [testScriptures[0]]);

      notifier.onType('And '); // Correct word first — commits "And "
      expect(notifier.state.correctPlacements, 4);

      notifier.onType('wrong '); // Then a wrong word

      expect(notifier.state.typedText, isEmpty);
      expect(notifier.state.typedChars, isEmpty);
      expect(notifier.state.resetCount, 1);
      expect(notifier.state.incorrectAttempts, 1);
      expect(notifier.state.correctPlacements, 0); // Reset to 0
      expect(notifier.state.correctUnitsAcrossAll, 0); // Undone
      expect(notifier.state.lastFeedback, 'reset');
    });

    test('onType — backspace (master) — edits the unjudged word buffer freely',
        () {
      notifier.startGame(
          difficulty: DifficultyLevel.master, scriptures: [testScriptures[0]]);

      notifier.onType('Anx'); // Typo in progress — not judged
      expect(notifier.state.typedChars, isEmpty);
      expect(notifier.state.incorrectAttempts, 0);

      notifier.onType('An'); // Backspace the typo
      expect(notifier.state.typedText, 'An');

      notifier.onType('And');
      notifier.onType('And '); // Commit the fixed word

      expect(notifier.state.typedChars.length, 4); // "And "
      expect(notifier.state.resetCount, 0);
      expect(notifier.state.incorrectAttempts, 0);
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
      // testScriptures[0] starts "And it came to pass..."
      notifier.startGame(
          difficulty: DifficultyLevel.master, scriptures: [testScriptures[0]]);

      notifier.onType('And '); // commits "And " (4 chars)
      notifier.onType('it '); // commits "it " (3 chars)
      expect(notifier.state.correctPlacements, 7);
      final correctAcrossBefore = notifier.state.correctUnitsAcrossAll;
      expect(correctAcrossBefore, 7);

      // Commit a wrong word to trigger reset
      notifier.onType('nope ');

      expect(notifier.state.correctUnitsAcrossAll, correctAcrossBefore - 7);
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
        'Typing without punctuation completes scripture (auto-fill)',
        () {
      // Use a short scripture: "In the beginning was the Word, and the Word was with God, and the Word was God."
      notifier.startGame(
          difficulty: DifficultyLevel.advanced,
          scriptures: [shortPunctuatedScripture]);

      final target = notifier.state.targetText;

      // Type only non-punctuation characters
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
      // "In the beginning was the Word, and ..."
      notifier.startGame(
          difficulty: DifficultyLevel.master,
          scriptures: [shortPunctuatedScripture]);

      for (final word in ['In ', 'the ', 'beginning ', 'was ', 'the ']) {
        notifier.onType(word);
        expect(notifier.state.lastFeedback, 'word');
      }
      final placedBefore = notifier.state.typedChars.length;
      expect(placedBefore, greaterThan(0));

      // User types the word with its natural comma — must commit, not reset
      notifier.onType('Word, ');

      expect(notifier.state.resetCount, 0,
          reason: 'Typed punctuation must not reset a Master run');
      expect(notifier.state.incorrectAttempts, 0);
      // The comma and following space were auto-filled into the commit
      final committed =
          notifier.state.typedChars.map((c) => c.char).join();
      expect(committed, 'In the beginning was the Word, ');
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

      // Commit words past the comma ("In the beginning was the Word, and")
      for (final word in ['In ', 'the ', 'beginning ', 'was ', 'the ',
          'Word, ', 'and ']) {
        notifier.onType(word);
      }
      final target = notifier.state.targetText;
      final commaIndex = target.indexOf(',');
      expect(notifier.state.typedChars.length, greaterThan(commaIndex));

      // Now commit a wrong word to trigger master reset
      notifier.onType('wrong ');

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

  group('Scripture Builder — Word Commit (Master)', () {
    String committed() =>
        notifier.state.typedChars.map((c) => c.char).join();

    test('word in progress is not judged — buffer holds it, no typedChars',
        () {
      notifier.startGame(
          difficulty: DifficultyLevel.master, scriptures: [testScriptures[0]]);

      notifier.onType('A');
      notifier.onType('An');
      notifier.onType('And');

      expect(notifier.state.typedText, 'And');
      expect(notifier.state.typedChars, isEmpty);
      expect(notifier.state.incorrectAttempts, 0);
      expect(notifier.state.correctPlacements, 0);
    });

    test(
        'space commits the word — target casing, trailing space auto-filled, buffer cleared',
        () {
      notifier.startGame(
          difficulty: DifficultyLevel.master, scriptures: [testScriptures[0]]);

      notifier.onType('and '); // lowercase — matching is case-insensitive

      expect(committed(), 'And '); // display shows the target's casing
      expect(notifier.state.typedChars.every((c) => c.isCorrect), isTrue);
      expect(notifier.state.typedText, isEmpty);
      expect(notifier.state.correctPlacements, 4);
      expect(notifier.state.lastFeedback, 'word');
    });

    test(
        'autocorrect-style whole-word rewrite commits cleanly — "Amd" fixed to "And "',
        () {
      notifier.startGame(
          difficulty: DifficultyLevel.master, scriptures: [testScriptures[0]]);

      notifier.onType('Amd'); // fat-finger typo in progress
      expect(notifier.state.typedChars, isEmpty); // not judged

      // Autocorrect replaces the whole buffer and appends the space
      notifier.onType('And ');

      expect(committed(), 'And ');
      expect(notifier.state.resetCount, 0);
      expect(notifier.state.incorrectAttempts, 0);
    });

    test('stray space with no letters typed is swallowed silently', () {
      notifier.startGame(
          difficulty: DifficultyLevel.master, scriptures: [testScriptures[0]]);

      notifier.onType(' ');

      expect(notifier.state.lastFeedback, isNull);
      expect(notifier.state.typedText, isEmpty);
      expect(notifier.state.incorrectAttempts, 0);
      expect(notifier.state.resetCount, 0);
    });

    test('each wrong word counts one incorrectAttempt (not per character)',
        () {
      notifier.startGame(
          difficulty: DifficultyLevel.master, scriptures: [testScriptures[0]]);

      notifier.onType('And ');
      notifier.onType('completely '); // wrong word → reset

      expect(notifier.state.incorrectAttempts, 1);
      expect(notifier.state.starRating, 2);
    });

    test(
        'final word is never judged mid-typing — commits via space or done key',
        () {
      final scripture = Scripture(
        id: 'word-commit-final',
        book: ScriptureBook.bookOfMormon,
        volume: 'Test',
        reference: 'Test 1:1',
        name: 'Final Word Test',
        keyPhrase: 'Test',
        fullText: 'Be still',
      );
      notifier.startGame(
          difficulty: DifficultyLevel.master, scriptures: [scripture]);

      notifier.onType('Be ');
      expect(committed(), 'Be ');
      expect(notifier.state.isScriptureComplete, isFalse);

      // Matching the final word is NOT enough — the user may still be
      // typing a longer (wrong) word, so nothing is judged until a commit.
      notifier.onType('still');
      expect(notifier.state.isScriptureComplete, isFalse);
      expect(notifier.state.typedText, 'still');

      // The done key (submitWord) commits it without a trailing space.
      notifier.submitWord('still');

      expect(notifier.state.isScriptureComplete, isTrue);
      expect(notifier.state.lastFeedback, 'correct');
      expect(committed(), 'Be still');
      expect(notifier.state.typedChars.length,
          notifier.state.targetText.length);
    });

    test(
        'autocorrect splitting a typo into two words still commits — "andit" → "and it "',
        () {
      // testScriptures[0] starts "And it came to pass..."
      notifier.startGame(
          difficulty: DifficultyLevel.master, scriptures: [testScriptures[0]]);

      notifier.onType('andit'); // run-together typo in progress
      // Autocorrect rewrites the whole buffer into two words + space
      notifier.onType('and it ');

      expect(committed(), 'And it ');
      expect(notifier.state.resetCount, 0);
      expect(notifier.state.incorrectAttempts, 0);
    });

    test('submitWord commits the buffer like the keyboard done key', () {
      notifier.startGame(
          difficulty: DifficultyLevel.master, scriptures: [testScriptures[0]]);

      notifier.onType('And');
      notifier.submitWord();

      expect(committed(), 'And ');
      expect(notifier.state.typedText, isEmpty);
      expect(notifier.state.resetCount, 0);
    });

    test('em-dash joined words are committed one word at a time', () {
      // "And now, as I said concerning faith—faith is not..."
      notifier.startGame(
          difficulty: DifficultyLevel.master,
          scriptures: [punctuatedScripture]);

      for (final word in ['And ', 'now ', 'as ', 'I ', 'said ',
          'concerning ', 'faith ', 'faith ', 'is ']) {
        notifier.onType(word);
      }

      expect(notifier.state.resetCount, 0);
      expect(committed(), 'And now, as I said concerning faith—faith is ');
    });

    test('completing every word finishes the scripture with all-correct chars',
        () {
      notifier.startGame(
          difficulty: DifficultyLevel.master,
          scriptures: [shortPunctuatedScripture]);

      final target = notifier.state.targetText;
      // "In the beginning was the Word, and the Word was with God, and the Word was God."
      for (final word in target.split(' ')) {
        if (notifier.state.isScriptureComplete) break;
        notifier.onType('$word ');
      }

      expect(notifier.state.isScriptureComplete, isTrue);
      expect(notifier.state.typedChars.length, target.length);
      expect(notifier.state.typedChars.every((c) => c.isCorrect), isTrue);
      expect(committed(), target);
    });
  });
}
