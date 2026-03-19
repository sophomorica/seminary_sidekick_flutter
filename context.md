# Seminary Sidekick - Context & TODOs

## Project Overview
A Flutter app to help users master 95 Doctrinal Mastery scriptures through interactive games (Scripture Match, Word Builder) and a memorization tool. Built with Riverpod for state management, GoRouter for navigation, and Material 3 theming.

## Architecture
- **Models**: `Scripture` (immutable data), `UserProgress` (per-scripture stats), enums for books/mastery/game types
- **Providers**: Riverpod StateNotifiers for scriptures, progress, matching game, word builder game
- **Screens**: Home dashboard, Games hub, Progress analytics, Scripture browsing/detail, Memorize tool, Game screens
- **Data**: 95 scriptures in `lib/data/scriptures_data.dart`
- **Storage**: Hive initialized but not wired up for persistence

## TODOs

### High Priority
- [x] **Persist user progress with Hive** — Hive is initialized in `main.dart` but progress is never saved/loaded. Wire up `ProgressNotifier` to read/write from a Hive box so data survives app restarts.
- [ ] **Implement Quick Quiz game** — Third game type is stubbed as "Coming Soon" in the Games Hub. Design and implement a multiple-choice quiz where users identify the correct reference, key phrase, or scripture text.
- [ ] **Add search UI** — `searchScripturesProvider` exists but there's no search bar or screen. Add a search interface to the home screen or scripture list.

### Medium Priority
- [ ] **Integrate confetti celebrations** — `confetti` package is included but unused. Add confetti animations when users achieve mastery or perfect game scores.
- [ ] **Add sound effects** — `audioplayers` dependency included but not used. Add audio feedback for correct/incorrect answers and game completion.
- [ ] **Implement scripture notes** — Notes section on scripture detail screen is a placeholder. Allow users to save personal notes per scripture using Hive.
- [ ] **Add activity history** — "Recent Activity" on progress screen shows "No activity yet". Track and display recent game sessions and practice history.

### Low Priority
- [ ] **Write unit tests** — Only a placeholder widget test exists. Add tests for models, providers, and game logic.
- [ ] **Add settings screen** — No user preferences UI. Add options for theme, difficulty defaults, notification preferences.
- [ ] **Add bookmarking** — Allow users to favorite/bookmark scriptures for quick access.
