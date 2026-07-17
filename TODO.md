# Seminary Sidekick — Task Board

> **How this file works**: Single source of truth for what needs to be done.
> Agents claim tasks by setting `status: in_progress` and `claimed_by`. Mark `done` when complete.
> Always read fresh before starting. Commit claim before writing code.
>
> Full details on completed tasks are in git history.

---

## 🚀 Launch Status (updated 2026-07-15)

**iOS v1.0.1 — SUBMITTED** (in App Store review). Marketing version **1.0.1**. Always archive with `./scripts/build_ios_release.sh` (loads `.env`, hard-fails if `REVENUECAT_IOS_KEY` / `SUPABASE_URL` / `SUPABASE_ANON_KEY` are missing).

**All App Store submission blockers resolved (owner):**

- [X] **Paid Apps Agreement** Active (banking + tax complete)
- [X] **3.1.2(c) EULA** — Privacy Policy + Terms of Use links on upgrade screen; standard EULA in App Description (passed review on prior cycle)
- [X] **2.1(b) Subscribe** — root cause was bare archive without RevenueCat dart-defines; fixed via `./scripts/build_ios_release.sh` + Sentry on purchase failure paths; **1.0.1** built/submitted with defines
- [X] Subscriptions attached; listing, screenshots, privacy labels, age rating, sidekick-proxy premium gate enforcing

No remaining App Store Connect / banking / EULA / IAP blockers for this submission. Watch ASC + email only if review asks a new question.

**Owner open items (not submission blockers — post-approval / product hygiene):**

- [ ] **Supabase free-tier auto-pause** — project pauses after ~7 days idle (already bit us during screenshots); kills Group Play and Sidekick AI. Upgrade to Pro (~$25/mo) or keep-alive **before real users arrive**.
- [ ] **After approval — RevenueCat tidy-up**: delete leftover sample "Seminary Sidekick Pro" entitlement + Test Store products.
- [ ] **TASK-051 two-instance realtime smoke test** before relying on Group Play at class scale.
- [ ] **TASK-045 audio ear-check** on device (see sanity-check list below).
- [ ] **Android launch** (separate effort): Play Console products, `REVENUECAT_ANDROID_KEY`, release signing — see `REVENUECAT_SETUP.md` Step 2.

**Rejection / build history (resolved — keep for context):**

| When | Version | Outcome |
|------|---------|---------|
| 2026-07-04 | 1.0.0 (1) | Processing reject ITMS-91061 (`share_plus` privacy manifest) → fixed ^10.1.4 |
| 2026-07-05 | 1.0.0 (2) | Waiting for review; later **3.1.2(c)** EULA link rejection → fixed + resubmitted as build 3 |
| 2026-07-10 | 1.0.0 (3) | **2.1(b)** Subscribe error (missing RevenueCat dart-defines) → build script + resubmit |
| 2026-07-15 | **1.0.1** | **Submitted** (current) — all prior blockers resolved for this binary |

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

**Owner steps (Sidekick / privacy):** ✅ all done — proxy deployed + `XAI_API_KEY` secret set (2026-06-13); premium entitlement gate enforcing via `REVENUECAT_SECRET_KEY` (2026-07-04); privacy policy live at `https://seminarysidekick.com/privacy` and on the App Store listing; `flutter analyze` clean + `flutter test` green (2026-07-03).

**Owner steps (RevenueCat / store):** "Missing Metadata" ✅ cleared 2026-07-04; iOS subscriptions wired and submitted with the app. **iOS v1.0.1 is submitted** (see Launch Status). Still open (Launch Status): Android (Play Console products + `REVENUECAT_ANDROID_KEY` + release signing), optional App Store Connect API key for RevenueCat product sync, post-approval sample-entitlement tidy-up.

### Journal Discoverability & App Store Submission (2026-07-02 → 2026-07-04)

