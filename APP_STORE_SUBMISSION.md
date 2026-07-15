# App Store Submission Pack — Seminary Sidekick

> Copy-paste source for the App Store Connect listing. Everything here is a draft you own — edit freely. **Bracketed `[…]` items need a real value from you.**
> App: **Seminary Sidekick** · Bundle ID `com.seminarysidekick.app` · Version **1.0.1** · SKU `seminarysidekick`
>
> **Status (2026-07-15): iOS v1.0.1 SUBMITTED** — in App Store review. **All submission blockers resolved** (Paid Apps Agreement / banking, EULA links, Subscribe/RevenueCat dart-defines, listing/IAP metadata). Non-blocker hygiene lives in §8 and `TODO.md` → 🚀 Launch Status. Future iOS archives: **always** `./scripts/build_ios_release.sh` (never bare `flutter build ipa`).

---

## 0. Submission status checklist

`[x]` = done · `[ ]` = still to do.

### Current

- [X] **iOS v1.0.1 submitted** for App Store review (2026-07-15). Pricing Free, worldwide availability; both subscriptions attached with the build; screenshots + listing metadata in place.
- [X] **All prior review blockers resolved** (owner confirmed):
  - Paid Apps Agreement **Active** (banking + tax)
  - **3.1.2(c)** EULA — Privacy Policy + Terms of Use on upgrade screen + standard EULA in App Description
  - **2.1(b)** Subscribe — archives use `./scripts/build_ios_release.sh` so `REVENUECAT_IOS_KEY` (and Supabase defines) are present; Sentry on purchase failure paths
- [X] **Build rule locked in**: script loads `.env`, hard-fails if `REVENUECAT_IOS_KEY` / `SUPABASE_URL` / `SUPABASE_ANON_KEY` are missing. xAI key is **not** a client dart-define — it lives in the `sidekick-proxy`.

### Foundation (code + store setup — complete)

- [X] **Sidekick proxy deployed + `XAI_API_KEY` secret set** (2026-06-13) — premium AI returns real responses for reviewers.
- [X] **Bundle ID** `com.seminarysidekick.app` set across the iOS project (+ Android `applicationId`).
- [X] **App Store Connect** app record + "Seminary Sidekick Premium" subscription group (Monthly $4.99 / Yearly $34.99).
- [X] **RevenueCat** — `premium` entitlement, both products attached, `default` offering current; iOS public SDK key in gitignored `.env`.
- [X] **Launch-safety** — Sidekick safety prompt, "Delete All My Data", privacy-policy + EULA links on upgrade screen, "Subscribe" CTA.
- [X] **Privacy policy live** at `https://seminarysidekick.com/privacy`.
- [X] **Screenshots** — iPhone 6.9" + iPad 13" (see §6).
- [X] **Listing** pasted into ASC — App Information (§1), copy (§2), App Privacy (§3), Age Rating (§4), Review notes (§5).
- [X] **Sentry** + **sidekick-proxy premium gate** enforcing (`REVENUECAT_SECRET_KEY`).

### Review history (resolved — keep for context)

| When | Version | Outcome |
|------|---------|---------|
| 2026-07-04 | 1.0.0 (1) | Submitted; **ITMS-91061** in processing (`share_plus` privacy manifest) → bumped to ^10.1.4 |
| 2026-07-05 | 1.0.0 (2) | Resubmitted (submission ID `9e3cdac1-11c1-40eb-afcc-84931cd7ef54`) → later **3.1.2(c)** EULA link rejection (2026-07-09) |
| 2026-07-10 | 1.0.0 (3) | EULA fix resubmitted; **3.1.2(c) passed**. New reject: **2.1(b)** Subscribe error (archive missing RevenueCat dart-defines → "Purchases aren't available right now"). Mitigations: release build script + Sentry on purchase failure paths. |
| 2026-07-15 | **1.0.1** | **Submitted** (current) — banking, EULA, purchase path, and store metadata all resolved for this binary |

No open App Store submission blockers. Remaining owner work is post-approval / product hygiene (§8).

