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
│ ├── group_play_state.dart # Aggregate state for GroupPlayNotifier
│ └── announcement.dart # Broadcast in-app banner (Supabase)
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
│ ├── announcement_provider.dart # Supabase announcements + Hive dismissals
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
│ ├── announcement_service.dart # Supabase fetch for in-app Home announcements
│ ├── group_play_service.dart # All Supabase calls + resilient realtime streams
│ ├── quiz_question_factory.dart # Shared question generation (solo + group)
│ ├── nickname_validator.dart # Group play nickname profanity filter
│ └── crash_reporting_service.dart # Sentry wrapper: init gate, breadcrumbs, tags
├── widgets/
│ ├── announcement_banner.dart # Dismissible Home banner + detail sheet
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
| `LAUNCH_READINESS_REPORT.md` | 2026-07-01 claim-by-claim verification of all docs against the code; remaining manual submission steps + watch items |
| `crash_reporting_service.dart` | Sentry wrapper — init gate (`SENTRY_DSN`), breadcrumbs, premium tag, `recordError`               |
