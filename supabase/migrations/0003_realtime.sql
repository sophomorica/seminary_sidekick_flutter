-- Seminary Sidekick — Group Play realtime publications
--
-- We push three tables onto the `supabase_realtime` publication so clients
-- can subscribe to per-room changes:
--
--   - rooms     → status / current_question_index / ended_at transitions
--   - players   → joins, leaves, score updates, last_seen heartbeats
--   - answers   → live leaderboard ticks during a quiz
--
-- Note: high-frequency ephemeral events (host pushing the next question,
-- per-keystroke signals) should NOT use Postgres Changes — they should use
-- Supabase Realtime *Broadcast* on a channel named `room:{code}`. Postgres
-- Changes is the durable, lower-rate fallback for state-of-record updates.

alter publication supabase_realtime add table public.rooms;
alter publication supabase_realtime add table public.players;
alter publication supabase_realtime add table public.answers;
