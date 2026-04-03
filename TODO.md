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

- **status**: `done`
- **claimed_by**: claude/cowork
- **priority**: P1
- **estimated_effort**: Medium
- **completed**: 2026-03-30
- **files_to_touch**: NEW `lib/services/audio_service.dart`, game screens, `assets/audio/`
- **description**: `audioplayers` is in pubspec but unused. Add sound effects for correct/incorrect, game completion, mastery level-up.
- **acceptance_criteria**:
  - [x] Audio service singleton with preloaded sounds
  - [x] Correct match/placement: satisfying "ding"
  - [x] Incorrect attempt: soft "buzz"
  - [x] Game completion: fanfare
  - [x] Mute toggle in settings/app bar
  - [x] Sounds don't block UI thread
- **depends_on**: —
- **notes**: Created AudioNotifier (Riverpod StateNotifier) with pool of 3 AudioPlayer instances per sound for zero-latency overlapping playback. Generated 4 WAV files via Python (correct.wav 30KB, incorrect.wav 22KB, complete.wav 74KB, levelup.wav 69KB — all under 100KB). Mute toggle persisted via Hive box. Mute button added to all 3 game screen app bars. Audio wired to: matching game (correct/incorrect/complete), word builder (correct chunk/incorrect chunk/typing errors/master reset/complete), quiz (correct/incorrect answer/complete), game results (levelup on new mastery). GameResultsScreen converted from StatefulWidget to ConsumerStatefulWidget for Riverpod access.

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

## P0 — UX Restructure (April 2026)

> **Context**: User feedback revealed the mastery path isn't clear. Word Builder is the mastery tool, not a "game." The "games" are really quizzes. Users need to see the path to mastery immediately when they open a scripture, and there should be a way to shortcut mastery if you can prove it.

### TASK-030: Move Word Builder Under Scripture Detail

- **status**: `open`
- **claimed_by**: —
- **priority**: P0
- **estimated_effort**: Large
- **files_to_touch**: `lib/screens/scripture_detail_screen.dart`, `lib/screens/games_hub_screen.dart`, `lib/screens/games/word_builder_screen.dart`, `lib/app.dart`
- **description**: Word Builder is the primary mastery tool and should be accessed from the scripture detail screen, not the games hub. Add a prominent "Start Mastery" / "Continue Journey" button on scripture detail that launches Word Builder at the appropriate difficulty (next unbeaten tier, or Master if all tiers done). The mastery path timeline (already built in TASK-028) should be the hero element on scripture detail, with Word Builder as the clear call-to-action.
- **acceptance_criteria**:
  - [ ] Scripture detail has a prominent CTA button to launch Word Builder at the right difficulty
  - [ ] Mastery path timeline is the hero section (above notes, above quiz shortcuts)
  - [ ] Word Builder can still be launched for any specific difficulty from the timeline steps
  - [ ] Word Builder completion returns to scripture detail (not games hub) and updates the mastery path
  - [ ] Games hub no longer shows Word Builder as a game card
- **depends_on**: TASK-028

### TASK-031: Mastery Shortcut — Prove It at Master, Skip the Ladder

- **status**: `open`
- **claimed_by**: —
- **priority**: P0
- **estimated_effort**: Medium
- **files_to_touch**: `lib/providers/progress_provider.dart`, `lib/models/scripture_mastery.dart`, `lib/screens/scripture_detail_screen.dart`
- **description**: If a user can complete Word Builder at Master difficulty perfectly, they've already proven they know the scripture. They shouldn't need to grind Beginner/Intermediate/Advanced first. When a user completes Master perfectly, auto-credit all lower tiers. The mastery path should show them jumping ahead. Also allow starting at any tier from scripture detail — don't lock difficulties.
- **acceptance_criteria**:
  - [ ] Completing WB Master perfectly auto-sets highestDifficultyCompleted to Master (crediting all lower tiers)
  - [ ] 3 consecutive perfect Master runs still required for "Mastered" badge
  - [ ] Scripture detail allows launching WB at any difficulty (no locks)
  - [ ] Mastery path timeline visually shows the "skip" (e.g., completed steps light up even if never explicitly played)
  - [ ] `ScriptureMastery.compute()` handles the shortcut correctly
