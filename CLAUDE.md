# CLAUDE.md — Seminary Sidekick

> **Single entry point for AI agents.** Read this file before touching any code.
> For the launch/feature task board, see `TODO.md`.
> For ongoing maintenance work (security hygiene, dependency bumps, infra audits, tech-debt cleanups), see `MAINTENANCE.md`.

---

## What This App Is

A focused scripture mastery tool for the 100 Doctrinal Mastery scriptures of The Church of Jesus Christ of Latter-day Saints.

The core loop is **Study → Build → Prove → Master**. Users study the text, then use **Scripture Builder** (the primary mastery tool) to progressively prove they can reproduce it from memory. Supplementary practice tools (Scripture Match, Quick Quiz) help with recognition and comprehension but do not gate mastery.

The viral mechanic is **Class Play** (Group Play) — Kahoot-style live multiplayer rounds for the whole seminary class. One teacher running a live round = 20-30 students opening the app at once; it's the highest-leverage growth lever the brand has and the feature that turns "great scripture mastery app" into "the defacto seminary app." **Shipped (v1, 2026-05)**: Supabase-backed (Realtime + anonymous auth), 4-letter join codes + QR, two game modes — live Quick Quiz and Scripture Builder Race — with lobby, countdown, answer-distribution reveal, live leaderboard with rank deltas, podium results, and free/premium host tiers (6-player casual vs 30-player class rooms). See TASK-048's decomposition (TASK-051–062) in `TODO.md` and `SUPABASE_SETUP.md` for the backend runbook. Group play NEVER writes to personal mastery/progress — it's purely social.

**Key UX principle**: The path to mastery must be obvious. When a user opens a scripture, they should immediately see where they are on the mastery path, what to do next, and what “mastered” means. Scripture Builder lives directly under each scripture as the central mastery tool.

**Landing principle**: The app should open to **"Let's Learn / Let's Play"** — not a dashboard. Home is the jumping-off point to study and practice. Stats, progress rings, and long descriptions belong on the Stats tab, not on the first thing a kid sees. Keep Home punchy: pick up where you left off, start a quick quiz, launch Scripture Builder. The dashboard view is reachable via the Stats tab for users who want it.

**Design philosophy**: Fun first with warm, satisfying feedback (animations, haptics, confetti, progressive difficulty). The experience is reverent and purposeful while remaining engaging for seminary students. The primary success metrics are **engagement with friends and mastery retention** — we want kids to come back on their own AND invite their seminary group to play together.

**Status**: Free-tier MVP complete. Premium tier (Seminary Sidekick AI — Grok-powered journal prompts, reflection questions, smart goals, timeline insights, chat) built. Group Play v1 (quiz + Scripture Builder race) shipped end-to-end. Current focus is **launch readiness**: real RevenueCat purchase wiring, crash reporting, store identity (bundle IDs/signing), Sidekick system-prompt safety hardening, real audio assets, and privacy/legal. See "Current Task Status" below and `TODO.md`.

**Business model**: Freemium.

- **Free tier** = Full mastery loop (Scripture Builder, Practice tools, spaced repetition, progress tracking, activity feed).
- **Premium tier** = Seminary Sidekick AI (JSON snapshot → structured response), journal with dynamic prompts, curriculum awareness, gentle reminders, and light engagement layers.

---

## Tech Stack

| Choice                             | Why                                                     |
| ---------------------------------- | ------------------------------------------------------- |
| **Flutter + Dart**                 | Pixel-level animation control, game-quality performance |
| **Riverpod** (StateNotifier)       | Predictable state, testable, no context dependency      |
| **GoRouter** (StatefulShellRoute)  | Bottom nav with preserved tab state                     |
| **Hive**                           | Lightweight local persistence                           |
| **Google Fonts**                   | Merriweather (headings) + Inter (body)                  |
| **flutter_animate**                | Animations                                              |
| **confetti**                       | Celebration effects                                     |
| **audioplayers**                   | Sound effects                                           |
| **purchases_flutter** (RevenueCat) | In-app subscriptions for freemium model                 |
| **supabase_flutter**               | Group Play backend: Postgres + RLS, Realtime, anon auth |
| **qr_flutter** / **share_plus**    | Lobby QR join codes / share game results                |
| **sentry_flutter** (Sentry)        | Crash reporting — no-op unless `SENTRY_DSN` dart-define |

