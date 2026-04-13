# Seminary Sidekick — Task Board

> **How this file works**: Single source of truth for what needs to be done.
> Agents claim tasks by setting `status: in_progress` and `claimed_by`. Mark `done` when complete.
> Always read fresh before starting. Commit claim before writing code.
>
> Full details on completed tasks are in git history.

---

## Completed — Free-Tier MVP (2026-03-19 → 2026-04-06)

| Task | What | Completed |
|------|------|-----------|
| TASK-001 | Hive persistence for progress | 2026-03-19 |
| TASK-002 | Quick Quiz game | 2026-03-19 |
| TASK-003 | Wire game results → progress provider | 2026-03-28 |
| TASK-004 | Per-scripture notes (Hive-backed) | 2026-03-23 |
| TASK-005 | Sound effects & audio feedback | 2026-03-30 |
| TASK-006 | Confetti celebrations | 2026-03-23 |
| TASK-007 | Practice from scripture detail (single-scripture sessions) | 2026-03-30 |
| TASK-008 | Speech-to-text for Master typing | 2026-03-30 |
| TASK-009 | Spaced repetition (SM-2) | 2026-04-06 |
| TASK-010 | Recent activity feed | 2026-04-06 |
| TASK-011 | Game-specific difficulty descriptions | 2026-03-28 |
| TASK-012 | Dark mode | 2026-03-30 |
| TASK-013 | Onboarding — mastery path tutorial | 2026-04-06 |
| TASK-020 | Test infrastructure (mockito, fake_async, helpers) | 2026-03-28 |
| TASK-021 | Model unit tests | 2026-03-30 |
| TASK-022 | Progress provider tests | 2026-03-30 |
| TASK-023 | Scripture provider tests | 2026-03-30 |
| TASK-024 | Matching game provider tests | 2026-03-30 |
| TASK-025 | Word builder provider tests | 2026-03-30 |
| TASK-026 | Holistic mastery system — data layer | 2026-04-02 |
| TASK-027 | Holistic mastery system — UI integration | 2026-04-02 |
| TASK-028 | Word Builder-centric mastery path (redesign v2) | 2026-04-02 |
| TASK-029 | Mastery system tests (40 tests) | 2026-04-02 |
| TASK-030 | Move Word Builder under scripture detail | 2026-04-02 |
| TASK-031 | Mastery shortcut — prove it at Master, skip the ladder | 2026-04-06 |
| TASK-032 | Rename Games Hub → Practice/Quizzes | 2026-04-06 |

---

## Backlog — Future (not prioritized)

| Task | What | Effort |
|------|------|--------|
| TASK-014 | Social features (legacy placeholder — see TASK-111/112) | XL |
| TASK-015 | Localization (i18n) | Large |


## Premium Tier — Paid Features (Freemium Model)

> **Vision**: The free tier delivers the complete Word Builder-centric mastery journey with engaging feedback loops.  
> The **Premium tier** unlocks the **Seminary Sidekick** — an AI companion powered by Grok that helps students move from memorization to true mastery (find, understand, and apply).  
> On app open, Premium users send a JSON snapshot of their progress to the Sidekick. The Sidekick responds with structured JSON that triggers personalized prompts, goals, timeline updates, and gentle reminders — making diligent effort feel natural and rewarding.

### TASK-033: Freemium Infrastructure & Subscription Basics

- **status**: `done`
- **priority**: P0
- **estimated_effort**: Medium
- **claimed_by**: claude-opus-agent
- **started**: 2026-04-06T00:00:00Z
- **completed**: 2026-04-06T00:30:00Z
- **files_to_touch**: NEW `lib/providers/subscription_provider.dart`, `lib/app.dart`, `lib/main.dart`, `lib/screens/upgrade_screen.dart`, `lib/widgets/premium_teaser.dart`, `lib/theme/app_theme.dart`, pubspec.yaml
- **description**: Clean freemium model. All existing mastery tools remain completely free. Premium unlocks the Seminary Sidekick features.
- **acceptance_criteria**:
  - [x] Subscription state managed via Riverpod with graceful free-tier fallbacks
  - [x] RevenueCat integration for monthly/yearly plans
  - [x] Tasteful upgrade prompts at natural moments
  - [x] Free tier remains generous and untouched
