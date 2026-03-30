# CLAUDE.md — Seminary Sidekick

## What This Is

A gamified scripture memorization app for LDS Doctrinal Mastery passages (~100 scriptures across 4 volumes). Built with Flutter/Dart. The core loop is Learn, Practice, Test, Master. MVP is ~85% complete.

## Tech Stack

Flutter + Dart, Riverpod (StateNotifier), GoRouter (StatefulShellRoute for bottom nav), Hive (local persistence), Google Fonts (Merriweather + Inter), flutter_animate, confetti, audioplayers.

## Project Structure

```
lib/
  main.dart              # Entry: Hive init, orientation lock, ProviderScope
  app.dart               # GoRouter config, bottom nav shell
  models/                # Immutable data classes + enums
    enums.dart           # ScriptureBook, MasteryLevel, GameType, DifficultyLevel
    scripture.dart       # Scripture model with pre-split words
    user_progress.dart   # UserProgress with toJson/fromJson
  data/
    scriptures_data.dart # 100 Doctrinal Mastery scriptures (allScriptures)
  providers/             # Riverpod state management
    scripture_provider.dart     # Read-only: all, byBook, byId, search
    progress_provider.dart      # ProgressNotifier (Hive-backed)
    matching_game_provider.dart
    word_builder_provider.dart
    quiz_game_provider.dart
    notes_provider.dart         # Per-scripture notes (Hive-backed)
  screens/
    home_screen.dart
    scripture_list_screen.dart
    scripture_detail_screen.dart
    memorize_screen.dart
    games_hub_screen.dart
    progress_screen.dart
    games/
      matching_game_screen.dart
      word_builder_screen.dart
      quiz_game_screen.dart
      game_results_screen.dart
  widgets/
    scripture_card.dart
    mastery_badge.dart
    progress_ring.dart
  theme/
    app_theme.dart       # Full design system: colors, typography, spacing
```

## Key Conventions

**Never hardcode colors or text styles.** Use `AppTheme.*` for colors and `Theme.of(context).textTheme.*` for typography. Primary is warm rust (#D9805F), secondary is sage green (#618C84), accent is calm blue (#5B8ABF).

**Provider pattern**: Every stateful feature uses `StateNotifier<FeatureState>` with an immutable state class that has `copyWith`. Provider is a top-level `final featureProvider = StateNotifierProvider<...>`. Read-only providers use `Provider` or `Provider.family`.

**Game screen pattern**: `ConsumerStatefulWidget` with `TickerProviderStateMixin`. Start game in `postFrameCallback`. Use `ref.listen()` for state transitions. Timer, shake/pulse animation controllers, haptic feedback on every action. Exit confirmation dialog. Navigate to shared `GameResultsScreen` via `Navigator.pushReplacement`.

**Navigation**: Tab switching uses GoRouter (`context.go`). Game screens use `Navigator.push` (transient overlays, not in nav history). Game results use `Navigator.pushReplacement`.

**Naming**: Files are `snake_case.dart`. Classes are `PascalCase`. Providers are `camelCaseProvider`. Notifiers are `FeatureNotifier`. State classes are `FeatureState`.

**Feedback on every action**: Correct = green + pulse + light haptic. Incorrect = red + shake + medium haptic. Completion = heavy haptic. Use `AnimatedContainer` for smooth transitions.

## Current Task Status

Open P0 tasks: TASK-003 (wire game results to progress provider), TASK-020 through TASK-025 (test infrastructure and unit tests).

Open P1 tasks: TASK-005 (sound effects), TASK-007 (practice from scripture detail).

Open P2 tasks: TASK-008 (speech-to-text), TASK-009 (spaced repetition), TASK-010 (activity feed).

See `TODO.md` for full details, acceptance criteria, and dependency info.

## Agent Coordination

Read `TODO.md` fresh before starting work. Claim tasks by setting `status: in_progress` and `claimed_by` with your agent ID. Commit the claim before writing code. Two agents should never edit the same file concurrently — check `files_to_touch` for conflicts. When done, mark `status: done`, check off acceptance criteria, and add notes.

Commit format: `[verb] TASK-XXX: [description]` where verb is one of claim, complete, fix, add, update, refactor, block.

## Build & Test

```bash
flutter pub get          # Install deps
flutter analyze          # Must pass with no errors
flutter test             # Run all tests (test suite not yet built — see TESTING.md)
flutter run              # Run app
```

## Important Files to Read

- `CONTEXT.md` — Full project context, data model, game mechanics
- `ARCHITECTURE.md` — Conventions, patterns, checklists for adding games/providers
- `TESTING.md` — Test architecture guide with priorities and examples
- `AGENTS.md` — Coordination protocol for concurrent agents
- `TODO.md` — Single source of truth for tasks
- `app_theme.dart` — Single source of truth for colors and spacing
