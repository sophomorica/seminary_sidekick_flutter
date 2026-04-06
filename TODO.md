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

---

## Premium Tier — Paid Features (Freemium Model)

> **Free tier** = full mastery loop (Word Builder, quizzes, spaced repetition, progress tracking).
> **Premium tier** = AI companion, journal, curriculum sync, goals, social, deep study tools.
>
> The Church defines scripture mastery as three pillars — *find*, *understand*, *apply*. The free tier nails "find" and "memorize." Premium targets "understand" and "apply" through AI-guided reflection, contextual study tools, and curriculum alignment.
>
> **Architecture**: Everything depends on TASK-100 (backend + auth + paywall). Nothing else ships without it.

---

### TASK-100: Premium Infrastructure — Backend, Auth, & Paywall

- **status**: `open`
- **priority**: P0
- **estimated_effort**: XL
- **files_to_touch**: NEW `lib/services/auth_service.dart`, NEW `lib/services/api_service.dart`, NEW `lib/providers/auth_provider.dart`, NEW `lib/providers/subscription_provider.dart`, NEW `lib/screens/paywall_screen.dart`, NEW `lib/screens/profile_screen.dart`, `lib/app.dart`, `lib/main.dart`, `pubspec.yaml`
- **description**: User accounts (Firebase Auth — email + Apple/Google SSO), subscription management (RevenueCat), API service for AI calls, paywall gate, profile screen. Free-tier features stay functional without sign-in. Local Hive data syncs to cloud on account creation.
- **acceptance_criteria**:
  - [ ] Auth: sign up / sign in / sign out (email + SSO)
  - [ ] Subscription state tracked and gated (free vs premium)
  - [ ] RevenueCat integration for App Store + Google Play
  - [ ] Paywall screen with feature comparison and purchase flow
  - [ ] API service layer for authenticated backend requests
  - [ ] Free-tier fully functional without sign-in
  - [ ] Local progress syncs to cloud on account creation
  - [ ] Profile screen: account info, subscription status, sign out
- **depends_on**: —
- **notes**: Recommend Firebase for auth/data + Cloud Function (or separate API) for AI agent calls.

---

### AI Study Companion

> Centerpiece of premium. Two modes: daily prompt on home screen + full conversational chat. The AI knows the student's mastery progress, current seminary curriculum, and scriptural context. Warm, Socratic, faith-affirming — a thoughtful seminary teacher, not a lecturer.

### TASK-101: AI Agent — Backend & API Integration

- **status**: `open`
- **priority**: P0
- **estimated_effort**: XL
- **files_to_touch**: NEW `lib/services/ai_service.dart`, NEW `lib/providers/ai_provider.dart`, `lib/models/user_progress.dart`, `pubspec.yaml`, backend
- **description**: Backend endpoint that accepts student context (mastery progress, current scriptures, seminary curriculum week, recent activity) and returns AI-generated content. System prompt embodies seminary mastery philosophy. Rate limiting + token budget per user/day. Content safety filtering. Graceful offline fallback.
- **acceptance_criteria**:
  - [ ] Backend endpoint accepts student context, returns AI responses
  - [ ] System prompt captures find/understand/apply philosophy
  - [ ] AI has access to mastery levels, current scriptures, streaks, activity
  - [ ] AI knows student's place in 4-year seminary curriculum
  - [ ] Rate limiting and token budget per user per day
  - [ ] Responses are age-appropriate, faith-affirming, doctrinally sound
  - [ ] Graceful fallback if AI unavailable (cached prompts, offline mode)
  - [ ] Content safety filtering on outputs
- **depends_on**: TASK-100

### TASK-102: Daily Prompt — AI-Generated Home Screen Card

