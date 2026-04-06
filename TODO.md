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

- **status**: `open`
- **priority**: P0
- **estimated_effort**: Large
- **files_to_touch**: NEW `lib/services/sidekick_service.dart`, NEW `lib/providers/sidekick_provider.dart`, NEW `lib/models/sidekick_snapshot.dart`, NEW `lib/models/sidekick_response.dart`
- **description**: Core service that connects to Grok (xAI API). On app open (for premium users), it sends a JSON snapshot of user data and receives structured JSON to trigger app behavior.
- **acceptance_criteria**:
  - [ ] On premium app launch: automatically create and send JSON snapshot (mastery progress, current scriptures, goals, seminary curriculum week, recent activity)
  - [ ] AI responds with structured JSON that the app can parse (daily prompt, suggested goal, timeline insight, reminder, quick-win suggestion, etc.)
  - [ ] System prompt trains the Sidekick to act as a thoughtful seminary tutor (reverent, Socratic, focused on understand + apply + ACT principles)
  - [ ] Chat interface can send direct messages to the same Sidekick
  - [ ] Backend proxy recommended for API key safety and prompt control
  - [ ] Graceful offline fallback with cached responses
- **depends_on**: TASK-033
- **notes**: This is the main paid feature. Use Grok/xAI API. Keep snapshot and response models simple and well-typed.

### TASK-035: AI-Powered Journal & Dynamic Reflection Prompts

- **status**: `open`
- **priority**: P1
- **estimated_effort**: Medium
- **files_to_touch**: NEW `lib/screens/journal_screen.dart`, NEW or extend `journal_provider.dart`, `sidekick_provider.dart`, NEW `lib/models/journal_entry.dart`
- **description**: Premium journal where the Sidekick generates prompts and can pre-seed entries.
- **acceptance_criteria**:
  - [ ] Sidekick suggests 1–3 thoughtful reflection prompts based on the user's snapshot
  - [ ] Prompts encourage personal application, teaching others, cause-and-effect, etc.
  - [ ] Easy “Reflect Now” buttons throughout the app
  - [ ] Rich-text entries with scripture tagging
- **depends_on**: TASK-034

### TASK-036: AI-Driven Goals, Timeline & Gentle Reminders

- **status**: `open`
- **priority**: P1
- **estimated_effort**: Medium
- **files_to_touch**: NEW `lib/providers/goals_provider.dart`, extend `home_screen.dart` and `progress_screen.dart`
- **description**: Goals, mastery timeline, and reminders are generated or influenced by the Sidekick based on the user's snapshot.
- **acceptance_criteria**:
  - [ ] Sidekick can suggest realistic goals and timeline projections
  - [ ] Visual mastery timeline updated with AI insights
  - [ ] Gentle, encouraging reminders triggered from Sidekick responses
- **depends_on**: TASK-034

### TASK-037: “Ask Your Sidekick” Chat

- **status**: `open`
- **priority**: P1
- **estimated_effort**: Medium
- **files_to_touch**: NEW `lib/screens/sidekick_chat_screen.dart`, `sidekick_provider.dart`
- **description**: Direct chat interface with the Seminary Sidekick.
- **acceptance_criteria**:
  - [ ] Users can ask questions about any scripture or their progress
  - [ ] Chat sends messages to the same Grok-powered Sidekick (same system prompt)
  - [ ] Scripture references in responses are tappable
  - [ ] Entry point from scripture detail (“Ask Your Sidekick about this verse”)
- **depends_on**: TASK-034

### TASK-038: Premium Polish & Optional Enhancements

- **status**: `open`
- **priority**: P2
- **estimated_effort**: Medium
- **files_to_touch**: Various
- **description**: Additional small enhancements.
- **acceptance_criteria**:
  - [ ] Voice-to-journal (extend existing speech service)
  - [ ] Export journal entries
  - [ ] Optional safe family sharing of selected entries
- **depends_on**: TASK-035

### TASK-039: Premium Teaser & Upgrade Experience

- **status**: `open`
- **priority**: P1
- **estimated_effort**: Small
- **files_to_touch**: `lib/screens/onboarding_screen.dart`, `lib/screens/home_screen.dart`, `lib/screens/scripture_detail_screen.dart`, NEW `lib/widgets/premium_teaser.dart`
- **description**: Natural introduction to the Seminary Sidekick.
- **acceptance_criteria**:
  - [ ] Subtle upgrade moments after mastery wins or when opening journal
  - [ ] Clear value proposition focused on deeper understanding and application
  - [ ] Teasers are limited and dismissible
- **depends_on**: TASK-033, TASK-013

### TASK-040: Subtle Engagement Enhancements

- **status**: `open`
- **priority**: P2
- **estimated_effort**: Small-Medium
- **files_to_touch**: extend `home_screen.dart`, `scripture_detail_screen.dart`, `sidekick_provider.dart`
- **description**: Light layers on top of existing gamification that make spare-moment usage feel rewarding.
- **acceptance_criteria**:
  - [ ] Sidekick suggests quick “next best win” sessions based on the snapshot
  - [ ] Gentle nudges for nearly-mastered scriptures
  - [ ] “Time-to-kill” style prompts on home screen
  - [ ] Everything ties back to reflection and the journal
- **depends_on**: TASK-034, TASK-035
- **notes**: Build strictly on top of existing mechanics. No rewrites.

---

## Backlog — Future (not prioritized)

| Task | What | Effort |
|------|------|--------|
| TASK-014 | Social features (if desired later) | XL |
| TASK-015 | Localization (i18n) | Large |