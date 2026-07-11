# RevenueCat Setup — Seminary Sidekick Premium

> **Read this once, top to bottom, before touching any dashboard.** Roughly 45–60 minutes end-to-end, plus Apple/Google review lag on the products themselves.
> Everything here is owner-driven (you). Agents do not touch the RevenueCat, App Store Connect, or Play Console dashboards.

---

## What this gets us

In-app subscriptions for the premium tier (Seminary Sidekick AI, journal, smart goals, deep study tools). RevenueCat sits between the app and the two stores so we write one entitlement check instead of two billing integrations, and we get receipt validation, restore-purchases, and cross-platform subscription status for free.

The free tier of the app is unaffected. If RevenueCat is not configured (no API key), the app runs entirely on the free tier — every premium gate just stays locked. Nothing crashes.

## Status (updated 2026-06-13)

**iOS is wired end-to-end.** What's already done:

- ✅ **Bundle ID** `com.seminarysidekick.app` registered in the Apple Developer portal and set across `ios/Runner.xcodeproj` (app + RunnerTests) and the Android `applicationId`. The old `com.example.*` placeholders are gone.
- ✅ **Step 1 — App Store Connect (iOS)**: app record created (SKU `seminarysidekick`), subscription group "Seminary Sidekick Premium" with monthly ($4.99) + yearly ($34.99) subscriptions, each with an English (U.S.) localization.
- ✅ **Step 3 — RevenueCat dashboard**: App Store app configured with the In-App Purchase `.p8` key; `premium` entitlement created; both products added and attached to `premium`; the `default` (current) offering's Monthly + Annual packages now serve the App Store products.
- ✅ **Step 4/5 — iOS SDK key**: the `appl_…` public key is stored in the gitignored `.env` as `REVENUECAT_IOS_KEY` (placeholders are in `.env.example`).
- ✅ **CTA decision**: no free trial planned — the upgrade button is relabeled **"Subscribe"** (see the trial section below).

**Still TODO (owner):**

- ⬜ **Step 2 — Android** (Play Console products) + the `goog_…` key as `REVENUECAT_ANDROID_KEY`, plus the Play app + service-account JSON in RevenueCat.
- ⬜ **App Store Connect API key** (optional) — products show "Could not check" in RevenueCat until this is added or Apple approves them.
- ⬜ **Submit a build** to clear the subscriptions' "Missing Metadata" status (also needs a per-subscription review screenshot).
- ⬜ **Tidy-up**: delete the leftover sample **"Seminary Sidekick Pro"** entitlement + Test Store products that RevenueCat auto-created — harmless (the app only checks `premium`), but cleaner gone.

## The decisions, locked in

| Thing              | Value                                             | Where it lives in code                                    |
| ------------------ | ------------------------------------------------- | --------------------------------------------------------- |
| Monthly price      | **$4.99 / month**                           | `PremiumPlan.monthly` in `subscription_provider.dart` |
| Yearly price       | **$34.99 / year** (≈ $2.92/mo, "Save 42%") | `PremiumPlan.yearly`                                    |
| Monthly product ID | `seminary_sidekick_monthly`                     | `PremiumPlan.monthly.id`                                |
| Yearly product ID  | `seminary_sidekick_yearly`                      | `PremiumPlan.yearly.id`                                 |
| Entitlement ID     | `premium`                                       | `SubscriptionNotifier.premiumEntitlementId`             |
| Offering           | the**current/default** offering             | resolved at runtime via `offerings.current`             |

**These three identifiers — the two product IDs and the `premium` entitlement — must match the dashboard EXACTLY.** The app gates premium off the `premium` entitlement, not off product IDs, so the entitlement name is the one that absolutely cannot drift. If you want to change any of them, change the code constant and the dashboard together.

The displayed prices ($4.99 / $34.99) are a fallback. Once offerings load, the app shows the **real localized price from the store** (`storeProduct.priceString`), which is what Apple and Google require. So the in-app price will always reflect what the user is actually charged in their currency — set the real price in the stores (Step 1–2), and the app follows.

---

## Prerequisites

- An Apple Developer account ($99/yr) with the app created in **App Store Connect**, and a **paid apps agreement** signed (App Store Connect → Business → Agreements). **Subscriptions will not appear in the app until this agreement is active** — this trips everyone up.
- A Google Play Console account ($25 one-time) with the app created and a payments profile set up.
- A free RevenueCat account: https://app.revenuecat.com
- The app's real bundle ID: **`com.seminarysidekick.app`** (✅ done — registered with Apple and set in the iOS project + Android `applicationId`).

---

## Step 1 — App Store Connect (iOS): create the subscriptions  ✅ DONE