- **status**: `open`
- **priority**: P0
- **estimated_effort**: Medium
- **files_to_touch**: NEW `lib/widgets/daily_prompt_card.dart`, NEW `lib/providers/daily_prompt_provider.dart`, `lib/screens/home_screen.dart`
- **description**: Personalized daily prompt card on home screen. References current scriptures, seminary lesson, or recent activity. "Reflect" button → journal. "Discuss" button → AI chat. Free users see blurred teaser. Offline fallback with generic prompt.
- **acceptance_criteria**:
  - [ ] Daily prompt card on home screen (premium)
  - [ ] Personalized based on current scriptures and progress
  - [ ] Refreshes daily (cached locally, fetched from backend)
  - [ ] "Reflect" → journal entry pre-seeded with prompt
  - [ ] "Discuss" → AI chat with prompt as conversation starter
  - [ ] Free users see blurred teaser with upgrade CTA
  - [ ] Offline fallback with generic scripture-based prompt
- **depends_on**: TASK-101

### TASK-103: AI Chat — Conversational Study Companion

- **status**: `open`
- **priority**: P0
- **estimated_effort**: Large
- **files_to_touch**: NEW `lib/screens/ai_chat_screen.dart`, NEW `lib/providers/ai_chat_provider.dart`, NEW `lib/models/chat_message.dart`, NEW `lib/widgets/chat_bubble.dart`, `lib/app.dart`
- **description**: Full chat with AI companion. Ask questions, discuss passages, get help applying verses. Conversation history persisted locally. Entry from dedicated tab/FAB + "Ask about this scripture" from scripture detail. AI weaves in mastery challenges and journal prompts. Scripture references as tappable links. Free users get 1-2 messages then paywall.
- **acceptance_criteria**:
  - [ ] Chat screen with bubbles, text input, send button
  - [ ] Conversation history persisted locally
  - [ ] Full student context (progress, scriptures, curriculum)
  - [ ] "Ask about this scripture" from scripture detail
  - [ ] AI suggests mastery challenges and journal prompts in conversation
  - [ ] Typing indicator, tappable scripture references
  - [ ] Conversation starters for new chats
  - [ ] Free users: 1-2 messages then paywall
- **depends_on**: TASK-101

---

### Scripture Journal

> AI-prompted reflective journaling — the "apply" pillar. AI generates prompts, student writes, builds a personal scripture study journal over time.

### TASK-104: Scripture Journal — Core

- **status**: `open`
- **priority**: P1
- **estimated_effort**: Large
- **files_to_touch**: NEW `lib/screens/journal_screen.dart`, NEW `lib/screens/journal_entry_screen.dart`, NEW `lib/models/journal_entry.dart`, NEW `lib/providers/journal_provider.dart`, `lib/app.dart`
- **description**: Journal with entries tied to scripture(s). Start from daily prompt, AI chat, or scripture detail. Searchable by date/scripture/keyword. Basic rich text. Hive local + cloud sync. Export to PDF/text.
- **acceptance_criteria**:
  - [ ] Chronological entry list, create with optional scripture tag(s)
  - [ ] Basic rich text (bold, italic, bullet lists)
  - [ ] AI prompt can pre-seed new entry
  - [ ] Filter/search by scripture, date, keyword
  - [ ] Edit capability, tappable scripture tags
  - [ ] Hive local + cloud sync
  - [ ] Export (PDF or plain text)
- **depends_on**: TASK-100

### TASK-105: AI Journal Prompts — Context-Aware Reflection Questions

- **status**: `open`
- **priority**: P1
- **estimated_effort**: Medium
- **files_to_touch**: `lib/providers/journal_provider.dart`, `lib/screens/journal_entry_screen.dart`, `lib/services/ai_service.dart`
- **description**: 2-3 AI reflection prompts when creating a new journal entry. Adapt to mastery level (comprehension for beginners, application/teaching for advanced). Reference curriculum when relevant. Tap to use, dismiss to free-write, regenerate button. Cached for offline.
- **acceptance_criteria**:
  - [ ] 2-3 AI prompts on new journal entry
  - [ ] Adapt to mastery level of tagged scripture(s)
  - [ ] Reference seminary curriculum when relevant
  - [ ] Tap to use, dismiss, or regenerate
  - [ ] Cached for offline
- **depends_on**: TASK-101, TASK-104

---

### Seminary Curriculum Sync