| Task | What | Completed |
|------|------|-----------|
| TASK-066 | Journal discoverability redesign — always-present Home journal card ("Acquiring Spiritual Knowledge" framing; premium teaser for free users; new `lib/screens/home/journal_card.dart`), Sidekick chat "Save to journal" chips (`JournalNotifier.addQuickEntry`, no-navigation save + snackbar), scripture-detail reflect link restyled as a full-width `OutlinedButton`, journal auto-creates an entry when launched with a scripture. Verified: `flutter analyze` clean, 604/604 tests. | 2026-07-02 |
| (untracked, owner-paired) | **App Store submission.** Sentry project + `SENTRY_DSN` wired via `.env` dart-define; MAINT-004 typing-punctuation fix (+2 regression tests); sidekick-proxy RevenueCat entitlement gate shipped and later set enforcing (2026-07-04); 9 iPhone 6.9" + 5 iPad 13" screenshots; full ASC metadata (listing copy, keywords, privacy labels, age rating, review info); subscription group localization + per-sub review screenshots + availability; app priced Free, worldwide availability; `flutter build ipa` + Transporter upload; build attached; **submitted for review 2026-07-04**. | 2026-07-04 |

---

## Active Tasks

### TASK-072: Game-complete redesign — animated score meter + mastery avatar (solo)