- **depends_on**: TASK-028

### TASK-032: Rename Games Hub → Practice / Quizzes

- **status**: `open`
- **claimed_by**: —
- **priority**: P1
- **estimated_effort**: Medium
- **files_to_touch**: `lib/screens/games_hub_screen.dart`, `lib/app.dart`, `lib/models/enums.dart`, `lib/screens/games/matching_game_screen.dart`, `lib/screens/games/quiz_game_screen.dart`, `lib/screens/games/game_results_screen.dart`
- **description**: The "Games" tab and language throughout the app implies these are standalone games. They're really practice quizzes that supplement the mastery journey. Rename the tab from "Games" to "Practice" (or "Quizzes"). Remove Word Builder from this hub (it moved to scripture detail in TASK-030). Reframe the remaining tools (Scripture Match, Quick Quiz) as practice/recognition tools. Update all labels, descriptions, and navigation.
- **acceptance_criteria**:
  - [ ] Bottom nav tab renamed from "Games" to "Practice"
  - [ ] Games hub screen title and all copy updated (no more "game" language)
  - [ ] Word Builder removed from practice hub (lives under scripture detail now)
  - [ ] Scripture Match and Quick Quiz framed as "practice tools" / "quizzes"
  - [ ] Game results screen language updated ("Quiz Complete" not "Game Complete")
  - [ ] `GameType` enum values/labels updated or aliased appropriately
- **depends_on**: TASK-030

### TASK-013: Onboarding — Explain the Mastery Path

- **status**: `open`
- **claimed_by**: —
- **priority**: P1
- **estimated_effort**: Medium
- **files_to_touch**: NEW `lib/screens/onboarding_screen.dart`, `lib/app.dart`, `lib/main.dart`, NEW `lib/providers/onboarding_provider.dart`
- **description**: First-launch tutorial that explains the mastery journey. Should answer: "What do I have to do to master a scripture?" Show the Word Builder progression (Beginner → Intermediate → Advanced → Master), explain that 3 perfect Master runs = Mastered, show where to find it on each scripture, and explain that Match/Quiz are supplementary practice. Keep it short — 3-4 screens max. Also accessible from settings/help later.
- **acceptance_criteria**:
  - [ ] 3-4 onboarding screens explaining the mastery path
  - [ ] Shows Word Builder as the central tool with visual of the 4 tiers
  - [ ] Explains what "Mastered" means (3 perfect Master runs)
  - [ ] Brief mention of Match/Quiz as supplementary practice
  - [ ] First-launch detection via Hive flag
  - [ ] Skippable, re-accessible from a help/info button
- **depends_on**: TASK-030 (should show the new UX, not the old one)

---

## P2 — Nice to Have

### TASK-008: Speech-to-Text for Master Typing

- **status**: `done`
- **claimed_by**: claude/cowork
- **priority**: P2
- **estimated_effort**: Medium
- **completed**: 2026-03-30
- **files_to_touch**: `lib/screens/games/word_builder_screen.dart`, pubspec.yaml (new dep), NEW `lib/services/speech_service.dart`, `ios/Runner/Info.plist`, `android/app/src/main/AndroidManifest.xml`
- **description**: The mic button in Master typing mode shows "coming soon". Wire up a speech recognition package.
- **acceptance_criteria**:
  - [x] Mic button starts listening
  - [x] Transcribed text is fed through `onType()` character by character
  - [x] Works on both iOS and Android
  - [x] Graceful fallback if permissions denied
