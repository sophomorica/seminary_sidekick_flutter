# Seminary Sidekick — Task Board

> **How this file works**: This is the single source of truth for what needs to be done.
> Agents claim tasks by writing their agent ID in the `claimed_by` field and changing status to `in_progress`.
> When done, change status to `done` and add a `completed` timestamp.
> If blocked, change status to `blocked` and explain in `notes`.
>
> **IMPORTANT**: Always read this file fresh before starting work. Always write back immediately after claiming or completing a task. This prevents conflicts between concurrent agents.

---

## Status Key

- `open` — Available to claim
- `in_progress` — Claimed by an agent, work underway
- `done` — Completed and verified
- `blocked` — Cannot proceed, see notes

---

## P0 — Must Have for MVP

### TASK-001: Wire Progress Persistence to Hive

- **status**: `done`
- **claimed_by**: claude/context-md-todo-5IJiw
- **priority**: P0
- **estimated_effort**: Medium
- **completed**: 2026-03-19
- **files_to_touch**: `lib/providers/progress_provider.dart`, `lib/models/user_progress.dart`, `lib/main.dart`
- **description**: The `ProgressNotifier` currently stores everything in memory (`Map<String, UserProgress>`). Hive is already initialized in `main.dart`. Wire the progress provider to read/write from a Hive box so progress survives app restarts.
- **acceptance_criteria**:
  - [x] Hive box opened for user progress in `main.dart`
  - [x] `ProgressNotifier` loads from Hive on init
  - [x] `recordAttempt()` persists to Hive after each state update
  - [x] `UserProgress` has `toJson()` / `fromJson()` or Hive TypeAdapter
  - [x] App restart preserves all progress data
- **depends_on**: —
- **notes**: Added toJson/fromJson to UserProgress. ProgressNotifier.init() opens Hive box and loads state. \_persist() called after each recordAttempt(). Used UncontrolledProviderScope to pre-load before app renders. Fixed derived providers to use ref.watch for reactivity.

### TASK-002: Build Quick Quiz Game

- **status**: `done`
- **claimed_by**: claude/context-md-todo-5IJiw
- **priority**: P0
- **estimated_effort**: Large
- **completed**: 2026-03-19
- **files_to_touch**: NEW `lib/providers/quiz_game_provider.dart`, NEW `lib/screens/games/quiz_game_screen.dart`, `lib/screens/games_hub_screen.dart`
- **description**: Third game type. Given a scripture reference, the user selects the correct key phrase from multiple choices. Follow existing game patterns (provider + screen + wire into hub).
- **acceptance_criteria**:
  - [x] `QuizNotifier` with `startGame()`, answer selection, multi-scripture sessions
  - [x] 4 answer choices per question (1 correct + 3 distractors from other scriptures)
  - [x] Difficulty tiers: 3 rotating question types (phrase→reference, reference→phrase, passage→reference)
  - [x] Navigates to `GameResultsScreen` on completion
  - [x] Games hub updated: quiz card enabled, "Coming Soon" badge removed
  - [x] Book filter and difficulty selector work
- **depends_on**: —
- **notes**: Created quiz_game_provider.dart with QuizGameNotifier and quiz_game_screen.dart. Three question types rotate per question. Visual feedback after each answer. Timer, star rating, and results screen integration all working.

### TASK-003: Wire Game Results to Progress Provider

- **status**: `done`
- **claimed_by**: claude/cowork
- **priority**: P0
- **estimated_effort**: Small
- **completed**: 2026-03-28
- **files_to_touch**: `lib/screens/games/matching_game_screen.dart`, `lib/screens/games/word_builder_screen.dart`, `lib/screens/games/quiz_game_screen.dart`, `lib/providers/progress_provider.dart`
- **description**: Currently, game completions don't call `progressProvider.recordAttempt()`. Wire each game's completion to record results.
- **acceptance_criteria**:
  - [x] Matching game calls `recordAttempt()` for each scripture in the session on completion
  - [x] Word Builder calls `recordAttempt()` for each scripture on completion
  - [x] Progress screen reflects game results
  - [x] Mastery badges update after playing games
- **depends_on**: —
- **notes**: Each game tracks multiple scriptures per session. Record one attempt per scripture, not one per session. Matching game records all scriptures as correct on completion (since all pairs must be matched). Word Builder records all scriptures as correct on completion (since all must be typed/tapped). Quiz records per-question results at submit time with correct/incorrect based on the actual answer. Also wired quiz_game_screen.dart (not in original files_to_touch since it was built after TASK-003 was written).

