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

## Deployment Readiness — Settings & Polish

### TASK-041: User Preferences & Settings Screen (Scaffolding)

- **status**: `done`
- **priority**: P0
- **estimated_effort**: Medium
- **claimed_by**: claude-opus-agent
- **started**: 2026-04-11T00:00:00Z
- **completed**: 2026-04-11T00:30:00Z
- **files_to_touch**: NEW `lib/providers/user_preferences_provider.dart`, NEW `lib/providers/study_streak_provider.dart`, NEW `lib/screens/settings/settings_screen.dart`, `lib/app.dart`, `lib/main.dart`, `lib/screens/home/home_screen.dart`, `lib/providers/progress_provider.dart`
- **description**: Settings screen scaffolding, user preferences provider, daily study streak, dynamic greeting, dynamic mastery description, tappable profile icon → settings.
- **acceptance_criteria**:
  - [x] UserPreferences provider (Hive-backed) with name, sound, haptics, font scale, notifications
  - [x] Study streak provider tracking consecutive days of activity
  - [x] Settings screen with Profile, Appearance, Sound & Feedback, Study Stats, Subscription, Data & Privacy, About sections
  - [x] Profile icon in header navigates to settings
  - [x] Hardcoded `'7🔥'` replaced with live streak badge from provider
  - [x] Hardcoded greeting replaced with time-based + user name (free) / AI prompt (premium)
  - [x] Hardcoded mastery description replaced with progress-aware text
  - [x] Study streak auto-records on any `recordAttempt()` call
- **depends_on**: —
- **notes**:
  - Settings UI is built but several toggles aren't wired through to the app yet (see TASK-042, TASK-043, TASK-044)
  - Sound toggle works (already wired to `AudioNotifier.setMuted()`)
  - Name field works (wired to `greetingNameProvider`)
  - Streak display works in both header and settings

### TASK-042: Wire Theme Toggle in Settings

- **status**: `done`
- **priority**: P0
- **estimated_effort**: Small
- **claimed_by**: claude-opus-agent
- **started**: 2026-04-11T01:00:00Z
- **completed**: 2026-04-11T01:05:00Z
- **files_to_touch**: `lib/app.dart`
- **description**: The theme dropdown in settings writes to `themeProvider` but `MaterialApp.router` ignores it — `themeMode` is hardcoded to `ThemeMode.system`. Wire it up.
- **acceptance_criteria**:
  - [x] `MaterialApp.router` reads `themeMode` from `ref.watch(themeProvider)` instead of `ThemeMode.system`
  - [x] Changing the theme dropdown in settings immediately switches light/dark/system
- **depends_on**: TASK-041
- **notes**:
  - Added `import 'providers/theme_provider.dart'` and `import 'providers/user_preferences_provider.dart'` to app.dart
  - Changed `themeMode: ThemeMode.system` → `themeMode: ref.watch(themeProvider)`

### TASK-043: Wire Text Size / Font Scale Setting

- **status**: `done`
- **priority**: P1
- **estimated_effort**: Small
- **claimed_by**: claude-opus-agent
- **started**: 2026-04-11T01:05:00Z
- **completed**: 2026-04-11T01:10:00Z
- **files_to_touch**: `lib/app.dart`
- **description**: The font scale dropdown in settings writes to `userPreferencesProvider.fontScale` but nothing applies it. Wrap the app in a `MediaQuery` override that scales text.
- **acceptance_criteria**:
  - [x] Changing text size in settings visibly changes text throughout the app
  - [x] Font scale persists across restarts
- **depends_on**: TASK-041
- **notes**:
  - Used `MaterialApp.builder` to inject a `MediaQuery` with `textScaler: TextScaler.linear(fontScale)`
  - Reads `fontScale` from `ref.watch(userPreferencesProvider).fontScale`

### TASK-044: Wire Haptic Feedback Toggle

