# Seminary Sidekick — Agent Coordination Protocol

> This file defines how AI agents work on this repo concurrently without stepping on each other.

## Quick Start for Agents

```
1. Read CONTEXT.md           → Understand what this app is
2. Read ARCHITECTURE.md      → Understand conventions and patterns
3. Read TODO.md              → Find an open task
4. Claim the task            → Write your agent ID into TODO.md
5. Do the work               → Follow the conventions
6. Mark task done            → Update TODO.md
7. Update CHANGELOG.md       → Log what you changed (if it exists)
```

## The Lock Protocol

Since multiple agents may work on this repo simultaneously, we use a simple file-based coordination system. There is no server — just files and discipline.

### Claiming a Task

1. **Read `TODO.md`** fresh (do not rely on cached state)
2. Find a task with `status: open`
3. Check the `depends_on` field — don't start blocked work
4. **Edit `TODO.md`** immediately:
   - Set `status` to `in_progress`
   - Set `claimed_by` to your agent identifier
   - Set `started` to current ISO timestamp
5. **Commit the claim** before starting any code work:
   ```
   git add TODO.md && git commit -m "claim TASK-XXX: [brief description]"
   ```

### Why Commit the Claim First?

If two agents try to claim the same task, the second `git commit` will fail with a merge conflict on `TODO.md`. That agent should pull, see the task is taken, and pick a different one. **This is the entire conflict resolution mechanism.**

### Completing a Task

1. Finish your code changes
2. Edit `TODO.md`:
   - Set `status` to `done`
   - Add `completed` timestamp
   - Check off acceptance criteria
   - Add any `notes` about what you did
3. Move the task block to the **Completed** section at the bottom
4. Commit everything together:
   ```
   git add -A && git commit -m "complete TASK-XXX: [what was done]"
   ```

### If You Get Blocked

1. Set `status` to `blocked` in `TODO.md`
2. Add a `blocked_by` note explaining the issue
3. Commit the status change
4. Move on to a different task

### If You Abandon a Task

1. Set `status` back to `open`
2. Clear `claimed_by`
3. Add a `notes` entry explaining why you stopped
4. Commit the status change

## File Ownership Rules

To minimize merge conflicts, tasks are scoped to specific files. Two agents should **never** edit the same file concurrently.

### Shared Files (Extra Caution Required)

These files are touched by many tasks. If your task modifies one, note it in the task's `files_to_touch` field so other agents can see:

| File | Why it's shared |
|------|-----------------|
| `lib/models/enums.dart` | New game types, difficulty changes |
| `lib/screens/games_hub_screen.dart` | Enabling new games |
| `lib/main.dart` | Initialization changes |
| `pubspec.yaml` | New dependencies |
| `TODO.md` | Task coordination |

### Safe Parallel Work

These task pairs can run concurrently without conflict:
- TASK-001 (Hive persistence) + TASK-002 (Quiz game) — different files entirely
- TASK-005 (Audio) + TASK-006 (Confetti) — different screens, new files
- TASK-004 (Notes) + TASK-008 (Speech-to-text) — different screens

These **cannot** run concurrently:
- TASK-002 (Quiz) + TASK-011 (Difficulty descriptions) — both touch enums.dart
- TASK-003 (Wire results) + any game task — overlapping game screen files
- Any two tasks that list the same file in `files_to_touch`

## Creating New Files

When your task requires a new file:
- Follow the naming conventions in `ARCHITECTURE.md`
- Place it in the correct directory
- Add necessary imports
- If it's a provider, follow the existing StateNotifier pattern
- If it's a screen, follow the existing ConsumerStatefulWidget pattern

## Commit Message Format

```
[verb] TASK-XXX: [concise description]

[optional body with details]
```

Verbs: `claim`, `complete`, `fix`, `add`, `update`, `refactor`, `block`

Examples:
```
claim TASK-002: Quick Quiz game
complete TASK-001: wire progress persistence to Hive
fix TASK-003: correct recordAttempt call in matching game
```

## Testing Expectations

- Flutter analyzer must pass with no errors (warnings OK)
- New providers should be unit-testable (no direct widget dependencies)
- Game screens should handle edge cases (empty scripture list, single scripture, etc.)
- No hardcoded strings that should be in the data layer

## When In Doubt

1. **Read the existing code** for the closest analog to what you're building
2. Matching game is the reference implementation for game patterns
3. Word Builder is the reference for multi-mode complexity
4. `app_theme.dart` is the single source of truth for colors and spacing
5. If a design decision isn't covered, pick the option that's most fun for a seminary student
