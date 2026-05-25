# Seminary Sidekick — Task Board

> **How this file works**: Single source of truth for what needs to be done.
> Agents claim tasks by setting `status: in_progress` and `claimed_by`. Mark `done` when complete.
> Always read fresh before starting. Commit claim before writing code.
>
> Full details on completed tasks are in git history.

---

## Completed Tasks (summary — see git history for details)

### Free-Tier MVP (2026-03-19 → 2026-04-06)

| Task | What | Completed |
|------|------|-----------|
| TASK-001 | Hive persistence for progress | 2026-03-19 |
| TASK-002 | Quick Quiz game | 2026-03-19 |
| TASK-003 | Wire game results → progress provider | 2026-03-28 |
| TASK-004 | Per-scripture notes (Hive-backed) | 2026-03-23 |
| TASK-005 | Sound effects & audio feedback | 2026-03-30 |
| TASK-006 | Confetti celebrations | 2026-03-23 |
| TASK-007 | Practice from scripture detail | 2026-03-30 |
| TASK-008 | Speech-to-text for Master typing | 2026-03-30 |
| TASK-009 | Spaced repetition (SM-2) | 2026-04-06 |
| TASK-010 | Recent activity feed | 2026-04-06 |
| TASK-011 | Game-specific difficulty descriptions | 2026-03-28 |
| TASK-012 | Dark mode | 2026-03-30 |
| TASK-013 | Onboarding — mastery path tutorial | 2026-04-06 |
| TASK-020 | Test infrastructure | 2026-03-28 |
| TASK-021 | Model unit tests | 2026-03-30 |
| TASK-022 | Progress provider tests | 2026-03-30 |
| TASK-023 | Scripture provider tests | 2026-03-30 |
| TASK-024 | Matching game provider tests | 2026-03-30 |
| TASK-025 | Word builder provider tests | 2026-03-30 |
| TASK-026 | Holistic mastery system — data layer | 2026-04-02 |
| TASK-027 | Holistic mastery system — UI integration | 2026-04-02 |
| TASK-028 | Scripture Builder-centric mastery path (redesign v2) | 2026-04-02 |
| TASK-029 | Mastery system tests (40 tests) | 2026-04-02 |
| TASK-030 | Move Scripture Builder under scripture detail | 2026-04-02 |
| TASK-031 | Mastery shortcut — prove it at Master, skip the ladder | 2026-04-06 |
| TASK-032 | Rename Games Hub → Practice/Quizzes | 2026-04-06 |

### Premium Tier / Seminary Sidekick AI (2026-04-06 → 2026-04-07)

| Task | What | Completed |
|------|------|-----------|
| TASK-033 | Freemium infrastructure (SubscriptionProvider, UpgradeScreen, PremiumTeaser, RevenueCat wiring) | 2026-04-06 |
| TASK-034 | Sidekick AI core service — Grok integration, snapshot/response models, chat, offline fallback | 2026-04-06 |
| TASK-035 | AI-powered journal & dynamic reflection prompts | 2026-04-07 |
| TASK-036 | AI-driven goals, timeline & gentle reminders | 2026-04-07 |
| TASK-037 | "Ask Your Sidekick" chat screen | 2026-04-07 |
| TASK-038 | Premium polish — voice-to-journal, export, family sharing | 2026-04-07 |
| TASK-039 | Premium teaser placements (home, scripture detail, onboarding) | 2026-04-06 |
| TASK-040 | Subtle engagement enhancements (quick wins, nearly-mastered nudges) | 2026-04-07 |

### Deployment Readiness (2026-04-11)

| Task | What | Completed |
|------|------|-----------|
| TASK-041 | Settings screen, UserPreferences provider, study streak, dynamic greeting | 2026-04-11 |
| TASK-042 | Wire theme toggle (reads from `themeProvider`) | 2026-04-11 |
| TASK-043 | Wire text size / font scale via `MaterialApp.builder` + `MediaQuery` | 2026-04-11 |
| TASK-044 | HapticService routes all haptics through preference toggle | 2026-04-11 |

### Post-MVP Home Reorientation (2026-05-05)

| Task | What | Completed |
|------|------|-----------|
| TASK-046 | Reorient Home to "Let's Learn / Let's Play" — dashboard moved to Stats tab, resume hero card with mastery pip indicator (new `lib/providers/resume_target_provider.dart`). Stale section files (`book_collections_section.dart`, `nearly_mastered_section.dart`, `quick_sessions_section.dart`, `premium_home_section.dart`, `stats_section.dart`) left untouched — future cleanup. | 2026-05-05 |

### Group Play Phase 1–3 (2026-05-07 → 2026-05-25)

| Task | What | Completed |
|------|------|-----------|
| TASK-051 (code) | Supabase migrations + RLS + realtime + SUPABASE_SETUP.md — **dashboard verification step still open, see Active** | code 2026-05-07 |
| TASK-052 | Group play foundation — models, GroupPlayService, GroupPlayNotifier, route stubs, Supabase init in `main.dart`, `quiz_question_factory.dart` extraction | 2026-05-07 |
| TASK-053 | Host lobby screen (setup view + lobby view, 4-letter code, QR, live roster, kick, start) | 2026-05-07 |
| TASK-054 | Join lobby screen (code+nickname entry, error banner, waiting view, auto-nav on phase) | 2026-05-07 |
| TASK-055 | Live group quiz screen (host/player views, countdown, leaderboard with rank deltas, confetti) | 2026-05-07 |
| TASK-056 | Group results screen (podium, leaderboard, share, Play Again reuses scope) | 2026-05-07 |
| TASK-057 | Practice Hub & Home entry points for group play | 2026-05-07 |
| TASK-060 | Nickname profanity filter (`NicknameValidator`, l33t normalization, 51-word seed list, 20 unit tests) | 2026-05-07 |