> Aligns study with the official 4-year seminary curriculum. AI and app know what the student is studying this week in class.

### TASK-106: Seminary Curriculum Data & Schedule Engine

- **status**: `open`
- **priority**: P1
- **estimated_effort**: Large
- **files_to_touch**: NEW `lib/models/curriculum.dart`, NEW `lib/providers/curriculum_provider.dart`, NEW `lib/services/curriculum_service.dart`, NEW `lib/data/curriculum_data.dart`
- **description**: Model the 4-year cycle (OT, NT, BoM, D&C). Weekly reading schedule + 25 Doctrinal Mastery scriptures per course. Student selects year, app calculates current week/lesson. AI uses curriculum context. "This week in seminary" on home screen.
- **acceptance_criteria**:
  - [ ] Data model: curriculum year, week, lesson, associated scriptures
  - [ ] Student selects seminary year (onboarding or settings)
  - [ ] Calculate current curriculum week from academic calendar
  - [ ] Provider: current lesson, this week's scriptures, upcoming schedule
  - [ ] AI receives curriculum context with every request
  - [ ] Current-lesson scriptures highlighted in scripture list
  - [ ] "This week in seminary" home screen section (premium)
- **depends_on**: TASK-100

---

### Goals, Alerts & Smart Reminders

> Consistent study habits through customizable goals and intelligent, non-nagging reminders.

### TASK-107: Goal Setting & Tracking

- **status**: `open`
- **priority**: P1
- **estimated_effort**: Medium
- **files_to_touch**: NEW `lib/models/study_goal.dart`, NEW `lib/providers/goals_provider.dart`, NEW `lib/screens/goals_screen.dart`, `lib/screens/home_screen.dart`, `lib/screens/progress_screen.dart`
- **description**: Personal mastery goals ("Master 5 this month," "Study every day," "Familiar on all NT by semester end"). Home screen progress bars. Confetti on completion. AI references goals in prompts. AI-suggested goals based on pace.
- **acceptance_criteria**:
  - [ ] Create goals: scripture count, streak days, mastery level, book completion
  - [ ] Optional deadline and progress tracking
  - [ ] Home screen active goal(s) with progress bar
  - [ ] Completion → confetti + activity feed
  - [ ] AI references goals in daily prompts
  - [ ] Goals screen: active, completed, AI-suggested
- **depends_on**: TASK-100

### TASK-108: Smart Reminders & Push Notifications

- **status**: `open`
- **priority**: P1
- **estimated_effort**: Medium
- **files_to_touch**: NEW `lib/services/notification_service.dart`, NEW `lib/providers/reminder_provider.dart`, `lib/screens/profile_screen.dart`, `pubspec.yaml`, backend
- **description**: Push notifications that help, not nag. Types: daily study reminder, spaced rep review (batched), streak-at-risk, goal deadline, weekly digest. Per-type toggle in settings. AI-personalized copy.
- **acceptance_criteria**:
  - [ ] FCM (or equivalent) integration
  - [ ] Daily study reminder at user-chosen time
  - [ ] Spaced rep review reminders (batched)
  - [ ] Streak-at-risk (evening before break)
  - [ ] Goal deadline + weekly digest
  - [ ] Per-type toggle in profile/settings
  - [ ] AI-personalized notification copy
- **depends_on**: TASK-100, TASK-009

---

### Deep Study Tools

> The "understand" layer — cross-references, historical context, topical chains.

### TASK-109: Cross-References & Scripture Chains

- **status**: `open`
- **priority**: P2
- **estimated_effort**: Large
- **files_to_touch**: NEW `lib/data/cross_references.dart`, NEW `lib/widgets/cross_reference_card.dart`, `lib/screens/scripture_detail_screen.dart`, `lib/models/scripture.dart`
- **description**: Related scriptures by topic on scripture detail. Topical chains (Faith → Alma 32:21, Hebrews 11:1, Ether 12:6, etc.). Tappable navigation. AI references cross-refs in chat. Free users see 1-2, premium sees all.
- **acceptance_criteria**:
  - [ ] Cross-reference data for all 100 scriptures
  - [ ] "Related Scriptures" on scripture detail (premium)
  - [ ] Topical grouping
  - [ ] Tappable references → scripture detail or inline text
  - [ ] AI chat references cross-refs
  - [ ] Free: 1-2 visible, premium: all
