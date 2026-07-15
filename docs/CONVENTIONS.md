## Conventions

### Image Assets

Never generate or source actual image files. When an image is needed, create a `.txt` file in `assets/images/` with a detailed description of what the image should depict (composition, style, colors, mood, dimensions, etc.). Name the file with the intended final image name but with a `.txt` extension (e.g., `onboarding_hero.txt` for an image that will become `onboarding_hero.png`). The user will generate the image later and replace the `.txt` with the real file.

### Audio Assets

Same rule as images — **never generate audio files** (no TTS, no Python synthesis, no auto-generated SFX). Previous agent-generated `.wav` files sounded bad and had to be thrown out. When a new sound effect is needed, create a `.txt` placeholder in `assets/audio/` with:

1. **Filename** — use the intended final audio name with a `.txt` extension (e.g., `streak_milestone.txt` for a file that will eventually become `streak_milestone.wav`).
2. **Sound description** — short prose description of what it should sound like (e.g., "A warm, bell-like chime that rings for ~400ms, reverent but satisfying").
3. **Where to source it** — name 2–3 places the user can grab something suitable: e.g., freesound.org search terms, Pixabay audio, Zapsplat categories, or specific SFX pack references.
4. **Expected duration and format** — e.g., "~300ms, 44.1kHz .wav, mono is fine".
5. **Any references to similar sounds** in other apps the user can mimic.

The user will manually source/record the real audio and drop it in next to the `.txt` (keep both during review; delete the `.txt` once the real file is in place). Do not reference the `.txt` from code — `SoundEffect` enum entries should keep pointing at the intended `.wav` path, and the user will replace the file.

### Naming

| Type          | Convention          | Example                     |
| ------------- | ------------------- | --------------------------- |
| Files         | `snake_case.dart`   | `matching_game_screen.dart` |
| Classes       | `PascalCase`        | `MatchingGameScreen`        |
| Providers     | `camelCaseProvider` | `scriptureBuilderProvider`       |
| Notifiers     | `[Feature]Notifier` | `ScriptureBuilderNotifier`       |
| State classes | `[Feature]State`    | `ScriptureBuilderState`          |

### Theme — Never Hardcode Colors or Text Styles

```dart
// Colors — always use AppTheme.*
AppTheme.primary          // Warm rust (#D9805F) — main actions, headings
AppTheme.secondary        // Sage green (#618C84) — secondary actions
AppTheme.accent           // Calm blue (#5B8ABF) — highlights, links
AppTheme.success          // Correct feedback
AppTheme.error            // Incorrect feedback
AppTheme.gold             // Achievements / Group Play race finish pips (solo results use meter grades)
AppTheme.dark             // Text
AppTheme.surface          // Card backgrounds
AppTheme.offWhite         // Scaffold background
AppTheme.bookColor('oldTestament')  // Book-specific
AppTheme.premiumGold      // Premium badges, upgrade CTAs (#D4A843)
AppTheme.premiumGoldLight // Premium background tint (#F5E6B8)
AppTheme.premiumGradientStart / premiumGradientEnd  // Premium icon gradients

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

### Lint Hygiene — Run `flutter analyze` Before Calling Work Done

`flutter analyze` must exit clean (zero issues, including infos). The same mistakes keep slipping through — check for these before finishing:

1. **Missing `const` on const-eligible constructors** (`prefer_const_constructors`) — the #1 repeat offender. All `AppTheme.*` colors and `Color(0xFF...)` literals are compile-time constants, so widgets built only from them must be `const`:
   - `const Icon(Icons.x, size: 16, color: AppTheme.secondary)` — not `Icon(...)`
   - Confetti `colors:` lists mixing `Theme.of(context)` with hex literals: the *list* can't be const, but each literal can — `const Color(0xFFFFD54F)`
2. **Unused imports** (`unused_import`) — after moving/extracting widgets or trimming a build method, re-check the file's imports (`app_theme.dart` is the usual leftover).
3. **Deprecated members** (`deprecated_member_use`) — after any `pub get`/dependency bump, run analyze and migrate renamed params instead of suppressing (e.g. Supabase `anonKey` → `publishableKey`, 2026-07-01).
4. **Wrong named params on animation widgets** — `SizeTransition` takes `axisAlignment` (`double`, `-1.0` = top/start), **not** `alignment: Alignment.topLeft` (that's `Align`). It fails analyze as `undefined_named_parameter` on this repo's SDK. (A prior version of this doc claimed the opposite — that was wrong and caused repeated agent errors, fixed 2026-07-12.) Always check the real constructor; don't invent Align-style params on size/fade/slide transitions.

Shared Flutter floors + the full analyze-pitfall list also live in
`../narrow-road-hq/standards/FLUTTER_APP_STANDARDS.md` — keep that file and
this section in sync when a new repeat offender shows up.

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

Scripture Builder follows this same pattern but is launched from scripture detail, not the practice hub.

### Navigation

| Route type         | Method                                                  | When                      |
| ------------------ | ------------------------------------------------------- | ------------------------- |
| Tab navigation     | GoRouter `context.go('/path')`                          | Main tabs                 |
| Scripture browsing | GoRouter `context.push('/scripture/$id')`               | Detail (Library branch)   |
| Fullscreen overlays | `pushFullscreen(context, page)` from `lib/navigation/fullscreen.dart` | Memorize, Journal-with-args, Sidekick chat with initial message, games |
| Upgrade / Settings / bare Journal | `pushUpgrade(context)` / `context.push('/upgrade')` etc. | Sibling GoRoutes *outside* the shell |
| Game results       | `Navigator.pushReplacement` (already on root nav)       | Replace game with results |

**Shell trap (repeat offender):** The bottom-nav shell uses a nested navigator. Plain `Navigator.of(context).push(MaterialPageRoute(...))` stacks *under* the "Seminary Sidekick" header + tab bar and creates a huge gap above the page's own AppBar/SafeArea. Always use `pushFullscreen` / `rootNavigator: true`, or a GoRouter sibling route (`/upgrade`, `/settings`, `/journal`). Solo games already do this via `game_setup_sheet.dart`.

### Feedback on Every Action

| Action             | Visual                | Haptic           |
| ------------------ | --------------------- | ---------------- |
| Correct            | Green + pulse (300ms) | `lightImpact()`  |
| Incorrect          | Red + shake (~400ms)  | `mediumImpact()` |
| Scripture complete | Green checkmark       | `heavyImpact()`  |
| Game complete      | Navigate to results   | `heavyImpact()`  |

Use `AnimatedContainer` for smooth state transitions.

### Data Access

```dart
ref.watch(scripturesProvider)                          // All scriptures
ref.watch(scripturesByBookProvider('oldTestament'))     // By book
ref.watch(scriptureByIdProvider('42'))                  // By ID
ref.watch(searchScripturesProvider('nephi'))            // Search
ref.watch(scriptureMasteryProvider('42'))               // Holistic mastery (Scripture Builder-driven)
ref.watch(holisticStatsProvider)                        // Aggregate mastery stats
ref.watch(masteryLevelProvider(('42', GameType.matching)))  // Per-game mastery (legacy, still used by game screens)
ref.watch(userStatsProvider)                            // Overall stats
ref.read(progressProvider.notifier).recordAttempt(...)  // Record attempt

