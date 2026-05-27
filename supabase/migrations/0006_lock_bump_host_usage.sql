-- ─── MAINT-001: Lock down bump_host_usage SECURITY DEFINER ────────────────
-- Tighten the SECURITY DEFINER function flagged by Supabase's linter:
--   1. Revoke the implicit PUBLIC EXECUTE grant. Postgres grants EXECUTE
--      to PUBLIC by default on every new function; the explicit grant in
--      0001 only ADDED `authenticated` — it did not remove PUBLIC.
--   2. Add an internal guard so callers may only bump their own counter,
--      even though SECURITY DEFINER bypasses RLS on host_usage.
--
-- Behavior preserved:
--   * Signature unchanged: bump_host_usage(p_host_id uuid) returns int.
--   * Return shape unchanged: int = rooms_this_week for the caller.
--   * Legitimate callers (GroupPlayService._bumpHostUsage) pass auth.uid()
--     so the new guard never fires for them.
--   * Idempotent / replay-safe: `create or replace`, `revoke` and `grant`
--     are all safe to run repeatedly.

create or replace function public.bump_host_usage(p_host_id uuid)
returns int
language plpgsql
security definer
set search_path = public
as $$
declare
  v_count int;
  v_uid   uuid := auth.uid();
begin
  -- Guard: caller must be signed in (no NULL juids allowed) AND may only
  -- bump their own row. Anything else is a 42501 (insufficient privilege).
  if v_uid is null then
    raise exception 'bump_host_usage requires an authenticated caller'
      using errcode = '42501';
  end if;
  if p_host_id <> v_uid then
    raise exception 'bump_host_usage: p_host_id (%) must match auth.uid() (%)',
      p_host_id, v_uid
      using errcode = '42501';
  end if;

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

-- Pull the implicit PUBLIC grant. Idempotent — no error if already revoked.
revoke execute on function public.bump_host_usage(uuid) from public;

-- Re-grant explicitly to `authenticated` (covers both regular sign-ins and
-- the anonymous-sign-in flow used by group play). `create or replace` does
-- not change ownership/permissions in current Postgres, so 0001's grant
-- should persist — but re-granting here is cheap insurance against any
-- replay quirks and makes the intent obvious at the call site.
grant execute on function public.bump_host_usage(uuid) to authenticated;