### Phase 5a — Shared scope picker (2026-05-25)

| Task | What | Completed |
|------|------|-----------|
| TASK-047 | Shared `ScriptureScope` model + Hive-backed `scriptureScopeProvider` + `ScriptureScopePicker` widget. Wired into Practice Hub (Quick Quiz / Scripture Match open a setup sheet with difficulty + scope + question-count override) and group play host lobby (replaces the minimal book chips). `QuizGameNotifier.startGame` and `MatchingGameNotifier.startGame` now accept optional `targetQuestionCount` / `targetPairCount` for "Every scripture in scope". | 2026-05-25 |
| TASK-049 | Dead `_selectedBooks` / `_selectedDifficulty` fields on Practice Hub quiz/match cards removed (absorbed by TASK-047). | 2026-05-25 |

### Phase 5b — Scripture Builder Race (2026-05-25)

| Task | What | Completed |
|------|------|-----------|
| TASK-062 | Group Scripture Builder race (second group-play game type). `GroupGameMode.scriptureBuilder` + `GroupSbConfig` + `GroupSbFinish` models with backward-compat JSON; supabase migration `0005_group_sb_finishes.sql` with RLS + realtime; `GroupPlayService.submitSbFinish/watchSbFinishes/hostAdvanceScripture`; notifier sbFinishes subscription + sbConfig + submit dedup; forked chunk-tap board (`SbRaceBoard`) decoupled from progress_provider; `GroupScriptureBuilderScreen` with host dashboard + player race view + DNF timer + per-mode finish flow (Round-by-Round vs Set-of-N); host-lobby game-mode selector; conditional auto-nav on phase transition; SB-flavored results with per-mode ranking. Added mounted-guards to all GroupPlayNotifier stream listeners. 34 new tests (594 total, all green). | 2026-05-25 |

---

## Active Tasks

> **Group Play status (2026-05-25)**: Quiz-mode v1 SHIPPED end-to-end. Phase 4 polish (TASK-058/059/061) is queued. Phase 5 expands to a second game type: Scripture Builder Race (TASK-062), which requires the shared scope picker (TASK-047) to land first.
>
> | Phase | Tasks | Status | Parallel? |
> |---|---|---|---|
> | 4 | TASK-058 (premium gating), TASK-059 (saved rosters), TASK-061 (analytics) | open | TASK-058/059 serial — both edit service + host_lobby |
> | 5a | TASK-047 (shared scope picker) | **DONE 2026-05-25** | — |
> | 5b | **TASK-062 (Scripture Builder Race)** | **DONE 2026-05-25** — pending owner: `supabase db push` for `0005_group_sb_finishes.sql` + two-instance smoke test | — |

> **Scope guardrail for group play**: NONE of the existing solo features are being modified. Scripture Builder, solo Quick Quiz, solo Scripture Match, mastery tracking, journal, Sidekick AI all remain exactly as they are. Touch only:
> - `pubspec.yaml`, `lib/main.dart`, `lib/app.dart`
> - `lib/screens/practice_hub_screen.dart` (entry-point card)
> - `lib/screens/home/home_screen.dart` (Play with Friends CTA)
>
> Everything else is NEW files under `lib/screens/group_play/`, `lib/services/group_play_service.dart`, `lib/providers/group_play_provider.dart`, `lib/models/group_*.dart`.

### TASK-045: Replace agent-generated sound effects with real audio