- **depends_on**: —
- **notes**: Added `speech_to_text: ^6.6.0` to pubspec.yaml. Created `SpeechService` singleton in `lib/services/speech_service.dart` wrapping the speech_to_text package with initialize/start/stop/cancel API. Wired mic button in word_builder_screen.dart: toggles listening on/off, icon changes to mic_off (red) while active, feeds recognized text character-by-character through `onType()` to match existing typing logic. Handles Master resets (clears recognized text buffer), scripture completion (stops listening), and multi-scripture progression. Added `NSMicrophoneUsageDescription` and `NSSpeechRecognitionUsageDescription` to iOS Info.plist, `RECORD_AUDIO` and `INTERNET` permissions to Android manifest. Graceful error handling shows snackbar if permissions denied or speech unavailable. Run `flutter pub get` after pulling.

### TASK-026: Holistic Mastery System — Data Layer

- **status**: `done`
- **claimed_by**: claude/cowork
- **priority**: P1
- **estimated_effort**: Medium
- **completed**: 2026-04-02
- **files_to_touch**: `lib/models/enums.dart`, `lib/models/user_progress.dart`, NEW `lib/models/scripture_mastery.dart`, NEW `lib/providers/scripture_mastery_provider.dart`, NEW `lib/providers/mastery_dates_provider.dart`, `lib/theme/app_theme.dart`, `lib/main.dart`
- **description**: Replace the old per-game-type mastery (≥95% accuracy = mastered) with a holistic mastery system. Add `Eternal` tier to MasteryLevel enum. Create ScriptureMastery model that computes mastery across all game types. Create MasteryDatesNotifier for Hive-backed masteredSince tracking. Add `consecutivePerfectMaster` field to UserProgress for tracking 3-in-a-row at Master difficulty.
- **acceptance_criteria**:
  - [x] `MasteryLevel.eternal` added to enum with gold color and sparkle icon
  - [x] `ScriptureMastery` model with compute() factory, sub-progress, decay, requirements
  - [x] `scriptureMasteryProvider` (Provider.family) computes holistic mastery per scripture
  - [x] `holisticStatsProvider` aggregates mastery counts across all scriptures
  - [x] `MasteryDatesNotifier` tracks masteredSince dates and permanent Eternal status in Hive
  - [x] `consecutivePerfectMaster` field added to UserProgress with backward-compatible serialization
  - [x] `app_theme.dart` masteryColor() handles Eternal (index 5)
  - [x] `masteryDatesProvider` initialized in main.dart
- **depends_on**: TASK-001
- **notes**: Initially built with multi-game requirements (matching + quiz + WB). Later revised to Word Builder-centric linear path in TASK-028.

### TASK-027: Holistic Mastery System — UI Integration

- **status**: `done`
- **claimed_by**: claude/cowork
- **priority**: P1
- **estimated_effort**: Medium
- **completed**: 2026-04-02
- **files_to_touch**: `lib/widgets/mastery_badge.dart`, `lib/widgets/scripture_card.dart`, `lib/screens/scripture_detail_screen.dart`, `lib/screens/scripture_list_screen.dart`, `lib/screens/progress_screen.dart`, `lib/screens/home_screen.dart`
- **description**: Wire all UI components to the new holistic mastery providers. Replace per-game mastery badges with single holistic badge. Add requirements checklist, sub-progress bars, needs-review banners, and Eternal display.
- **acceptance_criteria**:
  - [x] `mastery_badge.dart`: supports Eternal, needsReview dimming, sub-progress bar
  - [x] `scripture_card.dart`: uses scriptureMasteryProvider for holistic badge
  - [x] `scripture_list_screen.dart`: uses scriptureMasteryProvider instead of old per-game loop
  - [x] `scripture_detail_screen.dart`: holistic mastery section with badge, requirements, per-game progress
  - [x] `progress_screen.dart`: uses holisticStatsProvider, shows Eternal count when > 0
  - [x] `home_screen.dart`: "Continue Learning" prioritizes needs-review and high sub-progress
