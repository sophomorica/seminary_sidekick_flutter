# Supabase Setup — Seminary Sidekick Group Play

> **Read this once, top to bottom, before running any commands.** Roughly 20–30 minutes end-to-end.
> Everything here is owner-driven (you). Agents do not touch the Supabase dashboard.

---

## What this gets us

A dedicated Supabase project that powers the multiplayer "Seminary Group Play" feature: 4-letter room codes, live quizzes for up to 30 students, anonymous student auth, and a saved-class-rosters feature for premium teachers.

The free tier of the Flutter app is unaffected. None of the existing solo features (Scripture Builder, Quick Quiz, Scripture Match, mastery tracking, journal, Sidekick AI) talk to this database.

---

## Prerequisites

- Supabase CLI installed (`supabase --version` should print). You said you already have it from your other project.
- Logged in (`supabase login`). One-time browser auth.
- A Supabase account with an organization. The free tier is fine to start.

---

## Step 1 — Create a NEW Supabase project (separate from your other one)

Do this in the dashboard, not the CLI. Reasons we want a separate project rather than reusing your existing one:

- Quota and billing isolation. If this app blows up, the Realtime connection cap on this project is hit, not your other project's.
- Schema clarity. No mixing of tables from two unrelated apps.
- Easier handoff. If anyone ever picks up this app's backend, they get one project, not a tangled namespace.

**Do this:**

1. Go to https://supabase.com/dashboard.
2. Click **New project**.
3. Name it something like `seminary-sidekick`.
4. Pick a strong DB password. Stash it in a password manager — you won't need it day-to-day, but you'll need it once for the CLI link.
5. Pick a region close to your users. For a US/Canada-focused LDS audience, **us-west-1** or **us-east-1** is fine.
6. Free plan is correct for now. You will not exceed free-tier limits during development.
7. Wait ~90 seconds for the project to provision.

---

## Step 2 — Grab three credentials

From the new project's dashboard:

| Credential | Where | What it's for |
|---|---|---|
| **Project URL** | Project Settings → API → "Project URL" | Used by the Flutter app to know which Supabase to talk to |
| **anon (public) key** | Project Settings → API → "Project API keys" → `anon` `public` | Used by the Flutter app. Safe to ship in the client. |
| **Project ref** | Project Settings → General → "Reference ID" | Used by the CLI to link to this project |

Stash the URL and anon key in your password manager. **Do not commit them to git.** They go in via `--dart-define` at build time (see Step 7).

There is also a `service_role` key on the same page. **Never** put that in the Flutter app or commit it. It bypasses RLS. We do not need it for v1.

---

## Step 3 — Initialize Supabase locally and link to the project

From the project root (`/Users/muse/Desktop/active/seminary_sidekick`):

```bash
# One-time: create the supabase/ folder structure (config.toml, migrations/, etc.)
supabase init
```

If you already have `supabase/migrations/` in the repo (you will after this task — three migration files were just created), `supabase init` will leave them alone. It only adds `supabase/config.toml` and a few placeholder files if missing.

Then link to the cloud project you just created:

```bash
supabase link --project-ref <YOUR_PROJECT_REF>
```

It will prompt for the database password from Step 1.

---

## Step 4 — Push the migrations to the cloud project

The migration files committed to `supabase/migrations/` are:

| File | What it does |
|---|---|
| `0001_group_play_init.sql` | Creates `rooms`, `players`, `answers`, `saved_rosters`, `host_usage` tables + indexes + the `bump_host_usage()` helper function |
| `0002_rls_policies.sql` | Row-level security: anyone authenticated can read; writes are scoped to the row owner |
| `0003_realtime.sql` | Adds `rooms`, `players`, `answers` to the `supabase_realtime` publication |
| `0004_replica_identity_full.sql` | `REPLICA IDENTITY FULL` on `rooms` / `players` / `answers` so Realtime can evaluate filters on DELETE events (e.g. host kicking a player) |
| `0005_group_sb_finishes.sql` | Adds `group_sb_finishes` table + RLS + realtime for the Scripture Builder race mode (TASK-062) |
| `0006_lock_bump_host_usage.sql` | **MAINT-001**: revokes the implicit `PUBLIC` execute grant on `bump_host_usage()` and adds an internal `auth.uid()` guard so callers can only bump their own row |

Push them:

```bash
supabase db push
```

This applies the migrations to the cloud project in order. When it finishes, open the dashboard's **Table Editor** and verify all five tables exist.

> **If you ever want to start over** during early development, `supabase db reset --linked` rolls back and re-applies. Don't run that against prod once you have real users.

---

## Step 5 — Enable Anonymous Auth

This is a dashboard click, not a migration. Anonymous auth is what lets a kid type a 4-letter code + nickname and start playing without signing up.

1. Dashboard → **Authentication** → **Providers**.
2. Find **Anonymous** in the list.
3. Toggle it **on**.
4. Save.

There is nothing to configure beyond the toggle.

---