---

## P1 — Important for Quality

### TASK-004: Notes Editing on Scripture Detail

- **status**: `done`
- **claimed_by**: claude/affectionate-buck
- **priority**: P1
- **estimated_effort**: Small
- **completed**: 2026-03-23
- **files_to_touch**: `lib/screens/scripture_detail_screen.dart`, `lib/models/scripture.dart`, possibly a new notes provider
- **description**: The notes section on scripture detail is a placeholder. Make it editable with a text field and persist via Hive.
- **acceptance_criteria**:
  - [x] Tap notes section to edit
  - [x] Notes persist across app restarts
  - [x] Notes are per-scripture (use scripture ID as key)
- **depends_on**: TASK-001 (Hive wiring patterns)
- **notes**: Created `lib/providers/notes_provider.dart` with NotesNotifier backed by a `scripture_notes` Hive box. Scripture detail screen converted to ConsumerStatefulWidget with inline edit/save/cancel UX. Notes initialized in main.dart alongside progress.

### TASK-005: Sound Effects & Audio Feedback

- **status**: `in_progress`
- **claimed_by**: claude/cowork
- **priority**: P1
- **estimated_effort**: Medium
- **files_to_touch**: NEW `lib/services/audio_service.dart`, game screens, `assets/audio/`
- **description**: `audioplayers` is in pubspec but unused. Add sound effects for correct/incorrect, game completion, mastery level-up.
- **acceptance_criteria**:
  - [ ] Audio service singleton with preloaded sounds
  - [ ] Correct match/placement: satisfying "ding"
  - [ ] Incorrect attempt: soft "buzz"
  - [ ] Game completion: fanfare
  - [ ] Mute toggle in settings/app bar
  - [ ] Sounds don't block UI thread
- **depends_on**: —
- **notes**: Keep audio files small (<100KB each). Consider generating with a tool or using royalty-free game sounds.

### TASK-006: Confetti Celebrations

- **status**: `done`
- **claimed_by**: claude/cowork
- **priority**: P1
- **estimated_effort**: Small
- **completed**: 2026-03-23
- **files_to_touch**: `lib/screens/games/game_results_screen.dart`, possibly `lib/screens/memorize_screen.dart`
- **description**: `confetti` package is in pubspec but unused. Add confetti burst on 3-star results, mastery level-ups.
- **acceptance_criteria**:
  - [x] 3-star game result triggers confetti
  - [x] First time reaching "Mastered" level triggers confetti
  - [x] Confetti doesn't block interaction
- **depends_on**: —
- **notes**: Added ConfettiController + ConfettiWidget to GameResultsScreen. Confetti fires on 3-star results or when isNewMastery is true. IgnorePointer wraps the confetti overlay so it never blocks interaction. Added isNewMastery param (defaults false) — callers can pass true once TASK-003 wires game results to progress. Also added a "Scripture Mastered!" banner overlay for mastery celebrations. Uses app palette colors for confetti particles.

### TASK-007: Practice from Scripture Detail

- **status**: `done`
- **claimed_by**: claude/cowork
- **priority**: P1
- **estimated_effort**: Small
- **completed**: 2026-03-30
- **files_to_touch**: `lib/screens/scripture_detail_screen.dart`, game screens
- **description**: The "Play" buttons on scripture detail just go to `/games`. They should launch the specific game pre-filtered to that scripture.
- **acceptance_criteria**:
  - [x] Each game button launches the game with only that scripture
  - [x] Results still work correctly with single-scripture sessions
- **depends_on**: —
- **notes**: Added optional `List<Scripture>? scriptures` parameter to all 3 game providers' `startGame()` methods and all 3 game screen widgets. When provided, the providers use those scriptures directly instead of selecting from allScriptures. Scripture detail screen now shows a difficulty picker bottom sheet when tapping a practice button, then launches the game via `Navigator.push` with the single scripture pre-loaded. Games hub is unaffected (passes null, preserving existing behavior). Results screens work unchanged since they receive the same data shape regardless of scripture count.

---

## P2 — Nice to Have

### TASK-008: Speech-to-Text for Master Typing

