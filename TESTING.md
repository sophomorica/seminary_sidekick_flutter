# Seminary Sidekick — Testing Architecture Guide

> **Purpose**: This file tells the next agent exactly how to build the test suite from scratch.
> **Current state**: Zero meaningful tests. Only `test/widget_test.dart` exists (default Flutter boilerplate — delete it).

## Step 0: Add Dependencies

Add these to `dev_dependencies` in `pubspec.yaml`:

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.1
  hive_generator: ^2.0.1
  build_runner: ^2.4.7
  riverpod_generator: ^2.3.9
  # ADD THESE:
  mockito: ^5.4.4
  build_runner: ^2.4.7        # already present
  fake_async: ^1.3.1
```

Then run `flutter pub get`.

## Step 1: Create the Test Directory Structure

```
test/
├── models/
│   ├── scripture_test.dart
│   ├── user_progress_test.dart
│   └── enums_test.dart
├── providers/
│   ├── scripture_provider_test.dart
│   ├── progress_provider_test.dart
│   ├── matching_game_provider_test.dart
│   └── word_builder_provider_test.dart
├── screens/
│   └── (widget tests — lower priority, do these last)
└── helpers/
    └── test_helpers.dart       # Shared fixtures and utilities
```

## Step 2: Build Test Helpers First

Create `test/helpers/test_helpers.dart` with reusable fixtures:

```dart
import 'package:seminary_sidekick/models/scripture.dart';
import 'package:seminary_sidekick/models/enums.dart';

/// A small set of scriptures for testing. Don't use allScriptures in tests —
/// it's 100 entries and makes assertions noisy.
final testScriptures = [
  Scripture(
    id: 'test-1',
    book: ScriptureBook.bookOfMormon,
    volume: '1 Nephi',
    reference: '1 Nephi 3:7',
    name: 'Obedience to Commandments',
    keyPhrase: 'I will go and do',
    fullText: 'And it came to pass that I Nephi said unto my father I will go and do the things which the Lord hath commanded',
  ),
  Scripture(
    id: 'test-2',
    book: ScriptureBook.newTestament,
    volume: 'John',
    reference: 'John 3:16',
    name: 'God So Loved the World',
    keyPhrase: 'For God so loved the world',
    fullText: 'For God so loved the world that he gave his only begotten Son that whosoever believeth in him should not perish but have everlasting life',
  ),
  Scripture(
    id: 'test-3',
    book: ScriptureBook.oldTestament,
    volume: 'Proverbs',
    reference: 'Proverbs 3:5-6',
    name: 'Trust in the Lord',
    keyPhrase: 'Trust in the Lord with all thine heart',
    fullText: 'Trust in the Lord with all thine heart and lean not unto thine own understanding',
  ),
  Scripture(
    id: 'test-4',
    book: ScriptureBook.doctrineAndCovenants,
    volume: 'D&C',
    reference: 'D&C 58:27',
    name: 'Anxiously Engaged',
    keyPhrase: 'Anxiously engaged in a good cause',
    fullText: 'Verily I say men should be anxiously engaged in a good cause and do many things of their own free will',
  ),
  // Add a 5th for tests that need > 4 scriptures
  Scripture(
    id: 'test-5',
    book: ScriptureBook.bookOfMormon,
    volume: 'Moroni',
    reference: 'Moroni 10:4-5',
    name: 'Promise of the Book of Mormon',
    keyPhrase: 'Ask with a sincere heart',
    fullText: 'And when ye shall receive these things I would exhort you that ye would ask God the Eternal Father in the name of Christ if these things are not true',
  ),
];