---

## 1. App Information

| Field                    | Value                                                                     |
| ------------------------ | ------------------------------------------------------------------------- |
| Name                     | `Seminary Sidekick`                                                     |
| Subtitle (≤30 chars)    | `Master the seminary scriptures` (30)                                   |
| Primary category         | Education                                                                 |
| Secondary category       | Reference                                                                 |
| Bundle ID                | `com.seminarysidekick.app`                                              |
| SKU                      | `seminarysidekick`                                                      |
| Privacy Policy URL       | `https://seminarysidekick.com/privacy`                                  |
| Support URL              | `[https://seminarysidekick.com/support — confirm or use the homepage]` |
| Marketing URL (optional) | `https://seminarysidekick.com`                                          |
| Copyright                | `[2026 <legal owner / your name or LLC>]`                               |
| Pricing                  | Free (with auto-renewable subscriptions)                                  |

---

## 2. Listing copy

### Subtitle (≤30) — pick one

- `Master the seminary scriptures` (30)
- `Doctrinal Mastery, made simple` (30)
- `Study, practice, master, repeat` (31 — trim to `Study, practice & master`)

### Promotional text (≤170, editable anytime without review)

```
Learn all 100 Doctrinal Mastery scriptures with Scripture Builder, quick quizzes, and Kahoot-style class games — plus an AI study companion that helps you understand, not just memorize.
```

### Keywords (≤100 chars, comma-separated, no spaces after commas)

```
seminary,doctrinal mastery,scripture,LDS,come follow me,memorize,book of mormon,bible,quiz,study,faith
```

> 99 chars. Don't repeat the app name or category in keywords (Apple already indexes those).

### Description

```
Seminary Sidekick is the focused way to learn all 100 Doctrinal Mastery scriptures — and actually remember them.

The path to mastery is simple: Study, Build, Prove, Master. Open any scripture, study the text, then use Scripture Builder to progressively prove you can reproduce it from memory — from tapping word-chunks to typing it cold. Watch each scripture climb the mastery path as you go.

FREE — everything you need to master the scriptures:
• Scripture Builder — the core mastery tool, with four difficulty tiers
• Quick Quiz & Scripture Match — fast practice for recognition and references
• Spaced-repetition review so nothing slips away
• Progress tracking, streaks, and a clear mastery path for all 100 scriptures
• Play with Friends — host or join Kahoot-style live class games (quiz races and Scripture Builder races) with a join code or QR

PREMIUM — Seminary Sidekick AI (subscription):
• A warm, Socratic AI study companion that knows your progress and helps you understand and apply each scripture — not just memorize it
• A guided scripture journal with reflection prompts
• Smart goals, gentle reminders, and personalized study insights

Built to be reverent, encouraging, and genuinely fun — for personal study and for the whole seminary class.

Subscriptions:
• Monthly — $4.99/month
• Yearly — $34.99/year (best value)
Payment is charged to your Apple Account. Subscriptions renew automatically unless turned off at least 24 hours before the period ends; manage or cancel anytime in your Apple Account settings.

Privacy Policy: https://seminarysidekick.com/privacy
Terms of Use (EULA): https://www.apple.com/legal/internet-services/itunes/dev/stdeula/
```

> Apple requires the **subscription terms** + links to your **Privacy Policy** and a **Terms of Use (EULA)** for auto-renewable subscriptions, both in the description and in the App Privacy/agreements. The link above is Apple's standard EULA; swap for your own if you have one.

### What's New (version 1.0.1)

```
Welcome to Seminary Sidekick! Learn all 100 Doctrinal Mastery scriptures with Scripture Builder, Quick Quiz, Scripture Match, live "Play with Friends" class games, and the optional premium Seminary Sidekick AI study companion. This update includes purchase reliability and review fixes from the 1.0.0 review cycle.
```

<details>
<summary>What's New used for 1.0.0 (first submission)</summary>

```
Welcome to Seminary Sidekick! This first release includes the full mastery loop (Scripture Builder, Quick Quiz, Scripture Match), progress tracking, live "Play with Friends" class games, and the premium Seminary Sidekick AI study companion.
```

