# Launch Readiness Report — Seminary Sidekick

**Date:** 2026-07-01 · **Scope:** Full claim-by-claim verification of CLAUDE.md, TODO.md, MAINTENANCE.md, REVENUECAT_SETUP.md, SUPABASE_SETUP.md, APP_STORE_SUBMISSION.md against the actual code, plus live checks (privacy policy URL).

**Bottom line: the markdown files are accurate.** Every launch-readiness claim checked out against the code, with one stale line in CLAUDE.md (audio) and zero contradictions. There are **no code blockers** for iOS submission — everything remaining is manual owner work in Xcode/App Store Connect.

---

## 1. Claim verification results

| # | Claim (source) | Verdict | Evidence |
|---|---|---|---|
| 1 | RevenueCat wiring is real (`purchasePlan`/`restorePurchases`/`_syncWithRevenueCat` call `purchases_flutter`, gated on `premium` entitlement) | ✅ VERIFIED | `subscription_provider.dart:186–298` — real `Purchases.purchasePackage/restorePurchases/getCustomerInfo` calls; `_isEntitled` checks `premium` (line 146). Dev-mode premium override only active in debug builds (`isPremiumProvider`, lines 425–435) |
| 2 | RevenueCat SDK configured from `REVENUECAT_IOS_KEY`/`REVENUECAT_ANDROID_KEY` dart-defines; no-op without them | ✅ VERIFIED | `main.dart:127–166`, early return on empty key |
| 3 | Live localized prices; CTA = "Subscribe"; $4.99/mo, $34.99/yr "Save 42%" | ✅ VERIFIED | `upgrade_screen.dart:238–278`, `subscription_provider.dart:23–32,86` |
| 4 | Bundle ID `com.seminarysidekick.app` on Runner + RunnerTests; Android applicationId matches | ✅ VERIFIED | `project.pbxproj` (6 configs), `android/app/build.gradle.kts:26` |
| 5 | `.env` gitignored; no API keys in tracked files | ✅ VERIFIED | `.gitignore:2–4`; grep across lib/ios/android/supabase found nothing; all keys via `String.fromEnvironment` |
| 6 | Sidekick `_safetyGuardrails` (minors, no doctrinal authority, stay-on-topic, crisis→trusted adult, no disparagement) in both session and chat prompts | ✅ VERIFIED | `sidekick_service.dart`; guardrails injected client-side AND authoritatively server-side |
| 7 | xAI key off the client; Sidekick calls `sidekick-proxy` edge function via `functions.invoke` | ✅ VERIFIED | No key in lib/, no direct api.x.ai calls; `supabase/functions/sidekick-proxy/index.ts` reads `XAI_API_KEY` from server env, verifies JWT, prepends safety prompt |
| 8 | "Delete All My Data" clears every Hive box + signs out anonymous Supabase session | ✅ VERIFIED | `data_reset_service.dart` covers all 15 Hive boxes opened across the app; reachable in 2 taps from Settings |
| 9 | Privacy policy link via url_launcher | ✅ VERIFIED | Settings → `https://seminarysidekick.com/privacy` |
| 10 | Privacy policy live at that URL | ✅ VERIFIED (live fetch 2026-07-01) | Effective June 23, 2026; correctly discloses Supabase, xAI, RevenueCat, Sentry; children's section (13+); matches actual data flows |
| 11 | Sentry: no-op without `SENTRY_DSN`; no PII/screenshots/view-hierarchy; no user content in breadcrumbs/tags | ✅ VERIFIED | `crash_reporting_service.dart:14–60` (`sendDefaultPii=false`, `attachScreenshot=false`, `attachViewHierarchy=false`); only tag is a premium boolean |
| 12 | Nothing sensitive sent to Grok (no journal, notes, nicknames) | ✅ VERIFIED | Snapshot = aggregate stats + scripture IDs + activity summaries; chat = user-typed messages only |
| 13 | Supabase migrations 0001–0006 exist and match SUPABASE_SETUP.md | ✅ VERIFIED | All 6 files present; contents match runbook |
| 14 | RLS enabled on all tables; no permissive `USING(true)` on writes | ✅ VERIFIED | `0002_rls_policies.sql` — all writes owner-scoped; `0006` locks `bump_host_usage` (security definer + uid guard) |
| 15 | Free/premium host caps (6/30, 1 game/week free) enforced client + server | ✅ VERIFIED | `group_play_service.dart:154–217` + migration 0006 |
| 16 | 4-letter join codes, kick, profanity filter | ✅ VERIFIED | `group_play_service.dart:164–751`, RLS host-kick policy, `nickname_validator.dart` (l33t-normalized wordlist) |
| 17 | Group Play never writes to personal mastery/progress | ✅ VERIFIED | No `recordAttempt`/progress calls in group play provider or service |
| 18 | Audio: real CC0 .wav files replace placeholders | ✅ VERIFIED — **CLAUDE.md stale** | All 7 .wav present + `AUDIO_CREDITS.md` (Freesound CC0, App-Store-safe); `SoundEffect` enum matches. TODO.md correctly marks TASK-045 done 2026-06-13; **CLAUDE.md still lists it as open P0 with .txt placeholders — update it** |
| 19 | Info.plist usage strings for speech_to_text | ✅ VERIFIED | `NSMicrophoneUsageDescription` + `NSSpeechRecognitionUsageDescription` present; camera string not needed (QR is generate-only) |
| 20 | Tests match CLAUDE.md testing spec | ✅ VERIFIED | 31 test files across models/providers/services/screens, covering mastery, progress, games, group play |
| 21 | REVENUECAT_SETUP.md / APP_STORE_SUBMISSION.md internal consistency | ✅ VERIFIED | Product IDs, entitlement, prices, CTA label all match code exactly |