/// Quick reference: test-1 has 20 words, test-2 has 24, test-3 has 14, test-4 has 18, test-5 has 28
```

## Step 3: What to Test (Prioritized)

### Priority 1 — Models (fast, no dependencies)

#### `test/models/scripture_test.dart`

| Test | What to assert |
|------|---------------|
| `words` are correctly split from `fullText` | Length matches expected, no empty strings |
| Verse numbers stripped from words | e.g., "1 And it came" → ["And", "it", "came"] |
| Paragraph marks (¶) stripped | No ¶ in resulting words |
| `wordCount` matches `words.length` | Consistency |
| `difficultyScore` tiers | ≤15 words → 1, ≤30 → 3, ≤50 → 5, ≤75 → 7, >75 → 10 |
| `copyWith` preserves all fields | Only `userNotes` changes |
| Equality by ID | Two scriptures with same `id` are equal |
| Equality ignores other fields | Different `name`, same `id` → equal |
| `hashCode` consistent with equality | Same `id` → same hash |

#### `test/models/user_progress_test.dart`

| Test | What to assert |
|------|---------------|
| Default construction | All fields have expected defaults |
| `storageKey` format | Returns `{scriptureId}_{gameType.name}` |

#### `test/models/enums_test.dart`

| Test | What to assert |
|------|---------------|
| `ScriptureBook` has 4 values | Count and names |
| `MasteryLevel` ordering | newScripture < learning < familiar < memorized < mastered by `minAccuracy` |
| `GameType` has 3 values | matching, wordOrder, quiz |
| `DifficultyLevel.scriptureCount` increases | beginner < intermediate (or appropriate for each game) |
| Each enum value has non-empty labels | No blank `displayName`, `label`, `description` |

---

### Priority 2 — Progress Provider (core business logic)

#### `test/providers/progress_provider_test.dart`

This is the most critical provider to test — it calculates mastery, streaks, and accuracy.

| Test | What to assert |
|------|---------------|
| **recordAttempt — first attempt** | Creates new entry, totalAttempts=1, accuracy calculated |
| **recordAttempt — correct** | correctAttempts increments, streak increments |
| **recordAttempt — incorrect** | streak resets to 0, accuracy recalculated |
| **recordAttempt — best streak tracking** | bestStreak updates only when currentStreak exceeds it |
| **recordAttempt — best time** | First time is stored; subsequent only replaces if faster |
| **recordAttempt — difficulty progression** | highestDifficultyCompleted updates upward only |
| **Mastery thresholds** | 0-49% → newScripture, 50-69% → learning, 70-84% → familiar, 85-94% → memorized, 95%+ → mastered |
| **needsReview** | true when accuracy < 80 |
| **getProgress — missing key** | Returns null |
| **getProgress — existing key** | Returns correct UserProgress |
| **getMasteryLevel — no data** | Returns MasteryLevel.newScripture |
| **getOverallStats — empty** | All zeros |
| **getOverallStats — with data** | Counts totalAttempted, totalMemorized, totalMastered correctly |
| **getOverallStats — currentStreak** | Returns the highest streak across all entries |
| **Isolation between game types** | Progress for (scripture1, matching) doesn't affect (scripture1, wordOrder) |
| **Storage key format** | Verify `_getStorageKey` produces `{id}_{gameType.name}` |

**How to test a StateNotifier without widgets:**
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:seminary_sidekick/providers/progress_provider.dart';
import 'package:seminary_sidekick/models/enums.dart';

void main() {
  late ProgressNotifier notifier;

  setUp(() {
    notifier = ProgressNotifier();
  });

  test('first correct attempt creates progress with 100% accuracy', () {
    notifier.recordAttempt(
      scriptureId: 'test-1',
      gameType: GameType.matching,
      correct: true,
    );

    final progress = notifier.getProgress('test-1', GameType.matching);
    expect(progress, isNotNull);
    expect(progress!.totalAttempts, 1);
    expect(progress.correctAttempts, 1);
    expect(progress.accuracy, 100.0);
    expect(progress.currentStreak, 1);
  });
}
```

---

### Priority 3 — Scripture Provider (read-only queries)

#### `test/providers/scripture_provider_test.dart`

