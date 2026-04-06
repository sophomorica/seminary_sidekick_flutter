# CLAUDE.md — Seminary Sidekick

> **Single entry point for AI agents.** Read this file before touching any code.
> For the task board, see `TODO.md`.

---

## What This App Is

A gamified scripture memorization tool for the ~100 Doctrinal Mastery scriptures of The Church of Jesus Christ of Latter-day Saints (Old Testament, New Testament, Book of Mormon, Doctrine & Covenants).

The core loop: **Study → Build → Prove → Master**. Each scripture has its own mastery journey. Users study the text, then use **Word Builder** (the primary mastery tool) to progressively prove they can reproduce it from memory. Supplementary quizzes (Scripture Match, Quick Quiz) help with recognition and comprehension but don't gate mastery.

**Key UX principle**: The path to mastery must be obvious. When a user opens a scripture, they should immediately see where they are, what to do next, and what "mastered" means. Word Builder lives under the scripture itself — it's not a separate "game," it's THE mastery tool.

**Design philosophy**: Fun first (animations, haptics, satisfying feedback loops). Progressive difficulty (gentle on-ramp to brutal endgame). Visual warmth (warm rust/sage green/calm blue palette with Merriweather + Inter typography).

**Status**: MVP ~85% complete. Active development — major UX restructure in progress (moving Word Builder under scripture detail, reframing games as quizzes, adding onboarding).

---

## Tech Stack

| Choice | Why |
|--------|-----|
| **Flutter + Dart** | Pixel-level animation control, game-quality performance |
| **Riverpod** (StateNotifier) | Predictable state, testable, no context dependency |
| **GoRouter** (StatefulShellRoute) | Bottom nav with preserved tab state |
| **Hive** | Lightweight local persistence |
| **Google Fonts** | Merriweather (headings) + Inter (body) |
| **flutter_animate** | Animations |
| **confetti** | Celebration effects |
| **audioplayers** | Sound effects |

---

## Project Structure

```
lib/
├── main.dart                    # Entry: Hive init, orientation lock, ProviderScope
├── app.dart                     # GoRouter config, shell with bottom nav
├── models/
│   ├── enums.dart               # ScriptureBook, MasteryLevel, GameType, DifficultyLevel
│   ├── scripture.dart           # Scripture model with pre-split words
│   ├── user_progress.dart       # UserProgress with toJson/fromJson
│   └── scripture_mastery.dart   # Holistic mastery (computed, not stored)
├── data/
│   └── scriptures_data.dart     # 100 Doctrinal Mastery scriptures (allScriptures)
├── providers/
│   ├── scripture_provider.dart  # Read-only: all, byBook, byId, search
│   ├── progress_provider.dart   # ProgressNotifier (Hive-backed)
│   ├── scripture_mastery_provider.dart  # Holistic mastery + stats
│   ├── mastery_dates_provider.dart      # Hive-backed masteredSince dates
│   ├── matching_game_provider.dart
│   ├── word_builder_provider.dart
│   ├── quiz_game_provider.dart
│   └── notes_provider.dart      # Per-scripture notes (Hive-backed)
├── screens/
│   ├── home_screen.dart
│   ├── scripture_list_screen.dart
│   ├── scripture_detail_screen.dart
│   ├── memorize_screen.dart
│   ├── games_hub_screen.dart
│   ├── progress_screen.dart
│   └── games/
│       ├── matching_game_screen.dart
│       ├── word_builder_screen.dart
│       ├── quiz_game_screen.dart
│       └── game_results_screen.dart
├── services/
│   ├── audio_service.dart       # AudioNotifier with pooled players
│   └── speech_service.dart      # Speech-to-text wrapper
├── widgets/
│   ├── scripture_card.dart
│   ├── mastery_badge.dart
│   └── progress_ring.dart
└── theme/
    └── app_theme.dart           # Full design system: colors, typography, spacing
```

---

## Data Model

### Scripture (immutable)

Fields: `id` (String, '1'..'100'), `book` (ScriptureBook enum), `volume`, `reference`, `name` (topic), `keyPhrase`, `fullText`, `words` (pre-split, auto-computed), `wordCount` (auto-computed).

### UserProgress (per scripture × game type)

Fields: `scriptureId`, `gameType`, `highestDifficultyCompleted`, `totalAttempts`, `correctAttempts`, `currentStreak`, `bestStreak`, `bestTime`, `lastPracticed`, `accuracy`, `masteryLevel`, `needsReview`, `consecutivePerfectMaster`.

Storage key format: `{scriptureId}_{gameType.name}`

### Enums