- **depends_on**: —
- **notes**:
  - `SubscriptionNotifier` follows the same pattern as `ThemeNotifier` / `OnboardingNotifier` (Hive-backed StateNotifier with `init()`)
  - RevenueCat `purchases_flutter: ^8.1.0` added to pubspec; integration points are marked with TODO comments for when API keys are configured
  - Upgrade prompts are rate-limited: max 1/day, backs off after 3 dismissals
  - Three widget options for upgrade prompts: `PremiumTeaser` (card), `PremiumInlineLink` (subtle text), `PremiumGate` (swap premium content vs teaser)
  - `/upgrade` route added to GoRouter for full-screen upgrade experience
  - Premium colors added to AppTheme (premiumGold, premiumGoldLight, gradient pair)
  - Free tier is completely untouched — all premium checks default to free gracefully

### TASK-034: Seminary Sidekick AI Core Service (Grok Integration)

- **status**: `done`
- **claimed_by**: claude-opus-agent
- **started**: 2026-04-06T01:00:00Z
- **completed**: 2026-04-06T02:00:00Z
- **priority**: P0
- **estimated_effort**: Large
- **files_to_touch**: NEW `lib/services/sidekick_service.dart`, NEW `lib/providers/sidekick_provider.dart`, NEW `lib/models/sidekick_snapshot.dart`, NEW `lib/models/sidekick_response.dart`, `lib/main.dart`
- **description**: Core service that connects to Grok (xAI API). On app open (for premium users), it sends a JSON snapshot of user data and receives structured JSON to trigger app behavior.
- **acceptance_criteria**:
  - [x] On premium app launch: automatically create and send JSON snapshot (mastery progress, current scriptures, goals, seminary curriculum week, recent activity)
  - [x] AI responds with structured JSON that the app can parse (daily prompt, suggested goal, timeline insight, reminder, quick-win suggestion, etc.)
  - [x] System prompt trains the Sidekick to act as a thoughtful seminary tutor (reverent, Socratic, focused on understand + apply + ACT principles)
  - [x] Chat interface can send direct messages to the same Sidekick
  - [x] Backend proxy recommended for API key safety and prompt control
  - [x] Graceful offline fallback with cached responses
- **depends_on**: TASK-033
- **notes**:
  - SidekickService uses dart:io HttpClient → xAI API (grok-3-mini). API key via --dart-define; production uses backend proxy.
  - SidekickNotifier builds snapshot from existing providers, sends to Grok, caches in Hive.
  - Chat: conversation history + snapshot context, last 20 messages.
  - Offline fallback: cached response + hardcoded SidekickResponse.offlineFallback().
  - Non-blocking init in main.dart.
  - Convenience providers: dailyPromptProvider, quickWinProvider, reflectionPromptsProvider, chatHistoryProvider, isChatLoadingProvider.

### TASK-035: AI-Powered Journal & Dynamic Reflection Prompts

- **status**: `done`
- **priority**: P1
- **estimated_effort**: Medium
- **claimed_by**: claude-opus-agent
- **started**: 2026-04-07T00:00:00Z
- **completed**: 2026-04-07T01:00:00Z
- **files_to_touch**: NEW `lib/screens/journal_screen.dart`, NEW `lib/providers/journal_provider.dart`, NEW `lib/models/journal_entry.dart`, `lib/app.dart`, `lib/main.dart`, `lib/screens/home_screen.dart`, `lib/screens/scripture_detail_screen.dart`
- **description**: Premium journal where the Sidekick generates prompts and can pre-seed entries.
- **acceptance_criteria**:
  - [x] Sidekick suggests 1–3 thoughtful reflection prompts based on the user's snapshot
  - [x] Prompts encourage personal application, teaching others, cause-and-effect, etc.
  - [x] Easy “Reflect Now” buttons throughout the app
  - [x] Rich-text entries with scripture tagging