These tests verify the filtering/search logic. Since these are pure Riverpod providers, you can test them with a `ProviderContainer`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seminary_sidekick/providers/scripture_provider.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  test('scripturesProvider returns all 100 scriptures', () {
    final scriptures = container.read(scripturesProvider);
    expect(scriptures.length, 100);
  });
}
```

| Test | What to assert |
|------|---------------|
| `scripturesProvider` returns 100 entries | Count |
| `scripturesByBookProvider` filters correctly | Only matching book returned |
| `scripturesByBookProvider` — each book has entries | No empty book |
| `scriptureByIdProvider` — valid ID | Returns correct scripture |
| `scriptureByIdProvider` — invalid ID | Returns null |
| `searchScripturesProvider` — by reference | Finds "1 Nephi 3:7" |
| `searchScripturesProvider` — by name | Finds "Obedience" |
| `searchScripturesProvider` — by key phrase | Finds "I will go" |
| `searchScripturesProvider` — case insensitive | "nephi" finds "Nephi" |
| `searchScripturesProvider` — empty string | Returns empty or all |
| `searchScripturesProvider` — no match | Returns empty |

---

### Priority 4 — Matching Game Provider

#### `test/providers/matching_game_provider_test.dart`

| Test | What to assert |
|------|---------------|
| **startGame** — beginner | Creates 4 pairs, shuffled references and phrases |
| **startGame** — with book filter | Only scriptures from that book |
| **startGame** — state reset | Previous game state cleared |
| **selectPhrase** | Sets `selectedPhraseId` in state |
| **selectReference** | Sets `selectedReferenceId` in state |
| **selectPhrase then selectReference — correct match** | `correctMatches` increments, pair marked matched, feedback='correct' |
| **selectPhrase then selectReference — wrong match** | `incorrectAttempts` increments, feedback='incorrect' |
| **attemptDragMatch — correct** | Same as tap match |
| **attemptDragMatch — wrong** | Same as tap wrong |
| **Game completion** | `isComplete` true when all pairs matched |
| **Star rating** | 0 misses=3, 1-2 misses=2, 3+ misses=1 |
| **clearFeedback** | Resets `lastFeedback` and `lastMatchedId` to null |
| **getScripture** | Returns scripture from pairs by ID |
| **isMatched** | Returns correct matched status |
| **Double-select same phrase** | Deselects (or stays selected — verify behavior) |

---

### Priority 5 — Word Builder Provider (most complex)

#### `test/providers/word_builder_provider_test.dart`

Split into two `group()` blocks: chunk-tap mode and typing mode.

**Chunk-Tap Mode (Beginner/Intermediate):**

| Test | What to assert |
|------|---------------|
| **startGame beginner** | Mode is `chunkTap`, chunks are size 3 |
| **startGame intermediate** | Mode is `chunkTap`, chunks are size 2 |
| **Chunk count** | ceil(wordCount / chunkSize) chunks created |
| **Intermediate has distractors** | `availablePool.length` > `targetChunks.length` |
| **Beginner has no distractors** | `availablePool.length` == `targetChunks.length` |
| **selectChunk — correct** | Chunk placed, removed from pool, correctPlacements increments |
| **selectChunk — wrong** | incorrectAttempts increments, pool unchanged |
| **selectChunk — distractor** | incorrectAttempts increments |
| **Scripture complete** | `isScriptureComplete` true when all chunks placed |
| **Multi-scripture progression** | `nextScripture()` loads next, index increments |
| **All scriptures done** | `isComplete` true, `completionTime` set |
| **Color indices assigned** | Each chunk has sequential colorIndex |

**Typing Mode (Advanced/Master):**

| Test | What to assert |
|------|---------------|
| **startGame advanced** | Mode is `typing`, `targetText` is fullText |
| **startGame master** | Mode is `typing` |
| **onType — correct character** | `typedChars` grows, char marked `isCorrect: true` |
| **onType — wrong character (advanced)** | Char marked `isCorrect: false`, `hasActiveError` true |
| **onType — blocked when error active (advanced)** | New chars ignored until error deleted |
| **onType — backspace (advanced)** | Last char removed, `hasActiveError` recalculated |
| **onType — wrong character (master)** | Full reset: `typedText` empty, `resetCount` increments |
| **onType — backspace (master)** | Ignored (returns early) |
| **Case insensitive matching** | 'a' matches 'A' |
| **Typing completion** | `isScriptureComplete` true when all chars typed |
| **correctUnitsAcrossAll tracking** | Increments across multiple scriptures |
| **Master reset undoes correctUnitsAcrossAll** | Count decremented by correctPlacements on reset |
| **Star rating** | 0 errors=3, 1-3 errors=2, 4+ errors=1 |

---

### Priority 6 — Widget Tests (do last, if time permits)

Widget tests are slower and more brittle. Focus on:

| Screen | What to test |
|--------|-------------|
| `MemorizeScreen` | Word visibility toggles correctly, Hide Next finds right word, Reveal All resets |
| `GamesHubScreen` | Matching and Word Builder are enabled, Quiz shows "Coming Soon" |
| `GameResultsScreen` | Correct star count rendered, stats display matches input |

Widget test pattern:
```dart
testWidgets('games hub shows quiz as coming soon', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(home: GamesHubScreen()),
    ),
  );
  expect(find.text('Soon'), findsOneWidget);
});
```

---

## Running Tests

```bash
# All tests
flutter test

# Specific file
flutter test test/providers/progress_provider_test.dart

# With coverage
flutter test --coverage

# Verbose
flutter test --reporter expanded
```

## Test Conventions

- **One test file per source file**: `lib/providers/foo.dart` → `test/providers/foo_test.dart`
- **Group by feature**: Use `group()` to organize related tests
- **Test names describe behavior**: `'recordAttempt with correct answer increments streak'`
- **setUp/tearDown**: Create fresh notifier instances in `setUp`, don't share state between tests
- **No widget dependencies in provider tests**: Test notifiers directly, not through widgets
- **Use test fixtures from `test_helpers.dart`**: Don't duplicate scripture definitions across test files
- **Assert state, not implementation**: Check `state.correctMatches == 1`, not internal method calls

## Definition of Done

The test suite is "done" when:
- [ ] All Priority 1-5 tests pass
- [ ] `flutter test` exits with 0
- [ ] `flutter analyze` has no errors
- [ ] Every provider public method has at least one test
- [ ] Edge cases covered: empty state, max state, boundary values
- [ ] Test helpers file exists with reusable fixtures
- [ ] No tests depend on execution order (each test is independent)

## Add to TODO.md When Starting

When you begin this work, claim these as sub-tasks in `TODO.md`:

```
TASK-020: Test infrastructure setup (deps, helpers, directory structure)
TASK-021: Model unit tests (scripture, user_progress, enums)
TASK-022: Progress provider tests
TASK-023: Scripture provider tests
TASK-024: Matching game provider tests
TASK-025: Word builder provider tests
TASK-026: Widget tests (if time permits)
```

These can run in parallel once TASK-020 is complete — each test file touches different source files.