- **ScriptureBook**: 4 values with `displayName` and `abbreviation`
- **MasteryLevel**: newScripture → learning → familiar → memorized → mastered → eternal (with color, icon, minAccuracy)
- **GameType**: matching, wordOrder, quiz (with displayName, description, icon) — note: "GameType" is a legacy name in code; conceptually wordOrder=mastery tool, matching/quiz=practice quizzes
- **DifficultyLevel**: beginner → intermediate → advanced → master (with scriptureCount, hasTimer, allowRetry, extraDistractors)

### Mastery System

Mastery is driven entirely by Word Builder progression:

- **New** (gray): Haven't started Word Builder
- **Learning** (orange): Completed WB Beginner
- **Familiar** (yellow): Completed WB Intermediate
- **Memorized** (green): Completed WB Advanced
- **Mastered** (blue): 3 consecutive perfect WB Master completions
- **Eternal** (gold): Sustained Mastered for 6 months (permanent, never decays)

**Shortcut**: If you can nail Master difficulty without doing lower tiers, you've proven it. (Planned — TASK-031.)

**Gentle decay**: 14+ days → "Needs Review" flag. 30+ days → drops one tier. Floor at Familiar. Eternal never decays.

**Why only Word Builder?** It's the only tool that tests *production* — can you produce the words from memory? Match/Quiz test recognition (different cognitive skill). You haven't "mastered" a scripture until you can type it cold.

---

## Mastery Tool: Word Builder

Word Builder is the PRIMARY mastery tool. It lives under each scripture (accessed from scripture detail), not in the quizzes/games hub. It's how you prove you know a scripture. The four difficulty tiers map directly to mastery levels:

- **Beginner** (chunk-tap): 3-word chunks, tap in order → earns **Learning** mastery
- **Intermediate** (chunk-tap): 2-word chunks + distractors from other scriptures → earns **Familiar** mastery
- **Advanced** (typing): Type the passage with first-letter hints. Wrong char turns red, must backspace → earns **Memorized** mastery
- **Master** (typing): Blind typing (all underscores). Any wrong char resets everything. Speech-to-text available → 3 consecutive perfect runs earns **Mastered**

**Shortcut rule**: If a user can complete Master difficulty perfectly, they've proven mastery regardless of whether they did Beginner/Intermediate/Advanced. The system should recognize this (planned — see TODO.md TASK-031).

### Study Tool: Memorize
Study aid accessed from scripture detail. Two modes: First Letter (progressive shrink to first letter then underscore) and Full Hide (straight to underscores). Tap words to toggle, or use Hide Next / Reveal All / Hide All. This is for studying — no mastery progression attached.

### Supplementary Quizzes (not mastery-gating)

These help with recognition and comprehension but do NOT drive mastery. They live in a "Practice" or "Quizzes" tab (currently called "Games" — rename planned).

- **Scripture Match**: Two columns — key phrases vs references. Tap-to-select or drag-and-drop to match. Tests reference recognition.
- **Quick Quiz**: Given a passage/reference, select correct key phrase/reference from 4 choices. Three question types rotate. Tests comprehension.

---

## Conventions

### Naming

| Type | Convention | Example |
|------|-----------|---------|
| Files | `snake_case.dart` | `matching_game_screen.dart` |
| Classes | `PascalCase` | `MatchingGameScreen` |
| Providers | `camelCaseProvider` | `wordBuilderProvider` |
| Notifiers | `[Feature]Notifier` | `WordBuilderNotifier` |
| State classes | `[Feature]State` | `WordBuilderState` |

### Theme — Never Hardcode Colors or Text Styles

```dart
// Colors — always use AppTheme.*
AppTheme.primary          // Warm rust (#D9805F) — main actions, headings
AppTheme.secondary        // Sage green (#618C84) — secondary actions
AppTheme.accent           // Calm blue (#5B8ABF) — highlights, links
AppTheme.success          // Correct feedback
AppTheme.error            // Incorrect feedback
AppTheme.gold             // Stars, achievements
AppTheme.dark             // Text
AppTheme.surface          // Card backgrounds
AppTheme.offWhite         // Scaffold background
AppTheme.bookColor('oldTestament')  // Book-specific

// Typography — always use Theme.of(context).textTheme.*
displayMedium   // Big headings (Merriweather)
headlineMedium  // Section headings
titleLarge      // Card titles (Inter)
bodyLarge       // Body text
bodySmall       // Captions

// Spacing
AppTheme.spacingSm (8), spacingMd (16), spacingLg (24), spacingXl (32)

// Radii
AppTheme.radiusSm (8), radiusMd (12), radiusLg (16)
```

### Provider Pattern

Every stateful feature uses `StateNotifier<FeatureState>` with an immutable state class that has `copyWith`:

```dart
class FeatureState {
  final /* fields */;
  const FeatureState({/* required fields */});
  FeatureState copyWith({/* optional overrides */}) { ... }
}

class FeatureNotifier extends StateNotifier<FeatureState> {
  FeatureNotifier() : super(FeatureState(/* defaults */));
  void someAction() { state = state.copyWith(/* changes */); }
}

final featureProvider = StateNotifierProvider<FeatureNotifier, FeatureState>(
  (ref) => FeatureNotifier(),
);
```

Read-only providers use `Provider` or `Provider.family`.

### Quiz/Practice Screen Pattern

`ConsumerStatefulWidget` with `TickerProviderStateMixin`. Start game in `postFrameCallback`. Use `ref.listen()` for state transitions. Timer + shake/pulse animation controllers + haptic feedback on every action. Exit confirmation dialog. Navigate to shared `GameResultsScreen` via `Navigator.pushReplacement`.

Word Builder follows this same pattern but is launched from scripture detail, not the practice hub.

### Navigation

| Route type | Method | When |
|-----------|--------|------|
| Tab navigation | GoRouter `context.go('/path')` | Main tabs |
| Scripture browsing | GoRouter `context.go('/scripture/$id')` | Detail screens |
| Game screens | `Navigator.of(context).push()` | Transient overlays |
| Game results | `Navigator.of(context).pushReplacement()` | Replace game with results |
| Memorize tool | `Navigator.of(context).push()` | From scripture detail |

### Feedback on Every Action

| Action | Visual | Haptic |
|--------|--------|--------|
| Correct | Green + pulse (300ms) | `lightImpact()` |
| Incorrect | Red + shake (~400ms) | `mediumImpact()` |
| Scripture complete | Green checkmark | `heavyImpact()` |
| Game complete | Navigate to results | `heavyImpact()` |

Use `AnimatedContainer` for smooth state transitions.

### Data Access

```dart
ref.watch(scripturesProvider)                          // All scriptures
ref.watch(scripturesByBookProvider('oldTestament'))     // By book
ref.watch(scriptureByIdProvider('42'))                  // By ID
ref.watch(searchScripturesProvider('nephi'))            // Search
ref.watch(scriptureMasteryProvider('42'))               // Holistic mastery (Word Builder-driven)
ref.watch(holisticStatsProvider)                        // Aggregate mastery stats
ref.watch(masteryLevelProvider(('42', GameType.matching)))  // Per-game mastery (legacy, still used by game screens)
ref.watch(userStatsProvider)                            // Overall stats
ref.read(progressProvider.notifier).recordAttempt(...)  // Record attempt
```

---

## Adding a New Quiz/Practice Tool — Checklist

1. Create `lib/providers/[quiz]_provider.dart` — State class with `copyWith`, Notifier with `startGame()`, game actions, `nextScripture()`, `clearFeedback()`, `StateNotifierProvider`
2. Create `lib/screens/games/[quiz]_screen.dart` — `ConsumerStatefulWidget` with `TickerProviderStateMixin`, timer, animations, haptics, exit dialog, navigate to `GameResultsScreen`
3. Update `lib/screens/games_hub_screen.dart` (will become practice hub) — import, `isAvailable` check, `_launchGame()` switch
4. Update `TODO.md`
5. Ensure `GameType` enum entry exists in `enums.dart`

**Note**: Word Builder is NOT a quiz — it's the mastery tool and lives under scripture detail. Only supplementary practice tools go in the practice hub.

## Adding a New Provider — Checklist

1. Create file in `lib/providers/`
2. Define immutable state class with `copyWith`
3. Define notifier extending `StateNotifier<YourState>`
4. Export provider as top-level `final`
5. Add convenience `Provider.family` providers if needed

---

## Agent Coordination

### Quick Start

```
1. Read this file (CLAUDE.md)      → Understand everything
2. Read TODO.md                    → Find an open task
3. Claim the task                  → Write your agent ID into TODO.md, commit
4. Do the work                     → Follow the conventions above
5. Mark task done                  → Update TODO.md, commit
```

### Claiming a Task

1. Read `TODO.md` fresh (never rely on cached state)
2. Find a task with `status: open`
3. Check `depends_on` — don't start blocked work
4. Edit `TODO.md`: set `status: in_progress`, `claimed_by: [your-id]`, `started: [ISO timestamp]`
5. **Commit the claim before writing code**: `git add TODO.md && git commit -m "claim TASK-XXX: [description]"`

If two agents claim the same task, the second commit fails with a merge conflict. Pull, see it's taken, pick another task.

### Completing a Task

1. Finish code changes
2. Edit `TODO.md`: set `status: done`, `completed` timestamp, check acceptance criteria, add notes
3. Commit everything: `git add -A && git commit -m "complete TASK-XXX: [what was done]"`

### Blocked or Abandoned

