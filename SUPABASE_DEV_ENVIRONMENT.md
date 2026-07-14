# Supabase Dev Environment — Setup Spec

> **Goal:** stand up a second Supabase project (`seminary-sidekick-dev`) so local
> development never touches production. Written as an executable spec for an
> agent with the Supabase plugin/CLI. Production project: `seminary-sidekick`
> (ref `feqxdylouvoulhqwsffp`). See `SUPABASE_SETUP.md` for the prod runbook.

## Why

There is currently ONE Supabase project, shared between local dev and what will
be production. Post-launch, any of these against prod would hit real users:
a bad migration, `supabase db reset --linked`, edge-function experiments,
Realtime debugging, or purging anonymous auth users.

**Target state:** debug builds default to dev; only `./scripts/build_ios_release.sh`
knows prod credentials; migrations flow dev → prod, never dashboard-edited on prod.

---

## Phase 1 — Create the dev project

1. Create a new Supabase project:
   - Name: `seminary-sidekick-dev`
   - Region: **West US (N. California)** — match prod
   - Tier: Free (fine for dev; Realtime cap of 200 concurrent is plenty)
2. Record the new project **ref**, **URL**, and **publishable/anon key**
   (Settings → API). Do NOT record the service-role key anywhere in the repo.

## Phase 2 — Replicate prod configuration

All of this mirrors the "Current state" table in `SUPABASE_SETUP.md`.

1. **Apply migrations** `0001`–`0008` from `supabase/migrations/`:
   ```bash
   supabase link --project-ref <DEV_REF>
   supabase db push
   supabase migration list   # verify local and remote in sync
   ```
   ⚠️ The repo is currently linked to prod. After any work, verify which project
   is linked before running `db push` / `db reset`. Prefer passing
   `--project-ref` explicitly in scripts.
2. **Enable anonymous auth** (Authentication → Providers → Anonymous). Required
   for Group Play join-by-code. CAPTCHA not needed on dev.
3. **Verify Realtime publication** — `rooms`, `players`, `answers`,
   `group_sb_finishes` must be in `supabase_realtime` (migrations 0003/0005
   handle this; confirm under Database → Replication).
4. **Deploy the edge function:**
   ```bash
   supabase functions deploy sidekick-proxy --project-ref <DEV_REF>
   ```
5. **Set secrets** on the dev project:
   ```bash
   supabase secrets set XAI_API_KEY=<key> --project-ref <DEV_REF>
   supabase secrets set REVENUECAT_SECRET_KEY=<sk_...> --project-ref <DEV_REF>
   ```
   - `XAI_API_KEY`: reuse the prod xAI key (usage is trivial) OR create a
     second xAI key named `sidekick-dev` for clean cost attribution. Escalate
     to Patrick if a new key is preferred.
   - `REVENUECAT_SECRET_KEY`: reuse prod's — RevenueCat is one project; sandbox
     purchases grant the same `premium` entitlement. Note the gate fails
     closed: without this secret, Sidekick chat returns 403 even on dev.

## Phase 3 — Client env files

1. Update `.env.example`: add a comment block explaining the two-env scheme.
2. Create **`.env.dev`** (gitignored — verify `.gitignore` covers `.env*`
   except `.env.example`):
   ```
   SUPABASE_URL=https://<DEV_REF>.supabase.co
   SUPABASE_ANON_KEY=<dev publishable key>
   REVENUECAT_IOS_KEY=<same as prod — RevenueCat sandbox handles test purchases>
   ```
3. Keep the existing `.env` as **prod** credentials (or rename to `.env.prod`
   and update `scripts/build_ios_release.sh` accordingly — if renaming, grep
   the whole repo + scripts for `.env` references first).
4. Day-to-day dev command becomes:
   ```bash
   flutter run --dart-define-from-file=.env.dev
   ```

## Phase 4 — Guardrails so prod can't be hit by accident

1. **Release script owns prod.** `./scripts/build_ios_release.sh` must be the
   only path that injects prod `SUPABASE_URL`/`SUPABASE_ANON_KEY`. Verify it
   reads from the prod env file explicitly.
2. **Debug banner (optional but recommended):** in `lib/main.dart`, where
   `SUPABASE_URL` is read (~line 177), log which environment is active and,
   in debug mode, show a small "DEV backend" indicator if the URL is not the
   prod ref — prevents "why is my test room in prod" confusion. This is a UI
   change: check `PRODUCT_DESIGN.md` and keep it debug-only
   (`kDebugMode`). No hardcoded colors — `AppTheme.*` only.
3. **Never** run `supabase db reset --linked` while linked to prod. Add this
   warning to `SUPABASE_SETUP.md` next to the existing reset note, with the
   dev-project ref listed so the safe target is unambiguous.

## Phase 5 — Migration workflow going forward

Document this in `SUPABASE_SETUP.md` (new section "Two-project workflow"):

1. Write migration SQL in `supabase/migrations/NNNN_*.sql` (repo is source of truth).
2. Push to **dev** first: `supabase db push --project-ref <DEV_REF>`.
3. Test the affected flow on a device/simulator against dev.
4. Push to **prod**: `supabase db push --project-ref feqxdylouvoulhqwsffp`.
5. Never edit prod schema/policies in the dashboard; if an emergency dashboard
   change happens, back-port it into a migration file immediately.

Edge-function changes follow the same order: deploy to dev, test Sidekick chat
end-to-end, then deploy to prod.

## Phase 6 — Verification checklist (definition of done)

- [ ] `supabase migration list --project-ref <DEV_REF>` shows 0001–0008 in sync
- [ ] Anonymous sign-in succeeds against dev (run app with `.env.dev`, open Group Play)
- [ ] Host a room + join from a second client — Realtime lobby updates work on dev
- [ ] Sidekick chat works on dev with a sandbox-premium user; non-premium gets 403
- [ ] `flutter run --dart-define-from-file=.env.dev` is documented in `docs/BUILD_AND_RELEASE.md`
- [ ] `SUPABASE_SETUP.md` updated: two-project workflow section + dev project in the state table + migration table includes 0008 (currently missing)
- [ ] Release script verified to inject prod creds only
- [ ] `.gitignore` confirmed to exclude `.env.dev`
- [ ] `flutter analyze` clean; `/review` returns PASS

## Out of scope / escalate

- Local Docker stack (`supabase start`) — nice later for offline work; not part
  of this task.
- Seeding dev with test data beyond what migrations create — escalate if needed.
- Any change to prod project settings.

## Notes for the agent

- Shared-file caution applies: `main.dart` is on the no-concurrent-edits list.
- The service-role key must never land in the repo, `.env*` files, or logs.
- Claim this via the `TODO.md`/`MAINTENANCE.md` ritual in `docs/AGENT_WORKFLOW.md`.