- **depends_on**: TASK-034
- **notes**:
  - JournalEntry model: id, title, content, scriptureIds, scriptureReferences, prompt, createdAt, updatedAt, isFavorite. Factory `create()` for new entries, `fromJson`/`toJson` for Hive.
  - JournalNotifier: Hive-backed CRUD with `init()`, `createEntry()`, `editEntry()`, `saveEntry()`, `toggleFavorite()`, `deleteEntry()`, `closeEditor()`. Auto-generates titles from content or prompt.
  - JournalScreen: List view with AI reflection prompt cards + entry cards. Editor view with title/content fields, scripture tag picker (bottom sheet), and AI prompt display. Free users see premium teaser; premium users get full experience.
  - Reflection prompts: Consumed from `reflectionPromptsProvider` (sidekick_provider), displayed as gold-tinted cards with “Reflect Now” buttons.
  - “Reflect Now” entry points: Home screen card (first reflection prompt → opens journal editor), scripture detail inline link (“Reflect on this verse in your journal” → opens journal with scripture pre-tagged).
  - Journal tab added to bottom nav (4th tab, between Practice and Progress).
  - Convenience providers: journalEntriesProvider, activeJournalEntryProvider, journalEntriesByScriptureProvider, favoriteJournalEntriesProvider, journalEntryCountProvider, currentReflectionPromptsProvider.

### TASK-036: AI-Driven Goals, Timeline & Gentle Reminders

- **status**: `done`
- **priority**: P1
- **estimated_effort**: Medium
- **claimed_by**: claude-opus-agent
- **started**: 2026-04-07T00:00:00Z
- **completed**: 2026-04-07T00:30:00Z
- **files_to_touch**: NEW `lib/providers/goals_provider.dart`, extend `home_screen.dart`, `progress_screen.dart`, `sidekick_provider.dart`, `main.dart`
- **description**: Goals, mastery timeline, and reminders are generated or influenced by the Sidekick based on the user's snapshot.
- **acceptance_criteria**:
  - [x] Sidekick can suggest realistic goals and timeline projections
  - [x] Visual mastery timeline updated with AI insights
  - [x] Gentle, encouraging reminders triggered from Sidekick responses
- **depends_on**: TASK-034
- **notes**:
  - `GoalsNotifier` (Hive-backed StateNotifier) manages user goals with full CRUD: add, accept AI suggestion, complete, remove, dismiss reminder
  - `Goal` model supports both user-created and AI-suggested goals (via `Goal.fromSidekickGoal()`)
  - AI goal suggestions are rate-limited to 1/day and deduplicated against existing active goals
  - `masteryProjectionProvider` computes timeline: prefers AI `timelineInsight` from Sidekick response, falls back to local pace-based projection
  - Home screen (premium): Reminder banner (dismissable), Suggested Goal card (accept/dismiss), Active Goals list (tap circle to complete), Timeline Insight card
  - Progress screen (premium): Full Goals & Timeline section with mastery timeline projection, active goals with completion, and recent completed goals history
  - Goals are wired into `SidekickSnapshot.goals` so Grok sees the user's active goals and can suggest relevant next goals
  - GoalsNotifier initialized in `main.dart` before Sidekick init so goals are available for snapshot building
  - All widgets gracefully hidden for free-tier users (guarded by `isPremiumProvider`)

### TASK-037: “Ask Your Sidekick” Chat

- **status**: `done`
- **priority**: P1
- **estimated_effort**: Medium
- **claimed_by**: claude-opus-agent
- **started**: 2026-04-07T00:00:00Z
- **completed**: 2026-04-07T00:30:00Z
- **files_to_touch**: NEW `lib/screens/sidekick_chat_screen.dart`, `lib/app.dart`, `lib/screens/scripture_detail_screen.dart`
- **description**: Direct chat interface with the Seminary Sidekick.
- **acceptance_criteria**:
  - [x] Users can ask questions about any scripture or their progress
  - [x] Chat sends messages to the same Grok-powered Sidekick (same system prompt)
  - [x] Scripture references in responses are tappable
  - [x] Entry point from scripture detail (“Ask Your Sidekick about this verse”)