- **Blocked**: Set `status: blocked`, add `blocked_by` note, commit, move on
- **Abandoned**: Set `status: open`, clear `claimed_by`, add notes explaining why, commit

### File Ownership

Two agents should never edit the same file concurrently. Check `files_to_touch` for conflicts.

**Shared files (extra caution)**: `enums.dart`, `games_hub_screen.dart`, `main.dart`, `pubspec.yaml`, `TODO.md`

### Commit Format

```
[verb] TASK-XXX: [concise description]
```

Verbs: `claim`, `complete`, `fix`, `add`, `update`, `refactor`, `block`

---

## Testing

### Setup

Dev dependencies: `mockito ^5.4.4`, `fake_async ^1.3.1` (already added).

```
test/
├── models/
│   ├── scripture_test.dart
│   ├── user_progress_test.dart
│   ├── enums_test.dart
│   └── scripture_mastery_test.dart  # Holistic mastery: linear path, decay, Eternal, requirements
├── providers/
│   ├── scripture_provider_test.dart
│   ├── progress_provider_test.dart  # Includes consecutivePerfectMaster tracking tests
│   ├── matching_game_provider_test.dart
│   └── word_builder_provider_test.dart
├── screens/
│   └── (widget tests — lower priority)
└── helpers/
    └── test_helpers.dart       # 5 shared test scriptures
```

### Test Priorities

1. **Models** (fast, no deps): word splitting, verse stripping, difficulty tiers, copyWith, equality, enum values
2. **Scripture mastery model** (core mastery logic): linear path levels, Word Builder-driven computation, gentle decay, Eternal tier, sub-progress, requirements generation
3. **Progress provider** (core business logic): recordAttempt, accuracy, streaks, mastery thresholds, game type isolation, consecutivePerfectMaster tracking
4. **Scripture provider** (read-only queries): all 100 scriptures, by book, by ID, search
5. **Matching game provider**: game init, selection, matching, completion, star rating
6. **Word builder provider** (most complex): chunk-tap mode + typing mode across all 4 difficulty tiers
7. **Widget tests** (lowest priority): MemorizeScreen, GamesHubScreen, GameResultsScreen

### Testing StateNotifiers Directly

```dart
late ProgressNotifier notifier;
setUp(() { notifier = ProgressNotifier(); });

test('first correct attempt creates progress', () {
  notifier.recordAttempt(scriptureId: 'test-1', gameType: GameType.matching, correct: true);
  final progress = notifier.getProgress('test-1', GameType.matching);
  expect(progress!.totalAttempts, 1);
  expect(progress.accuracy, 100.0);
});
```

### Testing Providers with ProviderContainer

```dart
late ProviderContainer container;
setUp(() { container = ProviderContainer(); });
tearDown(() { container.dispose(); });

test('scripturesProvider returns all 100', () {
  expect(container.read(scripturesProvider).length, 100);
});
```

### Test Conventions

- One test file per source file
- Group related tests with `group()`
- Test names describe behavior: `'recordAttempt with correct answer increments streak'`
- Fresh notifier in `setUp`, no shared state
- Use fixtures from `test_helpers.dart`
- Assert state, not implementation

### Running Tests

```bash
flutter test                    # All tests
flutter test test/providers/    # Specific directory
flutter test --coverage         # With coverage
flutter analyze                 # Must pass with no errors
```

---

## Build & Run

```bash
flutter pub get          # Install deps
flutter analyze          # Must pass with no errors
flutter test             # Run all tests
flutter run              # Run app
```

---

## Key Files Reference

| File | Purpose |
|------|---------|
| `CLAUDE.md` | This file — single agent entry point (mastery spec is inline here) |
| `TODO.md` | Task board (claim/complete tasks here) |
| `app_theme.dart` | Single source of truth for colors and spacing |
| `scriptures_data.dart` | All 100 scripture entries |

## Current Task Status

See `TODO.md` for full details.

**Recently completed** (2026-04-02):
- TASK-026/027/028: Holistic mastery system — Word Builder-centric linear path
- TASK-029: Mastery system tests (40 new tests across 3 files)

**Active direction** (2026-04-02 — major UX restructure):
- **P0**: TASK-030 (move Word Builder under scripture detail as primary mastery tool)
- **P0**: TASK-031 (mastery shortcut — skip tiers if you prove Master)
- **P1**: TASK-032 (rename Games → Practice/Quizzes, remove WB from hub)
- **P1**: TASK-013 (onboarding tutorial — explain the mastery path)
- **P2**: TASK-009 (spaced repetition), TASK-010 (activity feed)


## Available Skills

- `/grill-me` — Use this when you need deep, relentless questioning on game mechanics, mastery logic, UX flows, or architecture decisions.
- `/request-refactor-plan` — Before any major refactor (especially providers or game screens).
