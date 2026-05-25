-- Seminary Sidekick — Group Play Realtime DELETE-event fix
--
-- Symptom: kicking a player succeeds in the database, but the host's roster
-- does not update because the client never receives the DELETE event.
--
-- Cause: Supabase Realtime delivers Postgres Changes events with a row
-- payload. INSERT and UPDATE carry the full new row, so filters like
-- `room_id = X` can be evaluated and the event fans out. DELETE, by default,
-- carries only the primary key (the table's "default" replica identity). A
-- filter on `room_id` cannot be evaluated against a row that doesn't include
-- `room_id`, so Supabase silently drops the event.
--
-- Fix: ALTER TABLE ... REPLICA IDENTITY FULL forces Postgres to include the
-- entire old row in the WAL when a DELETE happens, which lets Supabase
-- evaluate filters and deliver the event. Trade-off is slightly larger WAL
-- writes — negligible for our use case (a few rows per game).
--
-- Apply with `supabase db push`.

alter table public.players       replica identity full;
alter table public.rooms         replica identity full;
alter table public.answers       replica identity full;
alter table public.saved_rosters replica identity full;
