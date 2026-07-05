# App Store Submission Pack — Seminary Sidekick

> Copy-paste source for the App Store Connect listing. Everything here is a draft you own — edit freely. **Bracketed `[…]` items need a real value from you.**
> App: **Seminary Sidekick** · Bundle ID `com.seminarysidekick.app` · Version **1.0.0 (build 2)** · SKU `seminarysidekick`

---

## 0. The fastest path to "Submit" (status checklist)

`[x]` = done · `[ ]` = still to do. The ⛔ items are hard blockers for review; ⚠️ are quick but required.

**Already done (code + backend):**

- [X] **Sidekick proxy deployed + `XAI_API_KEY` secret set** (2026-06-13) — premium AI returns real responses for reviewers (verified: `supabase functions list` → `sidekick-proxy` ACTIVE v1; `supabase secrets list` → key present).
- [X] **Bundle ID** `com.seminarysidekick.app` set across the iOS project.
- [X] **App Store Connect** app record + "Seminary Sidekick Premium" subscription group (Monthly $4.99 / Yearly $34.99) created.
- [X] **RevenueCat** configured — `premium` entitlement, both products attached, `default` offering current; iOS public SDK key in gitignored `.env`.
- [X] **In-app launch-safety work** — Sidekick safety prompt, "Delete All My Data", privacy-policy link, "Subscribe" CTA; listing copy drafted (below).

**Still to do (roughly in order):**

- [X] ⚠️ **Confirm the privacy policy is live** at `https://seminarysidekick.com/privacy`.
- [X] ⛔ **Capture screenshots** on the iPhone 6.9" simulator (and ideally an iPad) — see §6.
- [X] ⚠️ **Paste the listing into App Store Connect** — **App Information** (§1), **listing copy** (§2), **App Privacy** (§3), **Age Rating** (§4), and **Review notes** (§5).
- [X] ⚠️ **Set the release build's dart-defines and archive** (done 2026-07-04):
  `flutter build ipa --dart-define=REVENUECAT_IOS_KEY=$REVENUECAT_IOS_KEY --dart-define=SUPABASE_URL=$SUPABASE_URL --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY --dart-define=SENTRY_DSN=$SENTRY_DSN`
  (xAI key is **not** passed anymore — it lives in the proxy.)
- [X] ⚠️ **Upload the build** (Transporter, 2026-07-04) — attached to 1.0.0, both subscriptions attached, "Missing Metadata" cleared (needed subscription-group localization + per-sub review screenshot + availability).
- [X] ⛔ **Submit for review — DONE 2026-07-04.** 🎉 (App priced Free, worldwide availability, iPad 13" screenshots included.)
- [X] ⛔ **Build 1 rejected in processing (ITMS-91061, 2026-07-04)** — `share_plus` 7.2.2 shipped without the required privacy manifest. **Fixed + resubmitted 2026-07-05**: `share_plus` bumped to ^10.1.4, version 1.0.0+2, build 2 uploaded via Transporter (passed processing), swapped onto the 1.0 version, submission resubmitted → **Waiting for Review** (submission ID `9e3cdac1-11c1-40eb-afcc-84931cd7ef54`).
- [ ] _After approval:_ delete the leftover sample "Seminary Sidekick Pro" entitlement + Test Store products in RevenueCat (cosmetic).

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

### What's New (version 1.0.0)

```
Welcome to Seminary Sidekick! This first release includes the full mastery loop (Scripture Builder, Quick Quiz, Scripture Match), progress tracking, live "Play with Friends" class games, and the premium Seminary Sidekick AI study companion.
```

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

- [X] Attach **both subscriptions to the 1.0.0 version** and submit them **with** the build (done 2026-07-04).
- [X] Description includes the required **subscription disclosure** (price, period, auto-renew, manage/cancel) — keep it.
- [X] Each subscription has a **localized display name + description** (plus the subscription-**group** localization, which was the hidden "Missing Metadata" cause).
- [X] Add a **review screenshot** of the paywall to each subscription (done 2026-07-04 — `14-paywall.png` on both).
- [X] Upgrade button says **"Subscribe"** (no free trial configured) — no "Start Free Trial" rejection risk.

---

## 8. Still-open owner items beyond this submission

- [X] **Sentry**: project created 2026-07-03; `SENTRY_DSN` in gitignored `.env` — passed as a dart-define in the submitted build.
- [X] **Sidekick premium gate**: `REVENUECAT_SECRET_KEY` Supabase secret set + `sidekick-proxy` redeployed and enforcing (2026-07-04).
- [ ] **Supabase free-tier auto-pause**: upgrade to Pro or set a keep-alive before launch — a paused project kills Group Play + Sidekick (already happened once).
- [ ] **Android**: Play Console products + `REVENUECAT_ANDROID_KEY` + release signing (separate launch).
- [ ] **Group Play**: two-instance realtime smoke test (TASK-051) before relying on it at class scale.
- [ ] **After approval**: delete the sample "Seminary Sidekick Pro" entitlement + Test Store products in RevenueCat.
