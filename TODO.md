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
- **notes**: Added toJson/fromJson to UserProgress. ProgressNotifier.init() opens Hive box and loads state. _persist() called after each recordAttempt(). Used UncontrolledProviderScope to pre-load before app renders. Fixed derived providers to use ref.watch for reactivity.

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
- **claimed_by**: claude/context-md-todo-5IJiw
- **priority**: P0
- **estimated_effort**: Small
- **completed**: 2026-03-23
- **files_to_touch**: `lib/screens/games/matching_game_screen.dart`, `lib/screens/games/word_builder_screen.dart`, `lib/screens/games/quiz_game_screen.dart`, `lib/providers/quiz_game_provider.dart`
- **description**: Currently, game completions don't call `progressProvider.recordAttempt()`. Wire each game's completion to record results.
- **acceptance_criteria**:
  - [x] Matching game calls `recordAttempt()` for each scripture in the session on completion
  - [x] Word Builder calls `recordAttempt()` for each scripture on completion
  - [x] Quiz game calls `recordAttempt()` for each question with per-question correctness
  - [x] Progress screen reflects game results (providers already use ref.watch)
  - [x] Mastery badges update after playing games (reactive providers from TASK-001)
- **depends_on**: —
- **notes**: All three games now call recordAttempt() per-scripture on completion. Matching/Word Builder record all as correct (game only completes when all done). Quiz tracks per-question results via new questionResults list. Time is split evenly across scriptures. Difficulty is recorded for mastery progression.

---

## P1 — Important for Quality

### TASK-004: Notes Editing on Scripture Detail
- **status**: `open`
- **claimed_by**: —
- **priority**: P1
- **estimated_effort**: Small
- **files_to_touch**: `lib/screens/scripture_detail_screen.dart`, `lib/models/scripture.dart`, possibly a new notes provider
- **description**: The notes section on scripture detail is a placeholder. Make it editable with a text field and persist via Hive.
- **acceptance_criteria**:
  - [ ] Tap notes section to edit
  - [ ] Notes persist across app restarts
  - [ ] Notes are per-scripture (use scripture ID as key)
- **depends_on**: TASK-001 (Hive wiring patterns)

### TASK-005: Sound Effects & Audio Feedback
- **status**: `open`
- **claimed_by**: —
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
- **status**: `open`
- **claimed_by**: —
- **priority**: P1
- **estimated_effort**: Small
- **files_to_touch**: `lib/screens/games/game_results_screen.dart`, possibly `lib/screens/memorize_screen.dart`
- **description**: `confetti` package is in pubspec but unused. Add confetti burst on 3-star results, mastery level-ups.
- **acceptance_criteria**:
  - [ ] 3-star game result triggers confetti
  - [ ] First time reaching "Mastered" level triggers confetti
  - [ ] Confetti doesn't block interaction
- **depends_on**: —

### TASK-007: Practice from Scripture Detail
- **status**: `open`
- **claimed_by**: —
- **priority**: P1
- **estimated_effort**: Small
- **files_to_touch**: `lib/screens/scripture_detail_screen.dart`, game screens
- **description**: The "Play" buttons on scripture detail just go to `/games`. They should launch the specific game pre-filtered to that scripture.
- **acceptance_criteria**:
  - [ ] Each game button launches the game with only that scripture
  - [ ] Results still work correctly with single-scripture sessions
- **depends_on**: —
- **notes**: May need to add a `scriptures` parameter to game screens, or a `singleScriptureId` param.

---

## P2 — Nice to Have

### TASK-008: Speech-to-Text for Master Typing
- **status**: `open`
- **claimed_by**: —
- **priority**: P2
- **estimated_effort**: Medium
- **files_to_touch**: `lib/screens/games/word_builder_screen.dart`, pubspec.yaml (new dep)
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
- **status**: `open`
- **claimed_by**: —
- **priority**: P2
- **estimated_effort**: Small
- **files_to_touch**: `lib/models/enums.dart`, `lib/screens/games_hub_screen.dart`
- **description**: DifficultyLevel descriptions are currently Word Builder-specific ("Tap 3-word chunks"). Each game should show its own description.
- **acceptance_criteria**:
  - [ ] Matching game shows matching-relevant descriptions
  - [ ] Word Builder shows current descriptions
  - [ ] Quiz shows quiz-relevant descriptions
  - [ ] Games hub renders the right description per game
- **depends_on**: —
- **notes**: Could add a `Map<GameType, String>` to DifficultyLevel, or handle in the UI layer.

---

## P3 — Future / Post-MVP