- **status**: `done`
- **claimed_by**: cursor-bc-3c69e6be
- **started**: 2026-07-15T18:25:06Z
- **completed**: 2026-07-15T18:45:00Z
- **priority**: P2
- **estimated_effort**: Medium-Large
- **files_to_touch**: `lib/screens/games/game_results_screen.dart` (rewrite), `lib/services/score_story_engine.dart` (new, pure Dart), `lib/widgets/score_meter.dart` (new), `lib/widgets/mastery_avatar.dart` (new), `lib/providers/progress_provider.dart` (add avatar-stage getter), `lib/models/enums.dart` (⚠️ shared file — new `AvatarStage` enum), `assets/images/avatar_stage*.txt` (already created), `pubspec.yaml` (⚠️ shared — asset entries only if needed), `test/screens/game_results_screen_test.dart` (update), new tests
- **description**: Replace the three-star results page with an animated "score story": a half-circle gauge (no needle) that score events feed one at a time, misses knock back, ending in a dramatic pause → final score pop + word grade → mastery-avatar level-up morphs. Prototypes approved by owner 2026-07-15 (Cowork session): v1 layout, ~25% faster pacing, dramatic pause, avatar morphs AFTER the total.

  **A. Score model — new `ScoreStoryEngine` (pure Dart, display-only).** Input: the fields `GameResultsScreen` already receives (`correctMatches`, `incorrectAttempts`, `totalPairs`, `completionTime`, `difficulty`, `gameType`). Output: `ScoreStory` = ordered list of `ScoreEvent{label, points, isMiss, icon}` + `finalScore` (0–1000) + `grade`. Categories (do NOT invent data we don't track — no streak):
  1. `Accuracy` — up to 600 pts: `600 * correct / (correct + incorrect)`.
  2. `Speed bonus` — up to 250 pts: scale from per-difficulty par times (define consts per gameType/difficulty; generous, tune later).
  3. `Misses` — one negative event, `-20 × incorrectAttempts` capped at −150 (0 misses → skip event, emit `Flawless +50` instead).
  4. `Finish bonus` — flat +150 for completing the round.
  Rounding: final score clamped 0–1000, ints only. Grades: ≥900 `Masterful`, ≥750 `Strong`, ≥500 `Getting there`, else `Keep practicing`. Word grade REPLACES stars everywhere on this screen; the providers' `starRating` getters stay (other call sites + tests) but the results screen no longer reads them.
  **Event order**: Accuracy → Speed → Misses (or Flawless) → Finish — misses deliberately mid-sequence so the meter climbs, takes the hit, recovers.

  **B. Meter widget — `ScoreMeter` (CustomPainter, model on `lib/widgets/progress_ring.dart`).** Half-circle arc, 16px stroke, rounded caps, track in outline/border color. Fill color by fraction: <0.4 `AppTheme.error`, <0.7 `AppTheme.warning`, else `AppTheme.success`. Center: scrolling integer total (tween with `easeOutCubic`), word grade below. Sequence per event: label+points chip fades in above (icon + `+N`/`−N`, success/error color) → arc tweens to new total (~640ms gains / ~330ms misses) → chip fades, receipt row appears in the stats list below (label left, signed points right, misses in error color). Miss extras: horizontal shake of the whole card (~220ms) + `HapticService.heavy()`; gains get `light()`. After last event: number blanks ~750ms (dramatic pause) → final score pops in with overshoot scale + grade + `medium()` haptic. Confetti (existing `ConfettiController` pattern) ONLY when grade is Masterful or `isNewMastery`.

  **C. Avatar — `MasteryAvatar` + `AvatarStage`.** No overall user level exists today (VERIFIED: only per-scripture `MasteryLevel` + `ProgressStats.totalMastered`). Derive stage from `totalMastered` via a new getter on `ProgressStats`: `0–2 → stage1, 3–9 → stage2, 10–24 → stage3, 25+ → stage4` (make thresholds named consts — owner will tune). Stages/art (`assets/images/`, `.txt` placeholders until art exists — render a placeholder circle w/ stage icon + name until PNGs land): 1 `Quick to Observe` (Mormon 1:2) → 2 `Stalwart` (2 Ne 31:20) → 3 `Stripling Warrior` (Alma 53) → 4 `Standard Bearer` (Alma 46, mini Captain Moroni hoisting the rent cloak). Placement: under the gauge, avatar circle + stage name/`Stage N of 4`. During the run: small hop on gains, flinch/rotate on misses. Level-up: compute stage from `totalMastered` BEFORE vs AFTER this round's progress write; if changed, after the final-score pop play morph(s): scale-down+rotate out → swap stage → overshoot scale in + expanding ring. Multi-stage jumps cascade ~0.7s each; entire results sequence is tap-to-skip (tap anywhere → jump to final state, all events in receipt list, correct final stage). `SoundEffect.levelup` on morph.

  **D. Integration.** `GameResultsScreen` keeps its public constructor signature (callers in matching/quiz/scripture-builder screens unchanged). Internally: build `ScoreStory`, drive the sequence with an `AnimationController`/async sequence, keep `isNewMastery` banner (after morphs). Remove star row + `AppTheme.gold` star usage from this screen.
- **acceptance_criteria**:
  - [x] `ScoreStoryEngine` unit tests: category math, clamping, 0-miss Flawless path, grade thresholds, event ordering, determinism
  - [x] `ScoreMeter` + sequence widget tests: events render in order, receipt rows accumulate, final score/grade shown, tap-to-skip lands final state (use `HapticService.disabled()` override; avoid confetti path in settle tests per existing harness trick)
  - [x] Avatar stage getter unit tests incl. threshold boundaries; morph cascade fires only when stage changed by this round
  - [x] Misses knock meter down mid-sequence w/ shake + heavy haptic; dramatic pause before final pop; confetti only Masterful/new-mastery
  - [x] No stars on solo results; providers' `starRating` untouched and green
  - [x] Display-only: no changes to mastery/progress WRITE paths (engine consumes existing fields)
  - [x] No generated images — placeholder rendering until owner supplies PNGs for the four `avatar_stage*.txt` specs
  - [x] `AppTheme.*` tokens only, no hardcoded colors/styles; `flutter analyze` clean; `flutter test` green (existing `game_results_screen_test.dart` updated)
- **notes**:
  - Stage before/after inferred via `isNewMastery` + current `totalMastered` (constructor unchanged). Morph after final-score pop; tap-to-skip jumps to final state.
  - Group Play parity is TASK-073.

### TASK-073: Group Play quiz — personal score-meter moment (scoped parity with TASK-072)

- **status**: `done`
- **claimed_by**: cursor-bc-3c69e6be
- **started**: 2026-07-15T18:45:00Z
- **completed**: 2026-07-15T19:05:00Z
- **priority**: P3
- **estimated_effort**: Small-Medium
- **files_to_touch**: `lib/screens/group_play/group_results_screen.dart`, possibly `lib/services/score_story_engine.dart` (group-quiz adapter), tests
- **description**: Full visual parity with the solo redesign is NOT a small lift (VERIFIED 2026-07-15: `GroupResultsScreen` shares no widgets with solo; SB race scoring is time/rank-based and doesn't map to a 0–1000 meter). Scoped goal instead: in **quiz mode only**, show the local player a brief personal `ScoreMeter` moment (their `GroupPlayer.score` normalized against the round max — points are already speed-weighted, `maxPoints 1000`/question in `group_answer.dart`) ABOVE the podium reveal, compressed (~2s, 2–3 events: accuracy, speed, misses), then flow into the existing podium/leaderboard. SB race results unchanged. No mastery avatar in Group Play (Group Play never writes mastery — avatar staging is a personal-progress concept).
- **acceptance_criteria**:
  - [x] Quiz-mode group results open with the local player's compressed meter story, then podium as today
  - [x] SB race (roundByRound + setOfN) results byte-for-byte behavior unchanged
  - [x] No writes to personal mastery/progress from Group Play (unchanged invariant)
  - [x] Reuses `ScoreMeter` widget — no forked copy
  - [x] `flutter analyze` clean; `flutter test` green incl. existing group tests
- **notes**:
  - Uses shared `CompressedScoreStory` + `ScoreStoryEngine.buildGroupQuiz` (normalize `me.score` vs `questionCount * 1000`). Compact `ScoreMeter` stays above podium after the moment. Confetti delayed until meter completes in quiz mode; SB confetti timing unchanged.

### TASK-074: Star-copy sweep — align tutorials/pages with meter grades + avatar journey

- **status**: `done`
- **claimed_by**: cursor-bc-3c69e6be
- **started**: 2026-07-15T19:05:53Z
- **completed**: 2026-07-15T19:10:00Z
- **priority**: P2 (onboarding currently teaches a rating system that no longer exists on results)
- **estimated_effort**: Small-Medium
- **files_to_touch**: `lib/screens/onboarding/mastery_page.dart` (and sibling onboarding pages as found), any other screens/copy that reference results stars (sweep required), `docs/FEATURES.md` / `docs/OVERVIEW.md` if they describe star ratings, affected widget tests
- **description**: TASK-072 replaced the three-star results rating with the score meter (word grades: Masterful/Strong/Getting there/Keep practicing) + mastery avatar (Quick to Observe → Stalwart → Stripling Warrior → Standard Bearer, derived from `UserStats.avatarStage`). Sweep the app for anywhere SB, quiz, or matching results are described — tutorials, onboarding, hub cards, help/empty states, docs — and update the framing: it's no longer "earn three stars", it's your score grade on the meter and where you are on the avatar journey.
  **Sweep starting points (VERIFIED 2026-07-15, not exhaustive — grep for star/stars/rating in lib/ and docs/):**
  - `lib/screens/onboarding/mastery_page.dart` — shows a 3-star row. ⚠️ CAUTION: those stars illustrate "3 perfect Master runs = Mastered" (`consecutivePerfectMaster`), NOT the removed results rating. The mechanic is unchanged; only the VISUAL should stop using stars (e.g., three check/shield pips, or a mini avatar-journey strip). Do not change mastery rules.
  - `lib/screens/group_play/widgets/sb_finish_banner.dart` — mid-race per-finish stars (`GroupSbFinish.starRatingFor`). Group Play kept stars intentionally in TASK-073; leave the logic, but if copy anywhere calls it the same system as solo results, decouple the wording. Escalate before changing group visuals.
  - Non-issues found in sweep (icon-only, unrelated): `settings_screen.dart`, `activity_tile.dart`; `book_collections_section.dart` is a known-stale file — skip.
- **acceptance_criteria**:
  - [x] No user-facing copy or tutorial anywhere describes solo game results as stars/three-stars
  - [x] Onboarding mastery page teaches: meter + word grade on results, avatar journey as the long-term progression; "3 perfect Master runs = Mastered" mechanic still communicated, just without star iconography
  - [x] Where results are referenced for SB, quiz, AND matching (all three share `GameResultsScreen`), framing is grade + avatar stage
  - [x] `docs/FEATURES.md`/`docs/OVERVIEW.md` updated if they describe the old rating
  - [x] Mastery/progress rules untouched (copy/visual sweep only); `flutter analyze` clean; `flutter test` green (onboarding widget tests updated if they assert stars)
- **notes**:
  - Mastery onboarding: check-circle pips for perfect runs; cards for score meter grades + `AvatarStage` strip.
  - Quizzes onboarding copy points at the shared meter/grade. Group SB finish stars left; comments decoupled from solo results.
  - Docs: FEATURES/OVERVIEW/CONVENTIONS/TESTING updated.

### TASK-071: Scripture Builder Master — word-commit typing (autocorrect-friendly)

- **status**: `done`
- **priority**: P1 (owner: Master is near-impossible on phone keyboards — typo = full reset, autocorrect disabled)
- **estimated_effort**: Medium
- **claimed_by**: claude-pebw48
- **started**: 2026-07-15T00:00:00Z
- **completed**: 2026-07-15T00:00:00Z
- **files_to_touch**: `lib/services/word_commit_engine.dart` (new), `lib/providers/scripture_builder_provider.dart`, `lib/screens/games/scripture_builder/scripture_builder_screen.dart`, `lib/screens/games/scripture_builder/typing_input_field.dart` (new), `lib/screens/games/scripture_builder/typed_display_rules.dart`, `lib/models/enums.dart`, `lib/screens/onboarding/scripture_builder_page.dart`, `docs/FEATURES.md`, tests
- **description**: Change Master's unit of judgment from character to word. The field holds only the word in progress with OS autocorrect ON; the word is judged when committed with the spacebar (the moment autocorrect fires), normalized case/punctuation-insensitively. Wrong word = full reset (unchanged penalty). Backspace within the buffer is free. Matching lives in a pure-Dart `WordCommitEngine` so a future Group Play typing tier reuses identical rules (Group Play SB is chunk-tap only today — nothing to change there now).
- **acceptance_criteria**:
  - [x] Master: nothing judged mid-word; space/done commits; autocorrect rewrites ("cjeck" → "check ", "ofthe" → "of the ") pass the formatter (≤3-word insertions) and commit cleanly
  - [x] Wrong committed word = full verse reset (unchanged); one `incorrectAttempt` per wrong word
  - [x] Dash-joined words ("faith—faith") committable one word at a time or as one span; apostrophe/comma words match with or without punctuation
  - [x] Final word commits via space or the keyboard done key (never judged mid-typing — no early completion on a prefix of a longer wrong word)
  - [x] Advanced per-character behavior unchanged (regression: existing tests pass)
  - [x] Scoring/progress/mastery pathways unchanged (typedChars-based math intact)
  - [x] `flutter analyze` clean, `flutter test` green
- **notes**:
  - Needs an on-device iOS pass before release: autocorrect fires on space, clear-on-commit vs composing region, reset refocus (widget tests can't cover IME behavior).

### TASK-070: Ask Sidekick hot buttons + dark-mode contrast

- **status**: `done`
- **priority**: P1 (hot buttons open chat but never send; dark mode Ask card / chat hard to read)
- **estimated_effort**: Small
- **claimed_by**: cursor-agent-3eb0
- **started**: 2026-07-14T17:22:00Z
- **completed**: 2026-07-14T17:35:00Z
- **files_to_touch**: `lib/screens/sidekick_chat/sidekick_chat_screen.dart`, `lib/screens/scripture_detail/scripture_detail_screen.dart`, `lib/screens/sidekick_chat/chat_bubble.dart`, `lib/screens/sidekick_chat/chat_input.dart`, `lib/screens/sidekick_chat/chat_empty_state.dart`, `lib/screens/sidekick_chat/typing_indicator.dart`, `test/screens/sidekick_chat_auto_send_test.dart`
- **description**: From scripture detail "Ask Your Sidekick", tapping a starter chip opens `SidekickChatScreen` with `initialMessage`, but `_sendInitialContextMessage` bailed when persisted chat history was non-empty — so the question never sent. Separately, the Ask card hardcoded `AppTheme.tertiary` (#6F5A10) which is nearly invisible on midnight dark surfaces; user chat bubbles also used light-mode navy on dark navy.
- **acceptance_criteria**:
  - [x] Tapping a scripture-detail starter chip clears prior chat and sends that question (fresh context)
  - [x] "Or ask anything" / scripture-only open still only auto-sends when chat is empty
  - [x] Ask Sidekick card + chips use dark-mode-aware `sidekickColor` (readable on dark)
  - [x] Chat user bubbles / send affordance / timestamps readable in dark mode
  - [x] `flutter analyze` clean; tests cover auto-send decision
- **notes**:
  - Hot-button starters **clear chat then send** (fresh context; journal is the keep path).
  - `decideSidekickAutoOpen` (+ tests) covers premium skip, clear-and-send, and empty-only generic open; provider race test covers clearChat vs in-flight send.
  - Ask card / chips / chat chrome switched to `AppTheme.sidekickColor` + colorScheme tokens; user bubbles use `colorScheme.primary` in dark.
  - No `Switch.adaptive` change needed — `activeThumbColor` analyzes clean on Flutter 3.44.6 (earlier note claiming a rename to `activeColor` was wrong).
  - In-flight harden: `clearChat` bumps chat epoch + clears `isLoadingChat`; stale completions discarded; `_hasAutoSentInitial` only set when `sendMessage` returns true; post-frame auto-send checks `mounted`.
  - Verified: `flutter analyze` clean, `flutter test` green.

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

These tasks are **code-complete** and summarized in the Completed tables above; their full specs live in git history. The only thing left on each is a manual check the agent sandbox can't run (no Flutter SDK, no second device). Not code blockers — the app is already submitted; worth ticking before launch-day traffic:

- [x] **Run the suite locally** — done 2026-07-03: `flutter analyze` clean, `flutter test` all green.
- [ ] **TASK-045 audio ear-check** — play through Scripture Builder / Quick Quiz / Match / group lobby + quiz countdown; re-pick any sound that doesn't land. (One open call: the `streak_milestone` chime is wired to the per-scripture answer streak `[5,10,25,50,100]`, not a daily-streak event — flag if you want a true daily-streak chime.)
- [ ] **TASK-058 free-tier cap** — with `forcePremium: false`, confirm a free host can create exactly 1 room/week (2nd attempt shows the upgrade dialog).
- [ ] **TASK-051 / TASK-062 two-instance smoke test** — host + 2nd device: create a quiz room AND a Scripture Builder race, verify live realtime sync; confirm a group SB race leaves solo mastery/streak/progress untouched (the decoupling invariant). (This is also TASK-051's remaining acceptance criterion below.)

### TASK-068: Sidekick chat history policy + context-window bugs

- **status**: `done`
- **priority**: P1 (two live bugs degrade chat quality today; unbounded history is a privacy + UX liability)
- **estimated_effort**: Small
- **claimed_by**: cursor-agent
- **started**: 2026-07-11T14:22:52Z
- **completed**: 2026-07-11T14:30:00Z
- **files_to_touch**: `lib/services/sidekick_service.dart`, `lib/providers/sidekick_provider.dart`, `lib/screens/sidekick_chat/sidekick_chat_screen.dart`
- **description**: Found during chat review (2026-07-11). Chat history currently **never clears**: every message is cached to Hive (`sidekick_cache` → `chat_history`) after each send, reloaded on every launch, with no cap, no expiry, and no user-facing clear action (only Settings → "Delete All My Data" wipes it). Worst case is the current behavior — an ever-growing scroll and Hive blob. Additionally, two bugs in what gets sent to the model:
  1. **Wrong end of the window**: `sidekick_service.dart` `chat()` uses `history.take(20)`, which takes the **first** 20 messages, not the most recent 20 (despite the "Include recent chat history" comment). Once a conversation passes 20 messages, the model permanently sees only the oldest 20 and loses all recent context.
  2. **Duplicate newest message**: `sidekick_provider.dart` `sendMessage()` appends the user message to `updatedHistory` before calling `chat()`, which also appends `userMessage` explicitly — so while history ≤ 20 messages, the newest user message is sent to the API twice.
- **decisions_made** (owner, 2026-07-11):
  - **Do NOT auto-clear on launch** — losing yesterday's conversation mid-thought feels bad. Bound growth with a rolling cap instead.
  - Rationale for less retention generally: the session snapshot (progress context) is rebuilt every launch anyway, so old history has little functional value; the Sidekick is a daily study companion, not a long-term confidant; and chats can contain personal spiritual content from minors.
- **acceptance_criteria**:
  - [x] API context window fixed: send the **last** 20 history messages (e.g. `history.skip(max(0, history.length - 20))` or a sublist), not the first 20
  - [x] Newest user message sent exactly once (pass history *without* the just-added message, or stop appending it separately in the service)
  - [x] **Rolling storage cap**: on every cache write, trim persisted + in-state history to the most recent ~50 messages (constant, easy to tune)
  - [x] **"New conversation" action** in the chat screen app bar (menu or icon) that clears history (state + Hive) with a confirm dialog; empty state reappears
  - [x] "Delete All My Data" still clears chat history (should be free — it wipes all Hive boxes; just verify)
  - [x] `flutter analyze` clean; existing tests green; add provider tests for the trim + the last-20 window if practical
- **notes**:
  - Keep the cap and window as named constants (`_maxStoredMessages = 50`, `_apiHistoryWindow = 20`) — likely to be tuned.
  - No schema/model changes needed; `SidekickMessage` already has `toJson`/`fromJson`.
  - Privacy: never log or Sentry-report chat content while touching these paths (existing rule).
  - **Done 2026-07-11**: `selectRecentChatHistory` (last-N, not first-N) + provider passes prior history so the newest user turn is appended once; `trimChatHistory` / `maxStoredMessages = 50` on load + every cache write; header "New conversation" icon with confirm → `clearChat()`; `DataResetService` already clears `sidekick_cache`; tests in `test/providers/sidekick_chat_history_test.dart`.

### TASK-067: Graceful handling of sidekick-proxy 403 (lapsed subscription) in chat

- **status**: `done`
- **priority**: P1 (real users WILL hit this — it's the guaranteed UX for any mid-session subscription lapse)
- **estimated_effort**: Small
- **claimed_by**: cursor-agent
- **completed**: 2026-07-11T13:40:00Z
- **files_to_touch**: `lib/services/sidekick_service.dart`, `lib/providers/sidekick_provider.dart`, `lib/screens/sidekick_chat/sidekick_chat_screen.dart`, `lib/providers/subscription_provider.dart`
- **description**: Found during safety stress testing (2026-07-11): after ~1 hour of sandbox chat, the sidekick-proxy entitlement gate correctly returned 403 ("A premium subscription is required...") because the sandbox subscription expired (Apple sandbox: monthly renews every 5 min, max 12 renewals ≈ 1 hour). The chat UI surfaced the raw exception string: `Could not send message: SidekickServiceException: sidekick request failed (status 403)...`. The gate is working as designed (fails closed, protects xAI spend); the client-side presentation is the bug. In production this exact state occurs whenever a real subscription lapses mid-session — the client's cached RevenueCat `CustomerInfo` still says premium while the server says no.
- **acceptance_criteria**:
  - [x] `sidekick_service.dart` detects HTTP 403 from `sidekick-proxy` and throws a typed exception (e.g. `SidekickEntitlementException`) instead of the generic failure
  - [x] Chat UI catches it and shows a friendly inline message (e.g. "Your subscription needs a refresh") with a **Restore/Refresh** action — never the raw exception string
  - [x] The action triggers a RevenueCat re-sync (`restorePurchases` / refresh `CustomerInfo`); if the entitlement is truly gone, route to `upgrade_screen.dart`; if it was a stale cache, retry the message succeeds
  - [x] Same handling applies to the structured session refresh path (`refreshSession()`), not just chat sends
  - [x] The user's typed message is not lost — it stays in the input (or is retryable) after the 403
  - [x] `flutter analyze` clean
- **notes**:
  - Do NOT weaken the server gate; it fails closed on purpose (see `SUPABASE_SETUP.md`). A RevenueCat API outage will also 403 premium users — the friendly message should read as "refresh/try again" rather than accusing the user of not paying.
  - Sentry: breadcrumb the 403 path only (no chat content — privacy rules). Do **not** `recordError` the raw `FunctionException` — that opened FLUTTER-7 as a false crash; entitlement gate is expected business logic.
  - For sandbox testing after a lapse: just re-purchase with the sandbox Apple ID, or raise the tester's subscription renewal rate in App Store Connect → Sandbox.
  - **Done 2026-07-11**: `SidekickEntitlementException` from proxy 403; chat restores text to input + Refresh banner → `refreshEntitlement()` then retry or `/upgrade`; session refresh uses the same friendly copy; Sentry breadcrumb on the 403 path (no message content). **Follow-up 2026-07-17 (FLUTTER-7)**: removed `recordError` on this path + `beforeSend` drop for entitlement-gate `FunctionException`.

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
| TASK-069 | Premium AI voice recite for Scripture Builder (Advanced + Master) | Large |

### TASK-069: Premium AI voice recite for Scripture Builder (Advanced + Master)

- **status**: open (backlog — not prioritized)
- **priority**: P2
- **context**: On-device speech-to-text was removed from Scripture Builder on 2026-07-12 (typing-only now on Advanced + Master). The OS recognizer mangled proper nouns (`Nephi` → "knee five") and client-side homophone matching could never cover scripture vocabulary. Journal voice dictation was kept — `SpeechService`, the `speech_to_text` package, and mic/speech Info.plist permission strings are all still in place.
- **target design**:
  - UI: record a voice memo (tap start/stop) — NOT live STT word-matching
  - Upload audio + target scripture text/id to a new Supabase edge function (mirror `sidekick-proxy`: JWT verification, CORS, server-side transcription/AI secret, **RevenueCat premium gate**)
  - AI judges the recitation and returns **pass/fail** (not word-by-word fill-in)
  - Premium-only; free users see an upgrade teaser or no mic at all
  - A pass counts toward the same Mastered rules as a perfect typing run (3 consecutive Master perfects) unless product revisits
- **scaffolding reference** (recover the old, mature STT implementation via git):
  - `git show 555ccf6:<path>` — "address PR review: never penalize STT partials" (latest STT polish; ancestor of current HEAD). Related prior: `b599740` (Master STT reset/cancel fix).
  - Key paths at that commit:
    - `lib/screens/games/scripture_builder/scripture_builder_screen.dart` (mic UI, `_toggleSpeechListening` / `_onSpeechResult`)
    - `lib/providers/scripture_builder_provider.dart` (`onSpeechInput`, `_speechWordMatches`, `_areHomophones`, `_numberWords`)
    - `test/providers/scripture_builder_provider_test.dart` (`Scripture Builder — Speech-to-text` group)
  - Removal commit: `4181cfb` — the pre-removal tree is one `git show 4181cfb^:<path>` away.
- **acceptance_criteria** (rough):
  - [ ] Record → analyze → pass/fail flow on Advanced + Master
  - [ ] Premium gate enforced server-side (RevenueCat entitlement, like sidekick-proxy)
  - [ ] Group play never writes personal mastery (unchanged rule)
  - [ ] `flutter analyze` clean + tests green
