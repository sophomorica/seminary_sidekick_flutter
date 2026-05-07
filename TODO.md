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

- **status**: `done`
- **priority**: P0
- **estimated_effort**: Medium
- **claimed_by**: claude-sonnet-cowork
- **started**: 2026-05-05T12:00:00Z
- **completed**: 2026-05-05T12:45:00Z
- **files_to_touch**: `lib/screens/home/home_screen.dart`, NEW `lib/providers/resume_target_provider.dart`, `lib/screens/progress/progress_screen.dart`
- **description**: The current Home is a dashboard — greeting, mastery ring, long progress description, then tiny "Practice Games" CTA buried below. Kids should land on a screen that says "do something now." Move the dashboard feel (ring, numbers, long text) to the Stats tab and keep Home action-first.
- **acceptance_criteria**:
  - [x] First viewport of Home has at most a one-line greeting + two big action CTAs: **"Let's Learn"** (→ /library) and **"Let's Play"** (→ /practice). Owner-approved framing during prototype review on 2026-05-05.
  - [x] Resume hero on top: needs-review-first then most-recently-practiced non-mastered scripture (per owner's rule), with mastery pip indicator and a single big "Continue practice" CTA → `/scripture/{id}`. Fresh users / all-mastered users get an "Everything you've started is mastered" nudge instead.
  - [x] Removed the 160px mastery ring + "Overall Mastery" paragraph + Started/Needs-Review tiles from Home. The 140px ring + Started + Needs Review tiles now live as the dashboard hero on the Stats tab.
  - [x] Premium "Quick Win" card stays but demoted below the Let's Learn / Let's Play tiles.
  - [x] Streak badge in shell header untouched.
  - [x] Nearly-mastered nudges and book collections were never wired into the current orchestrator — leaving the stale section files (`book_collections_section.dart`, `nearly_mastered_section.dart`, `quick_sessions_section.dart`, `premium_home_section.dart`, `stats_section.dart`) untouched. Future cleanup task should either wire them into Stats or delete them.
  - [x] Brand new users (zero activity) skip both the resume card and the all-caught-up nudge — the two big tiles speak for themselves.
- **depends_on**: —
- **notes**:
  - **NEW provider** `lib/providers/resume_target_provider.dart` — `ResumeTarget?` exposes `scripture`, `lastPracticed`, and `isReviewNudge`. Selection rule: smart review queue first (filtered to exclude mastered/eternal), else most-recently-practiced non-mastered via `ScriptureMastery.lastPracticedAny`.
  - **Stats tab consolidation**: dedicated "Mastery Streak — Days of Focus" card removed; the streak number is now a subtitle on the heatmap card ("X-day streak · daily engagement with the word"). Owner-approved during prototype review.
  - **Mastery pip indicator**: 6-dot row on the resume card. Filled = levels reached (sage), highlighted = next level to push for (rust), empty = future levels.
  - Image cards reduced from 240→168px height so resume card has visual primacy.
  - Existing greeting flow preserved (premium AI prompt OR time-greeting + name).
  - Did NOT introduce a generic `lastPracticedScriptureIdProvider` — `ScriptureMastery.lastPracticedAny` already provides per-scripture aggregation, which is enough for the resume rule.
  - **Future considerations**: TASK-057 will add a "Play with friends" CTA below the tiles when group play lands. The new layout has room — drop it between the tiles and the QuickWin card.

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

> **Status as of 2026-05-07 — END-TO-END TESTED**: Foundation + host lobby + join lobby + entry points are done and proven working on a real two-instance setup (iOS Simulator + Chrome). A host can create a room, see the code, watch a player join in real-time, and start the game; both clients navigate to the (placeholder) live quiz screen.
>
> | Phase | Tasks | Status | Parallel? |
> |---|---|---|---|
> | 1 | TASK-051 (Supabase setup) | **done** | — |
> | 2 | TASK-052 (foundation) | **done** | — |
> | 3a | TASK-053 (host lobby), TASK-054 (join lobby), TASK-057 (entry points) | **done** | — |
> | 3b | **TASK-055 (live quiz), TASK-056 (results), TASK-060 (nickname filter)** | **OPEN — claim now** | **YES — 3 parallel agents safe** |
> | 4 | TASK-058 (premium gating), TASK-059 (saved rosters), TASK-061 (analytics) | open | After 3b lands |
>
> **For agents claiming a Phase-3b task**: the foundation is stable and proven. Read `lib/screens/group_play/host_lobby_screen.dart` and `join_lobby_screen.dart` first — they're the canonical templates for the project's group-play UI patterns (theme usage, `ref.listen` on phase transitions, error banners, dark-mode handling, leave-confirm flow). Then read your task's notes for specific provider methods and state fields you'll consume.
>
> **Shared-file edits in Phase 3b**: each task swaps ONE placeholder import in `lib/app.dart` (3 lines: import + route line + drop the `Placeholder` suffix). No other shared files. Three agents can land their PRs in any order without conflicts.
>
> **Phase-4 scheduling note**: TASK-058 and TASK-059 both modify `group_play_service.dart` and `host_lobby_screen.dart`. Land them serially, not in parallel.

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
  - [x] **Owner step**: New Supabase project created in dashboard, separate from any existing project
  - [x] **Owner step**: `supabase link --project-ref <ref>` + `supabase db push` runs cleanly
  - [x] **Owner step**: Anonymous auth toggled on
  - [x] **Owner step**: Realtime publication includes `rooms`, `players`, `answers`
  - [x] **Owner step**: Project URL + anon key stashed; `--dart-define=SUPABASE_URL=... SUPABASE_ANON_KEY=...` added to local run command
  - [ ] **Verifying agent step (after TASK-052 lands)**: smoke test in SUPABASE_SETUP.md passes — anonymous user can create a room and a second device can see it via realtime
- **depends_on**: —
- **notes**:
  - Service-role key stays out of the Flutter app forever. anon key is safe to ship.
  - Owner already runs Supabase elsewhere — a separate project keeps quotas isolated.
  - Default free-tier limits (200 concurrent connections, 5GB DB) are way more than this app needs in dev or even early adoption.

### TASK-052: Group play foundation (models, service, provider, route stubs)

- **status**: `done`
- **priority**: P0
- **estimated_effort**: Large
- **claimed_by**: claude-opus-agent
- **started**: 2026-05-07T00:00:00Z
- **completed**: 2026-05-07T01:00:00Z
- **files_to_touch**: NEW `lib/models/group_room.dart`, NEW `lib/models/group_player.dart`, NEW `lib/models/group_question.dart`, NEW `lib/models/group_answer.dart`, NEW `lib/models/group_play_state.dart`, NEW `lib/services/quiz_question_factory.dart`, NEW `lib/services/group_play_service.dart`, NEW `lib/providers/group_play_provider.dart`, NEW `lib/screens/group_play/_placeholder_screens.dart`, `lib/providers/quiz_game_provider.dart` (now delegates to factory), `lib/main.dart` (Supabase init + anonymous sign-in), `lib/app.dart` (add `/group-play/*` routes wired to placeholder screens), `pubspec.yaml` (`supabase_flutter ^2.5.0`, `qr_flutter ^4.1.0`)
- **description**: Establish the data layer and orchestration layer for group play. Add placeholder screens for each route so UI tasks (TASK-053..TASK-056) can build in parallel without conflicting on `app.dart`.
- **acceptance_criteria**:
  - [x] `GroupRoom`, `GroupPlayer`, `GroupQuestion`, `GroupAnswer` models with `copyWith`, `fromJson`/`toJson`, equality
  - [x] `GroupPlayState` provider state with subStates: `idle`, `hosting`, `joining`, `inLobby`, `inQuiz`, `viewingResults`, `error`
  - [x] `GroupPlayService` covers all required methods (createRoom, joinRoom, leaveRoom, startRoom, advanceQuestion, submitAnswer, endRoom, kickPlayer, watchRoom, watchPlayers, watchAnswers, listenForEvents). Internal `_broadcast` is used by host-side methods to push ephemeral events.
  - [x] `GroupPlayNotifier` exposes the same surface, transforms service streams into state updates
  - [x] 4-letter room code generator uses an unambiguous alphabet (excludes I, O, 0, 1, B, S). Profanity filter integration is deferred to TASK-060 — the alphabet is conservative enough that obvious bad words can't form
  - [x] Speed-weighted scoring formula implemented as `computeSpeedWeightedPoints` in `group_answer.dart`
  - [x] Question generation extracted to `lib/services/quiz_question_factory.dart`. Solo provider (`quiz_game_provider.dart`) refactored to delegate. Behavior identical (verified by reading existing test in `test/providers/quiz_game_provider_test.dart` — only public `QuizQuestionType` symbol used, which is now a typedef alias)
  - [x] Routes added: `/group-play/host`, `/group-play/join`, `/group-play/lobby/:code`, `/group-play/quiz/:code`, `/group-play/results/:code` — pointing at placeholders that show the owning TASK-NNN
  - [x] `main.dart`: `_maybeInitSupabase()` reads `SUPABASE_URL` and `SUPABASE_ANON_KEY` from `--dart-define`, initializes the client, signs in anonymously. Tolerates missing dart-defines (logs and skips so solo features still work)
  - [ ] **Smoke test (owner step, post `flutter pub get`)**: launch app with `--dart-define=SUPABASE_URL=... SUPABASE_ANON_KEY=...`, verify console logs an anonymous user id, navigate to `/group-play/host`, see placeholder
  - [x] Service-level doc comment lists every channel name and table touched
- **depends_on**: TASK-051 (the migrations must be deployed before service smoke-tests work, but the Dart code can be written in parallel)
- **notes**:
  - Models go in `lib/models/group_*.dart` with one model per file (matches existing code style)
  - Question pushes during a live quiz go via Broadcast on `room:{code}`, while durable state (current_question_index, room status) updates via Postgres on the `rooms` row — both arrive at the client; Broadcast is the fast path, Postgres Changes is the safety net
  - Provider disposes all channels in `leave()` / `resetToIdle()` and on dispose
  - **Owner action items before Phase 3 starts**:
    1. Run `flutter pub get` (adds `supabase_flutter`, `qr_flutter`)
    2. Run `flutter analyze` — should be clean. If supabase_flutter ^2.5 has a different API surface than what was written, fix the diff and capture as a bug
    3. Run the smoke test above
    4. Once green, fan out Phase 3 to multiple agents — TASK-053, TASK-054, TASK-055, TASK-056, TASK-060 are all parallel-safe

### TASK-053: Host lobby screen

- **status**: `done`
- **priority**: P0
- **estimated_effort**: Medium
- **claimed_by**: claude-opus-agent
- **started**: 2026-05-07T02:45:00Z
- **completed**: 2026-05-07T03:15:00Z
- **files_to_touch**: NEW `lib/screens/group_play/host_lobby_screen.dart`, NEW `lib/screens/group_play/widgets/room_code_display.dart`, NEW `lib/screens/group_play/widgets/joined_players_list.dart`, NEW `lib/screens/group_play/widgets/group_play_scope_picker.dart` (minimal v1 picker — full version comes from TASK-047)
- **description**: Two views in one screen. **Setup view**: pick scope + difficulty + start the room. **Lobby view**: huge 4-letter code, QR, live list of joined players, kick button per player, "Start Game" button.
- **acceptance_criteria**:
  - [x] Setup view: all 4 difficulties via `_DifficultyChips`, `_BookChips` ("All 100" + per-volume), nickname field defaulted from `greetingNameProvider`
  - [x] On "Create Room", calls `groupPlayProvider.notifier.hostCreateRoom(scope, hostNickname)`. Provider transitions to inLobby and the screen renders `_LobbyView`
  - [x] Lobby view: code displayed at 72sp monospace bold on a primary card with editorial shadow; QR code below using `qr_flutter` encoding `seminary-sidekick://group-play/join?code=ABCD`
  - [x] Player roster updates in real-time via the provider's stream subscription. Each non-host row has a kick (X) IconButton
  - [x] Player count + cap displayed in section label ("PLAYERS  N/6" or "/30"). Inline "Up to 30 with Premium →" link appears when free host is at cap
  - [x] Start button disabled until ≥1 non-host has joined; label flips from "Waiting for players…" to "Start Game (N players)"
  - [x] Tapping Start calls `hostStartGame()`. `ref.listen` on `groupPlayPhaseProvider` auto-navigates to `/group-play/quiz/:code` when phase flips to inQuiz
  - [x] Back navigation shows `AlertDialog` confirmation. On confirm, `notifier.leave()` + return to /practice
- **depends_on**: TASK-052
- **notes**:
  - Skipped per-widget extraction (room_code_display.dart, joined_players_list.dart) — screen is short enough that splitting added boilerplate without clarity. Easy to extract later
  - QR encodes the deep link, but iOS/Android deep-link config still needs to land separately for the QR to be scannable from outside the app. For v1, the visible 4-letter code is the source of truth
  - Setup view scope picker is minimal — TASK-047 will replace it with the multi-select sheet
  - Host nickname defaults from `greetingNameProvider` but is editable per-game (useful for "Mr. Lamoureux" vs "Patrick")
  - Free vs Premium cap is enforced server-side via `player_cap`; the inline upgrade link is just UX

### TASK-054: Join lobby screen

- **status**: `done`
- **priority**: P0
- **estimated_effort**: Small
- **claimed_by**: claude-opus-agent
- **started**: 2026-05-07T02:15:00Z
- **completed**: 2026-05-07T02:30:00Z
- **files_to_touch**: NEW `lib/screens/group_play/join_lobby_screen.dart`, `lib/app.dart` (swapped placeholder for real screen)
- **description**: Player enters a 4-letter code + nickname, joins the room, sees the lobby, waits for host to start.
- **acceptance_criteria**:
  - [x] Code field: monospace + 12-letter spacing (visually obvious it's 4 chars), auto-uppercase via both `textCapitalization` AND a `_UpperCaseFormatter` (handles paste/autofill), big vertical padding for tap target
  - [x] Nickname field: 2–14 char validator inline; alphanumeric+space-only `FilteringTextInputFormatter`. Profanity filter integration deferred to TASK-060 — comment in code marks the spot
  - [x] "Join" button calls `groupPlayProvider.notifier.joinAsPlayer(code, nickname)`
  - [x] Error states render via `_ErrorBanner` inline above the button. Specific exception messages from `GroupPlayService` (RoomNotFoundException, RoomFullException, NicknameTakenException, RoomAlreadyStartedException, RoomEndedException) flow through the provider's `state.error` and render as-is
  - [x] On success, switches to `_WaitingView` with the room code chip, "Playing as <nickname>", animated "Waiting for host…" indicator, live roster (count + cap), Leave button
  - [x] `ref.listen` on `groupPlayPhaseProvider` auto-navigates to `/group-play/quiz/:code` when the room flips to active. Also handles "host ended without starting" gracefully (snackbar + return home)
- **depends_on**: TASK-052
- **notes**:
  - Soft profanity-filter integration: validator just checks length+charset for now. When TASK-060 lands, swap the validator body for a `NicknameValidator.validate(value)` call
  - The `Leave Room` button calls `notifier.leave()` which disposes all stream subscriptions cleanly
  - Back-arrow in app bar also calls `leave()` so we don't leak a player row
  - The screen is fully dark-mode aware (uses `Theme.of(context).brightness` to pick fill colors)

### TASK-055: Live group quiz screen

- **status**: `in_progress`
- **priority**: P0
- **estimated_effort**: Large
- **claimed_by**: claude-opus-agent
- **started**: 2026-05-07T18:00:00Z
- **files_to_touch**: NEW `lib/screens/group_play/group_quiz_screen.dart`, NEW `lib/screens/group_play/widgets/group_question_card.dart`, NEW `lib/screens/group_play/widgets/live_leaderboard.dart`, NEW `lib/screens/group_play/widgets/answers_received_indicator.dart`, `lib/app.dart` (one-line swap: replace `GroupQuizPlaceholderScreen` import + reference with `GroupQuizScreen`)
- **description**: The actual gameplay. Host pushes questions one at a time; players answer; between questions, top-5 leaderboard with deltas; after the last question, navigate to the results screen.
- **agent_context_block** (read first):
  - **Templates to copy from**: `lib/screens/group_play/host_lobby_screen.dart` and `lib/screens/group_play/join_lobby_screen.dart`. They establish the project's group-play UI patterns: `ConsumerStatefulWidget`, `ref.listen<GroupPlayPhase>` for navigation, two-view layouts via switch, theme + dark-mode handling, `_ErrorBanner` style.
  - **Solo quiz visual reference**: `lib/screens/games/quiz_game_screen.dart`. Match its answer button shapes, correct/incorrect colors, animations so this feels familiar.
  - **Provider surface to consume** (from `lib/providers/group_play_provider.dart`):
    - `groupPlayProvider` → `GroupPlayState` (has `room`, `me`, `players`, `questions`, `answers`, `currentQuestionAnswered`, `mySelectedChoice`, `isHost`, `currentQuestion`, `leaderboard`)
    - `groupPlayPhaseProvider` → for `ref.listen` to detect `viewingResults` and navigate
    - `currentGroupQuestionProvider` → `GroupQuestion?` (the question on screen now)
    - `groupPlayLeaderboardProvider` → `List<GroupPlayer>` sorted by score desc
    - `isGroupHostProvider` → `bool`
  - **Provider methods to call**:
    - Host: `notifier.hostAdvanceQuestion()`, `notifier.hostEndGame()`
    - Player: `notifier.submitAnswer(selectedChoice: int, elapsed: Duration)`
  - **Models**: `GroupQuestion` (in `lib/models/group_question.dart`) has `prompt`, `options` (4 strings), `correctIndex`, `scriptureReference`. `GroupAnswer` is what the leaderboard reads. Speed-weighted scoring is already done in the service — you just call `submitAnswer` with the elapsed Duration and points appear on the player row.
  - **Route**: `/group-play/quiz/:code`. The host lobby and join lobby both navigate here when `phase == GroupPlayPhase.inQuiz`. After last question or `hostEndGame`, navigate to `/group-play/results/:code`.
- **acceptance_criteria**:
  - [ ] **Host view**: current question, 20-second countdown (use `room.scope.questionTimeoutSeconds`), live "X of N answered" counter pulled from `state.answers.where((a) => a.questionIndex == room.currentQuestionIndex)`, "Next Question" button calls `hostAdvanceQuestion()`
  - [ ] **Player view**: current question, four answer buttons; locks after answer (use `state.currentQuestionAnswered`) or timeout; shows "+N pts ✓" feedback after submission (the points are on the updated `me.score` after submit)
  - [ ] **Between-question screen** (transient state): top-5 leaderboard from `groupPlayLeaderboardProvider` with rank deltas — keep a snapshot of last leaderboard in local state to compute "▲2" / "▼1" / "—"
  - [ ] After last question (`room.currentQuestionIndex >= state.questions.length - 1`), host taps Next → `hostEndGame()` → `ref.listen` sees phase flip to `viewingResults` and navigates everyone to `/group-play/results/:code`
  - [ ] Disconnect handling (V1, simple): rely on the existing room watcher — if `room.status == ended`, navigate to results. Per-player disconnect detection can wait
  - [ ] Score updates already persist via `submitAnswer` — no extra work needed
  - [ ] After completion, swap the placeholder import in `app.dart` for the real screen
- **depends_on**: TASK-052
- **notes**:
  - Question pushes already happen via Broadcast in the service — clients see them via the `rooms` Postgres Changes stream. You don't need to subscribe to broadcast directly; just watch `currentQuestionIndex` change via the existing provider state.
  - `confetti` is already in pubspec — use sparingly for correct-answer flair; keep duration short so a class of 30 doesn't lag.
  - V1 doesn't need rejoin-after-disconnect logic. Document any edge cases as TODO comments instead of building them.
  - Don't create a new provider — everything you need is on `groupPlayProvider`.

### TASK-056: Group results screen

- **status**: `in_progress`
- **priority**: P1
- **estimated_effort**: Small-Medium
- **claimed_by**: claude-opus-agent
- **started**: 2026-05-07T03:15:00Z
- **files_to_touch**: NEW `lib/screens/group_play/group_results_screen.dart`, NEW `lib/screens/group_play/widgets/podium_view.dart`, `lib/app.dart` (one-line swap: `GroupResultsPlaceholderScreen` → `GroupResultsScreen`)
- **description**: Final podium for top 3, full leaderboard, share, and host actions (Play Again / End).
- **agent_context_block** (read first):
  - **Templates to copy from**: `lib/screens/group_play/host_lobby_screen.dart` (uses confetti package similarly elsewhere — see `lib/screens/games/game_results_screen.dart` for the existing solo results pattern with confetti).
  - **Provider state to consume** (from `lib/providers/group_play_provider.dart`):
    - `groupPlayProvider` → `GroupPlayState` with `room`, `players`, `me`, `answers` (full list of all answers in this session)
    - `groupPlayLeaderboardProvider` → already-sorted `List<GroupPlayer>`
    - `isGroupHostProvider` → `bool`
    - `me?.score` → your final score
  - **Provider methods**:
    - `notifier.hostCreateRoom(scope: state.room!.scope, hostNickname: me!.nickname)` for "Play Again" — reuses the same scope
    - `notifier.resetToIdle()` to wipe state before going back home
  - **Computing per-player stats**: walk `state.answers` filtered by `playerId` to compute accuracy and avg response time. Example:
    ```dart
    final myAnswers = state.answers.where((a) => a.playerId == player.id).toList();
    final accuracy = myAnswers.isEmpty ? 0.0 : myAnswers.where((a) => a.isCorrect).length / myAnswers.length;
    final avgMs = myAnswers.isEmpty ? 0 : myAnswers.map((a) => a.responseTimeMs).reduce((a, b) => a + b) ~/ myAnswers.length;
    ```
  - **Sharing**: existing `share_plus` integration in `lib/services/journal_export_service.dart` is a usable reference for `Share.share(text)` patterns.
  - **Confetti**: `package:confetti` already in pubspec. See `lib/screens/games/game_results_screen.dart` for an existing controller/duration pattern.
  - **Route**: `/group-play/results/:code`. Phase is `viewingResults`. Both host and player land here.
- **acceptance_criteria**:
  - [ ] Podium for top 3 with confetti (3 columns: 2nd, 1st-tallest, 3rd)
  - [ ] Full leaderboard rows: rank, nickname, score, accuracy %, avg response time. Highlight the local user's row.
  - [ ] Host: "Play Again" → creates a new room with same scope, navigates to `/group-play/host` (or directly into a fresh lobby). "End" → `notifier.resetToIdle()` + `context.go('/')`
  - [ ] Players: "Done" → `notifier.resetToIdle()` + `context.go('/')`
  - [ ] Share button: text-only summary via `share_plus` (no premium gate — sharing IS the viral hook)
  - [ ] After completion, swap placeholder import in `app.dart` for the real screen
- **depends_on**: TASK-052
- **notes**:
  - The "Class breakdown" tab (per-question accuracy) is TASK-061's job — leave space for it but don't build it
  - "Play Again" reuses scope via `state.room!.scope` — that's why `GroupRoom.scope` is preserved through endRoom
  - Don't gate sharing behind premium even though most premium features are gated. Sharing is the viral loop.

### TASK-057: Practice Hub & Home entry points

- **status**: `done`
- **priority**: P0
- **estimated_effort**: Small-Medium
- **claimed_by**: claude-opus-agent
- **started**: 2026-05-07T01:30:00Z
- **completed**: 2026-05-07T02:00:00Z
- **files_to_touch**: `lib/screens/practice_hub_screen.dart`, `lib/screens/home/home_screen.dart`
- **description**: Surface group play in the app shell. **Practice Hub**: new "Group Play" card with Host / Join buttons. **Home**: a "Play with Friends" CTA tile.
- **acceptance_criteria**:
  - [x] Practice Hub: `_GroupPlayCard` placed above the path selector (top of the page after the header). Two buttons — "Host a Game" → `/group-play/host`, "Join a Game" → `/group-play/join`. Gradient (secondary → tertiary) so it stands out without competing with the primary Word Builder hero
  - [x] Free hosts see subtitle: "Up to 6 players free · Premium for class size"
  - [x] Premium hosts see subtitle: "Up to 30 players · Save your class roster"
  - [x] Home: `_buildPlayWithFriendsTile` placed right after the existing "Let's Play" tile. Defaults to Join screen on tap (most common flow: friend texted me a code). Has a "NEW" badge so kids notice it
  - [x] Both entry points navigate via GoRouter (`context.push` from Practice Hub, `context.push` from Home)
  - [x] Done re-ordering of "depends_on": originally listed TASK-053/054, but doing this BEFORE the destination screens land was deliberately chosen so the owner (a solo dev) can navigate end-to-end through placeholders during development
- **depends_on**: ~~TASK-053, TASK-054~~ — overridden 2026-05-07; entry points landed first against placeholder destinations to enable navigation testing
- **notes**:
  - Decision pivot: schedule originally said "build destinations first, then entry points," but doing it the other way around is friendlier for a solo dev who needs to validate flows end-to-end before any real screen exists
  - Practice Hub's Group Play card uses a gradient, not an image — no new asset needed
  - Home tile also uses a gradient (tertiary → secondary) for the same reason
  - Shared-file edits: only added new code, did not touch existing widgets in either file
  - When TASK-046 (Home reorientation) lands, the "Play with Friends" tile slot may move; the call site is one line

### TASK-058: Premium gating for group hosting

- **status**: `open`
- **priority**: P1
- **estimated_effort**: Small-Medium
- **claimed_by**: —
- **files_to_touch**: `lib/services/group_play_service.dart`, `lib/providers/group_play_provider.dart`, `lib/screens/group_play/host_lobby_screen.dart`
- **description**: Enforce the free/premium hosting split. Free hosts: cap 6, 1 game/week. Premium hosts: cap 30, unlimited games.
- **agent_context_block** (read first):
  - **Most of this is already implemented in `lib/services/group_play_service.dart`** — TASK-052 wired up the foundation. Audit before adding:
    - `freeHostCap = 6`, `premiumHostCap = 30`, `freeHostWeeklyLimit = 1` constants are defined
    - `createRoom` already reads `isPremiumHost` from the caller, calls `bump_host_usage` RPC, throws `FreeTierLimitException` if exceeded
    - `joinRoom` already throws `RoomFullException` if `players.length >= room.playerCap`
    - `host_lobby_screen.dart` already has a basic "Up to 30 with Premium →" inline link when at cap
  - **What's actually left**:
    - Verify the cap enforcement works end-to-end with a free user creating 2 rooms in a week (currently only manually testable by toggling `forcePremium` in `app_config.dart`)
    - Polish the upgrade prompts: the current host lobby link only shows AT cap. Add a "approaching cap" prompt when `players.length >= cap - 1`
    - The "1 game/week" limit's UX needs work — when `FreeTierLimitException` fires, the host gets the raw error message. Replace with a tasteful upgrade dialog
- **acceptance_criteria**:
  - [x] On `createRoom`, service writes `player_cap` (6 or 30) + `is_premium_host` to the row — DONE in TASK-052
  - [x] On `createRoom`, service calls `bump_host_usage` RPC, throws `FreeTierLimitException` if exceeded — DONE in TASK-052
  - [x] On `joinAsPlayer`, service rejects with `RoomFullException` when at cap — DONE in TASK-052
  - [ ] Host lobby shows tasteful upgrade dialog (not raw exception) when free host hits weekly limit
  - [ ] Host lobby renders inline "Upgrade for class size" link both AT cap AND one-below-cap (rate-limited via `canShowUpgradePromptProvider`)
  - [ ] Manual verification: with `forcePremium: false` in `app_config.dart`, can create exactly 1 room/week; second attempt this week shows the upgrade dialog
- **depends_on**: TASK-053 — done
- **notes**:
  - **Most of this task is already done** by TASK-052's foundation. Treat this as polish + UX layer only.
  - Server-side enforcement is the source of truth; client-side checks are UX nice-to-haves
  - If a host upgrades mid-room, the cap doesn't auto-raise on the active room — they'd have to start a new one. Document this behavior in code comments.
  - **Phase 4 scheduling**: this task and TASK-059 both modify `host_lobby_screen.dart` and `group_play_service.dart`. Land them serially.

### TASK-059: Saved class rosters (premium feature)

- **status**: `open`
- **priority**: P1
- **estimated_effort**: Medium
- **claimed_by**: —
- **files_to_touch**: NEW `lib/screens/group_play/saved_rosters_screen.dart`, NEW `lib/providers/saved_rosters_provider.dart`, `lib/services/group_play_service.dart` (add saved-roster CRUD methods), `lib/screens/group_play/host_lobby_screen.dart` (add "Load saved class" button), `lib/screens/group_play/group_results_screen.dart` (add "Save as Class" button), `lib/app.dart` (add `/group-play/saved-rosters` route)
- **description**: The killer paywall feature for teachers. Premium hosts can name + save the current room's roster, then start a new game pre-populated with that class. Expected players light up green when they actually join.
- **agent_context_block** (read first):
  - **Schema is ready**: `saved_rosters` table already exists from `supabase/migrations/0001_group_play_init.sql` with RLS scoped to host. No migration changes needed.
  - **Service additions needed** in `lib/services/group_play_service.dart`:
    ```dart
    Future<List<SavedRoster>> listSavedRosters() async { ... }       // SELECT all where host_id = me
    Future<SavedRoster> saveRoster(String name, List<String> nicknames) async { ... }  // INSERT
    Future<void> renameRoster(String id, String name) async { ... }  // UPDATE
    Future<void> deleteRoster(String id) async { ... }               // DELETE
    ```
  - **NEW model**: `lib/models/saved_roster.dart` — mirror the `saved_rosters` table (id, hostId, name, playerNicknames List<String>, createdAt, updatedAt, fromJson/toJson, copyWith).
  - **NEW provider**: `savedRostersProvider` — StateNotifierProvider with init() that loads on demand. Premium-only; free users get an empty list + teaser.
  - **Provider state for "ghosted" expected players**: extend `GroupPlayState` with an `expectedNicknames: List<String>` field. The host lobby renders ghosted entries for nicknames in this list that haven't joined yet, solid+green when they do.
  - **PremiumTeaser pattern**: see `lib/widgets/premium_teaser.dart` for the existing teaser widget — use `PremiumGate` to swap real UI vs teaser based on `isPremiumProvider`.
- **acceptance_criteria**:
  - [ ] After a game ends on the results screen, premium host sees "Save as Class" button → opens name dialog → calls `service.saveRoster(name, currentNicknames)` → success snackbar
  - [ ] Host lobby setup view has "Load saved class" button (premium only) → bottom sheet listing saved rosters from `savedRostersProvider` → tapping one prefills the lobby with expected nicknames as ghosted entries
  - [ ] Ghosted entries turn solid + green when that nickname actually joins (compare `state.players.map((p) => p.nickname)` against `state.expectedNicknames`)
  - [ ] `/group-play/saved-rosters` route — full screen list with rename / delete actions
  - [ ] Free users tapping "Load saved class" see a `PremiumTeaser` instead of the bottom sheet
- **depends_on**: TASK-058 (don't claim until 058 is done — both modify the service)
- **notes**:
  - Roster size inherently respects the 30-player premium cap (the cap is on `players` table, not on saved roster size)
  - "View history" (linking past `rooms` rows to a roster) is deferred to v2 — leave a TODO comment
  - The bottom sheet should default-sort by most-recent first, max 10 visible at a time

### TASK-060: Nickname profanity filter

- **status**: `open`
- **priority**: P1
- **estimated_effort**: Small
- **claimed_by**: —
- **files_to_touch**: NEW `lib/services/nickname_validator.dart`, NEW `assets/data/profanity_seed.txt`, `pubspec.yaml` (already declares `assets/data/` — verify nothing changes), `lib/screens/group_play/join_lobby_screen.dart` (replace inline validator), `lib/screens/group_play/host_lobby_screen.dart` (apply the same validator to the host's nickname field), NEW `test/services/nickname_validator_test.dart`
- **description**: Light profanity filter so kids don't put something dumb on the projector. No false-positive horror stories — keep the wordlist short and obvious.
- **agent_context_block** (read first):
  - **Where the validator plugs in**:
    - `lib/screens/group_play/join_lobby_screen.dart` line ~287 — current validator is inline length+charset checks. Comment marks the spot: *"TASK-060 will plug a profanity filter in here once it lands."*
    - `lib/screens/group_play/host_lobby_screen.dart` `_handleCreate` — currently just checks `nickname.length < 2`. Same upgrade.
  - **Pattern**: keep the validator pure, no Riverpod dependency. Both screens can import it directly:
    ```dart
    import '../../services/nickname_validator.dart';
    ...
    final result = NicknameValidator.validate(value);
    if (result is NicknameProfanity) return 'Pick something else.';
    if (result is NicknameTooShort) return 'At least 2 characters.';
    // etc.
    ```
  - **Asset loading**: the wordlist file is loaded via `rootBundle.loadString('assets/data/profanity_seed.txt')` once at startup. Wrap it in a static cached future so the first call awaits, subsequent calls are sync.
- **acceptance_criteria**:
  - [ ] `NicknameValidator.validate(name)` returns a sealed result: `NicknameValid | NicknameProfanity | NicknameTooShort | NicknameTooLong | NicknameInvalidChars` (use a sealed class or Dart pattern matching)
  - [ ] Length: 2–14 chars
  - [ ] Allowed chars: alphanumeric + spaces only (no emoji, no symbols)
  - [ ] Wordlist covers obvious English profanity + common bypasses (l33t-speak normalization: 0→o, 1→l, 3→e, 4→a, 5→s, 7→t, @→a). Keep it short — ~50 entries — stored in `assets/data/profanity_seed.txt` (one word per line, lowercase)
  - [ ] Validator is pure — no async, no DB, no service deps. The wordlist is loaded once at app start (or lazily on first call), then matching is sync
  - [ ] Both `join_lobby_screen.dart` and `host_lobby_screen.dart` switch their inline validators to call `NicknameValidator.validate`
  - [ ] Unit tests in `test/services/nickname_validator_test.dart` covering: too-short, too-long, invalid chars, valid clean name, obvious profanity, l33t-speak bypass, mixed case bypass
- **depends_on**: —
- **notes**:
  - This task is fully isolated — can start immediately and lands without touching the service or provider
  - Don't ship a real profanity list in this PR. Use placeholder pseudo-words ("badword", "bypass", "rude") in `profanity_seed.txt` so the test suite is meaningful but the repo doesn't have actual offensive language committed. The owner will swap in a real seed list before production
  - Match against the *normalized* string (lowercase + l33t replacement + spaces stripped) so "B@dW0rd" still gets caught
  - Don't be aggressive with matching — exact word match only, not substring. A nickname containing the letters "ass" should NOT trigger if it's "Cassandra"

### TASK-061: Post-game class breakdown analytics (premium)

- **status**: `open`
- **priority**: P2
- **estimated_effort**: Medium
- **claimed_by**: —
- **files_to_touch**: `lib/screens/group_play/group_results_screen.dart`, NEW `lib/screens/group_play/widgets/class_breakdown_view.dart`
- **description**: Teachers want to know which scriptures their class struggled on. Tally per-question accuracy across the session.
- **agent_context_block** (read first):
  - **Data is already available** on `GroupPlayState.answers` and `GroupPlayState.questions`. No new service calls or schema changes.
  - **Aggregation pseudocode**:
    ```dart
    final questions = state.questions;
    final answers = state.answers;
    final breakdown = questions.map((q) {
      final qAnswers = answers.where((a) => a.questionIndex == q.index).toList();
      final correctPct = qAnswers.isEmpty ? 0.0 : qAnswers.where((a) => a.isCorrect).length / qAnswers.length;
      // Most common wrong choice
      final wrongCounts = <int, int>{};
      for (final a in qAnswers.where((a) => !a.isCorrect)) {
        wrongCounts[a.selectedChoice] = (wrongCounts[a.selectedChoice] ?? 0) + 1;
      }
      final mostWrong = wrongCounts.entries.fold<MapEntry<int, int>?>(null, (acc, e) =>
        acc == null || e.value > acc.value ? e : acc);
      return (question: q, correctPct: correctPct, mostWrongChoice: mostWrong?.key);
    }).toList()..sort((a, b) => a.correctPct.compareTo(b.correctPct));  // hardest first
    ```
  - **PremiumGate pattern**: see `lib/widgets/premium_teaser.dart` for `PremiumGate` which swaps real content for a teaser.
  - **TabBar**: results screen needs a TabController. Convert to ConsumerStatefulWidget with SingleTickerProviderStateMixin if it isn't already.
- **acceptance_criteria**:
  - [ ] Results screen has a second tab "Class breakdown" (premium only)
  - [ ] Per-question rows: scripture reference, correct %, hardest answer (most common wrong choice text)
  - [ ] Sort by hardest → easiest by default
  - [ ] Tap a row → `context.push('/scripture/${q.scriptureId}')` opens the scripture detail
  - [ ] Free hosts see a `PremiumTeaser` in place of the tab content
- **depends_on**: TASK-056
- **notes**:
  - This is a polish task — don't claim until TASK-056 lands so the results screen exists to extend

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