---

## Project Structure

lib/
├── main.dart # Entry: Hive init, orientation lock, ProviderScope
├── app.dart # GoRouter config, shell with bottom nav
├── models/
│ ├── enums.dart
│ ├── scripture.dart
│ ├── user_progress.dart
│ ├── scripture_mastery.dart
│ ├── sidekick_snapshot.dart # JSON sent to Grok
│ ├── sidekick_response.dart # Structured response from Grok
│ ├── journal_entry.dart
│ ├── scripture_scope.dart # Shared "which scriptures count" value type
│ ├── group_room.dart # Group play: room + scope + GroupGameMode
│ ├── group_player.dart # Group play: roster row
│ ├── group_question.dart # Group play: frozen quiz question
│ ├── group_answer.dart # Group play: answer + speed-weighted points
│ ├── group_sb_config.dart # SB race config (difficulty, play mode, set)
│ ├── group_sb_finish.dart # SB race finish event (incl. DNF)
│ └── group_play_state.dart # Aggregate state for GroupPlayNotifier
├── data/
│ └── scriptures_data.dart
├── providers/
│ ├── scripture_provider.dart
│ ├── progress_provider.dart
│ ├── scripture_mastery_provider.dart
│ ├── mastery_dates_provider.dart
│ ├── matching_game_provider.dart
│ ├── scripture_builder_provider.dart
│ ├── quiz_game_provider.dart
│ ├── notes_provider.dart
│ ├── sidekick_provider.dart # Main AI orchestration
│ ├── subscription_provider.dart # Freemium state + RevenueCat
│ ├── goals_provider.dart
│ ├── journal_provider.dart
│ ├── group_play_provider.dart # Group play orchestration + realtime subs
│ └── scripture_scope_provider.dart # Hive-backed last-used scope per game
├── screens/
│ ├── home/
│ │ ├── home_screen.dart # Orchestrator: stats, books, premium, sessions, nudges
│ │ ├── stats_section.dart # StatCard grid (scriptures started, mastered, streak)
│ │ ├── book_collections_section.dart # BookCard grid with icons
│ │ ├── premium_home_section.dart # Reminder, goal, timeline, reflect cards
│ │ ├── quick_sessions_section.dart # Quick session tiles
│ │ └── nearly_mastered_section.dart # Nearly-mastered nudge tiles
│ ├── scripture_detail/
│ │ ├── scripture_detail_screen.dart # Main detail: text, notes, practice buttons, difficulty
│ │ ├── mastery_path_section.dart # HolisticMasterySection + MasteryPathStep
│ │ ├── encouragement_card.dart # AI encouragement card (premium)
│ │ └── scripture_connections_card.dart # AI scripture connections (premium)
│ ├── journal/
│ │ ├── journal_screen.dart # Thin orchestrator (editor vs list)
│ │ ├── journal_list_view.dart # List with selection, export, share
│ │ ├── journal_editor_view.dart # Editor with voice-to-text, tagging
│ │ └── empty_journal_view.dart # Empty state + free-user prompt
│ ├── sidekick_chat/
│ │ ├── sidekick_chat_screen.dart # Chat screen with message history
│ │ ├── chat_bubble.dart # ChatBubble + RichMessageText
│ │ ├── chat_empty_state.dart # Empty state with suggestion chips
│ │ ├── chat_input.dart # Text field with send button
│ │ └── typing_indicator.dart # Animated typing dots
│ ├── progress/
│ │ ├── progress_screen.dart # Mastery ring, book breakdown, activity
│ │ ├── stats_grid.dart # StatsGrid + \_StatTile
│ │ ├── activity_tile.dart # ActivityTile
│ │ └── goals_timeline_section.dart # Goals + completed goals tiles
│ ├── onboarding/
│ │ ├── onboarding_screen.dart # PageView orchestrator with skip/dots
│ │ ├── welcome_page.dart # Welcome page
│ │ ├── scripture_builder_page.dart # Scripture Builder intro + tier rows
│ │ ├── mastery_page.dart # Mastery path explanation
│ │ └── quizzes_page.dart # Practice quizzes intro + quiz cards
│ ├── games/
│ │ ├── matching_game_screen.dart
│ │ ├── quiz_game_screen.dart
│ │ ├── game_results_screen.dart
│ │ └── scripture_builder/
│ │ └── scripture_builder_screen.dart # Primary mastery tool (all 4 difficulties)
│ ├── group_play/
│ │ ├── host_lobby_screen.dart # Setup + lobby (code, QR, roster, kick, mode)
│ │ ├── join_lobby_screen.dart # Code + nickname entry, waiting view
│ │ ├── group_quiz_screen.dart # Live quiz: question/standings local phases
│ │ ├── group_scripture_builder_screen.dart # SB race (host dashboard / player board)
│ │ ├── group_results_screen.dart # Podium + leaderboard + share + Play Again
│ │ └── widgets/ # leaderboard, podium, answer distribution,
│ │   # question card, SB race board, reconnecting banner, etc.
│ ├── scripture_list_screen.dart
│ ├── memorize_screen.dart
│ ├── practice_hub_screen.dart
│ └── upgrade_screen.dart
├── services/
│ ├── audio_service.dart
│ ├── speech_service.dart
│ ├── haptic_service.dart # All haptics, gated by user preference
│ ├── sidekick_service.dart # Grok API calls + snapshot logic
│ ├── group_play_service.dart # All Supabase calls + resilient realtime streams
│ ├── quiz_question_factory.dart # Shared question generation (solo + group)
│ ├── nickname_validator.dart # Group play nickname profanity filter
│ └── crash_reporting_service.dart # Sentry wrapper: init gate, breadcrumbs, tags
├── widgets/
│ ├── scripture_card.dart
│ ├── mastery_badge.dart
│ ├── progress_ring.dart
│ ├── premium_teaser.dart
│ └── scripture_scope_picker.dart # Shared scope picker (sheet + inline)
└── theme/
└── app_theme.dart

