-- Seminary Sidekick — Group Play schema (initial)
-- Tables: rooms, players, answers, saved_rosters, host_usage
-- Auth: every row is owned by a Supabase auth.uid() (anonymous or full).
-- See 0002_rls_policies.sql for access control and 0003_realtime.sql for
-- realtime publications.

create extension if not exists "pgcrypto";

-- ─── rooms ─────────────────────────────────────────────────────────────────
-- One row per group quiz session.
-- `code` is the 4-letter join code shown on the host's screen.
-- `scope` captures the question scope (books / scriptureIds / difficulty / etc).
-- `question_set` is the frozen list of questions for this session, generated
-- once at room start so all players see the same questions in the same order.
create table public.rooms (
  id                     uuid primary key default gen_random_uuid(),
  code                   text unique not null check (length(code) = 4),
  host_id                uuid not null,
  status                 text not null default 'lobby'
                           check (status in ('lobby', 'active', 'ended')),
  scope                  jsonb not null,
  question_set           jsonb,
  current_question_index int  not null default -1,
  player_cap             int  not null default 6 check (player_cap between 1 and 50),
  is_premium_host        boolean not null default false,
  created_at             timestamptz not null default now(),
  started_at             timestamptz,
  ended_at               timestamptz
);

create index rooms_status_idx  on public.rooms (status);
create index rooms_host_idx    on public.rooms (host_id);
create index rooms_created_idx on public.rooms (created_at desc);

-- ─── players ───────────────────────────────────────────────────────────────
-- One row per joined participant. Includes the host (with is_host = true).
-- `user_id` is the player's auth.uid() (anonymous or full).
-- Nicknames must be unique within a room; user_id must also be unique within
-- a room (a single device can only join once).
create table public.players (
  id            uuid primary key default gen_random_uuid(),
  room_id       uuid not null references public.rooms(id) on delete cascade,
  user_id       uuid not null,
  nickname      text not null check (length(nickname) between 2 and 14),
  score         int  not null default 0,
  is_host       boolean not null default false,
  joined_at     timestamptz not null default now(),
  last_seen_at  timestamptz not null default now(),
  unique (room_id, user_id),
  unique (room_id, nickname)
);

create index players_room_idx on public.players (room_id);

-- ─── answers ───────────────────────────────────────────────────────────────
-- One row per answer submission. `points_earned` already accounts for the
-- speed-weighted scoring formula computed on the client.
create table public.answers (
  id              uuid primary key default gen_random_uuid(),
  room_id         uuid not null references public.rooms(id) on delete cascade,
  player_id       uuid not null references public.players(id) on delete cascade,
  question_index  int  not null,
  selected_choice int  not null,
  is_correct      boolean not null,
  response_time_ms int not null check (response_time_ms >= 0),
  points_earned   int  not null,
  submitted_at    timestamptz not null default now(),
  unique (player_id, question_index)
);

create index answers_room_q_idx on public.answers (room_id, question_index);

-- ─── saved_rosters ─────────────────────────────────────────────────────────
-- Premium feature: hosts can save the current roster as a named class so they
-- don't have to rebuild it every week.
create table public.saved_rosters (
  id                uuid primary key default gen_random_uuid(),
  host_id           uuid not null,
  name              text not null check (length(name) between 1 and 60),
  player_nicknames  jsonb not null default '[]',
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now()
);

create index saved_rosters_host_idx on public.saved_rosters (host_id);

-- ─── host_usage ────────────────────────────────────────────────────────────
-- Free-tier rate limit: count rooms started per host per ISO week.
-- Use the bump_host_usage() function below to increment safely.
create table public.host_usage (
  host_id          uuid primary key,
  rooms_this_week  int  not null default 0,
  week_starts_at   timestamptz not null default date_trunc('week', now())
);

-- Helper: increments the counter for this week, resetting if a new week.
-- security definer so RLS doesn't block anonymous hosts from incrementing
-- their own row (we still gate the call via RLS-protected create_room flow).
create or replace function public.bump_host_usage(p_host_id uuid)
returns int
language plpgsql
security definer
set search_path = public
as $$
declare
  v_count int;
begin
  insert into public.host_usage (host_id, rooms_this_week, week_starts_at)
       values (p_host_id, 1, date_trunc('week', now()))
  on conflict (host_id) do update set
    rooms_this_week = case
      when public.host_usage.week_starts_at < date_trunc('week', now()) then 1
      else public.host_usage.rooms_this_week + 1
    end,
    week_starts_at = date_trunc('week', now())
  returning rooms_this_week into v_count;
  return v_count;
end;
$$;

grant execute on function public.bump_host_usage(uuid) to authenticated;