</details>

---

## 3. App Privacy answers (Data Collection)

> Honest profile based on the actual app. There is **no user account** — group play and purchases use anonymous IDs. Local study data (progress, notes, journal, goals, preferences) stays **on the device** (Hive) and is therefore **not "collected"** for App Privacy purposes — don't declare it.

**"Do you or your third-party partners collect data from this app?" → Yes.**

Declare these data types. For ALL of them: **Linked to the user? → No** (anonymous) and **Used for tracking? → No** (no cross-app/3rd-party ad tracking).

| Data type (Apple category)                   | What it is                                                                                                                              | Purpose                              | Notes                                                                     |
| -------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------ | ------------------------------------------------------------------------- |
| **Identifiers → User ID**             | Anonymous Supabase auth ID (group play) + RevenueCat app user ID                                                                        | App Functionality                    | Not tied to a real identity                                               |
| **User Content → Other User Content** | Group-play nickname; chat messages typed to the Sidekick AI (sent to xAI via our server proxy); journal/notes are NOT sent (local only) | App Functionality                    | Chat content is processed by xAI (Grok) as a third party — disclose this |
| **Purchases → Purchase History**      | Subscription status / purchase events via RevenueCat + Apple                                                                            | App Functionality                    | —                                                                        |
| **Diagnostics → Crash Data**          | Crash reports via Sentry                                                                                                            | App Functionality (and/or Analytics) | `sendDefaultPii` off; no screenshots, no PII                            |

Everything is **"Data Not Linked to You"** and **"Not Used to Track You."** Do not check any Advertising purposes.

> Third parties to mention in your privacy policy: **Supabase** (anonymous auth + group play data), **xAI/Grok** (AI chat content, via our proxy), **RevenueCat** + **Apple** (subscriptions), **Sentry** (crash diagnostics). Because many users are minors, the policy should explicitly address data from children/teens.

---

## 4. Age Rating questionnaire

Apple's updated (2025) questionnaire computes the final tier (now 4+, 9+, 13+, 16+, 18+). Answer truthfully — for this app almost everything is **None / No**:

- Violence (cartoon, realistic, prolonged graphic), Sexual content/nudity, Profanity/crude humor, Horror, Alcohol/tobacco/drugs, Gambling, Contests → **None / No**
- **Medical or wellness** topics → **No** (religious education, not health/medical advice)
- **Unrestricted web access** → **No** (the app only opens your known privacy-policy link externally; no in-app browser)
- **Capabilities** → the app has a scoped **AI chat** (the Sidekick) and **user-generated nicknames** in group play. Answer the AI/chat and user-generated-content questions **truthfully (Yes where asked)**. Mitigations to mention if prompted: the AI is tightly scoped to scripture study with a server-enforced safety prompt; nicknames pass a profanity filter (`NicknameValidator`); there is no open user-to-user messaging or public content feed.
- In-app parental controls → No specific gate (not required for this content).

**Expected result:** likely **4+ or 9+**. Let Apple's questionnaire compute it — don't hand-pick a tier. If the AI-chat capability pushes it higher, that's fine; accept the computed rating.

---

## 5. App Review Information

**Sign-in required? → No.** The app needs no account; it runs anonymously.

**Demo / how to reach everything (paste into "Notes"):**

```
No login is required — the app runs with anonymous local data.

FREE features: open any scripture from Home → use "Scripture Builder" (the mastery tool), or "Quick Quiz" / "Scripture Match" from the practice hub. "Play with Friends" lets you host a live class game and join it from a second device using the 4-letter code or QR.

PREMIUM (Seminary Sidekick AI): tap "Upgrade" (Settings or any premium prompt) → choose Monthly ($4.99) or Yearly ($34.99) → complete the purchase with a Sandbox Apple Account. Premium unlocks the AI study companion (chat + daily prompts), the guided journal, and smart goals.

The AI companion is scoped strictly to scripture study and runs behind a server-side safety prompt (age-appropriate for the teen audience, defers doctrinal and personal questions to a teacher/parent/bishop, and redirects any distress to a trusted adult). No personal account or PII is collected; users can erase all local data anytime via Settings → "Delete All My Data."
```

