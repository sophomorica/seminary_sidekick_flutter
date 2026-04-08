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

## Backlog — Future (not prioritized)

| Task | What | Effort |
|------|------|--------|
| TASK-014 | Social features (if desired later) | XL |
| TASK-015 | Localization (i18n) | Large |