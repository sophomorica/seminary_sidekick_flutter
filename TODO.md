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

### Group Play Phase 4 — Premium hosting gate (2026-05-25)

| Task | What | Completed |
|------|------|-----------|
| TASK-058 | Premium gating for group hosting — free hosts capped at 6 players / 1 game per week, premium hosts 30 / unlimited; tasteful upgrade dialog on weekly-limit hit; near/at-cap inline upgrade link (rate-limited). Server-side `bump_host_usage` enforcement is the source of truth. | 2026-05-25 |

### Group Play Polish — Phase 4.5 (2026-06-10)

| Task | What | Completed |
|------|------|-----------|
| TASK-064 | Group play classroom-reliability + reveal polish (owner-directed after 2026-06-10 audit). **(1) Realtime reconnection**: `GroupPlayService._subscribeResilient` wraps all five realtime channels (rooms, players, answers, sb_finishes, broadcast) — auto-resubscribes with 1/2/4/8s backoff on `channelError`/`timedOut`/`closed`, refetches on every (re)subscribe so rows landed while down are never missed; new `service.reconnecting` stream → `GroupPlayState.isReconnecting` → calm `ReconnectingBanner` in live quiz + SB race screens. **(2) Answer-distribution reveal**: new `AnswerDistribution` widget (Kahoot-style per-choice animated bars, correct choice in success green) on the between-question standings view, visible to host AND players. **(3) Reveal animations**: leaderboard rows stagger in bottom-up (5th→1st, suspense beat); podium columns rise in award order (bronze→silver→gold via `PodiumView.goldRevealDelay`); results confetti now fires WITH the gold reveal instead of on a bare screen. **(4) Audio placeholders**: `countdown_tick.txt`, `group_join.txt`, `streak_milestone.txt` added to `assets/audio/` per the TASK-045 convention (owner sources real audio). CLAUDE.md refreshed to current reality (group play shipped, structure, providers, launch-readiness status). | 2026-06-10 |

### Launch Readiness — Crash Reporting & Audio (2026-06-10 → 2026-06-13)

| Task | What | Completed |
|------|------|-----------|
| TASK-063 | Crash reporting & error analytics (Sentry) — `crash_reporting_service.dart` init gate on `SENTRY_DSN` (silent no-op without it), uncaught Flutter/Dart/native capture via `appRunner`, privacy-locked (no PII / screenshots / user content), premium tag + route/tab breadcrumbs. | 2026-06-10 |
| TASK-045 | Replaced agent-generated `.wav` SFX with real CC0 audio (Freesound) for all 7 sounds; wired `countdown_tick` / `group_join` / `streak_milestone`; `AudioNotifier` now fails gracefully per-effect. Provenance in `assets/audio/AUDIO_CREDITS.md`. | 2026-06-13 |

### RevenueCat / Store Identity Launch Wiring (2026-06-13)

| Task | What | Completed |
|------|------|-----------|
| (untracked, owner-paired) | **End-to-end purchase wiring + store setup.** Code: real `purchases_flutter` calls in `subscription_provider.dart` (`purchasePlan`/`restorePurchases`/`_syncWithRevenueCat`/`_loadOfferings`) gated on the `premium` entitlement; `main.dart` `_maybeInitPurchases()` configures the SDK from `REVENUECAT_IOS_KEY`/`REVENUECAT_ANDROID_KEY` dart-defines (free-tier no-op without them); `upgrade_screen.dart` shows live localized prices and the CTA was relabeled **"Start Free Trial" → "Subscribe"** (no intro offer planned). Pricing **$4.99/mo, $34.99/yr ("Save 42%")**. **Bundle ID** `com.seminarysidekick.app` set across `ios/Runner.xcodeproj` (6 entries) + Android `applicationId`. **App Store Connect**: app record created, subscription group "Seminary Sidekick Premium" with monthly (`seminary_sidekick_monthly`, $4.99) + yearly (`seminary_sidekick_yearly`, $34.99) incl. localizations. **RevenueCat dashboard**: App Store app configured (In-App Purchase `.p8` key), `premium` entitlement, both products attached, `default` offering (current) serves the App Store products in its Monthly/Annual packages; iOS public SDK key stored in gitignored `.env`. See `REVENUECAT_SETUP.md`. | 2026-06-13 |

