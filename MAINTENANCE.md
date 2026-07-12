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
| MAINT-001 | Lock down `bump_host_usage` — `0006_lock_bump_host_usage.sql` revokes implicit `PUBLIC` grant + adds internal `auth.uid()` guard; signature/behavior preserved for legitimate callers. `supabase db push` done (0001–0006 local+remote in sync, 2026-06-13); dashboard-linter re-check folded into MAINT-002. | 2026-05-27 |
| MAINT-004 | Scripture Builder typing mode: a user-typed punctuation char (e.g. the comma in "world,") counted as a wrong character — and triggered a full reset on Master difficulty. Found live during App Store screenshot capture. Fix: `onType` now ignores every `_isAutoFillChar` (spaces AND punctuation) typed by the user, since auto-fill already inserts them. Two regression tests added in `scripture_builder_provider_test.dart` (advanced: no error/no attempt increment; master: no reset). | 2026-07-03 |
| MAINT-005 | `share_plus` ^7.2.2 → ^10.1.4 after Apple rejected build 1 in processing (**ITMS-91061 Missing privacy manifest** — 7.2.2 predates the required `PrivacyInfo.xcprivacy`; included since 8.0.2). Same `Share.share()`/`shareXFiles()` API, zero code changes; app version bumped 1.0.0+1 → 1.0.0+2, build 2 resubmitted 2026-07-05. Lesson for future bumps: any SDK on Apple's [required-manifest list](https://developer.apple.com/support/third-party-SDK-requirements) must ship a privacy manifest or upload processing rejects the binary. | 2026-07-05 |
| MAINT-006 | Scripture Builder Advanced typing display was revealing the next correct letter as a "cursor" highlight, defeating first-letter-only hints. Untyped Advanced positions now stay first-letter hints + underscores; cursor chrome highlights the slot without disclosing non-hint letters. Master blanking unchanged. | 2026-07-12 |

---

## Active

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

### MAINT-006: Scripture Builder Advanced — stop revealing next letter

- **status**: `done`
- **completed**: `2026-07-12T15:30:00Z`
- **priority**: P1 — Advanced difficulty is supposed to give first-letter hints only; revealing the next correct letter undercuts the challenge.
- **claimed_by**: `cursor-cloud-97ed`
- **started**: `2026-07-12T15:28:33Z`
- **files_to_touch**: `lib/screens/games/scripture_builder/scripture_builder_screen.dart`, `lib/screens/games/scripture_builder/typed_display_rules.dart`, `test/screens/typed_display_rules_test.dart`
- **description**: In Advanced typing mode, `_buildTypedSpans` highlights the cursor by literally painting `target[i]` (the next correct character). That spoiler defeats the "first letters shown, rest hidden" contract. Untyped positions should stay first-letter hints + underscores only; optional subtle cursor chrome is fine as long as it never discloses a non-hint letter.
- **acceptance_criteria**:
  - [x] Advanced untyped display never shows a letter that is not a first-letter-of-word hint
  - [x] Master mode still fully blanks non-space characters (no regression)
  - [x] `flutter analyze` clean
- **depends_on**: —
- **notes**:
  - Reported by owner: Advanced always shows the next correct letter while typing.
  - Fix: removed the spoiler branch that painted `target[i]` at the cursor; Advanced now always uses first-letter/underscore rules, with a subtle background highlight on the current typing slot.
  - Verified: `flutter analyze` clean; `scripture_builder_provider_test.dart` 45/45 green.
  - Review follow-up (2026-07-12): display rules extracted to `typed_display_rules.dart` (pure, unit-tested — `test/screens/typed_display_rules_test.dart` locks the "never reveal a non-hint letter" contract for Advanced and full blanking for Master); cursor chrome now hides while a red error is active (backspacing is the required action, not typing the next letter); first-letter hints now treat newlines as word boundaries and skip leading punctuation, so an opening quote/paren is no longer shown as the "first letter" — the hint lands on the word's first real letter; `nextLetterIndex` returns -1 (instead of a fallback index) when only auto-fill characters remain. Screen and provider punctuation sets verified byte-identical, with a regression test spot-checking the shared set.

---

## Recurring buckets (no active tasks yet — log here as they come up)

- **Dependency updates**: Flutter SDK, Dart SDK, pubspec packages. Cadence: quarterly or when a CVE drops.
- **Supabase platform**: dashboard linter sweeps, RLS audit refresh, migration hygiene (one feature = one migration file, no edits in place).
- **Test health**: flaky tests, slow tests, coverage gaps on critical paths (`progress_provider`, `scripture_mastery`, `group_play_service`).
- **Analyzer / lints**: `flutter analyze` must stay clean; if a new lint rule lands and produces noise, decide once (suppress or fix), don't let warnings accumulate.
- **Asset hygiene**: orphaned `.txt` placeholders (image + audio convention), unreferenced assets in `pubspec.yaml`.
- **Performance**: frame drops in Scripture Builder, cold-start time, Hive box sizes.
