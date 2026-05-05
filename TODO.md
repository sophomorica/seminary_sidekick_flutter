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

- **status**: `in_progress`
- **priority**: P0
- **estimated_effort**: Medium
- **claimed_by**: claude-sonnet-cowork
- **started**: 2026-05-05T12:00:00Z
- **files_to_touch**: `lib/screens/home/home_screen.dart`, NEW `lib/providers/resume_target_provider.dart`, `lib/screens/progress/progress_screen.dart`
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

### TASK-048: Seminary Group Play (Kahoot-style multiplayer) — UMBRELLA, decomposed

- **status**: `decomposed` — DO NOT CLAIM. See TASK-051 through TASK-061.
- **priority**: P1
- **decisions_made** (owner-reviewed 2026-05-05):
  - **Backend: Supabase** (Realtime + Postgres + Anonymous Auth). Owner already runs Supabase for another project so the platform skill is in-house. A new dedicated Supabase project will be created for this app to isolate quotas/billing.
  - **Architecture: cloud-relay**, host as a *logical* role (not a websocket server on the host's device). All participants are clients of Supabase; the host is just the player whose actions advance the quiz.
  - **No accounts for students.** Anonymous auth + nickname + 4-letter code.
  - **Free vs. Premium split**:
    - JOINING is always free. No exceptions, no caps, no signup.
    - HOSTING tiered: free hosts can run a *Casual* room (cap 6 players, 1 game/week). Premium hosts get *Class* rooms (cap 30, unlimited games, saved rosters, post-game analytics).
    - Premium price unchanged ($2.99/mo or $1.67/mo yearly). Group hosting becomes one more reason to subscribe alongside the existing Sidekick AI bundle.
  - **V1 scope limited to Quick Quiz only.** Scripture Match in group form is a v2 question — drag-and-drop multiplayer is awkward. Word Builder stays solo forever.
  - **Cost ceiling at the worst credible adoption** (~100K MAU, ~10K concurrent peak): roughly $2K–5K/mo on Supabase Realtime. Premium revenue at that scale ($15K–25K/mo at 5% conversion) covers it comfortably. We do NOT need to architect against this scale on day one — Pro tier ($25/mo, 500 concurrent) is fine for a long time.
  - **Future cost optimization** (NOT v1): WebRTC peer-to-peer with Supabase as signaling, or migrating the Realtime layer to Cloudflare Durable Objects. Both are v2 levers, mentioned here so the data model doesn't paint itself into a corner.

---

## Active — Group Play Build (decomposed from TASK-048, owner-decided 2026-05-05)

> **Scope guardrail**: NONE of the existing solo features are being modified. Word Builder, solo Quick Quiz, solo Scripture Match, mastery tracking, journal, Sidekick AI all remain exactly as they are. The only edits to existing files are:
>
> - `pubspec.yaml` (add `supabase_flutter`, `qr_flutter`)
> - `lib/main.dart` (initialize Supabase + anonymous sign-in)
> - `lib/app.dart` (add `/group-play/*` routes)
> - `lib/screens/practice_hub_screen.dart` (one new entry-point card)
> - `lib/screens/home/home_screen.dart` (one new "Play with friends" CTA)
>
> Everything else is NEW files under `lib/screens/group_play/`, `lib/services/group_play_service.dart`, `lib/providers/group_play_provider.dart`, and `lib/models/group_*.dart`.

> **Parallelism plan** (so multiple agents can move concurrently):
>
> | Phase | Tasks | Parallel? | Why |
> |---|---|---|---|
> | 1 | TASK-051 (Supabase setup) | No — owner-driven | Schema + dashboard config block everything else |
> | 2 | TASK-052 (foundation: models + service + provider + route stubs) | No — single agent | Defines interfaces every UI task depends on |
> | 3 | TASK-053, TASK-054, TASK-055, TASK-056, TASK-060 | **YES — up to 5 agents** | Each owns its own files; route stubs from TASK-052 prevent conflicts in `app.dart` |
> | 4 | TASK-057, TASK-058, TASK-059, TASK-061 | Mostly parallel | TASK-057 touches shared files (practice hub + home), the others are independent |
>
> **Shared-file caution.** TASK-057 is the only task in Phase 3+ that edits shared files (`practice_hub_screen.dart` and `home_screen.dart`). Schedule it serially or coordinate via commits. Everything else owns isolated files.

### TASK-051: Supabase project, schema, RLS, anonymous auth

- **status**: `partial` — migration files are written and committed; owner needs to run dashboard steps (see SUPABASE_SETUP.md)
- **priority**: P0
- **estimated_effort**: Small (mostly owner clicking through dashboard)
- **claimed_by**: —
- **files_to_touch**: `supabase/migrations/0001_group_play_init.sql` (DONE), `supabase/migrations/0002_rls_policies.sql` (DONE), `supabase/migrations/0003_realtime.sql` (DONE), NEW `SUPABASE_SETUP.md` (DONE), `.gitignore` (verify `.env` is ignored)
- **description**: Stand up a new Supabase project dedicated to Seminary Sidekick. Run migrations, enable anonymous auth, verify realtime. Detailed runbook in `SUPABASE_SETUP.md`.
- **acceptance_criteria**:
  - [x] Migration files for tables, RLS, realtime committed to `supabase/migrations/`
  - [x] `SUPABASE_SETUP.md` written with end-to-end instructions
  - [ ] **Owner step**: New Supabase project created in dashboard, separate from any existing project
  - [ ] **Owner step**: `supabase link --project-ref <ref>` + `supabase db push` runs cleanly
  - [ ] **Owner step**: Anonymous auth toggled on
  - [ ] **Owner step**: Realtime publication includes `rooms`, `players`, `answers`
  - [ ] **Owner step**: Project URL + anon key stashed; `--dart-define=SUPABASE_URL=... SUPABASE_ANON_KEY=...` added to local run command
  - [ ] **Verifying agent step (after TASK-052 lands)**: smoke test in SUPABASE_SETUP.md passes — anonymous user can create a room and a second device can see it via realtime
- **depends_on**: —
- **notes**:
  - Service-role key stays out of the Flutter app forever. anon key is safe to ship.
  - Owner already runs Supabase elsewhere — a separate project keeps quotas isolated.
  - Default free-tier limits (200 concurrent connections, 5GB DB) are way more than this app needs in dev or even early adoption.

### TASK-052: Group play foundation (models, service, provider, route stubs)

- **status**: `open`
- **priority**: P0
- **estimated_effort**: Large
- **claimed_by**: —
- **files_to_touch**: NEW `lib/models/group_room.dart`, NEW `lib/models/group_player.dart`, NEW `lib/models/group_question.dart`, NEW `lib/models/group_answer.dart`, NEW `lib/models/group_play_state.dart`, NEW `lib/services/group_play_service.dart`, NEW `lib/providers/group_play_provider.dart`, NEW `lib/screens/group_play/_placeholder_screens.dart`, `lib/main.dart` (Supabase init + anonymous sign-in), `lib/app.dart` (add `/group-play/*` routes wired to placeholder screens), `pubspec.yaml` (`supabase_flutter ^2.x`, `qr_flutter ^4.x`)
- **description**: Establish the data layer and orchestration layer for group play. Add placeholder screens for each route so UI tasks (TASK-053..TASK-056) can build in parallel without conflicting on `app.dart`.
- **acceptance_criteria**:
  - [ ] `GroupRoom`, `GroupPlayer`, `GroupQuestion`, `GroupAnswer` models with `copyWith`, `fromJson`/`toJson`, equality
  - [ ] `GroupPlayState` provider state with subStates: `idle`, `hosting`, `joining`, `inLobby`, `inQuiz`, `viewingResults`, `error`
  - [ ] `GroupPlayService` covers: `createRoom(scope, isPremium)`, `joinRoom(code, nickname)`, `leaveRoom()`, `startRoom()`, `advanceQuestion()`, `submitAnswer(...)`, `endRoom()`, `kickPlayer(playerId)`, `watchRoom(roomId)`, `watchPlayers(roomId)`, `watchAnswers(roomId)`, `broadcastEvent(roomCode, eventType, payload)`, `listenForEvents(roomCode)`
  - [ ] `GroupPlayNotifier` exposes the same surface, transforms service streams into state updates
  - [ ] 4-letter room code generator uses an unambiguous alphabet (excludes I, O, 0, 1) and runs through a profanity wordlist before returning (use the same wordlist TASK-060 will own — soft-import the validator with a fallback)
  - [ ] Speed-weighted scoring formula: `points = round(maxPoints * (1 - 0.5 * elapsedSec / questionTimeoutSec))`, clamped to `[maxPoints/2, maxPoints]` for correct answers, `0` for wrong/timeout. `maxPoints` defaults to 1000.
  - [ ] Question generation reuses the existing solo Quick Quiz logic — extract `QuizGameNotifier`'s scripture-pool selection + question construction into a shared helper (`lib/services/quiz_question_factory.dart`) and have BOTH the solo provider and the group service consume it. **Do not fork or duplicate the question logic.**
  - [ ] Routes added: `/group-play/host`, `/group-play/join`, `/group-play/lobby/:code`, `/group-play/quiz/:code`, `/group-play/results/:code` — each pointing at a placeholder Scaffold that displays the screen name + a "TODO: TASK-NNN" hint
  - [ ] `main.dart`: after Hive init and before `runApp`, call `Supabase.initialize(url: ..., anonKey: ...)` from `--dart-define`, then `await supabase.auth.signInAnonymously()` if there's no session
  - [ ] Smoke test (manual): launch app with `--dart-define`s, verify console logs an anonymous user id, navigate to `/group-play/host`, see placeholder screen
  - [ ] Add a brief `lib/services/group_play_service.dart` doc comment listing every Supabase channel name and table the service touches (so future readers can audit at a glance)
- **depends_on**: TASK-051 (the migrations must be deployed before service smoke-tests work, but the Dart code can be written in parallel)
- **notes**:
  - Models go in `lib/models/group_*.dart` with one model per file (matches existing code style)
  - Use `supabase_flutter`'s `RealtimeChannel` for both Postgres Changes (durable) and Broadcast (ephemeral)
  - Question pushes during a live quiz should go via Broadcast on `room:{code}`, not Postgres Changes — Broadcast is faster and meant for ephemeral signals
  - Provider must dispose channels on `leaveRoom()` / `endRoom()` to avoid connection leaks

### TASK-053: Host lobby screen

- **status**: `open`
- **priority**: P0
- **estimated_effort**: Medium
- **claimed_by**: —
- **files_to_touch**: NEW `lib/screens/group_play/host_lobby_screen.dart`, NEW `lib/screens/group_play/widgets/room_code_display.dart`, NEW `lib/screens/group_play/widgets/joined_players_list.dart`, NEW `lib/screens/group_play/widgets/group_play_scope_picker.dart` (minimal v1 picker — full version comes from TASK-047)
- **description**: Two views in one screen. **Setup view**: pick scope + difficulty + start the room. **Lobby view**: huge 4-letter code, QR, live list of joined players, kick button per player, "Start Game" button.
- **acceptance_criteria**:
  - [ ] Setup view: difficulty selector (Beginner / Intermediate / Master), scope selector (single book picker for v1; "All 100" option), question count override
  - [ ] On "Create Room", call `groupPlayProvider.notifier.hostCreateRoom(...)` and switch to lobby view
  - [ ] Lobby view: code displayed at ~96sp, projector-friendly contrast; QR code below using `qr_flutter`
  - [ ] Player list updates in real-time as joins arrive; each row has a kick (X) button for the host
  - [ ] Player cap indicator: free hosts see "Players: N/6", premium hosts see "Players: N/30"
  - [ ] Start button disabled until ≥1 non-host player has joined
  - [ ] Tapping Start calls `hostStartGame()` and navigates to `/group-play/quiz/:code`
  - [ ] Back nav prompts confirmation dialog ("End this room?") and on confirm calls `endRoom()`
  - [ ] If free host hits the player cap, show inline upgrade teaser (uses `PremiumInlineLink`)
- **depends_on**: TASK-052
- **notes**:
  - Keep the v1 scope picker minimal — TASK-047 will replace it with the full multi-select version
  - QR code encodes a deep link `seminary-sidekick://group-play/join?code=ABCD` (deep linking config can come later if needed; for now the QR can encode just the code as text and we'll iterate)
  - The widget-level files (`room_code_display.dart`, etc.) keep this screen small and reusable

### TASK-054: Join lobby screen

- **status**: `open`
- **priority**: P0
- **estimated_effort**: Small
- **claimed_by**: —
- **files_to_touch**: NEW `lib/screens/group_play/join_lobby_screen.dart`
- **description**: Player enters a 4-letter code + nickname, joins the room, sees the lobby, waits for host to start.
- **acceptance_criteria**:
  - [ ] Code field: monospace, auto-uppercase, 4-char limit; visually friendly (big tap target)
  - [ ] Nickname field: 2–14 chars, validated via `NicknameValidator` if available (soft import — gracefully accepts anything if TASK-060 hasn't landed)
  - [ ] "Join" button calls `groupPlayProvider.notifier.joinAsPlayer(code, nickname)`
  - [ ] Error states render inline: room not found, room is full, nickname taken, room already started, network error
  - [ ] On success, render "Waiting for host to start" view with the live list of joined players (so kids can watch friends arrive)
  - [ ] When room transitions to `active`, navigate to `/group-play/quiz/:code`
- **depends_on**: TASK-052
- **notes**:
  - When TASK-060 ships, the soft import becomes a hard one and inline error messages get specific per-failure-mode text

### TASK-055: Live group quiz screen

- **status**: `open`
- **priority**: P0
- **estimated_effort**: Large
- **claimed_by**: —
- **files_to_touch**: NEW `lib/screens/group_play/group_quiz_screen.dart`, NEW `lib/screens/group_play/widgets/group_question_card.dart`, NEW `lib/screens/group_play/widgets/live_leaderboard.dart`, NEW `lib/screens/group_play/widgets/answers_received_indicator.dart`
- **description**: The actual gameplay. Host pushes questions one at a time; players answer; between questions, top-5 leaderboard with deltas; after the last question, navigate to the results screen.
- **acceptance_criteria**:
  - [ ] **Host view**: current question, 20-second countdown, live "X of N answered" counter, "Next Question" button (skip if needed)
  - [ ] **Player view**: current question, four answer buttons; locks after answer or timeout; shows "+850 pts ✓" feedback after submission
  - [ ] **Between-question screen**: top-5 leaderboard with rank deltas (e.g. "▲2"); auto-advances after 5s on host's command (host taps "Next" or it auto-advances on a timer)
  - [ ] After last question, host calls `endRoom()` and everyone navigates to `/group-play/results/:code`
  - [ ] Disconnect handling: if host disconnects >30s, all clients show "Host left" and gracefully end (room state set to `ended`)
  - [ ] Disconnect handling: if a player disconnects, mark them stale; allow rejoin within room lifetime
  - [ ] Score updates persist to `answers` table per submission so the results screen has authoritative data
- **depends_on**: TASK-052
- **notes**:
  - Question pushes via Broadcast on `room:{code}` — durable state (current_question_index) updates via Postgres on the same `rooms` row
  - Reuse the visual language from solo Quick Quiz (`lib/screens/games/quiz_game_screen.dart`) — same answer button shapes, same correct/incorrect colors — so this feels familiar
  - Use `confetti` (already in pubspec) for "you got it" flair on correct answers, but keep it tame so 30 simultaneous celebrations don't tank performance

### TASK-056: Group results screen

- **status**: `open`
- **priority**: P1
- **estimated_effort**: Small-Medium
- **claimed_by**: —
- **files_to_touch**: NEW `lib/screens/group_play/group_results_screen.dart`, NEW `lib/screens/group_play/widgets/podium_view.dart`
- **description**: Final podium for top 3, full leaderboard, share, and host actions (Play Again / End).
- **acceptance_criteria**:
  - [ ] Podium for top 3 with confetti
  - [ ] Full leaderboard: rank, nickname, score, accuracy %, average response time
  - [ ] Host: "Play Again" creates a new room with the same scope; "End" returns home
  - [ ] Players: "Done" returns home
  - [ ] Share button: composes a text-only message ("Our class scored 78% on Mosiah scriptures!") and uses `share_plus` (already in pubspec)
  - [ ] Sharing is FREE — no premium gate (it's a viral hook)
- **depends_on**: TASK-052
- **notes**:
  - The "Class breakdown" tab (per-question accuracy) is a separate task (TASK-061) and gates behind premium

### TASK-057: Practice Hub & Home entry points

- **status**: `open`
- **priority**: P0
- **estimated_effort**: Small-Medium
- **claimed_by**: —
- **files_to_touch**: `lib/screens/practice_hub_screen.dart`, `lib/screens/home/home_screen.dart` (and possibly `lib/screens/home/play_now_card.dart` if we extract)
- **description**: Surface group play in the app shell. **Practice Hub**: new "Group Play" card with Host / Join buttons. **Home**: a "Play with friends" CTA tile.
- **acceptance_criteria**:
  - [ ] Practice Hub: new card at the top (above existing Quick Quiz / Scripture Match cards) with two buttons — "Host a Game" → `/group-play/host`, "Join a Game" → `/group-play/join`
  - [ ] Free hosts see subtitle: "Up to 6 players free • Premium for class size"
  - [ ] Premium hosts see subtitle: "Up to 30 players • Save your class roster"
  - [ ] Home: new tile/CTA placed below the primary actions (or wherever TASK-046 lands the layout)
  - [ ] Both entry points navigate via GoRouter
- **depends_on**: TASK-053, TASK-054
- **notes**:
  - **This task touches shared files** (practice_hub_screen.dart, home_screen.dart). Schedule serially with TASK-046 (Home reorientation) — coordinate by commit timing or merge order
  - Don't add an "Ask a friend to play" toast yet — comes later with TASK-050

### TASK-058: Premium gating for group hosting

- **status**: `open`
- **priority**: P1
- **estimated_effort**: Small-Medium
- **claimed_by**: —
- **files_to_touch**: `lib/services/group_play_service.dart`, `lib/providers/group_play_provider.dart`, `lib/screens/group_play/host_lobby_screen.dart`
- **description**: Enforce the free/premium hosting split. Free hosts: cap 6, 1 game/week. Premium hosts: cap 30, unlimited games.
- **acceptance_criteria**:
  - [ ] On `createRoom`, the service reads `isPremiumProvider` and writes `player_cap` (6 or 30) + `is_premium_host` to the row
  - [ ] On `createRoom`, the service calls `bump_host_usage(host_id)` (RPC). For free hosts, if `rooms_this_week > 1`, the service throws a `FreeTierLimitException` with an upgrade CTA
  - [ ] On `joinAsPlayer`, the service rejects join if `players` count for the room ≥ `player_cap` (returns `RoomFullException`)
  - [ ] Host lobby renders "Upgrade for class size" inline link (rate-limited via `canShowUpgradePromptProvider`) when free host approaches cap
  - [ ] Joining is NEVER gated — any user, free or premium, can join any room they have a code for
- **depends_on**: TASK-053
- **notes**:
  - Server-side enforcement (the RPC) is the source of truth; client-side checks are UX nice-to-haves
  - If a host upgrades mid-room, the cap doesn't auto-raise on the active room — they'd have to start a new one. Document this behavior in code comments.

### TASK-059: Saved class rosters (premium feature)

- **status**: `open`
- **priority**: P1
- **estimated_effort**: Medium
- **claimed_by**: —
- **files_to_touch**: NEW `lib/screens/group_play/saved_rosters_screen.dart`, NEW `lib/providers/saved_rosters_provider.dart`, `lib/services/group_play_service.dart`, `lib/screens/group_play/host_lobby_screen.dart`, `lib/screens/group_play/group_results_screen.dart`
- **description**: The killer paywall feature for teachers. Premium hosts can name + save the current room's roster, then start a new game pre-populated with that class. Expected players light up green when they actually join.
- **acceptance_criteria**:
  - [ ] After a game ends, premium host sees "Save as Class" → name dialog → `saved_rosters` row inserted via service
  - [ ] Host lobby setup view has "Load saved class" button (premium only) → bottom sheet listing saved rosters → loading one prefills the lobby with expected nicknames as ghosted entries
  - [ ] Ghosted entries turn solid + green when that nickname actually joins
  - [ ] Saved rosters list screen with rename / delete / view-history actions
  - [ ] Free users tapping "Load saved class" see a `PremiumTeaser` instead of the bottom sheet
- **depends_on**: TASK-058
- **notes**:
  - Schema (`saved_rosters` table) is already in TASK-051 — no migration changes needed
  - Roster size inherently respects the 30-player premium cap
  - "View history" can defer to v2 (linking past `rooms` rows to a roster requires a new join column — just leave it as a TODO comment for now)

### TASK-060: Nickname profanity filter

- **status**: `open`
- **priority**: P1
- **estimated_effort**: Small
- **claimed_by**: —
- **files_to_touch**: NEW `lib/services/nickname_validator.dart`, NEW `assets/data/profanity_seed.txt`, `pubspec.yaml` (asset declaration), `lib/screens/group_play/join_lobby_screen.dart` (consume the validator)
- **description**: Light profanity filter so kids don't put something dumb on the projector. No false-positive horror stories — keep the wordlist short and obvious.
- **acceptance_criteria**:
  - [ ] `NicknameValidator.validate(name)` returns a sealed result: `Valid | Profanity | TooShort | TooLong | InvalidChars`
  - [ ] Length: 2–14 chars
  - [ ] Allowed chars: alphanumeric + spaces only (no emoji, no symbols)
  - [ ] Wordlist covers obvious English profanity + common bypasses (l33t-speak normalization). Keep it short — ~50 entries — and stored in `assets/data/profanity_seed.txt` so it's easy to extend
  - [ ] Validator is pure — no async, no DB calls, no service deps. Easy to unit-test.
- **depends_on**: —
- **notes**:
  - This task can start immediately, in parallel with TASK-052, because it has no dependencies
  - TASK-052's room code generator should use this validator too — for v1 a soft import / fallback is fine, but the eventual integration is "all user-visible strings get filtered"

### TASK-061: Post-game class breakdown analytics (premium)

- **status**: `open`
- **priority**: P2
- **estimated_effort**: Medium
- **claimed_by**: —
- **files_to_touch**: `lib/screens/group_play/group_results_screen.dart`, NEW `lib/screens/group_play/widgets/class_breakdown_view.dart`
- **description**: Teachers want to know which scriptures their class struggled on. Tally per-question accuracy across the session.
- **acceptance_criteria**:
  - [ ] Results screen has a second tab "Class breakdown" (premium only)
  - [ ] Per-question rows: scripture reference, correct %, hardest answer (most common wrong choice)
  - [ ] Sort by hardest → easiest by default
  - [ ] Tap a row → opens scripture detail
  - [ ] Free hosts see a `PremiumTeaser` in place of the tab content
- **depends_on**: TASK-056

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