- **status**: `done`
- **priority**: P1
- **estimated_effort**: Small-Medium
- **claimed_by**: claude-opus-agent
- **started**: 2026-04-11T01:10:00Z
- **completed**: 2026-04-11T01:30:00Z
- **files_to_touch**: NEW `lib/services/haptic_service.dart`, `word_builder_screen.dart`, `matching_game_screen.dart`, `quiz_game_screen.dart`, `game_results_screen.dart`, `memorize_screen.dart`, `chat_bubble.dart`, `journal_list_view.dart`, `journal_editor_view.dart`
- **description**: Created central HapticService that checks user preference before firing. Replaced all 29 direct HapticFeedback.* calls across 8 files.
- **acceptance_criteria**:
  - [x] `HapticService` checks `userPreferencesProvider.hapticsEnabled` before calling `HapticFeedback.*`
  - [x] All 29 direct `HapticFeedback.*` calls in 8 screen files replaced with the service
  - [x] Toggling haptics off in settings immediately stops vibration feedback
- **depends_on**: TASK-041
- **notes**:
  - `HapticService` is a simple immutable class with `light()`, `medium()`, `heavy()`, `selection()` methods
  - Exposed via `hapticProvider` (Riverpod `Provider<HapticService>`) that rebuilds when the pref changes
  - `memorize_screen.dart` converted from StatefulWidget → ConsumerStatefulWidget for ref access
  - `chat_bubble.dart` widgets converted from StatelessWidget → ConsumerWidget for ref access
  - Zero direct `HapticFeedback.*` calls remain in the screens directory

---

## Active — Post-MVP Direction (owner-reviewed 2026-04-21)

> **Bottom line from the owner**: the core is good. What's left is re-orienting the app
> toward "learn + play immediately" and shipping the social angle that makes kids
> want to use this with their seminary group. Three clear themes: fix the sounds,
> move the landing into action, and turn Quick Quiz into something you can play
> alone on the whole library OR together Kahoot-style.

### TASK-045: Replace agent-generated sound effects with real audio