### Launch Safety / Security / Privacy (2026-06-13)

| Task | What | Completed |
|------|------|-----------|
| (untracked, owner-paired) | **Sidekick safety + xAI key security + privacy/deletion (iOS launch blockers).** (1) **Safety prompt** — `sidekick_service.dart` prompts share a `_safetyGuardrails` block: age-appropriate/minors, no-doctrinal-authority disclaimer (defer to teacher/parent/bishop), stay-on-topic refusals, crisis→trusted-adult redirect, no disparagement. (2) **xAI key off the client** — new `sidekick-proxy` Supabase Edge Function (`supabase/functions/sidekick-proxy/index.ts`) holds `XAI_API_KEY` server-side + prepends the safety prompt; `sidekick_service.dart` calls it via `functions.invoke` (no more `--dart-define=XAI_API_KEY`). (3) **In-app data deletion** — Settings → "Delete All My Data" (`lib/services/data_reset_service.dart`) clears all Hive boxes + signs out the anon Supabase session + reloads providers. (4) **Privacy policy** — Settings links to `https://seminarysidekick.com/privacy` via new `url_launcher` dep. | 2026-06-13 |

**Remaining owner steps (Sidekick / privacy):**

- ✅ **Done 2026-06-13** — proxy deployed + secret set: `XAI_API_KEY` secret is set and `sidekick-proxy` is live (`supabase functions list` → ACTIVE, v1). The xAI key lives only as a Supabase secret (the `.env` copy is an inert reference; the app never reads it).
- Confirm the privacy policy is actually live at `https://seminarysidekick.com/privacy` and add that URL to the App Store listing (App Privacy section).
- `flutter pub get` (new `url_launcher` dependency), then `flutter analyze` + `flutter test`, and smoke-test Sidekick + the delete-data flow on device.

**Remaining owner steps (RevenueCat / store):**

- **Android**: create the two subscriptions in Play Console, add the Play app + service-account JSON in RevenueCat, then put the `goog_…` key in `.env` as `REVENUECAT_ANDROID_KEY`.
- **App Store Connect API key** (optional): products currently show "Could not check" in RevenueCat — add the App Store Connect API key (or wait for Apple approval) to enable product/price import + sync.
- **Submit a build** to clear the subscriptions' "Missing Metadata" status (also needs a review screenshot per subscription).
- **Tidy-up**: delete the leftover sample **"Seminary Sidekick Pro"** entitlement + Test Store products in RevenueCat (left for owner — deletion).
- Android release signing. (Privacy policy / account deletion and Sidekick safety + xAI key backend proxy are now done — see the Sidekick/privacy section above; proxy deployed 2026-06-13.)

---

## Active Tasks

> **Group Play status (2026-06-13)**: Quiz-mode v1 + Scripture Builder Race SHIPPED end-to-end, plus Phase 4.5 polish (TASK-064: stream reconnection, answer-distribution reveal, reveal animations) and real audio (TASK-045, done — incl. group-play sounds: countdown tick, lobby join, streak milestone). Remaining: TASK-059 (saved rosters), TASK-061 (analytics), and the TASK-051 owner smoke test.
>
> | Phase | Tasks | Status | Parallel? |
> |---|---|---|---|
> | 4 | TASK-058 (premium gating) **DONE**, TASK-059 (saved rosters), TASK-061 (analytics) | partial | TASK-059 unblocked — only one editor at a time on service + host_lobby |
> | 5a | TASK-047 (shared scope picker) | **DONE 2026-05-25** | — |
> | 5b | **TASK-062 (Scripture Builder Race)** | **DONE 2026-05-25** — migrations deployed (`0005`/`0006` pushed; `supabase migration list` shows local+remote in sync through 0006 as of 2026-06-13). Pending owner: two-instance smoke test | — |

> **Scope guardrail for group play**: NONE of the existing solo features are being modified. Scripture Builder, solo Quick Quiz, solo Scripture Match, mastery tracking, journal, Sidekick AI all remain exactly as they are. Touch only:
> - `pubspec.yaml`, `lib/main.dart`, `lib/app.dart`
> - `lib/screens/practice_hub_screen.dart` (entry-point card)
> - `lib/screens/home/home_screen.dart` (Play with Friends CTA)
>
> Everything else is NEW files under `lib/screens/group_play/`, `lib/services/group_play_service.dart`, `lib/providers/group_play_provider.dart`, `lib/models/group_*.dart`.

