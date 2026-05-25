-- Seminary Sidekick — Group Play RLS policies
-- Pattern: anonymous players authenticate via Supabase anonymous auth and
-- get a real auth.uid(). All row ownership is keyed on that uid.
--
-- Reads are permissive within the authenticated role so any signed-in client
-- can look up a room by code (needed for joining). Writes are tightly scoped
-- to the row owner (host for rooms; player for their own answers).

alter table public.rooms         enable row level security;
alter table public.players       enable row level security;
alter table public.answers       enable row level security;
alter table public.saved_rosters enable row level security;
alter table public.host_usage    enable row level security;

-- ─── rooms ─────────────────────────────────────────────────────────────────
-- Any authenticated user can SELECT (so Join can look up by code).
-- Only the host can INSERT/UPDATE/DELETE their room.

create policy "rooms_select_authenticated"
  on public.rooms for select
  to authenticated
  using (true);

create policy "rooms_insert_self_as_host"
  on public.rooms for insert
  to authenticated
  with check (auth.uid() = host_id);

create policy "rooms_update_host_only"
  on public.rooms for update
  to authenticated
  using (auth.uid() = host_id)
  with check (auth.uid() = host_id);

create policy "rooms_delete_host_only"
  on public.rooms for delete
  to authenticated
  using (auth.uid() = host_id);

-- ─── players ───────────────────────────────────────────────────────────────
-- Any authenticated user can SELECT (used to render the lobby roster).
-- A user can INSERT/UPDATE only their own player row.
-- A user can DELETE their own row (self-leave) OR the host can DELETE any
-- player in their room (kick).

create policy "players_select_authenticated"
  on public.players for select
  to authenticated
  using (true);

create policy "players_insert_self"
  on public.players for insert
  to authenticated
  with check (auth.uid() = user_id);

create policy "players_update_self"
  on public.players for update
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "players_delete_self_or_host_kick"
  on public.players for delete
  to authenticated
  using (
    auth.uid() = user_id
    or exists (
      select 1 from public.rooms r
      where r.id = players.room_id
        and r.host_id = auth.uid()
    )
  );

-- ─── answers ───────────────────────────────────────────────────────────────
-- Any authenticated user can SELECT (used for the live leaderboard).
-- A user can INSERT only an answer that belongs to their own player row.
-- No UPDATE/DELETE — answers are append-only.

create policy "answers_select_authenticated"
  on public.answers for select
  to authenticated
  using (true);

create policy "answers_insert_self"
  on public.answers for insert
  to authenticated
  with check (
    exists (
      select 1 from public.players p
      where p.id = answers.player_id
        and p.user_id = auth.uid()
    )
  );

-- ─── saved_rosters ─────────────────────────────────────────────────────────
-- Owner-only: hosts see and manage their own saved classes.

create policy "saved_rosters_owner_all"
  on public.saved_rosters for all
  to authenticated
  using (auth.uid() = host_id)
  with check (auth.uid() = host_id);

-- ─── host_usage ────────────────────────────────────────────────────────────
-- Read-only by owner. Writes happen via bump_host_usage() (security definer).

create policy "host_usage_select_owner"
  on public.host_usage for select
  to authenticated
  using (auth.uid() = host_id);