**Contact:** `[your name]`, `[phone]`, `[email]`

> ✅ The `sidekick-proxy` function is deployed and the `XAI_API_KEY` secret is set (2026-06-13), so the AI chat a reviewer tests returns real responses (not the offline fallback).

---

## 6. Screenshots (you must capture these)

> ✅ **Done 2026-07-03/04** — 9 iPhone 6.9" shots (order: home, memorize, match, builder chunk-tap, group-play lobby, quick quiz, chat, stats, journal) + 5 iPad 13" shots (home, library, scripture detail, builder, group-play lobby) uploaded via Media Manager. iPad 13" is *required* (not optional) because the Flutter build targets iPad (`TARGETED_DEVICE_FAMILY 1,2`).

Required: **iPhone 6.9"** (e.g. iPhone 16 Pro Max simulator). Strongly recommended: **iPad 13"** if you ship for iPad. 3–10 images each; the first 1–3 matter most.

Suggested shots (turn on dev-mode premium to capture the AI screens):

1. Home — "Let's Learn / Let's Play"
2. Scripture detail with the mastery path + Scripture Builder
3. Scripture Builder mid-game (typing tier)
4. Play with Friends — lobby with join code/QR or the live leaderboard/podium
5. Seminary Sidekick AI — chat with a daily prompt
6. Progress / Stats — mastery ring + streaks

Tip: capture on the simulator with `⌘S`, or `flutter screenshot`. Keep them clean (no debug banners — build in profile/release).

---

## 7. Subscription review specifics (so IAP isn't rejected)

- [X] Attach **both subscriptions to the version** and submit them **with** the build (done for 1.0.0 on 2026-07-04; keep attached on **1.0.1** and every later version).
- [X] Description includes the required **subscription disclosure** (price, period, auto-renew, manage/cancel) — keep it.
- [X] Each subscription has a **localized display name + description** (plus the subscription-**group** localization, which was the hidden "Missing Metadata" cause).
- [X] **Review screenshot** of the paywall on each subscription (done 2026-07-04 — `14-paywall.png` on both).
- [X] Upgrade button says **"Subscribe"** (no free trial configured) — no "Start Free Trial" rejection risk.
- [X] In-app **Privacy Policy** + **Terms of Use (EULA)** links on the upgrade screen (required after 3.1.2(c); still required on every build).
- [X] Archive **with** `./scripts/build_ios_release.sh` so RevenueCat is configured (required after 2.1(b)).

---

## 8. Owner items after submission (not App Store blockers)

Mirrored in `TODO.md` → 🚀 Launch Status. Submission blockers (banking / Paid Apps Agreement, EULA, Subscribe/RevenueCat build, listing/IAP) are **done**. These are hygiene before real traffic or a separate launch track:

- [X] **Sentry**: project created 2026-07-03; `SENTRY_DSN` in gitignored `.env` — passed as a dart-define in release builds.
- [X] **Sidekick premium gate**: `REVENUECAT_SECRET_KEY` set + `sidekick-proxy` enforcing (2026-07-04).
- [X] **Paid Apps Agreement**, **EULA links**, **1.0.1 archive with dart-defines** — resolved for current submission.
- [ ] **Supabase free-tier auto-pause**: upgrade to Pro (~$25/mo) or set a keep-alive — a paused project kills Group Play + Sidekick (already happened once during screenshots).
- [ ] **Android launch** (separate effort): Play Console products + `REVENUECAT_ANDROID_KEY` + release signing — see `REVENUECAT_SETUP.md` Step 2.
- [ ] **Group Play**: two-instance realtime smoke test (TASK-051) before relying on it at class scale.
- [ ] **TASK-045 audio ear-check** on device.
- [ ] **After approval**: delete the sample "Seminary Sidekick Pro" entitlement + Test Store products in RevenueCat.
