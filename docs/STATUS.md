## Current Task Status

**Free-tier MVP** (completed 2026-04-06):

- All core tasks done.
- UX restructure complete: Scripture Builder is the hero on scripture detail.

**Freemium infrastructure** (completed 2026-04-06):

- TASK-033 done: SubscriptionProvider, UpgradeScreen, PremiumTeaser widgets, rate-limited prompts.

**Seminary Sidekick AI core** (completed 2026-04-06):

- TASK-034 done: SidekickService (Grok/xAI), SidekickProvider (orchestration + caching), snapshot/response models, chat support.

**Premium teaser & upgrade experience** (completed 2026-04-06):

- TASK-039 done: Premium teasers placed in home screen (after stats), scripture detail (inline link + mastery-level teaser), and onboarding (Sidekick mention on final page). All rate-limited and dismissible.

**Premium Tier — Seminary Sidekick AI** (completed 2026-04-07):

- TASK-035/036/037/038/040 all done — journal + prompts, goals + timeline + reminders, chat, polish, engagement layers.

**Deployment readiness polish** (completed 2026-04-11):

- TASK-041/042/043/044 done — settings screen, theme toggle wiring, font scale, haptics routed through a service.

**Post-MVP feature waves** (completed):

- TASK-046 Home reorientation ("Let's Learn / Let's Play") — done 2026-05-05.
- TASK-047 Shared scripture-scope picker + TASK-049 dead-state cleanup — done 2026-05-25.
- **Group Play (TASK-048 umbrella, decomposed into TASK-051–062)** — Quiz mode v1 shipped 2026-05-07 (Supabase backend, host/join lobbies, live quiz, results, profanity filter); premium hosting gates (TASK-058) and Scripture Builder Race mode (TASK-062) shipped 2026-05-25; group-play polish (TASK-064: stream reconnection, answer-distribution reveal, leaderboard/podium reveal animations) 2026-06-10.

**🚀 WAITING FOR REVIEW (resubmitted 2026-07-05)**: iOS v1.0.0 (build 1) was submitted 2026-07-04 with both subscriptions attached, then rejected in post-upload processing with **ITMS-91061 Missing privacy manifest** (`share_plus` 7.2.2 predates the required `PrivacyInfo.xcprivacy`). Fixed 2026-07-05: `share_plus` ^7.2.2 → ^10.1.4 (manifest included since 8.0.2; same `Share.share()` API, zero code changes), version bumped to 1.0.0+2, build 2 uploaded via Transporter (passed processing), swapped onto the 1.0 version, and the submission resubmitted — now **Waiting for Review**. Full submission record in `APP_STORE_SUBMISSION.md` §0; open post-submission items in `TODO.md` → "🚀 Launch Status" (Supabase free-tier auto-pause mitigation before launch, post-approval RevenueCat sample-entitlement cleanup, TASK-051 two-instance smoke test, audio ear-check, Android). Also shipped en route: TASK-066 journal discoverability (2026-07-02), MAINT-004 typing-punctuation fix (2026-07-03), and the sidekick-proxy RevenueCat entitlement gate — **enforcing** since 2026-07-04 (`REVENUECAT_SECRET_KEY` secret set; see `SUPABASE_SETUP.md`).

**Launch-readiness history** (owner-reviewed 2026-06-10; all resolved by the 2026-07-04 submission; see `TODO.md` / `MAINTENANCE.md` for full entries):

