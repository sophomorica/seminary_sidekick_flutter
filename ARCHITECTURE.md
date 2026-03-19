# Seminary Sidekick — Architecture & Conventions

> Read this before writing any code. These patterns are established and should be followed for consistency.

## Directory Structure

```
lib/
├── main.dart                    # App entry point, Hive init, orientation, ProviderScope
├── app.dart                     # GoRouter config, shell with bottom nav
├── models/                      # Immutable data classes and enums
│   ├── enums.dart               # All enums (ScriptureBook, MasteryLevel, GameType, DifficultyLevel)
│   ├── scripture.dart           # Scripture model
│   └── user_progress.dart       # UserProgress model
├── data/                        # Static data
│   └── scriptures_data.dart     # 100 Doctrinal Mastery scriptures (allScriptures list)
├── providers/                   # Riverpod state management
│   ├── scripture_provider.dart  # Read-only scripture queries
│   ├── progress_provider.dart   # Progress tracking (ProgressNotifier)
│   ├── matching_game_provider.dart
│   └── word_builder_provider.dart
├── screens/                     # Full-page UI
│   ├── home_screen.dart
│   ├── scripture_list_screen.dart
│   ├── scripture_detail_screen.dart
│   ├── memorize_screen.dart
│   ├── games_hub_screen.dart
│   ├── progress_screen.dart
│   └── games/                   # Game screens (launched via Navigator.push, not GoRouter)
│       ├── matching_game_screen.dart
│       ├── word_builder_screen.dart
│       └── game_results_screen.dart
├── widgets/                     # Reusable components
│   ├── scripture_card.dart
│   ├── mastery_badge.dart
│   └── progress_ring.dart
└── theme/
    └── app_theme.dart           # Design system (colors, typography, spacing, component themes)
```

## Naming Conventions

| Type | Convention | Example |
|------|-----------|---------|
| Files | `snake_case.dart` | `matching_game_screen.dart` |
| Classes | `PascalCase` | `MatchingGameScreen` |
| Providers | `camelCaseProvider` | `wordBuilderProvider` |
| StateNotifiers | `[Feature]Notifier` | `WordBuilderNotifier` |
| State classes | `[Feature]State` | `WordBuilderState` |
| Enum values | `camelCase` | `DifficultyLevel.beginner` |
| Private methods | `_camelCase` | `_loadScripture()` |

## Provider Pattern

Every stateful feature follows this structure:

```dart
// 1. State class (immutable, with copyWith)
class FeatureState {
  final /* fields */;
  const FeatureState({/* required fields */});
  FeatureState copyWith({/* optional overrides */}) { ... }
}

// 2. Notifier (business logic)
class FeatureNotifier extends StateNotifier<FeatureState> {
  FeatureNotifier() : super(FeatureState(/* defaults */));

  void someAction() {
    state = state.copyWith(/* changes */);
  }
}

// 3. Provider (global access point)
final featureProvider = StateNotifierProvider<FeatureNotifier, FeatureState>(
  (ref) => FeatureNotifier(),
);
```

### Read-only providers use `Provider` or `Provider.family`:
```dart
final scriptureByIdProvider = Provider.family<Scripture?, String>(
  (ref, id) => ref.watch(scripturesProvider).where((s) => s.id == id).firstOrNull,
);
```

## Game Screen Pattern

Every game screen follows this template:

```dart
class [Game]Screen extends ConsumerStatefulWidget {
  final DifficultyLevel difficulty;
  final ScriptureBook? bookFilter;
  // constructor with required difficulty

  @override
  ConsumerState<[Game]Screen> createState() => _[Game]ScreenState();
}

class _[Game]ScreenState extends ConsumerState<[Game]Screen>
    with TickerProviderStateMixin {

  // Timer
  late Timer _timer;
  Duration _elapsed = Duration.zero;

  // Animation controllers
  late AnimationController _shakeController;  // For incorrect feedback
  late AnimationController _pulseController;  // For correct feedback

  @override
  void initState() {
    super.initState();
    // Start game via provider in postFrameCallback
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read([game]Provider.notifier).startGame(
        difficulty: widget.difficulty,
        bookFilter: widget.bookFilter,
      );
    });
    // Init timer and animations
  }

  // Listen for completion, navigate to GameResultsScreen
  // Use ref.listen() in build() for state transitions
  // Use HapticFeedback for tactile responses
  // Use _onWillPop() with AlertDialog for exit confirmation
}
```

### Game Results
All games navigate to the shared `GameResultsScreen` on completion:
```dart
Navigator.of(context).pushReplacement(
  MaterialPageRoute(
    builder: (_) => GameResultsScreen(
      gameType: GameType.xxx,
      difficulty: widget.difficulty,
      correctMatches: state.correctCount,
      incorrectAttempts: state.incorrectCount,
      totalPairs: state.totalCount,
      completionTime: state.completionTime ?? _elapsed,
      starRating: state.starRating,
    ),
  ),
);
```

## Theme Usage

**Never hardcode colors or text styles.** Always reference the theme:

