-- 0008_group_play_rls_fixes.sql
-- Room-scoped reads, heartbeat RPC, and a defense-in-depth clock trigger.
--
-- 0007 tightened rooms SELECT to host-only but left the permissive
-- `using (true)` SELECT policies from 0002/0005 on players, answers, and
-- finishes — any authenticated user could read every room's roster, answers,
-- and finishes. This migration scopes those reads to the room's host and
-- members. 0007 also dropped `players_update_self` with no replacement, so
-- client-side last_seen heartbeats silently no-op; the `heartbeat` RPC
-- restores that path server-side.
--
-- Also aligns the finishes table name: historical 0005 on remote created
-- `group_wb_finishes`; the app and local migration file use `group_sb_finishes`.

-- ─── Rename group_wb_finishes → group_sb_finishes (if needed) ───────────────

do $$
begin
  if to_regclass('public.group_wb_finishes') is not null
     and to_regclass('public.group_sb_finishes') is null then
    alter table public.group_wb_finishes rename to group_sb_finishes;

    -- Policy names from the original 0005 apply (wb naming on remote).
    if exists (
      select 1 from pg_policies
      where schemaname = 'public'
        and tablename = 'group_sb_finishes'
        and policyname = 'group_wb_finishes_select_authenticated'
    ) then
      alter policy "group_wb_finishes_select_authenticated"
        on public.group_sb_finishes
        rename to "group_sb_finishes_select_authenticated";
    end if;

    if exists (
      select 1 from pg_policies
      where schemaname = 'public'
        and tablename = 'group_sb_finishes'
        and policyname = 'group_wb_finishes_insert_self'
    ) then
      alter policy "group_wb_finishes_insert_self"
        on public.group_sb_finishes
        rename to "group_sb_finishes_insert_self";
    end if;
  end if;
end $$;

-- ─── Membership helpers ─────────────────────────────────────────────────────
-- SECURITY DEFINER so policies on `players` can consult `players` without
-- self-referential RLS recursion.

create or replace function public.is_room_member(p_room_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.players p
    where p.room_id = p_room_id and p.user_id = auth.uid()
  );
$$;

revoke all on function public.is_room_member(uuid) from public;
grant execute on function public.is_room_member(uuid) to authenticated;

create or replace function public.is_room_host(p_room_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.rooms r
    where r.id = p_room_id and r.host_id = auth.uid()
  );
$$;

revoke all on function public.is_room_host(uuid) from public;
grant execute on function public.is_room_host(uuid) to authenticated;

-- ─── Room-scoped SELECT policies ────────────────────────────────────────────
-- Replace the permissive `using (true)` reads from 0002/0005.

drop policy if exists "players_select_authenticated" on public.players;
drop policy if exists "answers_select_authenticated" on public.answers;
drop policy if exists "group_sb_finishes_select_authenticated" on public.group_sb_finishes;
drop policy if exists "group_wb_finishes_select_authenticated" on public.group_sb_finishes;

create policy "players_select_room_scoped"
  on public.players for select
  to authenticated
  using (
    public.is_room_host(room_id) or public.is_room_member(room_id)
  );

create policy "answers_select_room_scoped"
  on public.answers for select
  to authenticated
  using (
    public.is_room_host(room_id) or public.is_room_member(room_id)
  );

create policy "group_sb_finishes_select_room_scoped"
  on public.group_sb_finishes for select
  to authenticated
  using (
    public.is_room_host(room_id) or public.is_room_member(room_id)
  );

-- ─── heartbeat ──────────────────────────────────────────────────────────────
-- 0007 removed players_update_self, so a direct UPDATE of last_seen_at
-- matches zero rows under RLS. This RPC is the sanctioned write path.

create or replace function public.heartbeat(p_room_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
begin
  if v_uid is null then
    raise exception 'NOT_AUTHENTICATED' using errcode = '42501';
  end if;

  update public.players
  set last_seen_at = now()
  where room_id = p_room_id and user_id = v_uid;
end;
$$;

revoke all on function public.heartbeat(uuid) from public;
grant execute on function public.heartbeat(uuid) to authenticated;

-- ─── Defense-in-depth: stamp the clock on any index change ─────────────────
-- advance_question already stamps question_started_at, but the host's UPDATE
-- policy still allows direct writes to current_question_index (e.g. startRoom
-- writing index 0). This trigger makes any such write stamp the server clock
-- so submit_answer's timing math can never run against a stale stamp.

create or replace function public.rooms_stamp_question_started_at()
returns trigger
language plpgsql
as $$
begin
  if new.current_question_index is distinct from old.current_question_index then
    new.question_started_at := now();
  end if;
  return new;
end;
$$;

drop trigger if exists rooms_stamp_question_started_at on public.rooms;

create trigger rooms_stamp_question_started_at
  before update on public.rooms
  for each row
  execute function public.rooms_stamp_question_started_at();
