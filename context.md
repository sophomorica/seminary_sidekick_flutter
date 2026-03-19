# Seminary Sidekick — Project Context

> **Last updated**: 2026-03-19
> **Status**: Active development, MVP ~85% complete
> **Stack**: Flutter/Dart, Riverpod, GoRouter, Hive, Google Fonts

## What This App Is

A gamified scripture memorization tool for the Doctrinal Mastery scriptures of The Church of Jesus Christ of Latter-day Saints. Covers ~100 passages across 4 volumes (Old Testament, New Testament, Book of Mormon, Doctrine & Covenants).

The core loop: **Learn → Practice → Test → Master**. Users memorize scriptures using a progressive hide tool, then test themselves through three games with increasing difficulty. Progress is tracked per scripture, per game, per difficulty level.

## Design Philosophy

- **Fun first**. This is a game, not a flashcard app. Animations, haptics, and satisfying feedback loops are non-negotiable.
- **Progressive difficulty**. Every feature has a gentle on-ramp (tap chunks) and a brutal endgame (blind typing from memory).
- **Visual warmth**. The palette is warm rust/terracotta (#D9805F) primary, sage green (#618C84) secondary, calm blue (#5B8ABF) accent. Merriweather for headings, Inter for body.

## Tech Stack Decisions

| Choice | Why |
|--------|-----|
| **Flutter** over React Native | Pixel-level animation control, game-quality performance |
| **Riverpod** (StateNotifier) | Predictable state, testable, no context dependency |
| **GoRouter** with StatefulShellRoute | Bottom nav with preserved tab state |
| **Hive** | Lightweight local persistence (initialized, not yet wired to progress) |
| **Google Fonts** | Merriweather + Inter, loaded at runtime |

## Data Model

### Scripture (immutable)
```
id: String (sequential '1'..'100')
book: ScriptureBook enum (oldTestament, newTestament, bookOfMormon, doctrineAndCovenants)
volume: String (e.g., "1 Nephi", "Matthew")
reference: String (e.g., "1 Nephi 3:7")
name: String (topic, e.g., "Obedience to Commandments")
keyPhrase: String (short memorable phrase)
fullText: String (complete passage text)
words: List<String> (pre-split, auto-computed, used by Word Builder)
wordCount: int (auto-computed)
```

### UserProgress (per scripture × game type)
```
scriptureId, gameType, highestDifficultyCompleted
totalAttempts, correctAttempts, currentStreak, bestStreak
bestTime, lastPracticed, accuracy, masteryLevel, needsReview
```
Storage key format: `{scriptureId}_{gameType.name}`

### Enums
- **ScriptureBook**: 4 values with displayName and abbreviation
- **MasteryLevel**: newScripture → learning → familiar → memorized → mastered (with color, icon, minAccuracy)
- **GameType**: matching, wordOrder, quiz (with displayName, description, icon)
- **DifficultyLevel**: beginner → intermediate → advanced → master (with scriptureCount, hasTimer, allowRetry, extraDistractors)

## App Structure

### Navigation (GoRouter)
```
/ (Home)         ─┐
/games           ─┤ StatefulShellRoute (bottom nav with 3 tabs)
/progress        ─┘
/scriptures/:bookId    (full-screen, no nav bar)
/scripture/:id         (full-screen, no nav bar)
```
Game screens and Memorize screen use `Navigator.push()` (not GoRouter) since they're transient full-screen overlays.

### File Map
```
lib/
├── main.dart                          # Entry: Hive init, orientation lock, ProviderScope
├── app.dart                           # GoRouter config, _AppShell with NavigationBar
├── models/
│   ├── enums.dart                     # ScriptureBook, MasteryLevel, GameType, DifficultyLevel
│   ├── scripture.dart                 # Scripture class with pre-split words
│   └── user_progress.dart             # UserProgress data class
├── data/
│   └── scriptures_data.dart           # allScriptures list (100 entries, all real text)
├── providers/
│   ├── scripture_provider.dart        # Read-only providers: all, byBook, byId, search
│   ├── progress_provider.dart         # ProgressNotifier + UserStats + convenience providers
│   ├── matching_game_provider.dart    # MatchingGameState + MatchingGameNotifier
│   └── word_builder_provider.dart     # WordBuilderState + WordBuilderNotifier (chunk + typing modes)
├── screens/
│   ├── home_screen.dart               # Dashboard: stats, book grid, continue learning
│   ├── scripture_list_screen.dart     # Book-filtered list with mastery badges
│   ├── scripture_detail_screen.dart   # Full text, key phrase, memorize button, progress cards
│   ├── memorize_screen.dart           # Progressive word-hide tool (2 modes)
│   ├── games_hub_screen.dart          # Game selection with book/difficulty filters
│   ├── progress_screen.dart           # Progress ring, stats grid, per-book breakdown
│   └── games/
│       ├── matching_game_screen.dart  # Drag-drop + tap-to-select matching
│       ├── word_builder_screen.dart   # 4-tier: chunk-tap (beg/int) + typing (adv/master)
│       └── game_results_screen.dart   # Star rating, stats, play again
├── widgets/
│   ├── scripture_card.dart            # Reusable preview card
│   ├── mastery_badge.dart             # Compact (dot) and expanded (dot + label)
│   └── progress_ring.dart             # Animated circular progress with CustomPainter
└── theme/
    └── app_theme.dart                 # Full design system: colors, typography, component themes
```

## Game Mechanics

### Matching Game (Scripture Match)
- Two columns: key phrases (left) vs references (right)
- Tap-to-select OR drag-and-drop to match
- Difficulty controls how many pairs appear
- Shake animation on wrong, pulse on correct, haptic feedback

### Word Builder
**Beginner** (chunk-tap): Scripture split into 3-word chunks, color-coded, tap in order. Wrong tap = nothing happens.
**Intermediate** (chunk-tap): 2-word chunks + distractor chunks from other scriptures mixed in.
**Advanced** (typing): Type the passage. First letter of each word shown as hint. Wrong char turns red, must backspace to fix.
**Master** (typing): Type blind — all characters hidden as underscores. Any wrong character resets entire progress. Mic button placeholder for speech-to-text.

### Quick Quiz (NOT YET BUILT)
Given a passage, select correct key phrases. Planned as the third game.

### Memorize Tool (not a game — a study aid)
Accessed from scripture detail screen. Two modes:
- **First Letter**: words progressively shrink to first letter, then to underscores
- **Full Hide**: words go straight to underscores
User can tap individual words to toggle, or use Hide Next / Reveal All / Hide All buttons.

## Provider Patterns

All providers use Riverpod. Game providers follow this pattern:
```dart
class [Game]Notifier extends StateNotifier<[Game]State> {
  void startGame({required DifficultyLevel, ScriptureBook? bookFilter})
  void [gameAction](...)  // selectChunk, onType, selectPhrase, etc.
  void nextScripture()    // multi-scripture sessions
  void clearFeedback()
}
final [game]Provider = StateNotifierProvider<[Game]Notifier, [Game]State>((ref) => ...);
```

Progress provider: `ProgressNotifier extends StateNotifier<Map<String, UserProgress>>`
- `recordAttempt()` updates accuracy, streaks, mastery level, best time
- Convenience providers: `progressByScriptureProvider`, `userStatsProvider`, `masteryLevelProvider`

## Mastery System

Accuracy-based thresholds (calculated from all attempts):
- **New**: 0% (no attempts)
- **Learning**: any attempts, <50%
- **Familiar**: ≥70%
- **Memorized**: ≥85%
- **Mastered**: ≥95%

## Key Dependencies (pubspec.yaml)
```
flutter_riverpod: ^2.4.9    # State management
hive_flutter: ^1.1.0        # Local persistence (initialized, not wired to progress yet)
go_router: ^13.0.0          # Navigation
google_fonts: ^6.1.0        # Typography
flutter_animate: ^4.3.0     # Animations (available but underused)
confetti: ^0.7.0            # Celebrations (imported, not used yet)
audioplayers: ^5.2.1        # Sound effects (imported, not used yet)
```

## What's NOT in this file

- Specific scripture text content (see `scriptures_data.dart`)
- Exact color hex values for every context (see `app_theme.dart`)
- Line-by-line implementation details (read the source files directly)

See `TODO.md` for what needs to be built next.
See `AGENTS.md` for how to coordinate work on this repo.
See `ARCHITECTURE.md` for conventions and patterns to follow.