**Could not verify from here** (no macOS/Flutter toolchain, no dashboard access): App Store Connect / RevenueCat dashboard state, edge-function deployment status, `flutter analyze`/`flutter test` passing. These claims are plausible and internally consistent but need on-device confirmation.

---

## 2. Remaining iOS submission steps (all manual, in order)

Matches APP_STORE_SUBMISSION.md §0 — that checklist is accurate. Sequence:

1. **Commit your working tree.** Uncommitted: doc condensation (TODO.md, SUPABASE_SETUP.md, CLAUDE.md), removal of dead share/bookmark buttons in `scripture_detail_screen.dart` (good — no-op buttons invite review complaints), and **APP_STORE_SUBMISSION.md is untracked**.
2. **Run `flutter pub get && flutter analyze && flutter test` locally** — I could not run these in this environment; last commit message suggests analyze was clean, but verify after the uncommitted edits.
3. **Set signing in Xcode** — `DEVELOPMENT_TEAM` is not set in the project (expected); select your team on the Runner target before archiving.
4. **Capture screenshots** — iPhone 6.9" required (⛔ blocker), iPad 13" if shipping iPad.
5. **Archive with dart-defines** (REVENUECAT_IOS_KEY, SUPABASE_URL, SUPABASE_ANON_KEY, SENTRY_DSN — create the Sentry project first or skip the DSN). Consider adding `APP_RELEASE=seminary_sidekick@1.0.0+1` for crash grouping.
6. **App Store Connect**: paste listing (§1–2), App Privacy (§3), age rating (§4), review notes (§5); confirm the Support URL (`/support` — verify it exists or use the homepage); fill Copyright + review contact.
7. **Upload build, attach both subscriptions to 1.0.0** (clears "Missing Metadata"), add a paywall review screenshot to each subscription.
8. **Submit.**
9. **Before relying on Class Play at scale:** two-instance realtime smoke test (TASK-051).

---

## 3. Watch items (not blockers)

- **CLAUDE.md staleness** — update the TASK-045 line (audio is done) so future agents don't re-do it.
- **Sidekick proxy has no rate limiting.** It verifies JWTs, but Supabase anonymous auth means any app instance can mint one — a motivated abuser could run up your xAI bill. Fine for launch scale; add per-user rate limiting to the edge function post-launch.
- **MAINT-002** (anon-RLS audit — likely intentional Kahoot-style design) and **MAINT-003** (enable Leaked Password Protection toggle) remain open; neither blocks iOS review.
- **Privacy policy mentions "Grok-voiced narration"** — I found no narration feature in the app. Over-disclosure is harmless, but tighten the wording when you next edit the policy.
- **Age rating**: with the 2025 questionnaire, the scoped AI chat may compute 13+ rather than 4+/9+. That's fine — it matches your policy's 13+ floor. Answer truthfully as §4 says.
- **Android is not launch-ready** (by design): debug signing keys in release config, no Play products, no `REVENUECAT_ANDROID_KEY`. Irrelevant to the iOS submission.

---

## 4. Overall assessment

Code-side, this app is submission-ready: real purchase wiring, hardened AI safety for a minor audience, server-side key custody, data deletion, honest privacy disclosures that match actual data flows, licensed audio, and solid test coverage. The documentation is unusually trustworthy — of ~21 material claims checked, the only error found was one stale status line. The critical path to "Submit" is now entirely screenshots + App Store Connect data entry + archive/upload, realistically a single working session.
