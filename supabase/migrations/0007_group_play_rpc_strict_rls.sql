-- 0007_group_play_rpc_strict_rls.sql
-- Web Group Play Join (v3): server-authoritative RPCs + strict RLS from day one.
-- No legacy clients — replaces permissive v1 policies.

-- ─── Schema ────────────────────────────────────────────────────────────────

alter table public.rooms
  add column if not exists question_started_at timestamptz;

create table if not exists public.room_bans (
  room_id   uuid not null references public.rooms(id) on delete cascade,
  user_id   uuid not null,
  banned_at timestamptz not null default now(),
  primary key (room_id, user_id)
);

create index if not exists room_bans_user_idx on public.room_bans (user_id);

alter table public.room_bans enable row level security;

create policy "room_bans_select_host"
  on public.room_bans for select
  to authenticated
  using (
    exists (
      select 1 from public.rooms r
      where r.id = room_bans.room_id and r.host_id = auth.uid()
    )
  );

-- unique(player_id, question_index) already on answers (0001).

-- ─── Helpers ───────────────────────────────────────────────────────────────

create or replace function public.sanitize_question_set(p_set jsonb)
returns jsonb
language sql
immutable
as $$
  select case
    when p_set is null then null
    when jsonb_typeof(p_set) <> 'array' then '[]'::jsonb
    else coalesce(
      (select jsonb_agg(elem - 'correctIndex') from jsonb_array_elements(p_set) elem),
      '[]'::jsonb
    )
  end;
$$;

revoke all on function public.sanitize_question_set(jsonb) from public;
grant execute on function public.sanitize_question_set(jsonb) to authenticated;

-- Parity with lib/models/group_answer.dart computeSpeedWeightedPoints
create or replace function public.compute_speed_weighted_points(
  p_is_correct boolean,
  p_response_time_ms int,
  p_question_timeout_seconds int,
  p_max_points int default 1000
)
returns int
language plpgsql
immutable
as $$
declare
  v_timeout_ms int;
  v_fraction double precision;
  v_scaled double precision;
  v_half int;
begin
  if not coalesce(p_is_correct, false) then
    return 0;
  end if;
  v_timeout_ms := p_question_timeout_seconds * 1000;
  if p_response_time_ms >= v_timeout_ms then
    return 0;
  end if;
  v_fraction := p_response_time_ms::double precision / v_timeout_ms::double precision;
  v_scaled := p_max_points * (1.0 - 0.5 * v_fraction);
  v_half := p_max_points / 2;
  return greatest(v_half, least(p_max_points, round(v_scaled)::int));
end;
$$;

revoke all on function public.compute_speed_weighted_points(boolean, int, int, int) from public;
grant execute on function public.compute_speed_weighted_points(boolean, int, int, int) to authenticated;

create or replace function public._room_to_sanitized_json(r public.rooms)
returns jsonb
language sql
stable
as $$
  select jsonb_build_object(
    'id', r.id,
    'code', r.code,
    'host_id', r.host_id,
    'status', r.status,
    'scope', r.scope,
    'question_set', public.sanitize_question_set(r.question_set),
    'current_question_index', r.current_question_index,
    'question_started_at', r.question_started_at,
    'player_cap', r.player_cap,
    'is_premium_host', r.is_premium_host,
    'created_at', r.created_at,
    'started_at', r.started_at,
    'ended_at', r.ended_at
  );
$$;

revoke all on function public._room_to_sanitized_json(public.rooms) from public;

-- Sanitized view: security_invoker=false so underlying rooms RLS does not
-- block members; membership filter is in the WHERE clause. Strips correctIndex.
create or replace view public.rooms_player_view
with (security_invoker = false)
as
select
  r.id,
  r.code,
  r.host_id,
  r.status,
  r.scope,
  public.sanitize_question_set(r.question_set) as question_set,
  r.current_question_index,
  r.question_started_at,
  r.player_cap,
  r.is_premium_host,
  r.created_at,
  r.started_at,
  r.ended_at
from public.rooms r
where r.host_id = auth.uid()
   or exists (
     select 1 from public.players p
     where p.room_id = r.id and p.user_id = auth.uid()
   );

grant select on public.rooms_player_view to authenticated;

-- ─── join_room ─────────────────────────────────────────────────────────────

