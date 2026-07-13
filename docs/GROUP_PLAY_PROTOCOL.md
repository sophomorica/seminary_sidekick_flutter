# Group Play cross-client protocol

Contract shared by the Flutter host app and the seminarysidekick.com web player.
Changes to broadcast events, RPC signatures, or scripture IDs must update this doc.

## Join codes

- Length: 4
- Alphabet: `ACDEFGHJKLMNPQRTUVWXYZ23456789` (no I/O/0/1/B/S)
- Normalized: `trim().toUpperCase()`
- Web URL: `https://seminarysidekick.com/join/{CODE}`

## RPCs (SECURITY DEFINER)

| RPC | Args | Returns | Notes |
|-----|------|---------|-------|
| `join_room` | `p_code text`, `p_nickname text` | `{ room, player }` sanitized room | Lobby only; ban + cap atomic |
| `submit_answer` | `p_room_id`, `p_question_index`, `p_choice_index` | `{ answer, is_correct, points_earned, response_time_ms }` | Server scores vs `question_started_at` |
| `advance_question` | `p_room_id`, `p_new_index` | full room row (host) | Sets `question_started_at = now()` |
| `kick_player` | `p_room_id`, `p_player_id` | void | Writes `room_bans`, deletes player |
| `heartbeat` | `p_room_id` | void | Sets the caller's own `players.last_seen_at = now()` for that room. Required since 0007 removed `players_update_self` — direct UPDATEs of `last_seen_at` match zero rows under RLS |

### Room clock trigger

A `BEFORE UPDATE` trigger on `rooms` (0008) sets `question_started_at = now()`
whenever `current_question_index` changes, even if the host writes the index
directly instead of calling `advance_question`. Clients must anchor question
countdowns to `question_started_at`, not local clocks.

### Error message tokens (in exception text)

`ROOM_NOT_FOUND`, `ROOM_FULL`, `NICKNAME_TAKEN`, `ROOM_ALREADY_STARTED`, `ROOM_ENDED`, `BANNED_FROM_ROOM`, `NOT_HOST`, `DUPLICATE_ANSWER`, `ANSWER_TOO_LATE`, `WRONG_QUESTION`, `QUESTION_NOT_STARTED`, `INVALID_QUESTION`, `NOT_IN_ROOM`, `CANNOT_KICK_HOST`, `PLAYER_NOT_FOUND`

## Broadcast channel

- Channel name: `room:{code}` (uppercase code)
- Events:
  - `question_advanced` → `{ index: number }`
  - `room_ended` → `{}`

Durable state still flows through Postgres Changes (`players`, `answers`, `group_sb_finishes`; hosts also `rooms`). Players read rooms via `rooms_player_view` (no `correctIndex`).

## Room scope JSON

See `GroupRoomScope` / `GroupSbConfig` in the Flutter models. Quiz omits `mode` when `quiz`. SB sets `mode: scriptureBuilder` + `scriptureBuilderConfig`.

## Scripture IDs

Owned by Flutter `lib/data/scriptures_data.dart`. Site port: `doctrinalMastery.json` via `$lib/data/scriptures`. IDs must match exactly.
