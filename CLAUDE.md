# Seminary Sidekick — Narrow Road Studios

Context is loaded by role — read only what your role lists. Don't preload other standards; the validator enforces them.

- **Workers:** this file + your task spec. Definition of done is below; everything else comes from the spec.
- **Validator / design-reviewer:** your agent file tells you which standards to read (`../narrow-road-hq/standards/`).
- **Main / planning sessions only:** also follow `../narrow-road-hq/standards/OPERATING_MANUAL.md` — especially §4 (re-derive, never vibes), §5 (VERIFIED/INFERRED/ASSUMED labels), and the pre-send self-test.

Design identity for THIS product lives in `PRODUCT_DESIGN.md` (this repo). Universal floors are shared; the vibe is this product's own.

## Non-negotiables
- Definition of done = `../narrow-road-hq/standards/CODE_STANDARDS.md` §Definition of done. The Stop hook enforces the deterministic parts; do not try to bypass it.
- Work is not complete until `/review` (validator subagent) returns PASS.
- Workers make no architectural decisions — escalate instead of improvising.
- No orphaned components: everything merged must be reachable and imported.

## Commands
- deps: `flutter pub get`
- analyze: `flutter analyze` (must exit clean — zero issues, including infos)
- test: `flutter test` (dir: `flutter test test/providers/`; coverage: `flutter test --coverage`)
- run: `flutter run` (Sentry: add `--dart-define=SENTRY_DSN=...`)
- iOS release: **ALWAYS** `./scripts/build_ios_release.sh` — never `flutter build ipa` by hand (a bare build shipped as 1.0.0+3 → broken purchases → 2.1(b) rejection).

## Stack rules
- Flutter / Dart. Riverpod (StateNotifier) for state; GoRouter with StatefulShellRoute for bottom nav; Hive for lightweight persistence; Supabase (Realtime + anon auth) for Group Play; RevenueCat for subscriptions.
- Never generate image or audio files (no TTS, no synthesis, no auto `.wav`) — use `.txt` placeholders per CODE_STANDARDS §Asset placeholders and `docs/CONVENTIONS.md`.
- Never hardcode colors or text styles — `AppTheme.*` and `Theme.of(context).textTheme.*` only.
- Coverage on providers, models, navigation, and core flows.
- `flutter analyze` must be clean before done — see FLUTTER_APP_STANDARDS.md §Flutter analyze pitfalls (const, unused imports, SizeTransition.axisAlignment ≠ Align.alignment, etc.).

## Repo-specific notes
- Scripture Builder is the PRIMARY mastery tool and lives under scripture detail — it is NOT a quiz and does not go in the practice hub. Mastery is driven only by Scripture Builder progression.
- Group Play NEVER writes to personal mastery/progress — purely social.
- Sidekick AI calls go through the `sidekick-proxy` Supabase Edge Function; the xAI key lives only as a Supabase secret — never in the client.
- Sentry privacy: never put user-generated content (journal entries, notes, chat, nicknames) in breadcrumbs/tags; `sendDefaultPii` stays off.
- Task boards: `TODO.md` (`TASK-XXX`) and `MAINTENANCE.md` (`MAINT-XXX`) — claim/complete ritual in `docs/AGENT_WORKFLOW.md`.
- Shared files (extra caution, no concurrent edits): `enums.dart`, `games_hub_screen.dart`, `main.dart`, `pubspec.yaml`, `TODO.md`.
- Skills: `/grill-me` (deep questioning on mechanics/UX/architecture), `/request-refactor-plan` (before major refactors), `/sidekick-prompt` (Grok system prompt help).
- Multi-agent review loops: coordinate through `HANDOFF.md` at the repo root per `../narrow-road-hq/standards/LOOP_STANDARDS.md`. Workers set `IN_PROGRESS`/`NEEDS_REVIEW`/`BLOCKED`; reviewers set `REVIEWING`/`CHANGES_REQUESTED`/`PASS`; planners set `PLAN_READY`. Never set a state you don't own; the loop ends only at `PASS`.

## Doc map
- `docs/OVERVIEW.md` — what the app is, core loop, UX/landing/design principles, business model, status. Read before product/UX decisions.
- `docs/ARCHITECTURE.md` — tech stack, project structure, data model, mastery system, key files reference. Read before touching code.
- `docs/FEATURES.md` — Scripture Builder tiers, Memorize tool, supplementary quizzes. Read when working on games/mastery.
- `docs/CONVENTIONS.md` — asset placeholders, naming, theme tokens, lint hygiene, provider/screen/navigation patterns, data access, new-tool checklists. Read before writing any Dart.
- `docs/AGENT_WORKFLOW.md` — task claim/complete ritual, file ownership, commit format. Read before claiming a task.
- `docs/TESTING.md` — test layout, priorities, StateNotifier/ProviderContainer patterns. Read before writing tests.
- `docs/BUILD_AND_RELEASE.md` — build/run commands, Sentry setup and privacy rules. Read before builds or crash-reporting work.
- `docs/STATUS.md` — historical task/launch status log. Read for project history context.
- `TODO.md` — feature/launch task board + current 🚀 Launch Status. Read to find or claim work.
- `MAINTENANCE.md` — maintenance board (security, deps, infra, tech debt). Read for hygiene work.
- `README.md` — public project readme. Rarely needed by agents.
- `PRODUCT_DESIGN.md` — this product's design identity/vibe. Read before UI work.
- `APP_STORE_SUBMISSION.md` — iOS submission pack (listing, privacy, review notes, checklist). Read for App Store work.
- `LAUNCH_READINESS_REPORT.md` — 2026-07-01 claim-by-claim launch verification. Read when auditing launch readiness.
- `REVENUECAT_SETUP.md` — RevenueCat runbook (products, entitlement, keys, sandbox). Read for subscription work.
- `SUPABASE_SETUP.md` — Supabase runbook (migrations, edge fns, key rotation, cost). Read for backend/Group Play infra work.
- `SIDEKICK_SAFETY_TEST.md` / `SIDEKICK_SAFETY_STRESS_TEST.md` — AI safety test suites. Read when changing Sidekick prompts/safety.