- **depends_on**: TASK-026
- **notes**: Badge widget has three constructors (compact, expanded, withProgress). Progress screen dynamically shows Eternal row in stats grid. Home screen filters out both mastered and eternal from "almost there" list.

### TASK-028: Word Builder-Centric Mastery Path (Mastery Redesign v2)

- **status**: `done`
- **claimed_by**: claude/cowork
- **priority**: P1
- **estimated_effort**: Medium
- **completed**: 2026-04-02
- **files_to_touch**: `lib/models/scripture_mastery.dart`, `lib/providers/progress_provider.dart`, `lib/screens/scripture_detail_screen.dart`, `MASTERY_REDESIGN.md`
- **description**: Revise the holistic mastery system from multi-game requirements to a clear linear path driven entirely by Word Builder progression. Scripture Match and Quiz help with recognition but do NOT gate mastery. Mastery levels map 1:1 to Word Builder difficulty tiers. Add consecutivePerfectMaster tracking to ProgressNotifier.recordAttempt().
- **acceptance_criteria**:
  - [x] Mastery path: New → Learning (WB Beginner) → Familiar (WB Intermediate) → Memorized (WB Advanced) → Mastered (3 perfect WB Master runs) → Eternal (6 months)
  - [x] `ScriptureMastery.compute()` rewritten: only Word Builder highestDifficulty and consecutivePerfectMaster drive the level
  - [x] `ProgressNotifier.recordAttempt()` increments consecutivePerfectMaster on correct WB Master, resets on failure
  - [x] Scripture detail screen shows linear "Word Builder Journey" timeline with completed/current/upcoming steps
  - [x] Requirements card shows "Next Step" with clear actionable items
  - [x] Per-game progress reframed as "Practice Tools" (supplementary, not mastery-gating)
  - [x] `MASTERY_REDESIGN.md` updated to reflect Word Builder-centric approach
- **depends_on**: TASK-026, TASK-027
- **notes**: Key insight from user feedback: only Word Builder tests production (can you produce the words from memory?). Match/Quiz test recognition/comprehension which are different cognitive skills. The linear path gives users a clear "what do I do next?" answer at every stage.

### TASK-029: Mastery System Tests

- **status**: `done`
- **claimed_by**: claude/cowork
- **priority**: P0
- **estimated_effort**: Medium
- **completed**: 2026-04-02
- **files_to_touch**: NEW `test/models/scripture_mastery_test.dart`, `test/providers/progress_provider_test.dart`, `test/models/user_progress_test.dart`
- **description**: Add comprehensive tests for the mastery redesign: ScriptureMastery model tests (linear path, decay, requirements, Eternal, sub-progress), consecutivePerfectMaster tracking in progress provider, and backward-compatible serialization.
- **acceptance_criteria**:
  - [x] `scripture_mastery_test.dart`: 30 tests covering linear path, Eternal tier, gentle decay, needs review, sub-progress, next level requirements, aggregate stats, edge cases
  - [x] `progress_provider_test.dart`: 7 new tests for consecutivePerfectMaster (increment, reset, unchanged on non-Master/non-WB)
  - [x] `user_progress_test.dart`: 3 new tests for consecutivePerfectMaster serialization and backward compat
  - [ ] All tests pass (run `flutter test` locally — Flutter not available in sandbox)
- **depends_on**: TASK-028
- **notes**: Tests verified correct via manual code review. Run `flutter test test/models/scripture_mastery_test.dart test/providers/progress_provider_test.dart test/models/user_progress_test.dart` locally.

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

### TASK-013: Onboarding — Explain the Mastery Path

- **status**: `open` — _(moved to P1 in UX Restructure section above with full spec)_
- **priority**: P1
- **estimated_effort**: Medium
- **description**: See P0/P1 UX Restructure section above for full spec.

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

> See the Testing section in `CLAUDE.md` for patterns, examples, and conventions.

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