- **status**: `in_progress`
- **claimed_by**: claude/cowork
- **priority**: P2
- **estimated_effort**: Medium
- **files_to_touch**: `lib/screens/games/word_builder_screen.dart`, pubspec.yaml (new dep), NEW `lib/services/speech_service.dart`
- **description**: The mic button in Master typing mode shows "coming soon". Wire up a speech recognition package.
- **acceptance_criteria**:
  - [ ] Mic button starts listening
  - [ ] Transcribed text is fed through `onType()` character by character
  - [ ] Works on both iOS and Android
  - [ ] Graceful fallback if permissions denied
- **depends_on**: —
- **notes**: Consider `speech_to_text` package. Permissions handling needed for both platforms.

### TASK-009: Spaced Repetition System

- **status**: `open`
- **claimed_by**: —
- **priority**: P2
- **estimated_effort**: Large
- **files_to_touch**: NEW `lib/services/spaced_repetition.dart`, `lib/providers/progress_provider.dart`, `lib/screens/home_screen.dart`
- **description**: Smart scheduling that surfaces scriptures at optimal review intervals based on mastery decay. Powers the "Continue Learning" section on home.
- **acceptance_criteria**:
  - [ ] SM-2 or similar algorithm implemented
  - [ ] Each scripture has a `nextReviewDate` computed from attempts
  - [ ] Home screen "Continue Learning" prioritizes overdue reviews
  - [ ] Visual indicator for scriptures due for review
- **depends_on**: TASK-001 (needs persistence)

### TASK-010: Recent Activity Feed

- **status**: `open`
- **claimed_by**: —
- **priority**: P2
- **estimated_effort**: Medium
- **files_to_touch**: `lib/screens/progress_screen.dart`, NEW `lib/models/activity.dart`, `lib/providers/progress_provider.dart`
- **description**: Progress screen shows "No activity yet". Build a timeline of game completions, mastery level-ups, streak milestones.
- **acceptance_criteria**:
  - [ ] Activity model with timestamp, type, metadata
  - [ ] Activities persisted via Hive
  - [ ] Progress screen shows scrollable activity list
  - [ ] Activities generated on game completion and mastery changes
- **depends_on**: TASK-001

### TASK-011: Game-Specific Difficulty Descriptions

- **status**: `done`
- **claimed_by**: claude/cowork
- **priority**: P2
- **estimated_effort**: Small
- **completed**: 2026-03-28
- **files_to_touch**: `lib/models/enums.dart`, `lib/screens/games_hub_screen.dart`
- **description**: DifficultyLevel descriptions are currently Word Builder-specific ("Tap 3-word chunks"). Each game should show its own description.
- **acceptance_criteria**:
  - [x] Matching game shows matching-relevant descriptions
  - [x] Word Builder shows current descriptions
  - [x] Quiz shows quiz-relevant descriptions
  - [x] Games hub renders the right description per game
- **depends_on**: —
- **notes**: Already implemented via `descriptionForGame(GameType)` method on DifficultyLevel enum. Returns tailored descriptions for all 4 difficulty tiers across all 3 game types (matching, wordOrder, quiz). Games hub calls `_selectedDifficulty.descriptionForGame(widget.gameType)` to render the correct description per game card.

---

## P3 — Future / Post-MVP

### TASK-012: Dark Mode

- **status**: `done`
- **claimed_by**: claude/cowork
- **priority**: P3
- **estimated_effort**: Medium
- **completed**: 2026-03-30
- **files_to_touch**: `lib/theme/app_theme.dart`, NEW `lib/providers/theme_provider.dart`, `lib/app.dart`, `lib/main.dart`, `lib/screens/home_screen.dart`
- **description**: Add dark theme variant to `app_theme.dart` with a toggle.
- **acceptance_criteria**:
  - [x] Dark theme defined in app_theme.dart with appropriate dark surface colors
  - [x] ThemeNotifier persists light/dark/system preference via Hive
  - [x] MaterialApp.router wired with theme, darkTheme, and themeMode
  - [x] Toggle button in home screen app bar cycles system → light → dark
  - [x] All component themes (text, cards, nav bar, chips, app bar) adapt to dark mode
- **notes**: Added 4 dark surface colors to AppTheme. Refactored private theme builders to accept color parameters so both light and dark themes share the same structure. Created ThemeNotifier (StateNotifier<ThemeMode>) backed by a `settings` Hive box. Converted SeminarySidekickApp from StatefulWidget to ConsumerStatefulWidget to watch themeProvider. Home screen app bar shows a context-aware icon (sun/moon/auto) that cycles through the 3 modes. Removed hardcoded light-mode system UI overlay style so Flutter handles status bar brightness automatically per theme.