## Step 6 — Verify Realtime is on (it usually is by default)

1. Dashboard → **Database** → **Replication**.
2. Confirm the `supabase_realtime` publication includes `rooms`, `players`, `answers`. The `0003_realtime.sql` migration should have added them, but check.
3. Dashboard → **Realtime** → confirm it shows "Enabled" for the project. Free tier gives you 200 concurrent connections, which is plenty for development and small-class testing.

---

## Step 7 — Pass credentials to the Flutter app

Two new keys join the existing `--dart-define` pattern (you already use this for the Grok/xAI key for Sidekick).

When running locally:

```bash
flutter run \
  --dart-define=XAI_API_KEY=<your-grok-key> \
  --dart-define=SUPABASE_URL=<your-project-url> \
  --dart-define=SUPABASE_ANON_KEY=<your-anon-key>
```

For builds (App Store / Play Store), the agent will wire these into your CI build config when TASK-052 lands. For now, only your dev machine needs them.

There will be a `.env.example` file added in the foundation task showing the expected variables (without real values). **Add `.env` to `.gitignore` if it isn't already.**

---

## Step 8 — Smoke test

Once TASK-052 (the Dart foundation task) is done, the agent will add a tiny smoke-test path you can run:

1. Launch the app with the three `--dart-define` args.
2. The app calls `supabase.auth.signInAnonymously()` on first launch and stashes the session.
3. Navigate to **Practice → Group Play → Host** (or whatever entry point lands first).
4. Create a room. Verify in the Supabase **Table Editor** that a new row appeared in `rooms` with your anonymous `auth.uid()` as `host_id`.
5. On a second device or a second simulator, **Practice → Group Play → Join**, type the code + a nickname, and confirm a row appears in `players`.

If both rows appear and the host's lobby screen updates in real-time when the second player joins, the backend is wired correctly.

---

## Cost monitoring (worth doing once a month)

- Dashboard → **Reports** → **Realtime**. Watch the **concurrent connections** chart. As long as that peak stays under 200, you're on the free tier.
- Dashboard → **Reports** → **Database**. Watch egress. We're storing tiny rows so DB cost is nothing.
- If you get a "concurrent connections" alert, that's your signal to upgrade to Pro ($25/mo, raises the cap to 500 with metered scale-up). Don't preemptively upgrade — your free-tier headroom is genuinely large for an indie app.

---

## What you do NOT need to set up

- No custom Postgres functions beyond `bump_host_usage()` (already in the migration).
- No edge functions for v1. Everything happens via the Supabase client SDK from Flutter.
- No backend server. The Dart code talks to Supabase directly.
- No CI step yet — the agent will propose one if/when it makes sense.

---

## Troubleshooting

**`supabase db push` says "permission denied for schema public"**
You're running it against a Supabase project where you're not the owner. Re-link with the right project ref.

**Anonymous sign-in returns 422**
Anonymous auth isn't enabled. Re-do Step 5.

**"new row violates row-level security policy" when creating a room**
The client called `supabase.from('rooms').insert(...)` before `signInAnonymously()` finished. The agent's `GroupPlayService` handles this in TASK-052 by awaiting the auth session before any DB call — verify that ordering when reviewing the PR.

**Players see the lobby but not real-time joins**
Realtime isn't enabled on the `players` table. Run `supabase db push` again, or manually toggle it in the **Replication** dashboard.

---

## When TASK-058 (saved rosters) lands, no extra setup needed

The `saved_rosters` table and its RLS policy are already in the v1 schema. Premium gating happens client-side via `isPremiumProvider` in the Flutter app.

---

## Sidekick AI proxy — `sidekick-proxy` Edge Function (added 2026-06-13)

The premium Sidekick (Grok/xAI) no longer ships its API key in the app. Requests
go through a Supabase Edge Function that holds the key server-side and prepends an
authoritative safety prompt. Code: `supabase/functions/sidekick-proxy/index.ts`;
client call site: `lib/services/sidekick_service.dart` (`functions.invoke`).

**Owner deploy steps (one-time + on changes):**

1. Set the Grok key as a function secret (NOT a client dart-define anymore):
   ```bash
   supabase secrets set XAI_API_KEY=xai-...your-real-key...
   ```
2. Deploy the function:
   ```bash
   supabase functions deploy sidekick-proxy
   ```
3. Leave JWT verification ON (default). The app's anonymous Supabase session
   authorizes the call automatically via `functions.invoke`, so Sidekick only
   works when Supabase is configured (`SUPABASE_URL` / `SUPABASE_ANON_KEY`).

**Smoke test:** open the app as a premium user (or dev-mode premium), trigger a
Sidekick session/chat, and confirm a response comes back. A 500 "missing
XAI_API_KEY" means the secret wasn't set; a 401/403 means JWT/anon-session issue.

> Editing the safety prompt: keep the copy in the Edge Function in sync with
> `_safetyGuardrails` in `lib/services/sidekick_service.dart`.