- **depends_on**: TASK-034
- **notes**:
  - Full chat screen with message bubbles (user right-aligned warm rust, sidekick left-aligned with gold avatar)
  - Scripture references in AI responses are detected via regex and rendered as tappable links (accent blue, underlined) that navigate to scripture detail via GoRouter
  - Empty state with suggestion chips (“Try asking...”) for onboarding
  - Typing indicator with animated dots while waiting for AI response
  - Error banner with dismissable error state
  - Clear conversation option in app bar overflow menu
  - Auto-sends initial context message when opened from scripture detail with `initialScriptureId`
  - Auto-scroll on new messages via `ref.listen`
  - Dark mode support throughout
  - Route: `/sidekick-chat?scriptureId=X` added to GoRouter
  - Premium users see functional “Ask your Sidekick about this verse” link on scripture detail; free users see PremiumInlineLink teaser (unchanged)

### TASK-038: Premium Polish & Optional Enhancements

- **status**: `done`
- **priority**: P2
- **estimated_effort**: Medium
- **claimed_by**: claude-opus-agent
- **started**: 2026-04-07T12:00:00Z
- **completed**: 2026-04-07T12:30:00Z
- **files_to_touch**: `lib/screens/journal_screen.dart`, `lib/services/journal_export_service.dart` (NEW), `pubspec.yaml`
- **description**: Additional small enhancements.
- **acceptance_criteria**:
  - [x] Voice-to-journal (extend existing speech service)
  - [x] Export journal entries
  - [x] Optional safe family sharing of selected entries
- **depends_on**: TASK-035
- **notes**:
  - **Voice-to-journal**: Mic FAB on journal editor uses existing `SpeechService`. Inserts dictated text at cursor position. Listening indicator bar with live partial text. Auto-stops after 30s timeout. Properly cleans up on dispose/back.
  - **Export**: `JournalExportService` singleton formats entries as readable plain text. Single entry share via system share sheet. Bulk export as `.txt` file via `share_plus` + `path_provider`. Export button in editor app bar + "Export all" in list view menu.
  - **Family sharing**: Safe sharing mode strips AI prompt metadata for privacy. Selection mode (long-press or menu) for multi-entry sharing. Personal note dialog before sharing. Family icon (family_restroom) in selection bar and per-entry context menu.
  - Per-entry context menu (three-dot) replaces bare delete icon — now has Export, Share with Family, and Delete options.
  - `share_plus: ^7.2.2` and `path_provider: ^2.1.2` added to pubspec.yaml.

### TASK-039: Premium Teaser & Upgrade Experience

- **status**: `done`
- **priority**: P1
- **estimated_effort**: Small
- **claimed_by**: claude-opus-agent
- **started**: 2026-04-06T01:00:00Z
- **completed**: 2026-04-06T01:30:00Z
- **files_to_touch**: `lib/screens/onboarding_screen.dart`, `lib/screens/home_screen.dart`, `lib/screens/scripture_detail_screen.dart`, `lib/widgets/premium_teaser.dart`
- **description**: Natural introduction to the Seminary Sidekick.
- **acceptance_criteria**:
  - [x] Subtle upgrade moments after mastery wins or when opening journal
  - [x] Clear value proposition focused on deeper understanding and application
  - [x] Teasers are limited and dismissible
- **depends_on**: TASK-033, TASK-013
- **notes**:
  - Home screen: PremiumTeaser card appears after stats when user has memorized/mastered scriptures (rate-limited via canShowUpgradePromptProvider)
  - Scripture detail: PremiumInlineLink ("Ask your Sidekick about this verse") below notes; PremiumTeaser card in mastery section when user reaches Memorized+ level
  - Onboarding: Subtle Seminary Sidekick AI mention on the final (Practice Quizzes) page — gold-bordered card with brief value prop
  - All teasers respect existing rate-limiting (max 1/day, backs off after 3 dismissals) and hide for premium users