```dart
// Colors
AppTheme.primary          // Main actions, headings
AppTheme.secondary        // Secondary actions, Word Builder
AppTheme.accent           // Highlights, links
AppTheme.success          // Correct feedback
AppTheme.error            // Incorrect feedback
AppTheme.gold             // Stars, achievements
AppTheme.dark             // Text
AppTheme.surface          // Card/section backgrounds
AppTheme.offWhite         // Scaffold background

// Book-specific colors
AppTheme.bookColor('oldTestament')

// Typography
Theme.of(context).textTheme.displayMedium  // Big headings (Merriweather)
Theme.of(context).textTheme.headlineMedium // Section headings
Theme.of(context).textTheme.titleLarge     // Card titles (Inter)
Theme.of(context).textTheme.bodyLarge      // Body text
Theme.of(context).textTheme.bodySmall      // Captions

// Spacing
AppTheme.spacingSm   // 8
AppTheme.spacingMd   // 16
AppTheme.spacingLg   // 24
AppTheme.spacingXl   // 32

// Radii
AppTheme.radiusSm    // 8
AppTheme.radiusMd    // 12
AppTheme.radiusLg    // 16
```

## Animation Conventions

- **Correct action**: `_pulseController` with short duration (300ms), light haptic
- **Incorrect action**: `_shakeController` with elastic TweenSequence (~400ms), medium haptic
- **Game completion**: Heavy haptic, navigate after 600ms delay
- **Scripture completion** (multi-scripture games): Heavy haptic, auto-advance after 800ms
- **Use `AnimatedContainer`** for smooth state transitions (color, border, size)
- **Use `AnimatedBuilder`** wrapping `Transform.translate` for shake effects

## Navigation Conventions

| Route type | Method | When to use |
|-----------|--------|-------------|
| Tab navigation | GoRouter (`context.go('/path')`) | Switching between main tabs |
| Scripture browsing | GoRouter (`context.go('/scripture/$id')`) | Detail screens in the browse flow |
| Game screens | `Navigator.of(context).push()` | Launching games (transient, not in nav history) |
| Game results | `Navigator.of(context).pushReplacement()` | Replacing game screen with results |
| Memorize tool | `Navigator.of(context).push()` | Launching from scripture detail |
| Going back | `Navigator.pop()` or `context.pop()` | Returning from full-screen routes |

## Data Access Patterns

```dart
// Get all scriptures
final scriptures = ref.watch(scripturesProvider);

// Get scriptures for a book
final otScriptures = ref.watch(scripturesByBookProvider('oldTestament'));

// Get a single scripture
final scripture = ref.watch(scriptureByIdProvider('42'));

// Search scriptures
final results = ref.watch(searchScripturesProvider('nephi'));

// Get mastery level
final mastery = ref.watch(masteryLevelProvider(('42', GameType.matching)));

// Get overall stats
final stats = ref.watch(userStatsProvider);

// Record a game attempt
ref.read(progressProvider.notifier).recordAttempt(
  scriptureId: '42',
  gameType: GameType.matching,
  correct: true,
  time: 45,
  difficultyCompleted: DifficultyLevel.beginner,
);
```

## Feedback Patterns

Every user action should have immediate feedback:

| Action | Visual | Haptic |
|--------|--------|--------|
| Correct match/placement | Green color, pulse animation | `HapticFeedback.lightImpact()` |
| Incorrect attempt | Red color, shake animation | `HapticFeedback.mediumImpact()` |
| Scripture completed | Green checkmark, "Complete!" text | `HapticFeedback.heavyImpact()` |
| Game completed | Navigate to results with star rating | `HapticFeedback.heavyImpact()` |
| Word hidden (memorize) | Scale animation, color transition | `HapticFeedback.lightImpact()` |
| Tapping a toggle | Color change | `HapticFeedback.selectionClick()` |

## Common Widgets

### Scripture Card (`widgets/scripture_card.dart`)
Use whenever showing a scripture preview (home, list, search results):
```dart
ScriptureCard(scripture: scripture)
```

### Mastery Badge (`widgets/mastery_badge.dart`)
```dart
MasteryBadge.compact(masteryLevel: mastery)   // Just a colored dot
MasteryBadge.expanded(masteryLevel: mastery)  // Dot + label text
```

### Progress Ring (`widgets/progress_ring.dart`)
```dart
ProgressRing(
  progress: 0.75,
  size: 120,
  color: AppTheme.primary,
  label: '75%',
)
```

## Adding a New Game — Checklist

1. Create `lib/providers/[game]_provider.dart`
   - State class with `copyWith`
   - Notifier with `startGame()`, game actions, `nextScripture()`, `clearFeedback()`
   - `StateNotifierProvider`
2. Create `lib/screens/games/[game]_screen.dart`
   - `ConsumerStatefulWidget` with `TickerProviderStateMixin`
   - Timer, animation controllers, haptic feedback
   - Exit confirmation dialog
   - Navigate to `GameResultsScreen` on completion
3. Update `lib/screens/games_hub_screen.dart`
   - Import new screen
   - Add to `isAvailable` check
   - Add to `_launchGame()` switch
4. Update `TODO.md` to mark the task done
5. The `GameType` enum entry should already exist — if not, add it to `enums.dart`

## Adding a New Provider — Checklist

1. Create the file in `lib/providers/`
2. Define the state class (immutable, with `copyWith`)
3. Define the notifier (extends `StateNotifier<YourState>`)
4. Export the provider as a top-level `final`
5. Add convenience family providers if screens need filtered access