- **status**: `open`
- **priority**: P0
- **estimated_effort**: Small (the agent work is just placeholders; user ships the real audio)
- **claimed_by**: —
- **files_to_touch**: `assets/audio/correct.wav`, `assets/audio/incorrect.wav`, `assets/audio/complete.wav`, `assets/audio/levelup.wav`, NEW `.txt` placeholders in `assets/audio/`, `CLAUDE.md` (already updated)
- **description**: The four `.wav` files under `assets/audio/` were generated by a prior agent (Python/TTS) and sound terrible. Owner will replace them manually. Mirrors the existing image-asset convention.
- **acceptance_criteria**:
  - [ ] Delete or rename the four existing `.wav` files so they don't ship
  - [ ] Create `correct.txt`, `incorrect.txt`, `complete.txt`, `levelup.txt` in `assets/audio/` following the new convention in `CLAUDE.md` (description, sourcing hints, duration/format, reference examples)
  - [ ] Verify `AudioNotifier.init()` fails gracefully when the real `.wav`s are missing (don't crash the app — log and no-op `play()`)
  - [ ] Owner drops in the real audio, deletes the `.txt`s, sanity-checks playback in Word Builder / Quick Quiz / Match
- **depends_on**: —
- **notes**:
  - See `lib/services/audio_service.dart` — `SoundEffect` enum paths stay the same; only the underlying files change
  - The new audio convention is documented in `CLAUDE.md` under "Conventions → Audio Assets"
  - Candidate additional sounds to scope while we're here: `streak_milestone`, `group_join`, `countdown_tick` (only if we proceed with Group Play — TASK-048)

### TASK-046: Reorient Home to "Let's Learn / Let's Play"

- **status**: `open`
- **priority**: P0
- **estimated_effort**: Medium
- **claimed_by**: —
- **files_to_touch**: `lib/screens/home/home_screen.dart`, potentially new `lib/screens/home/jump_in_card.dart`, `lib/screens/home/play_now_card.dart`
- **description**: The current Home is a dashboard — greeting, mastery ring, long progress description, then tiny "Practice Games" CTA buried below. Kids should land on a screen that says "do something now." Move the dashboard feel (ring, numbers, long text) to the Stats tab and keep Home action-first.
- **acceptance_criteria**:
  - [ ] First viewport of Home has at most a one-line greeting + two big action CTAs: **"Keep Learning"** (last-touched scripture or daily review) and **"Play a Quick Quiz"** (launches Quick Quiz on a sensible default set)
  - [ ] A third lightweight row for "Word Builder on [scripture]" or "Scripture Match" as secondary actions
  - [ ] Remove the 160px mastery ring + "Overall Mastery" paragraph from Home (keep it on Stats tab — already lives there)
  - [ ] Premium "Quick Win" card stays but demoted below the primary CTAs, not above them
  - [ ] Streak badge stays in the shell header
  - [ ] Nearly-mastered nudges, book collections, and the quick-session premium section can live further down the scroll OR move to Stats
  - [ ] Brand new users (no activity) see a welcoming "Start here →" that opens the first scripture or Library, not a giant zero-state ring
- **depends_on**: —
- **notes**:
  - Current Home is at `lib/screens/home/home_screen.dart` lines 44–220; most sections already exist as separate files under `lib/screens/home/` but are NOT used by the current orchestrator — there's stale extraction work to reconcile
  - Keep Stats tab (`/progress`) as the full dashboard — we're not deleting any of that, just relocating the entrance
  - Consider a `lastPracticedScriptureIdProvider` aggregated across all game types (today we have `lastWordBuilderScriptureIdProvider` but not for all tools)

### TASK-047: Multi-scripture quiz — pick a whole book (or all 100)

- **status**: `open`
- **priority**: P0
- **estimated_effort**: Medium
- **claimed_by**: —
- **files_to_touch**: `lib/screens/practice_hub_screen.dart`, `lib/providers/quiz_game_provider.dart`, `lib/providers/matching_game_provider.dart`, `lib/models/enums.dart` (maybe), possibly NEW `lib/screens/games/quiz_setup_sheet.dart`
- **description**: The provider layer already accepts `bookFilters: List<ScriptureBook>`, but the UI hard-codes `_selectedBooks = {}` and `_selectedDifficulty = beginner` in both `_QuizGameCard` and `_MatchingGameCardState` — so the user has no way to choose. Also, even with books selected, the question count is capped at `difficulty.quizQuestionCount` (10–40), so you can't actually quiz on every scripture in a book at once. Owner's vision: "I want to quiz on all the scriptures eventually."
- **acceptance_criteria**:
  - [ ] Practice Hub Quick Quiz card and Scripture Match card open a setup sheet (bottom sheet or dedicated screen) with:
    - Difficulty selector (Beginner / Intermediate / Master, same as Word Builder selector at the top of Practice Hub)
    - Scope selector: **All 100**, **One or more books** (multi-select chips), **Needs-review only**, **Nearly-mastered only**
    - Question count: default per difficulty, plus a **"Every scripture in scope"** option that overrides the cap
  - [ ] `QuizGameNotifier.startGame` accepts an optional `targetQuestionCount` param so the cap can be bypassed for "quiz everything"
  - [ ] Same treatment for `MatchingGameNotifier` — Master already signals "use all", extend this to explicit book scopes
  - [ ] Selected scope is remembered between sessions (Hive, per-game-type) so power users don't re-select every time
  - [ ] UX: the setup sheet is fast — two taps and you're in a quiz. Don't make it a wizard.
- **depends_on**: —
- **notes**:
  - The dead `_selectedBooks` / `_selectedDifficulty` fields in `practice_hub_screen.dart` (lines 675–676, 786–787) are the smoking gun that this was half-wired
  - `QuizGameNotifier._selectProportionally` already handles arbitrary book lists correctly, so most of the data layer is done
  - Consider exposing a `quizGameSetupProvider` (Hive-backed) to hold the last-used difficulty + scope
  - Think carefully about `matching_game_provider.dart` — `MatchPair` list gets long when scope is "all 100"; confirm the game screen handles 100-pair sessions or paginates

### TASK-048: Seminary Group Play (Kahoot-style multiplayer)

- **status**: `open`
- **priority**: P1 (this is the big social lever — but it's also the biggest scope)
- **estimated_effort**: XL
- **claimed_by**: —
- **files_to_touch**: NEW `lib/providers/group_play_provider.dart`, NEW `lib/services/group_play_service.dart`, NEW `lib/screens/group_play/` (host_lobby_screen, join_lobby_screen, group_quiz_screen, group_results_screen), `lib/screens/practice_hub_screen.dart`, `lib/screens/home/home_screen.dart`, `pubspec.yaml` (backend SDK), probably new backend/cloud function
- **description**: Owner called it Kahoot-style — one host (the seminary teacher or a student) starts a room, students join with a code, everyone answers the same questions simultaneously, live leaderboard at the end. Nothing meaningful has been built yet; this task is the scaffold.
- **acceptance_criteria**:
  - [ ] **Decision doc first** (before code): one-pager picking the backend. Candidates: Firebase Realtime DB + Firestore, Supabase (Realtime + Postgres), a thin custom WebSocket server. Criteria: cost at ~50 concurrent rooms of 30 kids, account requirements for kids (ideally none — just a name + code), offline fallback for spotty seminary wifi
  - [ ] **Lobby flow**: host taps "Start Group Play" → gets a 4-letter room code + QR → students tap "Join Group" → enter code + nickname → show list of joined students to the host → host taps "Start"
  - [ ] **Quiz flow**: re-uses the existing `QuizGameNotifier` question generation so we don't fork it — the host picks scope+difficulty (reuses TASK-047 setup sheet) → questions pushed to all clients → each student answers → scoring factors in correctness AND speed (Kahoot model)
  - [ ] **Leaderboard**: live after each question (top 5) + final podium after the quiz
  - [ ] **Teacher controls**: host can kick, skip, end early
  - [ ] **No accounts required** for students — just nickname + room code. Host might need a light-touch account eventually, but MVP can be anonymous.
  - [ ] **Free tier question**: decide whether group play is free (likely yes — this is the viral loop) or gated to Premium for hosts (possible — teachers/parents pay, kids join free)
  - [ ] **Analytics**: log session completion + answer distribution so teachers can see which scriptures the group struggled on (nice-to-have, could be TASK-050)
- **depends_on**: TASK-047 (question scope selection is shared)
- **notes**:
  - Current codebase has ZERO multiplayer infrastructure — `grep -i 'multiplayer|kahoot|lobby|firebase|websocket|supabase'` returns only unrelated matches in scripture text and `Icons.family_restroom`
  - Word Builder is NOT part of group play in V1 (it's a solo mastery tool) — group play is Quick Quiz + maybe Scripture Match
  - Think about abuse: nicknames need a light profanity filter so kids don't name themselves something dumb on the projector
  - Consider persistent "Seminary classes" later so teachers can run the same group week to week with saved rosters — out of scope for V1 but worth designing the data model with that future in mind

### TASK-049: Kill the dead difficulty/book state on Quick Quiz & Match cards

- **status**: `open`
- **priority**: P1 (small cleanup, will naturally fall out of TASK-047)
- **estimated_effort**: Small
- **files_to_touch**: `lib/screens/practice_hub_screen.dart`
- **description**: `_QuizGameCardState` and `_MatchingGameCardState` both declare `final DifficultyLevel _selectedDifficulty = DifficultyLevel.beginner;` and `final Set<ScriptureBook> _selectedBooks = {};` that never change and have no UI. Confusing for any future reader. Remove or replace with real state once TASK-047 lands.
- **acceptance_criteria**:
  - [ ] No orphaned unmutated state fields left in `practice_hub_screen.dart`
  - [ ] `flutter analyze` still clean
- **depends_on**: TASK-047 (do this as part of that work, not separately)

### TASK-050: "Friends & Groups" social layer (lightweight, async)

- **status**: `open` (parking lot — refine after TASK-048 ships)
- **priority**: P2
- **estimated_effort**: Large
- **description**: Once Kahoot-style live play is in, owner wants kids encouraged to engage with friends. Async layer: add a friend, compare mastery rings, send a scripture challenge ("beat my time on 1 Nephi 3:7"), weekly seminary-class leaderboards.
- **acceptance_criteria** (rough):
  - [ ] Lightweight friending by nickname/code (same anonymous-friendly auth as TASK-048)
  - [ ] Async challenge: send a scripture + difficulty to a friend, they try it, you see their score
  - [ ] Weekly leaderboard scoped to a "seminary group" (reuses the rooms from TASK-048 but persistent)
- **depends_on**: TASK-048

---

## Backlog — Future (not prioritized)

| Task | What | Effort |
|------|------|--------|
| TASK-014 | Legacy social features placeholder (superseded by TASK-048/050) | — |
| TASK-015 | Localization (i18n) | Large |