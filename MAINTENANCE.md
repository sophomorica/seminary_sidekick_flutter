# Seminary Sidekick — Maintenance Log

> **How this file works**: Running list of housekeeping work — security hygiene, infra/config audits, dependency bumps, perf cleanups, tech-debt nibbles. Anything that isn't a launch-blocking feature or roadmap item.
>
> **Why this is separate from `TODO.md`**: `TODO.md` is feature work pointed at launch and the post-launch roadmap. This file is the slow-burn pile — things we should fix because they accumulate risk over time, not because a user asked for them. Different cadence, different priority math, easier to triage in isolation.
>
> **Conventions**: Same claim/complete ritual as `TODO.md` (set `status: in_progress`, claim, commit; mark `done` and commit on completion). Task IDs use the `MAINT-XXX` prefix to keep them distinct from feature work in `TODO.md`.
>
> Full details on completed items are in git history.

---

## Completed (summary — see git history for details)

| Task | What | Completed |
|------|------|-----------|
| MAINT-001 | Lock down `bump_host_usage` — `0006_lock_bump_host_usage.sql` revokes implicit `PUBLIC` grant + adds internal `auth.uid()` guard; signature/behavior preserved for legitimate callers. Owner step: `supabase db push` + re-run dashboard linter to confirm both `bump_host_usage` warnings clear. | 2026-05-27 |

---

## Active

### MAINT-001: Lock down `bump_host_usage` SECURITY DEFINER function

- **status**: `done` — see Completed table above
- **completed**: 2026-05-27
- **priority**: P1
- **claimed_by**: claude-opus-4-7
- **started**: 2026-05-27
- **files_touched**: NEW `supabase/migrations/0006_lock_bump_host_usage.sql`, `SUPABASE_SETUP.md` (migration table updated; also backfilled rows for 0004 and 0005 which were undocumented)
- **acceptance_criteria**:
  - [x] New migration `0006_lock_bump_host_usage.sql`: revokes implicit `PUBLIC` grant, adds `auth.uid()` guard inside the function body (NULL check + `p_host_id <> auth.uid()` check, both raise 42501), re-grants execute to `authenticated`. Idempotent / replay-safe.
  - [x] `SUPABASE_SETUP.md` runbook table updated (added 0006 + backfilled missing rows for 0004 and 0005).
  - [ ] **Owner step**: `supabase db push` to apply 0006 (along with 0005 if not already pushed), then re-run Supabase dashboard linter — both `bump_host_usage` warnings should clear.
  - [ ] **Owner step**: smoke test that `createRoom` as an anonymous user still bumps the counter end-to-end.
- **notes**:
  - Signature unchanged. Legitimate callers in `GroupPlayService._bumpHostUsage` pass `auth.currentUser.id` which equals server-side `auth.uid()`, so the new guard never fires for them.
  - Guard handles the NULL-comparison edge case: `uuid <> NULL` evaluates to NULL (treated as false in IF), so an explicit `v_uid is null` check precedes the equality test.
  - The migration table in `SUPABASE_SETUP.md` was already stale ("three migration files" with six on disk); fixed in the same edit since adding a row under a stale heading would have been more confusing.

### MAINT-002: Audit anonymous-access RLS policies on group-play tables

- **status**: `open`
- **priority**: P2 — likely intentional design (Kahoot-style room codes), but unverified. Worth a one-pass audit before a wider launch where the surface area becomes attractive.
- **estimated_effort**: Small (read 5 policy files, document what each anon role can and can't do)
- **claimed_by**: —
- **files_to_touch**: `supabase/migrations/0002_rls_policies.sql` (read), NEW short audit note inside `SUPABASE_SETUP.md` under a "RLS audit log" heading
- **description**: Supabase's linter flags six tables for "Anonymous Sign-Ins Allowed" — `answers`, `group_wb_finishes`, `host_usage`, `players`, `rooms`, `saved_rosters`. For Kahoot-style group play this is by design: students join with a 4-letter code and no account. The question is whether the existing RLS policies *scope* anon access tightly enough that an attacker can't read or write rows outside their own session.
- **agent_context_block** (read first):
  - For each of the six tables, the audit should answer:
    1. **Read**: Can an anon user select rows for a room they didn't join? (Should be no for `answers`, `group_wb_finishes`, `players` — yes for `rooms` so join-by-code works.)
    2. **Insert**: Can an anon user insert rows attributing actions to a different `player_id` / `host_id`? (Should be no across the board.)
    3. **Update/Delete**: Same — only the row owner should be able to mutate. Host should be able to update `rooms.phase`, `current_question_index`, etc.
  - `saved_rosters` should be fully off-limits to anon (premium feature, host-scoped).
  - Doesn't require writing migrations unless a gap is found. Output is a short markdown table in `SUPABASE_SETUP.md` documenting what each role can do per table, with any gaps logged as follow-up MAINT items.
- **acceptance_criteria**:
  - [ ] All six flagged tables audited; per-table summary added to `SUPABASE_SETUP.md` (Anon: read/write scope, Authenticated: read/write scope).
  - [ ] Any gap found → filed as a follow-up `MAINT-XXX` here with a proposed fix.
  - [ ] If everything checks out, leave a note in the audit summary so we don't re-litigate.
- **depends_on**: —
- **notes**:
  - The linter doesn't distinguish "anon access is intentional" from "anon access is a bug" — it just flags every table where the `anon` role appears in any policy. So expect to keep most of these warnings *acknowledged but unfixed* after the audit.

### MAINT-003: Enable Supabase Leaked Password Protection

- **status**: `open`
- **priority**: P2 — zero downside, one toggle. Just do it before user signups go live.
- **estimated_effort**: Trivial (dashboard toggle + verify)
- **claimed_by**: —
- **files_to_touch**: `SUPABASE_SETUP.md` (note the toggle in the runbook so a future project clone doesn't miss it)
- **description**: Supabase Auth has a setting that checks new/changed passwords against HaveIBeenPwned's breach corpus and rejects known-compromised ones. Currently disabled (linter warning: "Leaked Password Protection Disabled"). No user-facing cost, no perf concern, just a toggle in Auth settings.
- **acceptance_criteria**:
  - [ ] Supabase dashboard → Authentication → Policies → enable "Leaked password protection" (exact label may shift; it's in the Password section of Auth settings).
  - [ ] `SUPABASE_SETUP.md` runbook updated so this toggle is part of fresh-project setup.
  - [ ] Linter warning clears.
- **depends_on**: —
- **notes**:
  - Group play uses anonymous auth, so this only kicks in if/when we add email+password signup (currently we don't have one). Still worth flipping on now so it's already in place when we do.

---

## Recurring buckets (no active tasks yet — log here as they come up)

- **Dependency updates**: Flutter SDK, Dart SDK, pubspec packages. Cadence: quarterly or when a CVE drops.
- **Supabase platform**: dashboard linter sweeps, RLS audit refresh, migration hygiene (one feature = one migration file, no edits in place).
- **Test health**: flaky tests, slow tests, coverage gaps on critical paths (`progress_provider`, `scripture_mastery`, `group_play_service`).
- **Analyzer / lints**: `flutter analyze` must stay clean; if a new lint rule lands and produces noise, decide once (suppress or fix), don't let warnings accumulate.
- **Asset hygiene**: orphaned `.txt` placeholders (image + audio convention), unreferenced assets in `pubspec.yaml`.
- **Performance**: frame drops in Scripture Builder, cold-start time, Hive box sizes.