---

## Data Model

### Scripture (immutable)

Fields: `id` (String, '1'..'100'), `book` (ScriptureBook enum), `volume`, `reference`, `name` (topic), `keyPhrase`, `fullText`, `words` (pre-split, auto-computed), `wordCount` (auto-computed).
**New models for Premium**:

- `SidekickSnapshot`: Contains current mastery state, seminary curriculum week, goals, recent activity, etc.
- `SidekickResponse`: Structured JSON from Grok that triggers app actions (daily prompt, quick win, goal suggestion, etc.).

(Keep all existing models unchanged)

**Premium models** (implemented):

- `SidekickSnapshot`: JSON payload sent to Grok on app launch. Contains `MasteryStats` (per-level counts), `List<ScriptureProgressSummary>` (up to 8 needing attention), recent activity strings, curriculum week, goals, streak, days active. Built by `SidekickNotifier._buildSnapshot()` from existing providers.
- `SidekickResponse`: Structured JSON from Grok. All fields optional: `dailyPrompt`, `suggestedGoal` (SidekickGoal), `quickWin` (QuickWin with scriptureId + actionType), `timelineInsight`, `reminder`, `reflectionPrompts`, `encouragement`, `connections` (ScriptureConnection). Has `fromJson`/`toJson` and `offlineFallback()` factory.
- `SidekickMessage`: Chat message with `role` (user/assistant), `content`, `timestamp`. Has `toApiMessage()` for API calls.

### UserProgress (per scripture × game type)

Fields: `scriptureId`, `gameType`, `highestDifficultyCompleted`, `totalAttempts`, `correctAttempts`, `currentStreak`, `bestStreak`, `bestTime`, `lastPracticed`, `accuracy`, `masteryLevel`, `needsReview`, `consecutivePerfectMaster`.

Storage key format: `{scriptureId}_{gameType.name}`

### Enums

- **ScriptureBook**: 4 values with `displayName` and `abbreviation`
- **MasteryLevel**: newScripture → learning → familiar → memorized → mastered → eternal (with color, icon, minAccuracy)
- **GameType**: matching, scriptureBuilder, quiz (with displayName, description, icon) — note: "GameType" is a legacy name in code; conceptually scriptureBuilder=mastery tool, matching/quiz=practice quizzes
- **DifficultyLevel**: beginner → intermediate → advanced → master (with scriptureCount, hasTimer, allowRetry, extraDistractors)

### Mastery System

Mastery is driven entirely by Scripture Builder progression:

- **New** (gray): Haven't started Scripture Builder
- **Learning** (orange): Completed SB Beginner
- **Familiar** (yellow): Completed SB Intermediate
- **Memorized** (green): Completed SB Advanced
- **Mastered** (blue): 3 consecutive perfect SB Master completions
- **Eternal** (gold): Sustained Mastered for 6 months (permanent, never decays)