### TASK-040: Subtle Engagement Enhancements

- **status**: `done`
- **priority**: P2
- **estimated_effort**: Small-Medium
- **claimed_by**: claude-opus-agent
- **started**: 2026-04-07T00:00:00Z
- **completed**: 2026-04-07T01:00:00Z
- **files_to_touch**: extend `home_screen.dart`, `scripture_detail_screen.dart`, `sidekick_provider.dart`
- **description**: Light layers on top of existing gamification that make spare-moment usage feel rewarding.
- **acceptance_criteria**:
  - [x] Sidekick suggests quick “next best win” sessions based on the snapshot
  - [x] Gentle nudges for nearly-mastered scriptures
  - [x] “Time-to-kill” style prompts on home screen
  - [x] Everything ties back to reflection and the journal
- **depends_on**: TASK-034, TASK-035
- **notes**:
  - `nextBestWinProvider`: Checks AI quick win first, falls back to locally computed nearly-mastered scriptures
  - `nearlyMasteredScripturesProvider`: Finds scriptures with subProgress >= 0.6, sorted closest-to-leveling-up first
  - `quickSessionPromptsProvider`: Up to 3 prompts combining AI quick win, nearly-mastered nudge, reflection prompt, and due reviews
  - Home screen: “Got a minute?” section (premium) with quick session tiles + “Almost there” section (all users) with progress rings
  - Scripture detail: Encouragement card + Scripture Connections card (premium)
  - All new widgets tap through to scripture detail, Word Builder, or journal — tying back to reflection

---

## Multiplayer — Live Head-to-Head (Local WebSocket)

> **Vision**: Students in the same classroom race each other on scripture mastery games in real-time.
> One device hosts a WebSocket server, others join via room code. No cloud, no accounts, no persistence.
> Sessions are ephemeral — play, see results, done. Room dies when the host closes it.
>
> **Tech**: Dart `dart:io` WebSocket server on host device. All players on same WiFi.
> No Firebase, no external dependencies. Zero cost forever.
>
> **Architecture**: All multiplayer code is NEW — existing single-player game logic, providers, and screens are NOT modified.
> Multiplayer game providers clone the game logic but swap side effects: broadcast progress to WebSocket instead of writing to Hive.
> No mastery progression, no spaced repetition, no Hive writes — just the raw game racing experience.
>
> **Parallelization**: TASK-100 is the foundation. TASK-101 and TASK-102 can run in parallel after it.
> TASK-103, TASK-104, TASK-105 can all run in parallel after TASK-101 + TASK-102 are done.
> TASK-106 is the integration pass after everything else.

### TASK-100: WebSocket Server & Multiplayer Service

- **status**: `open`
- **priority**: P0
- **estimated_effort**: Medium
- **files_to_touch**: NEW `lib/services/multiplayer_service.dart`
- **description**: Core networking layer. Host device runs a WebSocket server via `dart:io`. Clients connect via IP + port. The service handles room creation, player join/leave, message routing, and connection lifecycle. This is the foundation everything else builds on.
- **acceptance_criteria**:
  - [ ] `MultiplayerService` can start a WebSocket server on a configurable port (default 8080)
  - [ ] Host generates a 6-digit alphanumeric room code (no ambiguous chars: 0/O, 1/I/L excluded)
  - [ ] Clients connect via `ws://<hostIP>:<port>` with room code + nickname in handshake
  - [ ] Service exposes the host device's local IP address for display (QR code or manual entry)
  - [ ] Typed message protocol: JSON messages with `type` field (join, leave, ready, countdown, gameStart, progressUpdate, gameComplete, results, error)
  - [ ] Host tracks connected players (id, nickname, connected status)
  - [ ] Clean disconnect handling: player leaves → others notified, host leaves → all clients notified with "host disconnected" message
  - [ ] Service is a singleton or Riverpod-managed — not tied to widget lifecycle
  - [ ] Works on both iOS and Android (dart:io WebSocket is cross-platform)