### ✅ Done — pending only an owner sanity check

These tasks are **code-complete** and summarized in the Completed tables above; their full specs live in git history. The only thing left on each is a manual check the agent sandbox can't run (no Flutter SDK, no second device). Not code blockers — worth ticking before submit:

- [ ] **Run the suite locally** — `flutter pub get && flutter analyze && flutter test` (covers TASK-045, TASK-063, and the Sidekick/RevenueCat work).
- [ ] **TASK-045 audio ear-check** — play through Scripture Builder / Quick Quiz / Match / group lobby + quiz countdown; re-pick any sound that doesn't land. (One open call: the `streak_milestone` chime is wired to the per-scripture answer streak `[5,10,25,50,100]`, not a daily-streak event — flag if you want a true daily-streak chime.)
- [ ] **TASK-058 free-tier cap** — with `forcePremium: false`, confirm a free host can create exactly 1 room/week (2nd attempt shows the upgrade dialog).
- [ ] **TASK-051 / TASK-062 two-instance smoke test** — host + 2nd device: create a quiz room AND a Scripture Builder race, verify live realtime sync; confirm a group SB race leaves solo mastery/streak/progress untouched (the decoupling invariant). (This is also TASK-051's remaining acceptance criterion below.)

### TASK-065: Premium "Missionary Scriptures" pack (curated unlock)

- **status**: `open`
- **priority**: P2 (post-launch premium expansion — not a launch blocker)
- **estimated_effort**: Medium (data + paywall gating + collection UI; the heavy lifting is in keeping the core-100 mastery math untouched)
- **claimed_by**: —
- **description**: Add a second, curated scripture collection — **Missionary Scriptures** — that is locked behind the existing premium subscription. Free users see it as a locked collection with a premium teaser; premium users get the full Study → Build → Prove → Master loop on it, exactly like the core 100. This is a new reason to upgrade that sits alongside Sidekick AI and premium group hosting.
- **decisions_made** (owner, 2026-06-13):
  - **Curated only — NO user-added scriptures.** Letting users paste their own scriptures risks poorly-copied / mistyped text feeding the mastery engine (which checks production word-for-word). The unlock is a hand-curated, app-shipped set only.
  - **Gated by the existing premium subscription** (default assumption), not a separate one-time IAP. "Upgrade to unlock" reuses the current `isPremiumProvider` gate and `upgrade_screen.dart` — no new RevenueCat product unless we later decide to sell the pack standalone.
- **open_questions** (owner to resolve before build):
  - [ ] **Which scriptures?** Owner is undecided on the exact list. Likely candidates: common Preach My Gospel / missionary-prep proselytizing scriptures (e.g. Moroni 10:4–5, James 1:5, Malachi 3:8–10, 1 Nephi 3:7, etc.). Owner defines the final set + count. Until then this task is **not buildable past the data-model scaffolding.**
  - [ ] **Pack size / future packs?** Decide whether "Missionary Scriptures" is a one-off or the first of several premium packs (e.g. "Old Testament heroes", "Christmas scriptures"). If multiple are likely, the data model should carry a generic `collection`/`pack` identifier rather than a single boolean.
- **design_decisions_to_settle** (recommendations in italics):
  - **Mastery accounting**: missionary scriptures should get the full mastery loop but **stay a separate collection** so they don't dilute the headline "X of 100 mastered" stat. *Recommend: core-100 stats stay 0–100; missionary pack has its own progress strip/ring; aggregate "all started/mastered" stats can sum both, but the canonical "100 Doctrinal Mastery" number must not change.*
  - **Data model**: the 100 use string ids `'1'..'100'`. *Recommend adding a `collection`/`pack` field to `Scripture` (default `doctrinalMastery`) and giving missionary entries non-numeric ids (e.g. `'m1'`, `'m2'`) so nothing that assumes `1..100` breaks. Audit every place that hard-codes `100` or `length` against the full scripture list (mastery stats, progress ring denominators, onboarding copy).*
  - **Gating granularity**: lock at the collection level (whole pack visible-but-locked with a teaser), not per-scripture. *Recommend a locked `BookCard`/collection tile in the scripture list → tapping a locked missionary scripture routes to `upgrade_screen.dart`.*
- **acceptance_criteria** (provisional — finalize once the scripture list is chosen):
  - [ ] Curated missionary scripture entries added to the data layer with a `collection`/`pack` discriminator; core 100 unchanged and still report as exactly 100.
  - [ ] Free users: missionary collection is visible but locked; tapping it surfaces a premium teaser → upgrade flow. No way to start Builder/quizzes on locked scriptures.
  - [ ] Premium users: missionary scriptures behave identically to the core 100 (detail screen, Scripture Builder all 4 tiers, Memorize, practice quizzes, mastery progression).
  - [ ] Mastery/stat math audited: the "100 Doctrinal Mastery" headline number and progress-ring denominators do not regress when the pack exists; missionary progress tracked separately.
  - [ ] Group Play scope picker either excludes the missionary pack or includes it only for premium hosts (decide; default: exclude from v1 to avoid mixed free/premium room scope).
  - [ ] No user-add-scripture surface anywhere (explicitly out of scope).
  - [ ] `flutter analyze` clean; existing solo + group flows unaffected.
- **files_to_touch** (anticipated): `lib/data/scriptures_data.dart`, `lib/models/scripture.dart` (add `collection`/`pack`), `lib/models/enums.dart` (collection enum if generic), mastery/stat providers that assume 100 (`scripture_mastery_provider.dart`, `progress_provider.dart`, home/progress stat widgets), scripture list + book-collections UI, `upgrade_screen.dart` / `premium_teaser.dart` (locked-collection teaser).
- **depends_on**: owner picking the scripture list (open question above).
- **notes**:
  - Reuse `isPremiumProvider` and the existing `PremiumGate` / teaser widgets — do not invent a new entitlement.
  - Keep the curated text held to the same word-for-word quality bar as the core 100 (the mastery engine is unforgiving on production); double-check punctuation/verse-stripping against `scripture.dart`'s `words` auto-split.
  - If owner later wants a standalone (non-subscription) purchase, that's a separate RevenueCat product — note it but don't build it here.

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
    - Premium price ($4.99/mo or $2.92/mo yearly — $34.99/yr, "Save 42%"; updated 2026-06-13). Group hosting becomes one more reason to subscribe alongside the existing Sidekick AI bundle.
  - **V1 scope limited to Quick Quiz only.** Scripture Match in group form is a v2 question — drag-and-drop multiplayer is awkward. Scripture Builder (race-mode) added to v1.5 as TASK-062 (2026-05-25 decision).
  - **Cost ceiling at the worst credible adoption** (~100K MAU, ~10K concurrent peak): roughly $2K–5K/mo on Supabase Realtime. Premium revenue at that scale ($15K–25K/mo at 5% conversion) covers it comfortably. We do NOT need to architect against this scale on day one — Pro tier ($25/mo, 500 concurrent) is fine for a long time.
  - **Future cost optimization** (NOT v1): WebRTC peer-to-peer with Supabase as signaling, or migrating the Realtime layer to Cloudflare Durable Objects. Both are v2 levers, mentioned here so the data model doesn't paint itself into a corner.

### TASK-051: Supabase dashboard verification (smoke test only)

- **status**: `partial` — migrations deployed (0001–0006, local+remote in sync per `supabase migration list` 2026-06-13); smoke test still pending
- **priority**: P0
- **estimated_effort**: Small
- **claimed_by**: —
- **description**: Code is done (migrations in `supabase/migrations/`, runbook in `SUPABASE_SETUP.md`, owner has run the dashboard steps and pushed all migrations). Only remaining acceptance criterion:
  - [ ] **Verifying agent step**: smoke test in SUPABASE_SETUP.md passes — anonymous user can create a room and a second device can see it via realtime
- **notes**:
  - Service-role key stays out of the Flutter app forever. anon key is safe to ship.
  - Default free-tier limits (200 concurrent connections, 5GB DB) are way more than this app needs in dev or even early adoption.

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

## Cleanup & Parking Lot

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