**Shortcut**: If you can nail Master difficulty without doing lower tiers, you've proven it. (Planned — TASK-031.)

**Gentle decay**: 14+ days → "Needs Review" flag. 30+ days → drops one tier. Floor at Familiar. Eternal never decays.

**Why only Scripture Builder?** It's the only tool that tests _production_ — can you produce the words from memory? Match/Quiz test recognition (different cognitive skill). You haven't "mastered" a scripture until you can type it cold.

---

## Mastery Tool: Scripture Builder

Scripture Builder is the PRIMARY mastery tool. It lives under each scripture (accessed from scripture detail), not in the quizzes/games hub. It's how you prove you know a scripture. The four difficulty tiers map directly to mastery levels:

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
AppTheme.gold             // Stars, achievements
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
| Scripture browsing | GoRouter `context.go('/scripture/$id')`                 | Detail screens            |
| Game screens       | `Navigator.of(context).push()`                          | Transient overlays        |
| Game results       | `Navigator.of(context).pushReplacement()`               | Replace game with results |
| Memorize tool      | `Navigator.of(context).push()`                          | From scripture detail     |
| Upgrade screen     | GoRouter `context.go('/upgrade')` or `Navigator.push()` | From teasers/prompts      |

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

---

## Agent Coordination

### Quick Start

```
1. Read this file (CLAUDE.md)      → Understand everything
2. Read TODO.md or MAINTENANCE.md  → Find an open task (TODO = features/launch, MAINTENANCE = hygiene/security/deps)
3. Claim the task                  → Write your agent ID into the relevant file, commit
4. Do the work                     → Follow the conventions above
5. Mark task done                  → Update the relevant file, commit
```

Same claim/complete ritual applies to both boards. Task IDs are namespaced: `TASK-XXX` lives in `TODO.md`, `MAINT-XXX` lives in `MAINTENANCE.md`.

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
│   └── scripture_builder_provider_test.dart
├── screens/
│   └── (widget tests — lower priority)
└── helpers/
    └── test_helpers.dart       # 5 shared test scriptures