### TASK-012: Dark Mode
- **status**: `open`
- **priority**: P3
- **estimated_effort**: Medium
- **description**: Add dark theme variant to `app_theme.dart` with a toggle.

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
- **status**: `open`
- **claimed_by**: —
- **priority**: P0
- **estimated_effort**: Small
- **files_to_touch**: `pubspec.yaml`, NEW `test/helpers/test_helpers.dart`, DELETE `test/widget_test.dart`
- **description**: Add `mockito` and `fake_async` to dev_dependencies. Create test directory structure. Create shared test fixtures in `test_helpers.dart`. Delete the boilerplate `widget_test.dart`.
- **acceptance_criteria**:
  - [ ] `mockito` and `fake_async` in pubspec.yaml dev_dependencies
  - [ ] `flutter pub get` succeeds
  - [ ] `test/helpers/test_helpers.dart` exists with 5 test scriptures
  - [ ] Directory structure: `test/{models,providers,screens,helpers}/`
  - [ ] Boilerplate `widget_test.dart` deleted
- **depends_on**: —
- **notes**: See TESTING.md "Step 0" and "Step 2" for exact contents.

### TASK-021: Model Unit Tests
- **status**: `open`
- **claimed_by**: —
- **priority**: P0
- **estimated_effort**: Small
- **files_to_touch**: NEW `test/models/scripture_test.dart`, NEW `test/models/user_progress_test.dart`, NEW `test/models/enums_test.dart`
- **description**: Test all model classes — word splitting, difficulty scoring, equality, enum values.
- **acceptance_criteria**:
  - [ ] Scripture: words split, verse numbers stripped, difficultyScore tiers, copyWith, equality
  - [ ] UserProgress: default construction, storageKey format
  - [ ] Enums: all values present, labels non-empty, mastery ordering
  - [ ] All tests pass
- **depends_on**: TASK-020

### TASK-022: Progress Provider Tests
- **status**: `open`
- **claimed_by**: —
- **priority**: P0
- **estimated_effort**: Medium
- **files_to_touch**: NEW `test/providers/progress_provider_test.dart`
- **description**: Test ProgressNotifier — recordAttempt accuracy calculation, streak logic, mastery thresholds, overall stats aggregation. This is the most important provider to test.
- **acceptance_criteria**:
  - [ ] recordAttempt: first attempt, correct, incorrect, streak reset, best time, difficulty progression
  - [ ] Mastery thresholds: 0-49%, 50-69%, 70-84%, 85-94%, 95%+
  - [ ] needsReview: true < 80%, false >= 80%
  - [ ] getProgress: missing key returns null
  - [ ] getOverallStats: empty state, with data, streak calculation
  - [ ] Game type isolation: different game types don't cross-contaminate
  - [ ] All tests pass
- **depends_on**: TASK-020

### TASK-023: Scripture Provider Tests
- **status**: `open`
- **claimed_by**: —
- **priority**: P0
- **estimated_effort**: Small
- **files_to_touch**: NEW `test/providers/scripture_provider_test.dart`
- **description**: Test read-only providers — all scriptures, by book, by ID, search. Uses ProviderContainer.
- **acceptance_criteria**:
  - [ ] scripturesProvider returns 100 entries
  - [ ] scripturesByBookProvider filters correctly, no empty books
  - [ ] scriptureByIdProvider: valid ID returns scripture, invalid returns null
  - [ ] searchScripturesProvider: by reference, name, key phrase, case insensitive, no match
  - [ ] All tests pass
- **depends_on**: TASK-020

### TASK-024: Matching Game Provider Tests
- **status**: `open`
- **claimed_by**: —
- **priority**: P0
- **estimated_effort**: Medium
- **files_to_touch**: NEW `test/providers/matching_game_provider_test.dart`
- **description**: Test MatchingGameNotifier — game initialization, selection, matching, completion, star rating.
- **acceptance_criteria**:
  - [ ] startGame: correct pair count per difficulty, book filter works
  - [ ] selectPhrase/selectReference: state updates
  - [ ] Correct match: correctMatches increments, pair marked
  - [ ] Wrong match: incorrectAttempts increments
  - [ ] Game completion: isComplete when all pairs matched
  - [ ] Star rating: 0 misses=3, 1-2=2, 3+=1
  - [ ] All tests pass
- **depends_on**: TASK-020

### TASK-025: Word Builder Provider Tests
- **status**: `open`
- **claimed_by**: —
- **priority**: P0
- **estimated_effort**: Large
- **files_to_touch**: NEW `test/providers/word_builder_provider_test.dart`
- **description**: Test WordBuilderNotifier — both chunk-tap and typing modes across all 4 difficulty tiers. Most complex test file.
- **acceptance_criteria**:
  - [ ] Chunk mode: beginner=3-word chunks, intermediate=2-word + distractors
  - [ ] selectChunk: correct placement, wrong tap, distractor tap
  - [ ] Typing mode: correct char, wrong char (advanced vs master behavior)
  - [ ] Advanced: error blocks further typing, backspace clears error
  - [ ] Master: wrong char resets everything, backspace ignored
  - [ ] Case insensitive typing
  - [ ] Multi-scripture progression and completion
  - [ ] All tests pass
- **depends_on**: TASK-020

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
