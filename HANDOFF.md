# HANDOFF — TASK-079

- **task**: TASK-079 In-app announcements banner (Supabase-backed)
- **state**: `NEEDS_REVIEW`
- **branch**: `cursor/in-app-announcements-banner-d55b`
- **worker**: cursor-agent-task-079
- **reviewer**: —
- **updated**: 2026-07-20T17:00:00Z

## Summary

Adds a Supabase-backed Home announcement banner so owners can reach every app user with news, feature alerts, events, and how-to tips (GIF/image) without push notifications. Clients fetch on launch; users dismiss locally (Hive).

## What changed

- Migration `0009_announcements.sql` — `announcements` table + RLS (authenticated SELECT of active window) + public-read `announcement-media` storage bucket
- Model / service / provider + Home `AnnouncementBanner` (tap → detail sheet with media + CTA)
- `main.dart` init/refresh after Supabase; data reset clears dismissals
- Docs: `SUPABASE_SETUP.md` publish recipe, `FEATURES.md`, `ARCHITECTURE.md`
- Tests: model + provider

## Owner follow-up

- Run `supabase db push` to apply `0009` on the live project
- Publish announcements via Table Editor / SQL (see `SUPABASE_SETUP.md`)

## Verification (worker)

- `flutter analyze` — clean (0 issues)
- `flutter test test/models/announcement_test.dart test/providers/announcement_provider_test.dart` — 12/12 green

## Reviewer verdict

— (awaiting `/review`)