```

### Test Priorities

1. **Models** (fast, no deps): word splitting, verse stripping, difficulty tiers, copyWith, equality, enum values
2. **Scripture mastery model** (core mastery logic): linear path levels, Scripture Builder-driven computation, gentle decay, Eternal tier, sub-progress, requirements generation
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

### Crash Reporting (Sentry)

Wired through `lib/services/crash_reporting_service.dart`, enabled only when a DSN is provided at build/run time (same `--dart-define` pattern as Supabase):

```bash
flutter run --dart-define=SENTRY_DSN=https://...@oXXXX.ingest.sentry.io/XXXX
# Optional: tag releases for crash grouping
flutter build ipa --dart-define=SENTRY_DSN=... --dart-define=APP_RELEASE=seminary_sidekick@1.0.0+1
```

Without `SENTRY_DSN` the service is a silent no-op (dev/CI/tests send nothing).

**Privacy rules** — never put user-generated content in breadcrumbs, tags, or contexts: no journal entries, scripture notes, chat messages, or nicknames. Scripture IDs and tab/route names are fine. `sendDefaultPii`, screenshots, and view hierarchy are disabled in the service; do not turn them on.

For handled exceptions worth field visibility, call `CrashReportingService.recordError(e, st, hint: '...')` in the catch block. Use `CrashReportingService.addBreadcrumb(...)` for notable user actions (categories: `navigation`, `game`, `purchase`, ...).

---

## Key Files Reference

| File                         | Purpose                                                                                            |
| ---------------------------- | -------------------------------------------------------------------------------------------------- |
| `CLAUDE.md`                  | This file — single agent entry point (mastery spec is inline here)                                 |
| `TODO.md`                    | Feature/launch task board (claim/complete `TASK-XXX` items here)                                   |
| `MAINTENANCE.md`             | Maintenance log — security hygiene, deps, infra audits, tech-debt (`MAINT-XXX` items)              |
| `app_theme.dart`             | Single source of truth for colors and spacing                                                      |
| `scriptures_data.dart`       | All 100 scripture entries                                                                          |
| `subscription_provider.dart` | Freemium state, RevenueCat integration, prompt rate-limiting                                       |
| `upgrade_screen.dart`        | Full-screen premium upgrade experience (plan selection, purchase)                                  |
| `premium_teaser.dart`        | Reusable upgrade prompt widgets (PremiumTeaser, PremiumInlineLink, PremiumGate)                    |
| `sidekick_service.dart`      | Sidekick client — builds prompts (incl. `_safetyGuardrails`), calls the `sidekick-proxy` Edge Function via `functions.invoke`, parses JSON. Holds NO API key. |
| `sidekick-proxy` (edge fn)   | `supabase/functions/sidekick-proxy/index.ts` — server-side xAI proxy; holds `XAI_API_KEY` secret, prepends authoritative safety prompt, forwards to Grok |
| `data_reset_service.dart`    | "Delete All My Data" — clears all Hive boxes + signs out anonymous Supabase session + reloads providers (account-deletion requirement) |
| `sidekick_provider.dart`     | AI orchestration: snapshot building, session refresh, chat, caching                                |
| `sidekick_snapshot.dart`     | JSON payload model sent to Grok (MasteryStats, ScriptureProgressSummary)                           |
| `sidekick_response.dart`     | Structured response model from Grok (SidekickGoal, QuickWin, ScriptureConnection, SidekickMessage) |
| `group_play_service.dart`    | All Supabase calls for Group Play + resilient realtime streams (auto-resubscribe w/ backoff)       |
| `group_play_provider.dart`   | Group Play orchestration: phases, stream subscriptions, host/player actions                        |
| `SUPABASE_SETUP.md`          | Supabase maintenance runbook: current state, migration reference, edge-fn redeploy/key rotation, cost monitoring, troubleshooting |
| `REVENUECAT_SETUP.md`        | RevenueCat runbook: store products, `premium` entitlement, offering, API keys, sandbox testing     |
| `APP_STORE_SUBMISSION.md`    | iOS submission pack: listing copy, App Privacy answers, age rating, review notes, screenshot guide, ordered pre-submit checklist |
| `crash_reporting_service.dart` | Sentry wrapper — init gate (`SENTRY_DSN`), breadcrumbs, premium tag, `recordError`               |

## Current Task Status

**Free-tier MVP** (completed 2026-04-06):

- All core tasks done.
- UX restructure complete: Scripture Builder is the hero on scripture detail.

**Freemium infrastructure** (completed 2026-04-06):

- TASK-033 done: SubscriptionProvider, UpgradeScreen, PremiumTeaser widgets, rate-limited prompts.

**Seminary Sidekick AI core** (completed 2026-04-06):

- TASK-034 done: SidekickService (Grok/xAI), SidekickProvider (orchestration + caching), snapshot/response models, chat support.

**Premium teaser & upgrade experience** (completed 2026-04-06):

- TASK-039 done: Premium teasers placed in home screen (after stats), scripture detail (inline link + mastery-level teaser), and onboarding (Sidekick mention on final page). All rate-limited and dismissible.

**Premium Tier — Seminary Sidekick AI** (completed 2026-04-07):

- TASK-035/036/037/038/040 all done — journal + prompts, goals + timeline + reminders, chat, polish, engagement layers.

**Deployment readiness polish** (completed 2026-04-11):

- TASK-041/042/043/044 done — settings screen, theme toggle wiring, font scale, haptics routed through a service.

**Post-MVP feature waves** (completed):

- TASK-046 Home reorientation ("Let's Learn / Let's Play") — done 2026-05-05.
- TASK-047 Shared scripture-scope picker + TASK-049 dead-state cleanup — done 2026-05-25.
- **Group Play (TASK-048 umbrella, decomposed into TASK-051–062)** — Quiz mode v1 shipped 2026-05-07 (Supabase backend, host/join lobbies, live quiz, results, profanity filter); premium hosting gates (TASK-058) and Scripture Builder Race mode (TASK-062) shipped 2026-05-25; group-play polish (TASK-064: stream reconnection, answer-distribution reveal, leaderboard/podium reveal animations) 2026-06-10.

**Active direction — launch readiness** (owner-reviewed 2026-06-10; see `TODO.md` / `MAINTENANCE.md` for full entries):

- **P0 TASK-045**: Replace generated `.wav` sound effects with real audio (owner-sourced). `.txt` placeholders exist in `assets/audio/` (incl. `countdown_tick`, `group_join`, `streak_milestone`).
- **P0 TASK-063**: Crash reporting & error analytics (Sentry) — done 2026-06-10. Owner setup: create a Sentry project, pass `--dart-define=SENTRY_DSN=...` in release builds.
- **P0 (untracked, from 2026-06-10 audit)**: ~~real RevenueCat purchase wiring + iOS store identity~~ **DONE 2026-06-13** — `purchasePlan`/`restorePurchases`/`_syncWithRevenueCat` make real `purchases_flutter` calls gated on the `premium` entitlement; `main.dart` configures the SDK from `REVENUECAT_IOS_KEY`/`REVENUECAT_ANDROID_KEY` dart-defines (free-tier no-op without them); live localized prices surface on the upgrade screen and the CTA is now **"Subscribe"** (no free trial planned — relabeled from "Start Free Trial"). **Pricing locked: $4.99/mo, $34.99/yr ("Save 42%").** **iOS fully wired end-to-end**: real Bundle ID `com.seminarysidekick.app` set across `ios/Runner.xcodeproj` (app + RunnerTests) and Android `applicationId`; App Store Connect app + subscription group "Seminary Sidekick Premium" (monthly $4.99 / yearly $34.99) created; RevenueCat project configured (`premium` entitlement, both products attached, `default` offering current with the App Store products in its Monthly/Annual packages); iOS public SDK key in gitignored `.env`. See `REVENUECAT_SETUP.md` and the 2026-06-13 entry in `TODO.md`. **Remaining owner steps**: Android (Play Console products + `REVENUECAT_ANDROID_KEY`); optional App Store Connect API key (products show "Could not check" until added/approved); submit a build to clear "Missing Metadata"; delete the leftover sample "Seminary Sidekick Pro" entitlement + Test Store products in RevenueCat; Android release signing.
- **P0 (untracked, 2026-06-13) — Sidekick safety, xAI key security, privacy/deletion**: **DONE in code.** (1) **Safety hardening** — `sidekick_service.dart` prompts now carry a shared `_safetyGuardrails` block (age-appropriate / minors, no-doctrinal-authority disclaimer → defer to teacher/parent/bishop, stay-on-topic refusals, crisis→trusted-adult redirect, no disparagement). (2) **xAI key off the client** — Sidekick now calls the `sidekick-proxy` **Supabase Edge Function** (`supabase/functions/sidekick-proxy/index.ts`) via `functions.invoke`; the function holds `XAI_API_KEY` server-side and prepends an authoritative copy of the safety prompt. The key is no longer a client `--dart-define`. (3) **In-app data deletion** — Settings → "Delete All My Data" (`DataResetService`) clears every Hive box + signs out the anonymous Supabase session + reloads providers (Apple account-deletion requirement). (4) **Privacy policy** — Settings links to `https://seminarysidekick.com/privacy` via `url_launcher`. **Edge function deployed 2026-06-13**: `XAI_API_KEY` secret set + `sidekick-proxy` deployed and live (`supabase functions list` → ACTIVE, v1; `supabase secrets list` shows the secret). The xAI key lives only as a Supabase secret — not in any shipped file. **Remaining owner steps**: ensure the privacy policy is actually live at that URL and add it to the App Store listing; run `flutter pub get` (new `url_launcher` dep) + `flutter analyze` + `flutter test`.
- **P1 TASK-051 owner steps**: all 6 migrations are deployed — `supabase migration list` shows local + remote in sync (0001–0006) as of 2026-06-13. Remaining: two-instance realtime smoke test; MAINT-002 RLS audit.
- **P1 TASK-059**: Saved class rosters (premium). **P2 TASK-061**: post-game class breakdown analytics.
- **P2 TASK-050**: Async friends & group layer — after group play launch settles.
- **P2 TASK-065**: Premium "Missionary Scriptures" pack — unlock a curated extra scripture set behind the existing premium subscription. Curated-only (no user-added scriptures, by owner decision). See `TODO.md` for the full entry.

---

## Available Skills

- `/grill-me` — Use this when you need deep, relentless questioning on game mechanics, mastery logic, UX flows, or architecture decisions.
- `/request-refactor-plan` — Before any major refactor (especially providers or game screens).
- `/sidekick-prompt` — Ask for help crafting or refining the Seminary Sidekick system prompt for Grok.