> Already completed 2026-06-13: subscription group "Seminary Sidekick Premium" with both products and localizations exists. Steps kept below for reference / if you ever recreate them.

1. Go to https://appstoreconnect.apple.com → your app → **Monetization → Subscriptions**.
2. Create a **Subscription Group** (e.g. `Seminary Sidekick Premium`). Both plans go in the *same* group so users can upgrade/downgrade between monthly and yearly cleanly.
3. Add subscription #1:
   - **Reference Name**: `Monthly` (internal only)
   - **Product ID**: `seminary_sidekick_monthly`  ← exact, copy-paste it
   - **Duration**: 1 month
   - **Price**: $4.99 (USD base; Apple auto-fills other currencies — review the table)
4. Add subscription #2:
   - **Reference Name**: `Yearly`
   - **Product ID**: `seminary_sidekick_yearly`  ← exact
   - **Duration**: 1 year
   - **Price**: $34.99
5. For each, fill in the **localized display name** and **description** (required for review) and attach the required **review screenshot** (you can use a screenshot of the upgrade screen once you have one).
6. Status will sit at "Ready to Submit" / "Missing Metadata" until you submit them with an app version. That's fine for development — sandbox testing works before approval.

### About the upgrade button  ✅ RESOLVED

**Decision (2026-06-13): no free trial.** The upgrade-screen CTA has been relabeled from "Start Free Trial" to **"Subscribe"** in `upgrade_screen.dart`, so there's no mismatch for App Review.

If you ever decide to offer a trial later: add an **Introductory Offer** ("Free", e.g. 7 days) to each subscription (and the Play equivalent), then change the button copy back — RevenueCat surfaces the intro offer automatically.

---

## Step 2 — Google Play Console (Android): create the subscriptions  ⬜ TODO

> Not done yet — this is the main remaining store task. Do this when you're ready to ship Android.

1. Go to https://play.google.com/console → your app → **Monetize → Products → Subscriptions**.
2. Create subscription `seminary_sidekick_monthly`:
   - Add a **base plan**, billing period **monthly (P1M)**, auto-renewing, price **$4.99**.
3. Create subscription `seminary_sidekick_yearly`:
   - Add a **base plan**, billing period **yearly (P1Y)**, auto-renewing, price **$34.99**.
4. **Activate** each base plan (drafts are invisible to the app).
5. If you're offering a free trial, add it as an **offer** on each base plan.

> Android product IDs sometimes carry a base-plan suffix (e.g. `seminary_sidekick_monthly:monthly`). The app's plan-matching handles this — it matches by prefix — so you don't need to special-case it.

---

## Step 3 — RevenueCat dashboard: project, entitlement, products, offering  ✅ DONE (iOS)

> iOS side completed 2026-06-13 in the existing **Seminary Sidekick** project. The Play Store app/products (item 2 Play, and the Android side of items 4–5) are the remaining Android work. Steps kept for reference.

1. Project **Seminary Sidekick** already exists.
2. Apps under **Project settings → Apps**:
   - ✅ **App Store**: bundle ID `com.seminarysidekick.app`, In-App Purchase `.p8` key uploaded. (The App Store Connect *API* key — for product import/price-sync — is still optional/TODO; without it products show "Could not check".)
   - ⬜ **Play Store**: paste the Android package name `com.seminarysidekick.app`. Upload the **Play service-account credentials JSON** (Play Console → Setup → API access). RevenueCat documents the exact roles to grant.
3. ✅ **Entitlements** → `premium` created (Display Name "Premium").
   - ⚠️ Note: RevenueCat's onboarding auto-created a sample **"Seminary Sidekick Pro"** entitlement + Test Store products. Harmless (unused by the app), but delete them when convenient.
4. ✅ **Products** → `seminary_sidekick_monthly` + `seminary_sidekick_yearly` added under the App Store app and attached to `premium`. (Add the Android equivalents in the Play app when you do Step 2.)
5. ✅ **Offerings** → the `default` offering is **Current**; its **Monthly** and **Annual** packages serve the App Store products. (When Android products exist, add them to the same packages — one product per app per package.)

---

## Step 4 — Grab the public SDK API keys

In RevenueCat → **API keys → SDK API keys** (public, per app):

- ✅ iOS key (`appl_…`) — already captured and stored in `.env` as `REVENUECAT_IOS_KEY`.
- ⬜ Android key (`goog_…`) — grab once the Play app exists (Step 2) and add it to `.env` as `REVENUECAT_ANDROID_KEY`.