// Subscription (freemium)
ref.watch(subscriptionProvider)                        // Full subscription state
ref.watch(isPremiumProvider)                           // bool — is user premium?
ref.watch(canShowUpgradePromptProvider)                // bool — rate-limited prompt check
ref.read(subscriptionProvider.notifier).purchasePlan(plan)  // Trigger purchase
ref.read(subscriptionProvider.notifier).dismissUpgradePrompt()  // Record dismissal

// Sidekick AI (premium)
ref.watch(sidekickProvider)                            // Full sidekick state
ref.watch(sidekickResponseProvider)                    // Latest SidekickResponse
ref.watch(dailyPromptProvider)                         // String? — daily prompt
ref.watch(quickWinProvider)                            // QuickWin? — next action
ref.watch(reflectionPromptsProvider)                   // List<String> — journal prompts
ref.watch(chatHistoryProvider)                         // List<SidekickMessage>
ref.watch(isChatLoadingProvider)                       // bool — chat in flight?
ref.read(sidekickProvider.notifier).refreshSession()   // Re-fetch from Grok
ref.read(sidekickProvider.notifier).sendMessage(text)  // Chat message

// Group Play
ref.watch(groupPlayProvider)                           // Full GroupPlayState
ref.watch(groupPlayPhaseProvider)                      // idle/hosting/joining/inLobby/inQuiz/viewingResults/error
ref.watch(groupPlayLeaderboardProvider)                // Players sorted by score
ref.watch(isGroupHostProvider)                         // bool — am I the host?
ref.read(groupPlayProvider.notifier).hostCreateRoom(scope:, hostNickname:)
ref.read(groupPlayProvider.notifier).joinAsPlayer(code:, nickname:)
ref.read(groupPlayProvider.notifier).leave()           // Player leaves / host closes
// GroupPlayState.isReconnecting → show ReconnectingBanner during wifi blips;
// the service auto-resubscribes with backoff and refetches missed rows.
```

---

## Adding a New Quiz/Practice Tool — Checklist

1. Create `lib/providers/[quiz]_provider.dart` — State class with `copyWith`, Notifier with `startGame()`, game actions, `nextScripture()`, `clearFeedback()`, `StateNotifierProvider`
2. Create `lib/screens/games/[quiz]_screen.dart` — `ConsumerStatefulWidget` with `TickerProviderStateMixin`, timer, animations, haptics, exit dialog, navigate to `GameResultsScreen`
3. Update `lib/screens/games_hub_screen.dart` (will become practice hub) — import, `isAvailable` check, `_launchGame()` switch
4. Update `TODO.md`
5. Ensure `GameType` enum entry exists in `enums.dart`

**Note**: Scripture Builder is NOT a quiz — it's the mastery tool and lives under scripture detail. Only supplementary practice tools go in the practice hub.

## Adding a New Provider — Checklist

1. Create file in `lib/providers/`
2. Define immutable state class with `copyWith`
3. Define notifier extending `StateNotifier<YourState>`
4. Export provider as top-level `final`
5. Add convenience `Provider.family` providers if needed

