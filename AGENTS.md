# AGENTS.md

Product-, workflow-, and code-standards context lives in `CLAUDE.md` (start there). This file only adds cloud-environment specifics.

## Cursor Cloud specific instructions

Environment: Flutter `3.44.7` (Dart `3.12.2`), stable channel, installed at `/opt/flutter`. `/opt/flutter/bin` is on `PATH` via `~/.bashrc`. The update script runs `flutter pub get` on startup, so dependencies are already fetched.

Standard commands (analyze / test / run) are documented in `CLAUDE.md` §Commands — use those. `flutter analyze` is clean and `flutter test` (~796 tests) passes on a fresh checkout.

Running the app in the cloud VM:
- This is a mobile-first app (iOS primary, Android). There is no Android emulator (no `/dev/kvm`) and iOS builds are impossible on Linux, so the only way to visually run/preview the app here is the Flutter **web** target: `flutter run -d chrome` (or `flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080` and open `http://localhost:8080` in Chrome). `flutter build web` also succeeds.
- Non-obvious gotcha: web crashes at startup with `Unsupported operation: Platform._operatingSystem`. `_maybeInitPurchases()` in `lib/main.dart` calls `Platform.isIOS/isAndroid` without a `kIsWeb` guard, and `dart:io` `Platform` does not exist on web. To preview on web, temporarily wrap those checks in `if (!kIsWeb) { ... }` (import `package:flutter/foundation.dart`). Do NOT commit this — web is not a shipping target; it is only a cloud preview aid. Lint, tests, and `flutter build web` are unaffected by this issue.
- Flutter web uses the CanvasKit renderer; screen recordings can show blank/streaked canvas regions even when the app renders correctly. Prefer screenshots (not video) as UI evidence for the web target in the cloud.

Credentials: the solo scripture-mastery loop (home → library → Scripture Builder) runs fully with no external credentials. Group Play (Supabase), Sidekick AI (xAI via `sidekick-proxy` edge function), and RevenueCat purchases are optional and only activate when their keys are passed via `--dart-define` (see `SUPABASE_SETUP.md` and `REVENUECAT_SETUP.md`). Purchases and speech-to-text are mobile-only and no-op on web.