- **status**: `open`
- **priority**: P0
- **estimated_effort**: Small (agent work is just placeholders; user ships the real audio)
- **claimed_by**: —
- **files_to_touch**: `assets/audio/correct.wav`, `assets/audio/incorrect.wav`, `assets/audio/complete.wav`, `assets/audio/levelup.wav`, NEW `.txt` placeholders in `assets/audio/`, `CLAUDE.md` (already updated)
- **description**: The four `.wav` files under `assets/audio/` were generated by a prior agent (Python/TTS) and sound terrible. Owner will replace them manually. Mirrors the existing image-asset convention.
- **acceptance_criteria**:
  - [ ] Delete or rename the four existing `.wav` files so they don't ship
  - [ ] Create `correct.txt`, `incorrect.txt`, `complete.txt`, `levelup.txt` in `assets/audio/` following the new convention in `CLAUDE.md` (description, sourcing hints, duration/format, reference examples)
  - [ ] Verify `AudioNotifier.init()` fails gracefully when the real `.wav`s are missing (don't crash the app — log and no-op `play()`)
  - [ ] Owner drops in the real audio, deletes the `.txt`s, sanity-checks playback in Scripture Builder / Quick Quiz / Match
- **depends_on**: —
- **notes**:
  - See `lib/services/audio_service.dart` — `SoundEffect` enum paths stay the same; only the underlying files change
  - The new audio convention is documented in `CLAUDE.md` under "Conventions → Audio Assets"
  - Candidate additional sounds to scope while we're here: `streak_milestone`, `group_join`, `countdown_tick` (only if we proceed with Group Play — TASK-048)

### TASK-047: Shared scripture-scope picker (Quick Quiz, Match, Group Play)

- **status**: `done` — see Completed table above
- **completed**: 2026-05-25
- **priority**: P0 — **blocks TASK-062 (Scripture Builder Race) and should land first**
- **estimated_effort**: Medium-Large
- **claimed_by**: claude-opus-4-7
- **started**: 2026-05-25
- **scope_pivot** (2026-05-25): Originally a Quick-Quiz-only setup sheet. Promoted to a **shared picker component** consumed by every game that needs to choose "what's in scope." Group play needs the same UX (host picks scope before starting a room) and so does the upcoming Scripture Builder race mode (TASK-062). Doing this once, well, beats reimplementing it three times.
- **files_to_touch**:
  - NEW `lib/models/scripture_scope.dart` — value type representing a selection
  - NEW `lib/providers/scripture_scope_provider.dart` — Hive-backed last-used scope per game type
  - NEW `lib/widgets/scripture_scope_picker.dart` — reusable widget (modal sheet + inline variant)
  - `lib/screens/practice_hub_screen.dart` — wire setup sheet into Quick Quiz + Match cards, kill dead `_selectedBooks` / `_selectedDifficulty` fields
  - `lib/providers/quiz_game_provider.dart` — accept `ScriptureScope` + optional `targetQuestionCount` override
  - `lib/providers/matching_game_provider.dart` — accept `ScriptureScope`
  - `lib/screens/group_play/host_lobby_screen.dart` — swap minimal v1 picker for the shared widget
  - `lib/screens/group_play/widgets/group_play_scope_picker.dart` — DELETE or replace with thin wrapper around shared widget
  - NEW `test/models/scripture_scope_test.dart`, `test/providers/scripture_scope_provider_test.dart`
- **description**: Build a single scripture-scope picker used everywhere a user (or host) needs to choose "which scriptures are eligible for this session." Used by solo Quick Quiz, solo Scripture Match, group Quiz (replacing minimal v1 picker), and group Scripture Builder race (TASK-062). The provider layer already accepts `bookFilters: List<ScriptureBook>`, but the UI hard-codes `_selectedBooks = {}` and `_selectedDifficulty = beginner` in both `_QuizGameCard` and `_MatchingGameCardState` — so the user has no way to choose. Even with books selected, question count is capped at `difficulty.quizQuestionCount` (10–40), so you can't actually quiz on every scripture in a book at once. Owner's vision: "I want to quiz on all the scriptures eventually." Per-scripture selection is also required for the group Scripture Builder race mode where teachers want to assemble a custom set ("the 10 we've done so far this term").

- **agent_context_block** (read first):
  - **Why this exists as one widget**: three different game setups (Quick Quiz, group Quiz host lobby, group Scripture Builder host lobby) all need the user to answer the same question: "which scriptures count?" Building three pickers diverges UX and triples maintenance. Build one and let each call site supply its own callbacks + persisted-state slot.
  - **Existing data layer to lean on**:
    - `lib/data/scriptures_data.dart` exposes all 100 `Scripture` records.
    - `lib/providers/scripture_provider.dart` already has `scripturesByBookProvider(String)` and `searchScripturesProvider(String)` — use them inside the picker rather than re-querying.
    - `ScriptureBook` enum with `displayName` and `abbreviation` is in `lib/models/enums.dart`.
    - `ScriptureMastery` exposes `needsReview` and `subProgress` per scripture so the "Needs Review" / "Nearly Mastered" presets just filter the existing list.
  - **Solo provider entry points already accept book filters**:
    - `QuizGameNotifier.startGame({required DifficultyLevel difficulty, List<ScriptureBook> bookFilters = const []})` — line ~80 of `quiz_game_provider.dart`
    - `MatchingGameNotifier.startGame(...)` — same shape
    - Only thing missing is per-scripture selection and "every scripture in scope" question-count override.
  - **Group play already takes a scope**: `GroupRoomScope` (in `lib/models/group_room.dart`) has `difficultyName`, `bookNames`, `scriptureIds`, `questionCount`, `questionTimeoutSeconds`. The shared picker's output should map cleanly to it.
  - **Persistence**: `ScriptureScope` should serialize to JSON for Hive. Store one record per `ScopeUsageContext` (`quickQuiz`, `scriptureMatch`, `groupQuiz`, `groupScriptureBuilder`) so each game remembers its own last-used scope.
  - **Don't make this a wizard**: two taps from Practice Hub to "in a quiz" is the target. Defaults to last-used; advanced controls live behind a "Customize" disclosure.

- **acceptance_criteria**:
  - [ ] **NEW model** `lib/models/scripture_scope.dart` — a value type with:
    ```dart
    sealed class ScriptureScope {
      const ScriptureScope();
      Map<String, dynamic> toJson();
      List<Scripture> resolve(List<Scripture> allScriptures, /* optional masteryRef */);
    }
    class ScopeAll extends ScriptureScope { ... }
    class ScopeBooks extends ScriptureScope { final Set<ScriptureBook> books; ... }
    class ScopeScriptureIds extends ScriptureScope { final List<String> ids; ... }
    class ScopeNeedsReview extends ScriptureScope { ... }
    class ScopeNearlyMastered extends ScriptureScope { ... }
    ```
    Plus a `factory ScriptureScope.fromJson(Map)` that dispatches on a `type` discriminator.
  - [ ] **NEW widget** `lib/widgets/scripture_scope_picker.dart`:
    - Three-section sheet (top to bottom): **Quick presets** (chips: "All 100", "Old Testament", "Book of Mormon", "Needs Review", "Nearly Mastered"), **By book** (multi-select chip row across the 4 volumes), **Individual scriptures** (searchable scrollable list with checkboxes — collapsed by default behind a "Pick specific scriptures" disclosure).
    - Search bar at the top of the individual-scriptures section. Filters live as the user types.
    - Selected count + sample preview ("1 Nephi 3:7 + 9 more") always visible at the bottom above the "Use this scope" CTA.
    - "Clear" and "Restore last used" buttons in the sheet header.
    - Renders both as a `showModalBottomSheet` and as an inline form (for use inside the host-lobby setup view). Provide a `ScriptureScopePicker` widget API + `showScriptureScopePicker(...)` helper.
  - [ ] **NEW provider** `lib/providers/scripture_scope_provider.dart` (Hive-backed, follows the same pattern as `UserPreferencesNotifier`):
    - `lastUsedScope(ScopeUsageContext context) → ScriptureScope?`
    - `saveScope(ScopeUsageContext context, ScriptureScope scope)`
    - Survives app restart.
  - [ ] **`QuizGameNotifier.startGame` accepts an optional `targetQuestionCount` param** so the cap can be bypassed for "every scripture in scope". Default behavior unchanged (uses `difficulty.quizQuestionCount`).
  - [ ] **`MatchingGameNotifier.startGame` accepts the same `ScriptureScope`** — Master already signals "use all"; extend it for explicit per-book / per-scripture scopes.
  - [ ] **Practice Hub Quick Quiz card and Scripture Match card** each open a setup sheet on tap with:
    - Difficulty selector (same as Scripture Builder selector at top of Practice Hub)
    - `ScriptureScopePicker` widget for scope
    - "Question count" segmented control with default (per difficulty) + "Every scripture in scope" option that pipes `targetQuestionCount = resolved.length` to the notifier
    - "Start" CTA at the bottom
  - [ ] **Host lobby setup view** (`host_lobby_screen.dart`) swaps its inline `_BookChips` minimal picker for the shared widget. `_handleCreate` builds `GroupRoomScope` from the picker output: `ScopeAll` → empty `bookNames` + empty `scriptureIds`, `ScopeBooks` → `bookNames = books.map((b) => b.name)`, `ScopeScriptureIds` → `scriptureIds`, etc.
  - [ ] **Dead state removed**: `_selectedBooks` and `_selectedDifficulty` fields in `_QuizGameCardState` and `_MatchingGameCardState` are gone (closes TASK-049 inside this PR).
  - [ ] **Tests**:
    - `scripture_scope_test.dart` — JSON round-trip for each variant; `resolve()` returns the right scripture list against a fixture of 5 scriptures across 2 books
    - `scripture_scope_provider_test.dart` — save + load per-context, scopes don't bleed between contexts
  - [ ] `flutter analyze` clean. Existing solo Quick Quiz / Match flows still work end-to-end (manual smoke test: launch app, start Quick Quiz with default scope, confirm a 10-question game runs as before).

- **depends_on**: —

- **notes**:
  - **TASK-049 closes inside this PR** — killing the dead `_selectedBooks` / `_selectedDifficulty` fields is part of "Practice Hub Quick Quiz card and Match card open a setup sheet." Mark TASK-049 done in the same commit.
  - `QuizGameNotifier._selectProportionally` already handles arbitrary book lists correctly, so most of the data layer is done.
  - For the picker UX, model the "Pick specific scriptures" section after how email apps let you pick recipients — search at top, scrollable list, checkboxes, running tally at the bottom. Don't overload the user with all 100 visible at once before they search/filter.
  - **`MatchingGameNotifier` watch-out**: `MatchPair` list gets long when scope is "all 100". Confirm `matching_game_screen.dart` handles 100-pair sessions (pagination, scroll, or sub-rounds) — if it breaks, file a follow-up but don't block this task on it.
  - **Don't introduce `ScopeUsageContext` as a Hive enum** — use a `String` key (`'quickQuiz'`, `'groupQuiz'`, etc.) so we can add new contexts without migrations.
  - **Group-play host-lobby fallback**: if a host has no last-used scope for `groupQuiz`, default to `ScopeAll` (matches current minimal-picker behavior). Same for `groupScriptureBuilder` once TASK-062 lands.

### TASK-048: Seminary Group Play (Kahoot-style multiplayer) — UMBRELLA, decomposed

- **status**: `decomposed` — DO NOT CLAIM. See TASK-051 through TASK-062.
- **priority**: P1
- **decisions_made** (owner-reviewed 2026-05-05):
  - **Backend: Supabase** (Realtime + Postgres + Anonymous Auth). Owner already runs Supabase for another project so the platform skill is in-house. A new dedicated Supabase project will be created for this app to isolate quotas/billing.
  - **Architecture: cloud-relay**, host as a *logical* role (not a websocket server on the host's device). All participants are clients of Supabase; the host is just the player whose actions advance the quiz.
  - **No accounts for students.** Anonymous auth + nickname + 4-letter code.
  - **Free vs. Premium split**:
    - JOINING is always free. No exceptions, no caps, no signup.
    - HOSTING tiered: free hosts can run a *Casual* room (cap 6 players, 1 game/week). Premium hosts get *Class* rooms (cap 30, unlimited games, saved rosters, post-game analytics).
    - Premium price unchanged ($2.99/mo or $1.67/mo yearly). Group hosting becomes one more reason to subscribe alongside the existing Sidekick AI bundle.
  - **V1 scope limited to Quick Quiz only.** Scripture Match in group form is a v2 question — drag-and-drop multiplayer is awkward. Scripture Builder (race-mode) added to v1.5 as TASK-062 (2026-05-25 decision).
  - **Cost ceiling at the worst credible adoption** (~100K MAU, ~10K concurrent peak): roughly $2K–5K/mo on Supabase Realtime. Premium revenue at that scale ($15K–25K/mo at 5% conversion) covers it comfortably. We do NOT need to architect against this scale on day one — Pro tier ($25/mo, 500 concurrent) is fine for a long time.
  - **Future cost optimization** (NOT v1): WebRTC peer-to-peer with Supabase as signaling, or migrating the Realtime layer to Cloudflare Durable Objects. Both are v2 levers, mentioned here so the data model doesn't paint itself into a corner.

### TASK-051: Supabase dashboard verification (smoke test only)

- **status**: `partial` — migrations + setup doc shipped; smoke test still pending
- **priority**: P0
- **estimated_effort**: Small
- **claimed_by**: —
- **description**: Code is done (migrations in `supabase/migrations/`, runbook in `SUPABASE_SETUP.md`, owner has run the dashboard steps). Only remaining acceptance criterion:
  - [ ] **Verifying agent step**: smoke test in SUPABASE_SETUP.md passes — anonymous user can create a room and a second device can see it via realtime
- **notes**:
  - Service-role key stays out of the Flutter app forever. anon key is safe to ship.
  - Default free-tier limits (200 concurrent connections, 5GB DB) are way more than this app needs in dev or even early adoption.

### TASK-058: Premium gating for group hosting

- **status**: `in_progress`
- **priority**: P1
- **estimated_effort**: Small-Medium
- **claimed_by**: claude-opus-4-7
- **started**: 2026-05-25
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

---

## Active — Group Play Phase 5: Scripture Builder Race Mode (owner-decided 2026-05-25)

> **Why this is its own phase**: TASK-051..TASK-061 shipped a Quiz-only v1 of group play. Owner has now decided that Scripture Builder belongs in group play too — but as a **race mode**, fully decoupled from personal mastery. Personal solo Scripture Builder is untouched. Don't refactor or "share" the solo Scripture Builder screen — copy what's useful, fork what isn't, and keep group play in `lib/screens/group_play/` and `lib/services/group_play_service.dart`.
>
> **Owner decisions baked into the design**:
> - **Decoupled from personal mastery.** Group Scripture Builder finishes are NOT written to `progress_provider`. No streak, no mastery level change, no spaced-repetition bump. The classroom race is purely social.
> - **Chunk-tap difficulties only for v1.** Beginner (3-word chunks) and Intermediate (2-word chunks + distractors). Typing-based Advanced/Master are deferred — owner's seminary teaching experience: "most kids won't be able to type the answers very well."
> - **Two play modes, host-selected at room creation**:
>   1. **Round-by-Round** — host advances one scripture at a time. Per-scripture race: fastest correct completion wins the round. Cumulative score determines overall winner.
>   2. **Set-of-N** — host picks N scriptures. Queue starts simultaneously; each player works through all N in order. First player to finish all N wins. Cumulative elapsed time determines runners-up.
> - **Per-scripture host selection is a hard requirement.** Teachers want to assemble a custom set ("the 10 we've done so far this term"). This is why TASK-047 promotes the scope picker into a shared component.
> - **Future, not v1**: bracketed finals, head-to-head 1v1 round, "finals round" of top 4. Mentioned in `notes` of TASK-062 so the data model leaves room.

### TASK-062: Scripture Builder Race Mode (group play — second game type)

- **status**: `done` — code complete 2026-05-25; owner still needs to run `supabase db push` for `0005_group_sb_finishes.sql` and the two-instance smoke test before marking the dashboard step closed
- **priority**: P1
- **estimated_effort**: Large
- **claimed_by**: claude-opus-4-7
- **started**: 2026-05-25
- **completed**: 2026-05-25
- **files_to_touch**:
  - **Model extensions** (additive only, backward-compatible with shipped Quiz rooms):
    - `lib/models/group_room.dart` — add `GroupGameMode` enum (`quiz`, `scriptureBuilder`); add `mode` and `scriptureBuilderConfig` fields to `GroupRoomScope`; default `mode = quiz` so existing rooms deserialize unchanged
  - **New models**:
    - NEW `lib/models/group_sb_config.dart` — `GroupSbConfig` (chunkDifficulty: `beginner` | `intermediate`, playMode: `roundByRound` | `setOfN`, scriptureIds: `List<String>`, perScriptureTimeoutSeconds: `int?`)
    - NEW `lib/models/group_sb_finish.dart` — `GroupSbFinish` (id, roomId, playerId, scriptureIndex, elapsedMs, mistakeCount, completedAt, rankInRound) — mirrors `GroupAnswer` shape so the Supabase table is analogous
  - **Schema**:
    - NEW `supabase/migrations/0005_group_sb_finishes.sql` — `group_sb_finishes` table with RLS (player can insert own, host can read all in room), `room_id` index, `REPLICA IDENTITY FULL` for realtime DELETE delivery
    - Add `group_sb_finishes` to the realtime publication (same migration or extend `0003_realtime.sql`)
  - **Service additions** in `lib/services/group_play_service.dart`:
    - `submitSbFinish({required GroupRoom room, required GroupPlayer player, required int scriptureIndex, required int elapsedMs, required int mistakeCount})`
    - `hostAdvanceScripture(GroupRoom room)` — increments `current_question_index` analogously to `advanceQuestion` (the column is already named generically enough to handle both quiz and SB modes)
    - `watchSbFinishes(String roomId) → Stream<List<GroupSbFinish>>`
  - **Provider**:
    - Extend `GroupPlayState` with `sbFinishes: List<GroupSbFinish>` (default empty) and `sbConfig: GroupSbConfig?` (resolved from `room.scope.scriptureBuilderConfig` at room load time)
    - Extend `GroupPlayNotifier` with `submitSbFinish(...)`, `hostAdvanceScripture()`, `_sbFinishesSub` stream subscription
  - **Screens**:
    - NEW `lib/screens/group_play/group_scripture_builder_screen.dart` — the live race screen (host view + player view)
    - NEW `lib/screens/group_play/widgets/sb_race_board.dart` — chunk-tap board widget (forked / copied from solo `scripture_builder_screen.dart`, NOT shared — see notes)
    - NEW `lib/screens/group_play/widgets/sb_host_progress_dashboard.dart` — host's view of who has finished / who is still racing
    - NEW `lib/screens/group_play/widgets/sb_finish_banner.dart` — per-player "✓ Finished — 8.2s, 1 mistake" banner
  - **Host lobby updates**:
    - `lib/screens/group_play/host_lobby_screen.dart` — add a game-mode selector at the top of the setup view (Quiz / Scripture Builder Race). Conditional reveal of mode-specific settings (chunk-tap difficulty + play mode + set size for SB; existing question count + difficulty for Quiz). Wires `GroupGameMode` and `GroupSbConfig` into the `GroupRoomScope` passed to `hostCreateRoom`
  - **Routing**:
    - `lib/app.dart` — add `/group-play/word-builder/:code` route → `GroupScriptureBuilderScreen`
    - Host lobby + join lobby auto-route on `phase == inQuiz`: branch on `room.scope.mode` — `quiz` → `/group-play/quiz/:code` (existing), `scriptureBuilder` → `/group-play/word-builder/:code`
  - **Results screen** (`lib/screens/group_play/group_results_screen.dart`) — extend to render Word-Builder-flavored results when `room.scope.mode == scriptureBuilder`. Reuses podium + leaderboard but pulls per-player stats from `state.sbFinishes` instead of `state.answers`
  - **Tests**:
    - NEW `test/models/group_sb_config_test.dart` — JSON round-trip, backward compat (a `GroupRoomScope` JSON without a `mode` key still parses as `mode = quiz`)
    - NEW `test/models/group_sb_finish_test.dart` — JSON round-trip, equality
    - NEW `test/providers/group_play_provider_sb_test.dart` — covers `submitSbFinish` updating state correctly, host advance flow, "all players finished" detection

- **description**: Add Scripture Builder as a second group-play game type — a multiplayer race where players reassemble scripture text via chunk-tap (Beginner: 3-word chunks; Intermediate: 2-word chunks + distractors). Two host-selected play modes: **Round-by-Round** (host advances one scripture at a time, per-scripture fastest wins the round, cumulative score across rounds) and **Set-of-N** (host picks N scriptures, players race through all N in order, first to finish the set wins). Completely decoupled from personal mastery — group finishes never write to `progress_provider`. Host can pick the exact scripture list using the TASK-047 shared scope picker.

- **agent_context_block** (read first):
  - **Templates to copy from**:
    - `lib/screens/group_play/group_quiz_screen.dart` — the canonical pattern for live group play screens: host view vs player view branching, `ref.listen<GroupPlayPhase>` for navigation, local-UI-phase enum for between-question (here: between-scripture) leaderboard reveals.
    - `lib/screens/group_play/host_lobby_screen.dart` and `join_lobby_screen.dart` — theme usage, `_ErrorBanner` style, dark-mode handling, leave-confirm flow.
    - `lib/screens/games/scripture_builder/scripture_builder_screen.dart` — the solo chunk-tap board. **Copy what's needed into `sb_race_board.dart`; do NOT share.** Reason: solo Scripture Builder is tied to personal mastery and progress recording; group race must NEVER touch `progress_provider`. Sharing the screen invites accidental cross-contamination during future edits. Forking is cheap insurance.
  - **Solo Scripture Builder chunk logic to mirror** (see `lib/providers/scripture_builder_provider.dart`):
    - Beginner: `chunkSize = 3`, no distractors
    - Intermediate: `chunkSize = 2`, distractors from other scriptures (use `quiz_question_factory.dart` distractor-pool pattern; respect the in-scope filter rule established in the recent TASK-055 follow-up — distractors must come from in-scope scriptures only)
    - On wrong chunk tap: increment local `mistakeCount`, visual shake, no scoring penalty in v1 (just tracked for results). Owner can decide later whether mistakes subtract from score.
  - **Provider state surface** (after this task lands):
    - `groupPlayProvider.state.sbConfig` → `GroupSbConfig?` (null if mode == quiz)
    - `groupPlayProvider.state.sbFinishes` → `List<GroupSbFinish>` — full list of finishes for the room across all scriptures in the set
    - For Round-by-Round: filter `sbFinishes` by `scriptureIndex == room.currentQuestionIndex` to get current-round leaderboard
    - For Set-of-N: group `sbFinishes` by `playerId`; a player has finished the set when their finish count == `sbConfig.scriptureIds.length`
  - **Scoring**:
    - **Round-by-Round**: same speed-weighted formula as quiz (`computeSpeedWeightedPoints` in `group_answer.dart`), applied per round. Wrong-chunk mistakes do NOT subtract points in v1 (display-only). Cumulative score determines overall winner.
    - **Set-of-N**: rank is by total elapsed time across the set, ascending (faster = better). Tie-breaker: fewer mistakes. Display each player's running total during the race.
  - **Realtime delivery**:
    - `sb_finishes` subscription via Postgres Changes with `room_id` filter (mirrors `watchAnswers` pattern)
    - Host pushes "next scripture" via the existing `rooms.current_question_index` update (no new broadcast channel needed)
    - For set-of-N mode, `current_question_index` is irrelevant after start — players advance independently on their own device. Host's dashboard reads `sbFinishes` count per player to show progress.
  - **Per-scripture timeout** (`sbConfig.perScriptureTimeoutSeconds`): optional. Default null (no timeout). When set, on expiry a `GroupSbFinish` row is inserted server-side or client-side with `mistakeCount = -1` to indicate DNF. **Defer the server-side enforcement to v2** — client-side timer + auto-DNF insert is sufficient for v1.
  - **Host advances on "all finished" or manual**: in Round-by-Round, host sees a "Next Scripture" button that lights up when all live players have finished (or earlier if the host wants to move on). In Set-of-N, host's only controls are "End Game" and a live progress dashboard.

- **acceptance_criteria**:

  ### Model + schema
  - [ ] `GroupGameMode` enum added to `group_room.dart` with `quiz` and `scriptureBuilder` variants. `GroupRoomScope` gains a `mode: GroupGameMode` field (default `quiz`) and a `scriptureBuilderConfig: GroupSbConfig?` field. JSON round-trip preserves backward compat: a scope JSON without a `mode` key still parses as `quiz`.
  - [ ] `GroupSbConfig` model with `copyWith`, `fromJson`/`toJson`, equality.
  - [ ] `GroupSbFinish` model with same shape as `GroupAnswer` (id, roomId, playerId, scriptureIndex, elapsedMs, mistakeCount, completedAt). `copyWith`, `fromJson`/`toJson`, equality.
  - [ ] `0005_group_sb_finishes.sql` migration creates the table with RLS:
    - SELECT: players in the room can read (host needs to see all; players see all for live leaderboard)
    - INSERT: only the authenticated player whose `player_id` matches `players.user_id` for that row in this room
    - No UPDATE / DELETE policies (finishes are immutable)
    - `REPLICA IDENTITY FULL`
    - Added to `supabase_realtime` publication
  - [ ] Owner runs `supabase db push` and the migration applies cleanly to the existing project (no destructive changes to shipped tables).

  ### Service + provider
  - [ ] `GroupPlayService.submitSbFinish(...)` inserts a row, returns the inserted `GroupSbFinish`. Throws `GroupPlayException` on RLS rejection or network failure (mirrors `submitAnswer` error handling).
  - [ ] `GroupPlayService.watchSbFinishes(roomId)` returns a stream of `List<GroupSbFinish>` ordered by `completed_at` ascending. Mirrors `watchAnswers` exactly.
  - [ ] `GroupPlayService.hostAdvanceScripture(room)` — increments `current_question_index`, ends the room when past the last scripture in `sbConfig.scriptureIds`. Mirrors `advanceQuestion`. (Alternatively: just reuse `advanceQuestion` and let the index column do double duty — explicit alias method is fine if it makes call sites read better.)
  - [ ] `GroupPlayNotifier`:
    - Subscribes to `watchSbFinishes` when entering a SB room; cancels in `_disposeStreams`
    - Exposes `submitSbFinish({scriptureIndex, elapsedMs, mistakeCount})` and `hostAdvanceScripture()`
    - `state.sbFinishes` updates in real-time
    - For Round-by-Round, the existing `room.currentQuestionIndex` advancement reuses `_localPhase` reset on index change (same pattern as quiz)

  ### Screens
  - [ ] `GroupScriptureBuilderScreen` renders:
    - **Player view**: `SbRaceBoard` widget with chunk-tap UI. Live "race position" indicator at the top ("You: 2nd · Sarah finished 6.4s ago"). On completion, finish banner with elapsed time + mistake count. Set-of-N mode: also shows "Scripture 3 of 10" pill and a running total elapsed time.
    - **Host view**: chunk-tap board hidden; instead shows `SbHostProgressDashboard` — list of all players with their current state (still racing / finished — Xs / DNF). In Round-by-Round: "Next Scripture" button enabled once all live players have finished (or "Skip ahead" available immediately). In Set-of-N: "End Game" button + live progress bars per player ("Sarah: 7 of 10").
  - [ ] `SbRaceBoard` widget is a forked clone of the solo board — **does NOT import `scripture_builder_provider.dart`**. It owns its own local chunk state via `ConsumerStatefulWidget`. On completion, it calls back via a `onFinish(elapsedMs, mistakeCount)` callback, NOT into `progress_provider`.
  - [ ] `SbHostProgressDashboard` and `SbFinishBanner` extracted as widgets, dark-mode aware.
  - [ ] **Host lobby setup view** has a game-mode segmented control at the top (Quiz / Scripture Builder Race). Selecting Scripture Builder Race reveals:
    - Chunk-tap difficulty selector (Beginner / Intermediate)
    - Play mode selector (Round-by-Round / Set-of-N)
    - Scope picker (`ScriptureScopePicker` from TASK-047)
    - For Set-of-N: a numeric "Set size" field, capped at 30
    - For Round-by-Round: no extra field (host advances manually)
  - [ ] On "Create Room", the host lobby builds the `GroupRoomScope` with `mode = scriptureBuilder` and the resolved `GroupSbConfig`. `hostCreateRoom` ships unchanged — it just passes the scope through.
  - [ ] Auto-navigation: when `phase == inQuiz`, both host and player branch on `room.scope.mode`:
    - `quiz` → `/group-play/quiz/:code` (existing)
    - `scriptureBuilder` → `/group-play/word-builder/:code`
    `ref.listen<GroupPlayPhase>` lives in both the host lobby and the join lobby — both need this branching.

  ### Results
  - [ ] Group results screen renders SB-flavored results when `room.scope.mode == scriptureBuilder`:
    - Podium top 3 (rank determined by mode: Round-by-Round → cumulative round wins or cumulative speed-weighted points; Set-of-N → total elapsed time ascending, mistakes as tiebreaker)
    - Leaderboard rows show per-mode stats: round-by-round → "X round wins · Ys total time", set-of-N → "Finished in Xs · Y mistakes"
    - "Play Again" reuses the same `GroupRoomScope` (including `sbConfig`) — owner explicitly wants the same set repeatable for a "best of 3" feel

  ### Tests + verification
  - [ ] `flutter analyze` clean across all new files
  - [ ] All new unit tests pass; existing 500+ test suite remains green
  - [ ] **Manual smoke test** (owner step, two-instance setup — iOS Simulator + Chrome): host creates a Scripture Builder room with 3 scriptures in Round-by-Round mode, joins from second instance, races through, sees per-round leaderboard, ends game, sees correct results.
  - [ ] **Decoupling sanity check**: after a Group SB race, verify in the second instance's solo Scripture Builder + Stats that NO mastery / streak / progress changed. This is the critical correctness invariant.

- **depends_on**:
  - **Strongly recommended sequencing**: land TASK-047 first. SB host setup uses the shared scope picker; building it twice is a waste. If TASK-047 is still open when an agent claims TASK-062, the agent should pause and land TASK-047 first, then resume.
  - TASK-052 — done. SB rides on the foundation laid for Quiz.
  - TASK-055 — done. SB screen patterns the live quiz screen architecture.
  - TASK-056 — done. SB results extends the existing results screen.

- **notes**:
  - **NOT v1 — leave room in the data model but do not build**:
    - Bracketed finals / head-to-head 1v1 elimination round
    - "Finals round" of top 4 with the same scripture set
    - Per-mistake score penalties (currently display-only)
    - Server-side timeout enforcement (client-side auto-DNF is fine for v1)
    - Mixed-mode rooms (Quiz round → SB round → Quiz round). The mode is frozen at room creation in v1.
  - **Why a separate SB board widget instead of sharing the solo one**: solo Scripture Builder is tightly coupled to `ScriptureBuilderNotifier` which records to `progress_provider`. The risk of a future refactor accidentally importing progress recording into the group race is real. Forking the widget is one of those "10 minutes of duplication saves 10 hours of debugging" decisions.
  - **Distractor scope for Intermediate**: pull from in-scope scriptures only (same rule that landed for Quiz distractors in the TASK-055 follow-up). If the host picks 1 scripture, Intermediate has no distractors and visually degrades to Beginner-ish — that's fine, document it.
  - **Set-of-N upper bound**: cap at 30 to match the premium room player cap. A 30-scripture race is already extreme; defer "all 100 race" as v2.
  - **Confetti budget**: fire confetti when the local player finishes (700ms, ~14 particles), NOT on every player's finish — a class of 30 finishing in a 10-second window would overlap badly.
  - **Premium gating**: Scripture Builder race respects the same hosting tier from TASK-058 — free hosts can run it within their 1 game/week + 6 player cap; premium hosts get unlimited + 30 cap. No new premium gate needed beyond the existing hosting gate.

---

## Cleanup & Parking Lot

### TASK-049: Kill the dead difficulty/book state on Quick Quiz & Match cards

- **status**: `done` — closed as part of TASK-047 (2026-05-25)
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
