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
- **status**: `open`
- **claimed_by**: —
- **priority**: P0
- **estimated_effort**: Medium
- **files_to_touch**: `lib/providers/progress_provider.dart`, `lib/models/user_progress.dart`, `lib/main.dart`
- **description**: The `ProgressNotifier` currently stores everything in memory (`Map<String, UserProgress>`). Hive is already initialized in `main.dart`. Wire the progress provider to read/write from a Hive box so progress survives app restarts.
- **acceptance_criteria**:
  - [ ] Hive box opened for user progress in `main.dart`
  - [ ] `ProgressNotifier` loads from Hive on init
  - [ ] `recordAttempt()` persists to Hive after each state update
  - [ ] `UserProgress` has `toJson()` / `fromJson()` or Hive TypeAdapter
  - [ ] App restart preserves all progress data
- **depends_on**: —
- **notes**: Hive is already in pubspec and initialized. `UserProgress` needs serialization. Consider using `HiveObject` or a TypeAdapter.

### TASK-002: Build Quick Quiz Game
- **status**: `open`
- **claimed_by**: —
- **priority**: P0
- **estimated_effort**: Large
- **files_to_touch**: NEW `lib/providers/quiz_provider.dart`, NEW `lib/screens/games/quiz_screen.dart`, `lib/screens/games_hub_screen.dart`
- **description**: Third game type. Given a scripture reference, the user selects the correct key phrase from multiple choices. Follow existing game patterns (provider + screen + wire into hub).
- **acceptance_criteria**:
  - [ ] `QuizNotifier` with `startGame()`, answer selection, multi-scripture sessions
  - [ ] 4 answer choices per question (1 correct + 3 distractors from other scriptures)
  - [ ] Difficulty tiers: Beginner (show full text, pick key phrase), Intermediate (show key phrase, pick reference), Advanced (show reference, type key phrase), Master (audio-only or no hints)
  - [ ] Navigates to `GameResultsScreen` on completion
  - [ ] Games hub updated: quiz card enabled, "Coming Soon" badge removed
  - [ ] Book filter and difficulty selector work
- **depends_on**: —
- **notes**: Follow the patterns in `matching_game_provider.dart` and `word_builder_provider.dart`. Reuse `GameResultsScreen`. The `GameType.quiz` enum already exists.

### TASK-003: Wire Game Results to Progress Provider
- **status**: `open`
- **claimed_by**: —
- **priority**: P0
- **estimated_effort**: Small
- **files_to_touch**: `lib/screens/games/matching_game_screen.dart`, `lib/screens/games/word_builder_screen.dart`, `lib/providers/progress_provider.dart`
- **description**: Currently, game completions don't call `progressProvider.recordAttempt()`. Wire each game's completion to record results.
- **acceptance_criteria**:
  - [ ] Matching game calls `recordAttempt()` for each scripture in the session on completion
  - [ ] Word Builder calls `recordAttempt()` for each scripture on completion
  - [ ] Progress screen reflects game results
  - [ ] Mastery badges update after playing games
- **depends_on**: —
- **notes**: Each game tracks multiple scriptures per session. Record one attempt per scripture, not one per session.

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