- **depends_on**: —
- **notes**:
  - Player ID is a locally-generated UUID (no auth needed)
  - Message protocol example: `{"type": "progressUpdate", "playerId": "uuid", "progress": 0.45, "errors": 2}`
  - Host is also a player — the server and game client coexist on the same device
  - Use `NetworkInterface.list()` to find the device's WiFi IP (filter for IPv4, non-loopback, wlan/en0 interface)
  - Keep the protocol simple and flat — no nested state sync, just discrete events
  - Consider a `MultiplayerMessage` sealed class/enum for type-safe message handling in Dart

### TASK-101: Multiplayer Room Provider & Lobby UI

- **status**: `open`
- **priority**: P0
- **estimated_effort**: Medium
- **files_to_touch**: NEW `lib/providers/multiplayer_room_provider.dart`, NEW `lib/screens/multiplayer/multiplayer_hub_screen.dart`, NEW `lib/screens/multiplayer/create_room_screen.dart`, NEW `lib/screens/multiplayer/join_room_screen.dart`, NEW `lib/screens/multiplayer/lobby_screen.dart`
- **description**: State management for the multiplayer room lifecycle (create → lobby → countdown → active → results → done) and the UI screens for creating, joining, and waiting in the lobby. The host picks a game type, scripture(s), and difficulty, then shares the room code. Players join and see each other in the lobby. Host taps Start.
- **acceptance_criteria**:
  - [ ] `MultiplayerRoomNotifier` manages room state machine: `idle → creating → lobby → countdown → active → results → done`
  - [ ] `MultiplayerRoomState` tracks: room code, host/client role, player list, game config (game type, scripture IDs, difficulty), room status
  - [ ] **Create Room screen**: Host selects game type (Word Builder, Scripture Match, Quick Quiz), picks scriptures (by book or individual), picks difficulty → room created, code displayed large + device IP
  - [ ] **Join Room screen**: Enter host IP + room code (or scan QR — stretch goal), enter nickname → connect
  - [ ] **Lobby screen**: Shows all connected players with join animations, player count, game config summary. Host sees "Start Game" button (enabled when ≥2 players). All players see "Waiting for host to start..."
  - [ ] Countdown sequence: Host taps Start → 3-2-1-GO countdown synced to all players via WebSocket
  - [ ] Player leave/disconnect reflected in lobby in real-time
  - [ ] Back/exit from lobby disconnects cleanly
- **depends_on**: TASK-100
- **notes**:
  - Room state machine transitions are driven by WebSocket messages from the service layer
  - Scripture selection: reuse existing `scripturesProvider` / `scripturesByBookProvider` for the picker — just need a selection UI
  - Lobby is a `StreamBuilder` or `ref.listen` on the player list from `MultiplayerService`
  - Countdown uses server timestamps from host to sync (host sends `countdownStart` message with target start time)
  - QR code for join is a stretch goal — text entry of IP + code works for prototype
  - Follow existing screen patterns: `ConsumerStatefulWidget`, AppTheme colors, Inter/Merriweather fonts

### TASK-102: Shared Multiplayer Widgets (Opponent Progress & Race Results)

- **status**: `open`
- **priority**: P0
- **estimated_effort**: Small-Medium
- **files_to_touch**: NEW `lib/widgets/opponent_progress_bar.dart`, NEW `lib/screens/multiplayer/race_results_screen.dart`
- **description**: Reusable UI components shared across all three multiplayer game modes. The opponent progress overlay shows real-time progress bars for all players during a game. The race results screen shows final rankings after the game ends.
- **acceptance_criteria**:
  - [ ] `OpponentProgressBar` widget: shows a horizontal progress bar per opponent with nickname label, progress % (0.0→1.0), and "FINISHED" state. Animated smoothly. Compact enough to overlay at the top of any game screen without blocking gameplay.
  - [ ] `OpponentProgressOverlay` widget: stacks multiple `OpponentProgressBar`s vertically for all players in the room. Streams updates from `MultiplayerRoomProvider`.
  - [ ] `RaceResultsScreen`: shows final rankings sorted by finish time. Each row: rank (1st/2nd/3rd with medal icons), nickname, completion time, accuracy %, error count. Winner gets confetti + celebration animation. "Play Again" button (host only) and "Leave" button for all.
  - [ ] Opponent bars use distinct colors per player (cycle through a palette)
  - [ ] Graceful handling of disconnected players (grayed out bar, "DNF" in results)
