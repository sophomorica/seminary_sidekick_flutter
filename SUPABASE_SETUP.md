# Supabase Setup — Seminary Sidekick

> **Status: provisioned and live.** The backend is fully set up — this file is a
> maintenance runbook, not a first-time walkthrough. The one-time provisioning
> (create project, link, push migrations, enable anonymous auth + realtime, deploy
> the Sidekick proxy) is all done. Keep this for redeploys, key rotation, and debugging.

---

## Current state (verified 2026-06-13)

| Thing | Value |
|---|---|
| Project | `seminary-sidekick` (ref `feqxdylouvoulhqwsffp`, West US / N. California) |
| Migrations | `0001`–`0006` applied; local and remote in sync (`supabase migration list`) |
| Anonymous auth | Enabled (required for Group Play join-by-code) |
| Realtime | Enabled — `rooms`, `players`, `answers`, `group_sb_finishes` in the `supabase_realtime` publication |
| Edge function | `sidekick-proxy` deployed, ACTIVE (powers premium Sidekick AI) |
| Secret | `XAI_API_KEY` set on the project (server-side only) |

The free/solo side of the app (Scripture Builder, quizzes, mastery, journal) does **not**
touch Supabase. Only **Group Play** and the **premium Sidekick AI** do.

---

## Migration reference

| File | What it does |
|---|---|
| `0001_group_play_init.sql` | `rooms`, `players`, `answers`, `saved_rosters`, `host_usage` tables + indexes + `bump_host_usage()` |
| `0002_rls_policies.sql` | Row-level security — authenticated reads; writes scoped to the row owner |
| `0003_realtime.sql` | Adds `rooms`, `players`, `answers` to the `supabase_realtime` publication |
| `0004_replica_identity_full.sql` | `REPLICA IDENTITY FULL` so Realtime can filter DELETE events (e.g. host kicking a player) |
| `0005_group_sb_finishes.sql` | `group_sb_finishes` table + RLS + realtime for the Scripture Builder race (TASK-062) |
| `0006_lock_bump_host_usage.sql` | MAINT-001 — revokes the implicit `PUBLIC` grant on `bump_host_usage()`, adds an `auth.uid()` guard |

Apply new migrations with `supabase db push`; check sync with `supabase migration list`.
(`supabase db reset --linked` re-applies from scratch — **never** run it against prod with real users.)

---

## Sidekick AI proxy — `sidekick-proxy` Edge Function

Premium Sidekick (Grok/xAI) does **not** ship its API key in the app. Requests go through
this Edge Function, which holds the key server-side and prepends an authoritative safety
prompt. Code: `supabase/functions/sidekick-proxy/index.ts`; client call site:
`lib/services/sidekick_service.dart` (`functions.invoke`).

**Redeploy after code changes / rotate the key:**

```bash
supabase secrets set XAI_API_KEY=xai-...your-real-key...   # set or rotate the key
supabase functions deploy sidekick-proxy                    # deploy
```

JWT verification stays ON (default): the app's anonymous Supabase session authorizes the
call via `functions.invoke`, so Sidekick only works when `SUPABASE_URL` / `SUPABASE_ANON_KEY`
are configured.

**Premium entitlement gate (added 2026-07-02).** Sidekick chat is premium-only. The client
sends its RevenueCat `app_user_id` with each request, and the function verifies the
`premium` entitlement against the RevenueCat REST API (cached ~15 min per user) before
calling xAI — a tampered client can no longer chat for free. Enforcement requires a
RevenueCat **secret** API key (Project settings → API keys → Secret key, `sk_...`):

```bash
supabase secrets set REVENUECAT_SECRET_KEY=sk_...          # enables the gate
supabase functions deploy sidekick-proxy                    # redeploy with the check
```

⚠️ Owner step pending: `REVENUECAT_SECRET_KEY` has NOT been set yet — until it is, the
function logs a warning and skips the check (dev-friendly fail-open). Set it before launch.
The client UI also gates free users (teaser + locked input on the Sidekick tab), so the
server check is defense-in-depth, not the primary UX.

> Keep the safety prompt in the Edge Function in sync with `_safetyGuardrails` in
> `lib/services/sidekick_service.dart`.

---

## Client credentials

The app reads three values at build time (kept in the gitignored `.env`; see `.env.example`):
`SUPABASE_URL`, `SUPABASE_ANON_KEY`, `REVENUECAT_IOS_KEY`. The xAI key is **not** a client value
— it lives only as the Supabase secret above (the `.env` copy is an inert reference).

```bash
flutter run --dart-define-from-file=.env
```

---

## Cost monitoring (worth a monthly glance)

- Dashboard → **Reports → Realtime**: watch peak **concurrent connections**. Free tier caps at
  200 — plenty for development and small-class testing. A "concurrent connections" alert is the
  cue to consider Pro ($25/mo → 500 + metered). Don't preemptively upgrade.
- Dashboard → **Reports → Database**: egress is negligible (tiny rows).

---

## Troubleshooting

- **"new row violates row-level security policy"** — a DB call ran before `signInAnonymously()`
  finished. `GroupPlayService` awaits the auth session before any DB call; verify that ordering.
- **Anonymous sign-in returns 422** — anonymous auth got disabled. Re-enable under
  Authentication → Providers.
- **Players see the lobby but not real-time joins** — the `players` table fell out of the realtime
  publication. Re-run `supabase db push` or toggle it under Database → Replication.
- **Sidekick returns the offline fallback** — the `sidekick-proxy` function or `XAI_API_KEY` secret
  is missing; a 500 "missing XAI_API_KEY" confirms the secret. Redeploy / re-set per the section above.