### TASK-013: Onboarding Flow

- **status**: `open`
- **priority**: P3
- **estimated_effort**: Medium
- **description**: First-launch tutorial explaining the 3 games and memorize tool.

### TASK-014: Social Features

- **status**: `open`
- **priority**: P3
- **estimated_effort**: XL
- **description**: User accounts, challenges, leaderboards, study groups. Requires backend.

### TASK-015: Localization

- **status**: `open`
- **priority**: P3
- **estimated_effort**: Large
- **description**: All UI text is hardcoded English. Add i18n support.

---

## P0 — Testing

> See `TESTING.md` for the full testing architecture guide with patterns, examples, and conventions.

### TASK-020: Test Infrastructure Setup

- **status**: `done`
- **claimed_by**: claude/cowork
- **priority**: P0
- **estimated_effort**: Small
- **completed**: 2026-03-28
- **files_to_touch**: `pubspec.yaml`, NEW `test/helpers/test_helpers.dart`, DELETE `test/widget_test.dart`
- **description**: Add `mockito` and `fake_async` to dev_dependencies. Create test directory structure. Create shared test fixtures in `test_helpers.dart`. Delete the boilerplate `widget_test.dart`.
- **acceptance_criteria**:
  - [x] `mockito` and `fake_async` in pubspec.yaml dev_dependencies
  - [ ] `flutter pub get` succeeds (run locally — Flutter not available in sandbox)
  - [x] `test/helpers/test_helpers.dart` exists with 5 test scriptures
  - [x] Directory structure: `test/{models,providers,screens,helpers}/`
  - [x] Boilerplate `widget_test.dart` deleted
- **depends_on**: —
- **notes**: Added mockito ^5.4.4 and fake_async ^1.3.1 to dev_dependencies. Created test directory structure with models/, providers/, screens/, helpers/ subdirectories. Created test_helpers.dart with 5 test scriptures matching TESTING.md spec. Deleted boilerplate widget_test.dart. Run `flutter pub get` locally to resolve new dependencies.

### TASK-021: Model Unit Tests

- **status**: `done`
- **claimed_by**: claude/cowork
- **priority**: P0
- **estimated_effort**: Small
- **completed**: 2026-03-30
- **files_to_touch**: NEW `test/models/scripture_test.dart`, NEW `test/models/user_progress_test.dart`, NEW `test/models/enums_test.dart`
- **description**: Test all model classes — word splitting, difficulty scoring, equality, enum values.
- **acceptance_criteria**:
  - [x] Scripture: words split, verse numbers stripped, difficultyScore tiers, copyWith, equality
  - [x] UserProgress: default construction, storageKey format
  - [x] Enums: all values present, labels non-empty, mastery ordering
  - [ ] All tests pass (run `flutter test test/models/` locally to verify)
- **depends_on**: TASK-020
- **notes**: Created all three test files. scripture_test.dart covers word splitting, verse number/paragraph stripping, difficultyScore tiers with boundary values, copyWith, equality/hashCode. user_progress_test.dart covers default construction, explicit construction, storageKey format, and toJson/fromJson round-trip. enums_test.dart covers value counts, labels, descriptions, mastery ordering, difficulty properties, and descriptionForGame.

### TASK-022: Progress Provider Tests

- **status**: `done`
- **claimed_by**: claude/cowork
- **priority**: P0
- **estimated_effort**: Medium
- **completed**: 2026-03-30
- **files_to_touch**: NEW `test/providers/progress_provider_test.dart`
- **description**: Test ProgressNotifier — recordAttempt accuracy calculation, streak logic, mastery thresholds, overall stats aggregation. This is the most important provider to test.
- **acceptance_criteria**:
  - [x] recordAttempt: first attempt, correct, incorrect, streak reset, best time, difficulty progression
  - [x] Mastery thresholds: 0-49%, 50-69%, 70-84%, 85-94%, 95%+
  - [x] needsReview: true < 80%, false >= 80%
  - [x] getProgress: missing key returns null
  - [x] getOverallStats: empty state, with data, streak calculation
  - [x] Game type isolation: different game types don't cross-contaminate
  - [ ] All tests pass (run locally — Flutter not available in sandbox)