- **depends_on**: TASK-100, TASK-101
- **notes**:
  - Progress data comes from the room provider which streams from WebSocket
  - OpponentProgressBar should be lightweight — it rebuilds frequently (every ~500ms per player)
  - Use `AnimatedContainer` or `TweenAnimationBuilder` for smooth bar movement
  - RaceResultsScreen follows the pattern of existing `GameResultsScreen` but with multiple players
  - Confetti for the winner uses existing `confetti` package
  - "Play Again" resets room to lobby state; host picks new scriptures or keeps the same config
  - Player colors: use a predefined list of 8-10 distinct colors, assigned by join order

### TASK-103: Multiplayer Word Builder

- **status**: `open`
- **priority**: P1
- **estimated_effort**: Medium
- **files_to_touch**: NEW `lib/providers/mp_word_builder_provider.dart`, NEW `lib/screens/multiplayer/mp_word_builder_screen.dart`
- **description**: Multiplayer version of Word Builder. All players race to complete the same scripture at the same difficulty. Game logic is cloned from the single-player Word Builder but does NOT write to Hive or update mastery. Instead, it broadcasts progress % and error count to the room via WebSocket. Opponent progress bars overlay the game screen.
- **acceptance_criteria**:
  - [ ] `MpWordBuilderNotifier` contains the same chunk-tap (Beginner/Intermediate) and typing (Advanced/Master) logic as `WordBuilderNotifier`
  - [ ] No Hive writes, no mastery updates, no spaced repetition — pure game logic only
  - [ ] Broadcasts progress update to WebSocket on every correct placement/keystroke (throttled to max 2 updates/sec)
  - [ ] `OpponentProgressOverlay` displayed at top of screen during gameplay
  - [ ] When any player finishes, a "FINISHED" indicator appears on their progress bar for all other players
  - [ ] When the local player finishes, show brief celebration then wait for results (or auto-navigate after timeout)
  - [ ] When all players finish (or timeout), navigate to `RaceResultsScreen`
  - [ ] Game timeout: configurable (default 5 min) — players who haven't finished get ranked by progress %
  - [ ] All existing Word Builder feedback (haptics, colors, animations) preserved
- **depends_on**: TASK-100, TASK-101, TASK-102
- **notes**:
  - Clone logic from `lib/providers/word_builder_provider.dart` — do NOT import or extend it. Keep multiplayer fully isolated.
  - Progress calculation: `correctPlacements / totalUnits` for chunk-tap, `correctChars / totalChars` for typing
  - Read existing `word_builder_provider.dart` and `word_builder_screen.dart` carefully before starting — the chunk-tap and typing modes have distinct mechanics
  - The screen should look identical to single-player WB, just with the opponent overlay at top
  - Multi-scripture sessions: if host picked multiple scriptures, advance to next scripture when current one completes (progress resets per scripture, overall progress = scriptures completed / total)

### TASK-104: Multiplayer Scripture Match

