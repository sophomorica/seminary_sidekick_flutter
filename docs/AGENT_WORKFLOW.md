## Agent Coordination

### Quick Start

```
1. Read this file (CLAUDE.md)      → Understand everything
2. Read TODO.md or MAINTENANCE.md  → Find an open task (TODO = features/launch, MAINTENANCE = hygiene/security/deps)
3. Claim the task                  → Write your agent ID into the relevant file, commit
4. Do the work                     → Follow the conventions above
5. Mark task done                  → Update the relevant file, commit
```

Same claim/complete ritual applies to both boards. Task IDs are namespaced: `TASK-XXX` lives in `TODO.md`, `MAINT-XXX` lives in `MAINTENANCE.md`.

### Claiming a Task

1. Read `TODO.md` fresh (never rely on cached state)
2. Find a task with `status: open`
3. Check `depends_on` — don't start blocked work
4. Edit `TODO.md`: set `status: in_progress`, `claimed_by: [your-id]`, `started: [ISO timestamp]`
5. **Commit the claim before writing code**: `git add TODO.md && git commit -m "claim TASK-XXX: [description]"`

If two agents claim the same task, the second commit fails with a merge conflict. Pull, see it's taken, pick another task.

### Completing a Task

1. Finish code changes
2. Edit `TODO.md`: set `status: done`, `completed` timestamp, check acceptance criteria, add notes
3. Commit everything: `git add -A && git commit -m "complete TASK-XXX: [what was done]"`

### Blocked or Abandoned

- **Blocked**: Set `status: blocked`, add `blocked_by` note, commit, move on
- **Abandoned**: Set `status: open`, clear `claimed_by`, add notes explaining why, commit

### File Ownership

Two agents should never edit the same file concurrently. Check `files_to_touch` for conflicts.

**Shared files (extra caution)**: `enums.dart`, `games_hub_screen.dart`, `main.dart`, `pubspec.yaml`, `TODO.md`

### Commit Format

```
[verb] TASK-XXX: [concise description]
```

Verbs: `claim`, `complete`, `fix`, `add`, `update`, `refactor`, `block`