- **P0 TASK-045**: Real audio — **DONE 2026-06-13.** All 7 `.wav` SFX replaced with real CC0 audio (Freesound), incl. `countdown_tick`, `group_join`, `streak_milestone`; provenance in `assets/audio/AUDIO_CREDITS.md`; `AudioNotifier` fails gracefully per-effect. Remaining owner step: in-app ear-check (see the pre-submit checklist in `TODO.md`).
- **P0 TASK-063**: Crash reporting & error analytics (Sentry) — done 2026-06-10. Owner setup: create a Sentry project, pass `--dart-define=SENTRY_DSN=...` in release builds.
- **P0 (untracked, from 2026-06-10 audit)**: ~~real RevenueCat purchase wiring + iOS store identity~~ **DONE 2026-06-13** — `purchasePlan`/`restorePurchases`/`_syncWithRevenueCat` make real `purchases_flutter` calls gated on the `premium` entitlement; `main.dart` configures the SDK from `REVENUECAT_IOS_KEY`/`REVENUECAT_ANDROID_KEY` dart-defines (free-tier no-op without them); live localized prices surface on the upgrade screen and the CTA is now **"Subscribe"** (no free trial planned — relabeled from "Start Free Trial"). **Pricing locked: $4.99/mo, $34.99/yr ("Save 42%").** **iOS fully wired end-to-end**: real Bundle ID `com.seminarysidekick.app` set across `ios/Runner.xcodeproj` (app + RunnerTests) and Android `applicationId`; App Store Connect app + subscription group "Seminary Sidekick Premium" (monthly $4.99 / yearly $34.99) created; RevenueCat project configured (`premium` entitlement, both products attached, `default` offering current with the App Store products in its Monthly/Annual packages); iOS public SDK key in gitignored `.env`. See `REVENUECAT_SETUP.md` and the 2026-06-13 entry in `TODO.md`. **Update 2026-07-04**: build submitted, "Missing Metadata" cleared (group localization + review screenshots + availability). Still open: Android (Play Console products + `REVENUECAT_ANDROID_KEY` + release signing); optional App Store Connect API key for RevenueCat product sync; post-approval deletion of the sample "Seminary Sidekick Pro" entitlement + Test Store products.
- **P0 (untracked, 2026-06-13) — Sidekick safety, xAI key security, privacy/deletion**: **DONE in code.** (1) **Safety hardening** — `sidekick_service.dart` prompts now carry a shared `_safetyGuardrails` block (age-appropriate / minors, no-doctrinal-authority disclaimer → defer to teacher/parent/bishop, stay-on-topic refusals, crisis→trusted-adult redirect, no disparagement). (2) **xAI key off the client** — Sidekick now calls the `sidekick-proxy` **Supabase Edge Function** (`supabase/functions/sidekick-proxy/index.ts`) via `functions.invoke`; the function holds `XAI_API_KEY` server-side and prepends an authoritative copy of the safety prompt. The key is no longer a client `--dart-define`. (3) **In-app data deletion** — Settings → "Delete All My Data" (`DataResetService`) clears every Hive box + signs out the anonymous Supabase session + reloads providers (Apple account-deletion requirement). (4) **Privacy policy** — Settings links to `https://seminarysidekick.com/privacy` via `url_launcher`. **Edge function deployed 2026-06-13**: `XAI_API_KEY` secret set + `sidekick-proxy` deployed and live (`supabase functions list` → ACTIVE, v1; `supabase secrets list` shows the secret). The xAI key lives only as a Supabase secret — not in any shipped file. **All owner steps done**: privacy policy URL on the App Store listing (policy verified live 2026-07-01); `flutter analyze` clean + `flutter test` green (2026-07-03); premium entitlement gate enforcing via `REVENUECAT_SECRET_KEY` (2026-07-04).
- **P1 TASK-051 owner steps**: all 6 migrations are deployed — `supabase migration list` shows local + remote in sync (0001–0006) as of 2026-06-13. Remaining: two-instance realtime smoke test; MAINT-002 RLS audit.
- **P1 TASK-059**: Saved class rosters (premium). **P2 TASK-061**: post-game class breakdown analytics.
- **P2 TASK-050**: Async friends & group layer — after group play launch settles.
- **P2 TASK-065**: Premium "Missionary Scriptures" pack — unlock a curated extra scripture set behind the existing premium subscription. Curated-only (no user-added scriptures, by owner decision). See `TODO.md` for the full entry.
