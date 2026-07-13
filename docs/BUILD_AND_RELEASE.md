## Build & Run

```bash
flutter pub get          # Install deps
flutter analyze          # Must pass with no errors
flutter test             # Run all tests
flutter run              # Run app
```

### Crash Reporting (Sentry)

Wired through `lib/services/crash_reporting_service.dart`, enabled only when a DSN is provided at build/run time (same `--dart-define` pattern as Supabase):

```bash
flutter run --dart-define=SENTRY_DSN=https://...@oXXXX.ingest.sentry.io/XXXX
# Release builds: ALWAYS use ./scripts/build_ios_release.sh — it loads .env,
# validates every required dart-define (RevenueCat/Supabase, warns on Sentry),
# and tags APP_RELEASE automatically. Never run `flutter build ipa` by hand
# (a bare build shipped as 1.0.0+3 → broken purchases → 2.1(b) rejection).
```

Without `SENTRY_DSN` the service is a silent no-op (dev/CI/tests send nothing).

**Privacy rules** — never put user-generated content in breadcrumbs, tags, or contexts: no journal entries, scripture notes, chat messages, or nicknames. Scripture IDs and tab/route names are fine. `sendDefaultPii`, screenshots, and view hierarchy are disabled in the service; do not turn them on.

**Transient HTTP filtering** — Sentry's default failed-request capture treats 5xx responses as `HTTPClientError`. Upstream overload codes (`429` / `502` / `503` / `529`, e.g. xAI via `sidekick-proxy`) are dropped in `beforeSend` and native iOS failed-request capture is off (`captureNativeFailedRequests = false`) so expected Sidekick blips do not open crash issues (FLUTTER-6). Real app defects and non-transient 5xx still report.

For handled exceptions worth field visibility, call `CrashReportingService.recordError(e, st, hint: '...')` in the catch block. Use `CrashReportingService.addBreadcrumb(...)` for notable user actions (categories: `navigation`, `game`, `purchase`, ...).