These are *public* SDK keys — safe to ship in the app binary (that's their design). They are **not** the secret key; never put the secret key in the app.

---

## Step 5 — Run the app with the keys

The app reads the keys from `--dart-define` at build/run time (same pattern as Supabase and Sentry). No key = free tier, no crash. All values live in the gitignored `.env` (`REVENUECAT_IOS_KEY` is already there).

```bash
# Local run (iOS) — sources .env and passes everything through
# (xAI key no longer passed — it lives server-side in the sidekick-proxy)
export $(grep -v '^#' .env | xargs) && flutter run \
  --dart-define=REVENUECAT_IOS_KEY=$REVENUECAT_IOS_KEY \
  --dart-define=SUPABASE_URL=$SUPABASE_URL \
  --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY

# Release build (iOS) — ⛔ ALWAYS use the script, never `flutter build ipa` by hand.
# It validates .env has every required key and fails loudly if one is missing
# (build 1.0.0+3 shipped without REVENUECAT_IOS_KEY → broken purchases →
# App Review rejection 2.1(b) on 2026-07-10).
./scripts/build_ios_release.sh

# Android — once REVENUECAT_ANDROID_KEY is in .env (Step 2)
export $(grep -v '^#' .env | xargs) && flutter build appbundle \
  --dart-define=REVENUECAT_ANDROID_KEY=$REVENUECAT_ANDROID_KEY \
  --dart-define=SUPABASE_URL=$SUPABASE_URL \
  --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY \
  --dart-define=XAI_API_KEY=$XAI_API_KEY
```

A `--dart-define-from-file=config.json` (gitignored) is an alternative tidy way to keep these together. Don't commit the keys.

---

## Step 6 — Test with sandbox accounts

**iOS**: App Store Connect → **Users and Access → Sandbox → Testers** → create a sandbox Apple ID (use an email you control that is NOT a real Apple ID). On the device, sign out of the real App Store account; the purchase sheet will prompt for the sandbox account at purchase time. Sandbox renewals are accelerated (a "1 month" sub renews every few minutes), which is handy for testing expiry → the app's background sync should flip the user back to free.

**Android**: Play Console → **Setup → License testing** → add the tester's Google account. Upload at least an **internal testing** build so the subscription products resolve. Test purchases on a device signed in with the license-tester account are not charged.

### What "working" looks like

1. Open the upgrade screen → both plans show the **real store price** (not the $4.99/$34.99 fallback). If you see the fallback, offerings didn't load — check that an offering is marked Current and the keys are right.
2. Tap a plan → Subscribe → native sheet → complete with the sandbox account.
3. The screen pops, the user is now premium, premium gates unlock.
4. Force-quit and reopen → still premium (background sync re-confirms via the `premium` entitlement).
5. Tap **Restore Purchases** on a fresh install / reinstall → premium comes back.
6. Cancelling the native sheet → no error toast, just back to the upgrade screen (this is handled explicitly).

---

## How the code uses all this (for reference)

- `main.dart → _maybeInitPurchases()` calls `Purchases.configure(...)` with the platform key before the subscription provider initializes. No key → it logs and returns; the app is free-tier.
- `subscription_provider.dart`:
  - `purchasePlan(plan)` → `getOfferings()` → finds the package for the plan → `purchasePackage()` → unlocks premium **only if** the `premium` entitlement is active.
  - `restorePurchases()` → `Purchases.restorePurchases()` → reconciles against the `premium` entitlement.
  - `_syncWithRevenueCat()` (on launch, non-blocking) → `getCustomerInfo()` → reconciles local state with the entitlement (catches off-device purchases and expiries) and caches localized prices.
  - Premium gating everywhere reads `isPremiumProvider`, which is the `premium` entitlement in release builds.

---

## Troubleshooting

| Symptom                                                         | Likely cause                                                                                                               |
| --------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------- |
| Upgrade screen shows $4.99/$34.99 fallback, not localized price | Offerings didn't load: no Current offering, wrong/missing API key, or products not attached to the offering's packages.    |
| "That plan isn't available right now"                           | The plan's package isn't in the current offering, or the product ID doesn't match.                                         |
| Purchase succeeds but user stays free                           | The product isn't attached to the `premium` entitlement, or the entitlement ID in the dashboard ≠ `premium`.          |
| Products won't load at all on iOS                               | Paid Apps Agreement not active, or product still "Missing Metadata," or bundle ID mismatch between app / ASC / RevenueCat. |
| Products won't load on Android                                  | Base plan not Activated, package name mismatch, or testing on a build that wasn't uploaded to a track.                     |
| Works in debug, not release                                     | Key passed to `flutter run` but not to the release build command. Pass `--dart-define` on the build too.               |

When in doubt, RevenueCat's dashboard has a **Customer history** view — look up the sandbox customer and see exactly which entitlements/products RevenueCat thinks are active. That's the source of truth the app reads.