- **depends_on**: TASK-100

### TASK-110: Historical Context Cards

- **status**: `open`
- **priority**: P2
- **estimated_effort**: Medium
- **files_to_touch**: NEW `lib/data/historical_context.dart`, NEW `lib/widgets/context_card.dart`, `lib/screens/scripture_detail_screen.dart`
- **description**: Collapsible card per scripture: speaker, audience, setting, narrative, why it matters. Teen-accessible language. AI references context in chat. Free users see teaser (first sentence + blur).
- **acceptance_criteria**:
  - [ ] Context data for all 100 scriptures
  - [ ] Collapsible card on scripture detail
  - [ ] Teen-accessible language
  - [ ] AI references context in discussion
  - [ ] Free: teaser, premium: full
- **depends_on**: TASK-100

---

### Study Groups & Social

> Accountability and community — study with friends, compete with seminary class, share progress.

### TASK-111: Study Groups & Class Leaderboards

- **status**: `open`
- **priority**: P2
- **estimated_effort**: XL
- **files_to_touch**: NEW `lib/screens/groups_screen.dart`, NEW `lib/screens/group_detail_screen.dart`, NEW `lib/models/study_group.dart`, NEW `lib/providers/groups_provider.dart`, `lib/app.dart`, backend
- **description**: Create/join study groups (class, family, friends). Leaderboard, group challenges ("Everyone master John 3:16 this week"), group feed. Seminary teacher role (anonymized class stats). Invite via code/link. Privacy controls.
- **acceptance_criteria**:
  - [ ] Create/join group via invite code or link
  - [ ] Leaderboard: ranked by scriptures mastered
  - [ ] Group challenges: scripture + deadline, member progress
  - [ ] Group feed: milestones and completions (anonymizable)
  - [ ] Teacher role: class aggregate stats (not individual journals)
  - [ ] Leave/remove members, privacy controls
- **depends_on**: TASK-100
- **notes**: Ship minimal version first (leaderboard + challenges), iterate from there.

### TASK-112: Accountability Partners

- **status**: `open`
- **priority**: P2
- **estimated_effort**: Medium
- **files_to_touch**: NEW `lib/screens/accountability_screen.dart`, NEW `lib/providers/accountability_provider.dart`, `lib/screens/progress_screen.dart`
- **description**: Lightweight pairing — two people keeping each other on track. See each other's streaks/milestones, send encouragement, optional weekly auto-summary. Privacy: streaks/milestones only, never journal/chat.
- **acceptance_criteria**:
  - [ ] Invite partner via code/link
  - [ ] Partner dashboard: streaks and milestones
  - [ ] Encouragement messages (pre-written or short custom)
  - [ ] Optional weekly auto-summary
  - [ ] Privacy: no journal or chat access
- **depends_on**: TASK-100

---

### TASK-113: Premium Onboarding & Feature Discovery

- **status**: `open`
- **priority**: P1
- **estimated_effort**: Small
- **files_to_touch**: `lib/screens/onboarding_screen.dart`, `lib/screens/home_screen.dart`, NEW `lib/widgets/premium_teaser.dart`
- **description**: Natural "upgrade moments" for free users — blurred daily prompt, locked AI button, teaser cross-references. Inviting, not aggressive (max 1-2 per screen, dismissible). Premium users get 2-3 onboarding screens for new tools.
- **acceptance_criteria**:
  - [ ] Free-tier onboarding unchanged
  - [ ] Premium teaser widgets: blurred cards, lock icons, "Unlock with Premium"
  - [ ] Teasers on home, scripture detail, progress screens
  - [ ] Premium onboarding: 2-3 screens (AI, journal, goals)
  - [ ] CTAs → paywall screen
  - [ ] Not annoying: max 1-2 per screen, dismissible
- **depends_on**: TASK-100, TASK-013