- **status**: `open`
- **priority**: P1
- **estimated_effort**: Medium
- **files_to_touch**: NEW `lib/providers/mp_matching_provider.dart`, NEW `lib/screens/multiplayer/mp_matching_screen.dart`
- **description**: Multiplayer version of Scripture Match. All players see the same set of key phrases and references (same randomized order, seeded by host). Race to match them all correctly. Broadcasts progress to WebSocket.
- **acceptance_criteria**:
  - [ ] `MpMatchingNotifier` contains the same matching logic as `MatchingGameNotifier`
  - [ ] No Hive writes, no mastery updates — pure game logic only
  - [ ] Host generates and distributes the randomized pair order (seeded shuffle via room code) so all players see the same layout
  - [ ] Broadcasts progress update on every correct match (progress = correctMatches / totalPairs)
  - [ ] `OpponentProgressOverlay` displayed at top of screen during gameplay
  - [ ] Haptics, animations, and visual feedback preserved from single-player
  - [ ] Navigate to `RaceResultsScreen` when all players finish or timeout
- **depends_on**: TASK-100, TASK-101, TASK-102
- **notes**:
  - Clone logic from `lib/providers/matching_game_provider.dart` — keep multiplayer isolated
  - Seeded shuffle: use room code as seed for `Random(roomCode.hashCode)` so all players get same pair order without transmitting the full state
  - Read existing `matching_game_provider.dart` and `matching_game_screen.dart` before starting

### TASK-105: Multiplayer Quick Quiz

- **status**: `open`
- **priority**: P1
- **estimated_effort**: Medium
- **files_to_touch**: NEW `lib/providers/mp_quiz_provider.dart`, NEW `lib/screens/multiplayer/mp_quiz_screen.dart`
- **description**: Multiplayer version of Quick Quiz. All players answer the same questions in the same order (seeded by host). Race to complete all questions. Broadcasts progress to WebSocket.
- **acceptance_criteria**:
  - [ ] `MpQuizNotifier` contains the same quiz logic as `QuizGameNotifier`
  - [ ] No Hive writes, no mastery updates — pure game logic only
  - [ ] Host generates and distributes question order + answer options (seeded shuffle) so all players see the same questions
  - [ ] Broadcasts progress update on each answered question (progress = questionsAnswered / totalQuestions)
  - [ ] `OpponentProgressOverlay` displayed at top of screen during gameplay
  - [ ] Haptics, animations, and visual feedback preserved from single-player
  - [ ] Navigate to `RaceResultsScreen` when all players finish or timeout
- **depends_on**: TASK-100, TASK-101, TASK-102
- **notes**:
  - Clone logic from `lib/providers/quiz_game_provider.dart` — keep multiplayer isolated
  - Same seeded shuffle approach as TASK-104
  - Read existing `quiz_game_provider.dart` and `quiz_game_screen.dart` before starting

### TASK-106: Multiplayer Navigation & App Integration

- **status**: `open`
- **priority**: P1
- **estimated_effort**: Small
- **files_to_touch**: `lib/app.dart`, `lib/screens/practice_hub_screen.dart`
- **description**: Wire multiplayer into the existing app. Add a "Multiplayer" entry point on the Practice Hub screen and add GoRouter routes for all multiplayer screens. This is the only task that touches existing files.
- **acceptance_criteria**:
  - [ ] "Multiplayer" button/card on Practice Hub screen — prominent, distinct from single-player quizzes
  - [ ] GoRouter routes added: `/multiplayer` (hub), `/multiplayer/create`, `/multiplayer/join`, `/multiplayer/lobby`
  - [ ] Multiplayer game screens and results use `Navigator.push()` (transient, same as existing game screens)
  - [ ] Back navigation from multiplayer hub returns to Practice Hub
  - [ ] Multiplayer entry point works for both free and premium users (multiplayer is a free feature)
- **depends_on**: TASK-100, TASK-101, TASK-102, TASK-103, TASK-104, TASK-105
- **notes**:
  - Keep the Practice Hub changes minimal — just add one card/button for multiplayer
  - Follow existing navigation patterns from CLAUDE.md: GoRouter for tab/section nav, Navigator.push for transient game screens
  - Multiplayer is free-tier — no premium gate

---

## Backlog — Future (not prioritized)

| Task | What | Effort |
|------|------|--------|
| TASK-014 | Social features (if desired later) | XL |
| TASK-015 | Localization (i18n) | Large |