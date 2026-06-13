# RevenueCat Setup — Seminary Sidekick Premium

> **Read this once, top to bottom, before touching any dashboard.** Roughly 45–60 minutes end-to-end, plus Apple/Google review lag on the products themselves.
> Everything here is owner-driven (you). Agents do not touch the RevenueCat, App Store Connect, or Play Console dashboards.

---

## What this gets us

In-app subscriptions for the premium tier (Seminary Sidekick AI, journal, smart goals, deep study tools). RevenueCat sits between the app and the two stores so we write one entitlement check instead of two billing integrations, and we get receipt validation, restore-purchases, and cross-platform subscription status for free.

The free tier of the app is unaffected. If RevenueCat is not configured (no API key), the app runs entirely on the free tier — every premium gate just stays locked. Nothing crashes.

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
- The app's real bundle IDs. Note: the repo currently ships placeholder `com.example.*` bundle IDs — those must be replaced with your real reverse-domain IDs before you create store products (this is tracked separately as a launch blocker). Pick your real IDs now, e.g. `com.<yourorg>.seminarysidekick`.

---

## Step 1 — App Store Connect (iOS): create the subscriptions

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

### About the "Start Free Trial" button

The upgrade screen's CTA currently reads **"Start Free Trial."** That copy is only honest if you actually configure an **introductory offer** (free trial) on the subscriptions. Two choices:

- **Add a free trial**: in each subscription → **Introductory Offers** → create a "Free" offer (e.g. 7 days). Do the equivalent on Play (Step 2). RevenueCat will surface it automatically.
- **Or change the copy**: if you don't want a trial, edit the button text in `upgrade_screen.dart` (the `'Start Free Trial'` string) to `'Subscribe'` or `'Continue'`. Shipping "Start Free Trial" with no trial configured is an App Review rejection risk.

Decide this before submitting for review.

---

## Step 2 — Google Play Console (Android): create the subscriptions

1. Go to https://play.google.com/console → your app → **Monetize → Products → Subscriptions**.
2. Create subscription `seminary_sidekick_monthly`:
   - Add a **base plan**, billing period **monthly (P1M)**, auto-renewing, price **$4.99**.
3. Create subscription `seminary_sidekick_yearly`:
   - Add a **base plan**, billing period **yearly (P1Y)**, auto-renewing, price **$34.99**.
4. **Activate** each base plan (drafts are invisible to the app).
5. If you're offering a free trial, add it as an **offer** on each base plan.

> Android product IDs sometimes carry a base-plan suffix (e.g. `seminary_sidekick_monthly:monthly`). The app's plan-matching handles this — it matches by prefix — so you don't need to special-case it.

---

## Step 3 — RevenueCat dashboard: project, entitlement, products, offering

1. Go to https://app.revenuecat.com → **Create new project** → name it `Seminary Sidekick`.
2. Add your two app platforms under **Project settings → Apps**:
   - **App Store**: paste your real iOS bundle ID. Upload the **App Store Connect App-Specific Shared Secret** (App Store Connect → your app → App Information → "App-Specific Shared Secret") and, for server notifications, the App Store Connect API key — RevenueCat walks you through it.
   - **Play Store**: paste your real Android package name. Upload the **Play service-account credentials JSON** (Play Console → Setup → API access). RevenueCat documents the exact roles to grant.
3. **Entitlements** → create one:
   - **Identifier**: `premium`  ← must match the code constant exactly
   - Description: "Unlocks Seminary Sidekick AI and all premium features."
4. **Products** → import / add the four store products (two per platform):
   - `seminary_sidekick_monthly` (iOS + Android)
   - `seminary_sidekick_yearly` (iOS + Android)
   - Attach **all four** to the `premium` entitlement.
5. **Offerings** → make sure there's a **current** offering (the default one named `default` is fine). Add two **packages** to it:
   - A **Monthly** package → attach the monthly products.
   - An **Annual** package → attach the yearly products.
   - Mark this offering as **Current**. The app reads `offerings.current`, so if no offering is current, the upgrade screen will show "plan unavailable."

---

## Step 4 — Grab the public SDK API keys

In RevenueCat → **Project settings → API keys → Public app-specific keys**:

- iOS key starts with `appl_…`
- Android key starts with `goog_…`

These are *public* SDK keys — safe to ship in the app binary (that's their design). They are **not** the secret key; never put the secret key in the app.

---

## Step 5 — Run the app with the keys

The app reads the keys from `--dart-define` at build/run time (same pattern as Supabase and Sentry). No key = free tier, no crash.

```bash
# Local run (iOS simulator / device)
flutter run \
  --dart-define=REVENUECAT_IOS_KEY=appl_xxxxxxxxxxxxxxxx

# Local run (Android)
flutter run \
  --dart-define=REVENUECAT_ANDROID_KEY=goog_xxxxxxxxxxxxxxxx

# Release build — pass everything you use together
flutter build ipa \
  --dart-define=REVENUECAT_IOS_KEY=appl_xxx \
  --dart-define=SUPABASE_URL=... \
  --dart-define=SUPABASE_ANON_KEY=... \
  --dart-define=SENTRY_DSN=...

flutter build appbundle \
  --dart-define=REVENUECAT_ANDROID_KEY=goog_xxx \
  --dart-define=SUPABASE_URL=... \
  --dart-define=SUPABASE_ANON_KEY=... \
  --dart-define=SENTRY_DSN=...
```

A `--dart-define-from-file=config.json` (gitignored) is a tidy way to keep all of these together rather than a giant command line. Don't commit the keys.

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