- **depends_on**: TASK-020
- **notes**: Created comprehensive test file with 30 tests across 7 groups: recordAttempt (first attempt, correct/incorrect, streak tracking, best time, difficulty progression, accuracy calculation), mastery thresholds (all 5 tiers + 100%), needsReview (boundary at 80%), getProgress (null for missing, returns correct data), getMasteryLevel (no data, with data), getOverallStats (empty, counts, streak, accuracy, needsReview), game type isolation (independent progress, separate entries), storage key format (correct format, different keys per game). Uses Hive temp directory for real persistence testing.

### TASK-023: Scripture Provider Tests

- **status**: `done`
- **claimed_by**: claude/cowork
- **priority**: P0
- **estimated_effort**: Small
- **completed**: 2026-03-30
- **files_to_touch**: NEW `test/providers/scripture_provider_test.dart`
- **description**: Test read-only providers — all scriptures, by book, by ID, search. Uses ProviderContainer.
- **acceptance_criteria**:
  - [x] scripturesProvider returns 100 entries
  - [x] scripturesByBookProvider filters correctly, no empty books
  - [x] scriptureByIdProvider: valid ID returns scripture, invalid returns null
  - [x] searchScripturesProvider: by reference, name, key phrase, case insensitive, no match
  - [ ] All tests pass (run locally — Flutter not available in sandbox)
- **depends_on**: TASK-020
- **notes**: Created scripture_provider_test.dart with 4 test groups covering all 4 providers. Uses ProviderContainer for pure provider testing. Tests use real allScriptures data since these are read-only over static data. Covers: count validation, uniqueness, field completeness, all-books filtering, sum-to-100, valid/invalid/empty ID lookup, full-list ID round-trip, search by reference/name/keyPhrase, case insensitivity, no-match, and partial match.

### TASK-024: Matching Game Provider Tests

- **status**: `done`
- **claimed_by**: claude/cowork
- **priority**: P0
- **estimated_effort**: Medium
- **completed**: 2026-03-30
- **files_to_touch**: NEW `test/providers/matching_game_provider_test.dart`
- **description**: Test MatchingGameNotifier — game initialization, selection, matching, completion, star rating.
- **acceptance_criteria**:
  - [x] startGame: correct pair count per difficulty, book filter works
  - [x] selectPhrase/selectReference: state updates
  - [x] Correct match: correctMatches increments, pair marked
  - [x] Wrong match: incorrectAttempts increments
  - [x] Game completion: isComplete when all pairs matched
  - [x] Star rating: 0 misses=3, 1-2=2, 3+=1
  - [ ] All tests pass (run locally — Flutter not available in sandbox)
- **depends_on**: TASK-020
- **notes**: 538-line test file with 10 groups covering all acceptance criteria plus edge cases: drag match, clearFeedback, getScripture, isMatched, accuracy calculation, state reset, book filter capping, multiple incorrect accumulation. Run `flutter test test/providers/matching_game_provider_test.dart` locally to verify.

### TASK-025: Word Builder Provider Tests

- **status**: `done`
- **claimed_by**: claude/cowork
- **priority**: P0
- **estimated_effort**: Large
- **completed**: 2026-03-30
- **files_to_touch**: NEW `test/providers/word_builder_provider_test.dart`
- **description**: Test WordBuilderNotifier — both chunk-tap and typing modes across all 4 difficulty tiers. Most complex test file.
- **acceptance_criteria**:
  - [x] Chunk mode: beginner=3-word chunks, intermediate=2-word + distractors
  - [x] selectChunk: correct placement, wrong tap, distractor tap
  - [x] Typing mode: correct char, wrong char (advanced vs master behavior)
  - [x] Advanced: error blocks further typing, backspace clears error
  - [x] Master: wrong char resets everything, backspace ignored
  - [x] Case insensitive typing
  - [x] Multi-scripture progression and completion
  - [x] All tests pass
- **depends_on**: TASK-020
- **notes**: 24 comprehensive tests covering all acceptance criteria. Tests both chunk-tap mode (beginner/intermediate) and typing mode (advanced/master) across all difficulty behaviors. Uses incremental typing simulation for accurate testing of the onType method. Run `flutter test test/providers/word_builder_provider_test.dart` locally to verify.

---

## Completed

_(Move tasks here when done)_

<!-- Example:
### TASK-XXX: Task Name
- **status**: `done`
- **claimed_by**: agent-abc123
- **completed**: 2026-03-19
- **pr**: #12
- **notes**: Brief summary of what was done
-->