create or replace function public.join_room(p_code text, p_nickname text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_room public.rooms%rowtype;
  v_nick text := trim(p_nickname);
  v_count int;
  v_player public.players%rowtype;
begin
  if v_uid is null then
    raise exception 'NOT_AUTHENTICATED' using errcode = '42501';
  end if;
  if length(v_nick) < 2 or length(v_nick) > 14 then
    raise exception 'INVALID_NICKNAME' using errcode = 'P0001';
  end if;

  select * into v_room
  from public.rooms
  where code = upper(trim(p_code))
  for update;

  if not found then
    raise exception 'ROOM_NOT_FOUND' using errcode = 'P0002';
  end if;
  if v_room.status = 'ended' then
    raise exception 'ROOM_ENDED' using errcode = 'P0001';
  end if;
  if v_room.status = 'active' then
    raise exception 'ROOM_ALREADY_STARTED' using errcode = 'P0001';
  end if;
  if v_room.status <> 'lobby' then
    raise exception 'ROOM_NOT_LOBBY' using errcode = 'P0001';
  end if;

  if exists (
    select 1 from public.room_bans b
    where b.room_id = v_room.id and b.user_id = v_uid
  ) then
    raise exception 'BANNED_FROM_ROOM' using errcode = 'P0001';
  end if;

  select * into v_player
  from public.players
  where room_id = v_room.id and user_id = v_uid;

  if found then
    return jsonb_build_object(
      'room', public._room_to_sanitized_json(v_room),
      'player', to_jsonb(v_player)
    );
  end if;

  select count(*)::int into v_count from public.players where room_id = v_room.id;
  if v_count >= v_room.player_cap then
    raise exception 'ROOM_FULL' using errcode = 'P0001';
  end if;

  if exists (
    select 1 from public.players p
    where p.room_id = v_room.id and lower(p.nickname) = lower(v_nick)
  ) then
    raise exception 'NICKNAME_TAKEN' using errcode = 'P0001';
  end if;

  insert into public.players (room_id, user_id, nickname, is_host)
  values (v_room.id, v_uid, v_nick, false)
  returning * into v_player;

  return jsonb_build_object(
    'room', public._room_to_sanitized_json(v_room),
    'player', to_jsonb(v_player)
  );
end;
$$;

revoke all on function public.join_room(text, text) from public;
grant execute on function public.join_room(text, text) to authenticated;

-- ─── advance_question (host) — stamps question_started_at = now() ──────────

create or replace function public.advance_question(
  p_room_id uuid,
  p_new_index int
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_room public.rooms%rowtype;
begin
  if v_uid is null then
    raise exception 'NOT_AUTHENTICATED' using errcode = '42501';
  end if;

  select * into v_room from public.rooms where id = p_room_id for update;
  if not found then
    raise exception 'ROOM_NOT_FOUND' using errcode = 'P0002';
  end if;
  if v_room.host_id <> v_uid then
    raise exception 'NOT_HOST' using errcode = '42501';
  end if;
  if v_room.status <> 'active' then
    raise exception 'ROOM_NOT_ACTIVE' using errcode = 'P0001';
  end if;
  if p_new_index < 0 then
    raise exception 'INVALID_INDEX' using errcode = 'P0001';
  end if;

  update public.rooms set
    current_question_index = p_new_index,
    question_started_at = now()
  where id = p_room_id
  returning * into v_room;

  return to_jsonb(v_room);
end;
$$;

revoke all on function public.advance_question(uuid, int) from public;
grant execute on function public.advance_question(uuid, int) to authenticated;

-- ─── kick_player (host) ────────────────────────────────────────────────────

create or replace function public.kick_player(
  p_room_id uuid,
  p_player_id uuid
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_room public.rooms%rowtype;
  v_player public.players%rowtype;
begin
  if v_uid is null then
    raise exception 'NOT_AUTHENTICATED' using errcode = '42501';
  end if;

  select * into v_room from public.rooms where id = p_room_id;
  if not found then
    raise exception 'ROOM_NOT_FOUND' using errcode = 'P0002';
  end if;
  if v_room.host_id <> v_uid then
    raise exception 'NOT_HOST' using errcode = '42501';
  end if;

  select * into v_player
  from public.players
  where id = p_player_id and room_id = p_room_id;
  if not found then
    raise exception 'PLAYER_NOT_FOUND' using errcode = 'P0002';
  end if;
  if v_player.is_host then
    raise exception 'CANNOT_KICK_HOST' using errcode = 'P0001';
  end if;

  insert into public.room_bans (room_id, user_id)
  values (p_room_id, v_player.user_id)
  on conflict do nothing;

  delete from public.players where id = p_player_id;
end;
$$;

revoke all on function public.kick_player(uuid, uuid) from public;
grant execute on function public.kick_player(uuid, uuid) to authenticated;

-- ─── submit_answer ─────────────────────────────────────────────────────────

create or replace function public.submit_answer(
  p_room_id uuid,
  p_question_index int,
  p_choice_index int
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_room public.rooms%rowtype;
  v_player public.players%rowtype;
  v_q jsonb;
  v_correct int;
  v_is_correct boolean;
  v_timeout_sec int;
  v_elapsed_ms int;
  v_points int;
  v_answer public.answers%rowtype;
begin
  if v_uid is null then
    raise exception 'NOT_AUTHENTICATED' using errcode = '42501';
  end if;

  select * into v_room from public.rooms where id = p_room_id;
  if not found then
    raise exception 'ROOM_NOT_FOUND' using errcode = 'P0002';
  end if;
  if v_room.status <> 'active' then
    raise exception 'ROOM_NOT_ACTIVE' using errcode = 'P0001';
  end if;

  select * into v_player
  from public.players
  where room_id = p_room_id and user_id = v_uid;
  if not found then
    raise exception 'NOT_IN_ROOM' using errcode = 'P0001';
  end if;

  if exists (
    select 1 from public.answers a
    where a.player_id = v_player.id and a.question_index = p_question_index
  ) then
    raise exception 'DUPLICATE_ANSWER' using errcode = 'P0001';
  end if;

  if v_room.question_set is null
     or p_question_index < 0
     or p_question_index >= jsonb_array_length(v_room.question_set) then
    raise exception 'INVALID_QUESTION' using errcode = 'P0001';
  end if;

  if v_room.current_question_index <> p_question_index then
    raise exception 'WRONG_QUESTION' using errcode = 'P0001';
  end if;

  if v_room.question_started_at is null then
    raise exception 'QUESTION_NOT_STARTED' using errcode = 'P0001';
  end if;

  v_timeout_sec := coalesce((v_room.scope ->> 'questionTimeoutSeconds')::int, 20);
  v_elapsed_ms := (extract(epoch from (now() - v_room.question_started_at)) * 1000)::int;
  if v_elapsed_ms < 0 then
    v_elapsed_ms := 0;
  end if;

  if now() > v_room.question_started_at + make_interval(secs => v_timeout_sec) then
    raise exception 'ANSWER_TOO_LATE' using errcode = 'P0001';
  end if;

  v_q := v_room.question_set -> p_question_index;
  v_correct := (v_q ->> 'correctIndex')::int;
  v_is_correct := (p_choice_index = v_correct);
  v_points := public.compute_speed_weighted_points(
    v_is_correct, v_elapsed_ms, v_timeout_sec, 1000
  );

  insert into public.answers (
    room_id, player_id, question_index, selected_choice,
    is_correct, response_time_ms, points_earned
  ) values (
    p_room_id, v_player.id, p_question_index, p_choice_index,
    v_is_correct, v_elapsed_ms, v_points
  )
  returning * into v_answer;

  if v_points > 0 then
    update public.players
    set score = score + v_points
    where id = v_player.id;
  end if;

  return jsonb_build_object(
    'answer', to_jsonb(v_answer),
    'is_correct', v_is_correct,
    'points_earned', v_points,
    'response_time_ms', v_elapsed_ms
  );
end;
$$;

revoke all on function public.submit_answer(uuid, int, int) from public;
grant execute on function public.submit_answer(uuid, int, int) to authenticated;

-- ─── Strict RLS ────────────────────────────────────────────────────────────

drop policy if exists "rooms_select_authenticated" on public.rooms;
drop policy if exists "players_insert_self" on public.players;
drop policy if exists "players_update_self" on public.players;
drop policy if exists "answers_insert_self" on public.answers;
drop policy if exists "players_delete_self_or_host_kick" on public.players;

-- Host retains full row access on rooms (incl. correctIndex).
-- Players read via rooms_player_view (sanitized) only.
create policy "rooms_select_host_only"
  on public.rooms for select
  to authenticated
  using (auth.uid() = host_id);

-- Host INSERT/UPDATE/DELETE policies from 0002 remain.
-- Host UPDATE still allowed for start/end (question_set, status). Index advances
-- that need question_started_at MUST use advance_question RPC.

-- Host may insert own host player row at createRoom; joiner INSERTs only via join_room.
create policy "players_insert_host_self"
  on public.players for insert
  to authenticated
  with check (
    auth.uid() = user_id
    and is_host = true
    and exists (
      select 1 from public.rooms r
      where r.id = room_id and r.host_id = auth.uid()
    )
  );

-- Self-leave only; kick goes through kick_player RPC.
create policy "players_delete_self"
  on public.players for delete
  to authenticated
  using (auth.uid() = user_id);

-- answers: SELECT remains; no direct INSERT (submit_answer only).
-- players: no UPDATE policy (score only via submit_answer).
