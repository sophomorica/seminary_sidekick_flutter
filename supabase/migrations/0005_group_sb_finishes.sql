-- Seminary Sidekick — Group Scripture Builder finishes
--
-- Stores per-(player, scripture) finish events for the Word-Builder race
-- mode added in TASK-062. Mirrors the shape of `answers` so the realtime
-- subscription pattern is the same; the table is separate because the
-- columns are different (no question_index/choice/points — instead
-- scripture_index/elapsed_ms/mistake_count).
--
-- Sentinel: `mistake_count = -1` means DNF (timed out without completing).

create table public.group_sb_finishes (
  id              uuid primary key default gen_random_uuid(),
  room_id         uuid not null references public.rooms(id) on delete cascade,
  player_id       uuid not null references public.players(id) on delete cascade,
  scripture_index int  not null check (scripture_index >= 0),
  elapsed_ms      int  not null check (elapsed_ms >= 0),
  mistake_count   int  not null,
  completed_at    timestamptz not null default now(),
  -- One finish per player per scripture. If a player times out we still
  -- insert a row (mistake_count = -1); a second insert is rejected.
  unique (player_id, scripture_index)
);

create index group_sb_finishes_room_idx
  on public.group_sb_finishes (room_id, scripture_index);

-- ─── RLS ───────────────────────────────────────────────────────────────────
alter table public.group_sb_finishes enable row level security;

-- Any authenticated user can SELECT; the host's progress dashboard and the
-- per-player race position both need to read finishes across the room.
create policy "group_sb_finishes_select_authenticated"
  on public.group_sb_finishes for select
  to authenticated
  using (true);

-- INSERT only on behalf of yourself — the player_id row must be owned by
-- the calling user. Matches the answers_insert_self pattern exactly.
create policy "group_sb_finishes_insert_self"
  on public.group_sb_finishes for insert
  to authenticated
  with check (
    exists (
      select 1 from public.players p
      where p.id = group_sb_finishes.player_id
        and p.user_id = auth.uid()
    )
  );

-- No UPDATE / DELETE policies — finishes are immutable.

-- ─── Realtime ──────────────────────────────────────────────────────────────
-- See 0003_realtime.sql and 0004_replica_identity_full.sql for the rationale
-- behind both lines below. We need REPLICA IDENTITY FULL so DELETE events
-- delivered after `on delete cascade` (when the parent room is deleted) carry
-- the room_id, which keeps the client's filter coherent — even though we
-- don't currently subscribe to DELETE events here, parity with the rest of
-- the group-play tables avoids future foot-guns.
alter table public.group_sb_finishes replica identity full;
alter publication supabase_realtime add table public.group_sb_finishes;
