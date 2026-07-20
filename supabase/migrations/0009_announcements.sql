-- 0009_announcements.sql
-- Broadcast in-app announcements (feature alerts, community news, how-to tips).
-- Clients read active rows after anonymous sign-in; owners publish via the
-- Supabase dashboard / service role. No client INSERT/UPDATE/DELETE.

-- ─── Table ───────────────────────────────────────────────────────────────────

create table if not exists public.announcements (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  body text not null,
  -- info | feature | event | tip | update
  kind text not null default 'info'
    check (kind in ('info', 'feature', 'event', 'tip', 'update')),
  media_url text,
  -- image | gif | video (video opens externally; gif/image render inline)
  media_type text
    check (media_type is null or media_type in ('image', 'gif', 'video')),
  cta_label text,
  -- In-app path ("/practice") or absolute https URL
  cta_link text,
  -- Higher shows first when multiple are active
  priority int not null default 0,
  is_active boolean not null default true,
  starts_at timestamptz not null default now(),
  ends_at timestamptz,
  created_at timestamptz not null default now(),
  constraint announcements_ends_after_starts
    check (ends_at is null or ends_at > starts_at)
);

create index if not exists announcements_active_window_idx
  on public.announcements (is_active, priority desc, starts_at desc)
  where is_active = true;

comment on table public.announcements is
  'Broadcast in-app banners shown on Home. Published via dashboard; clients SELECT only.';

-- ─── RLS ─────────────────────────────────────────────────────────────────────

alter table public.announcements enable row level security;

-- Authenticated (incl. anonymous Group Play sessions) can read currently
-- active announcements inside their publish window. No public role access.
create policy "announcements_select_active_authenticated"
  on public.announcements
  for select
  to authenticated
  using (
    is_active = true
    and starts_at <= now()
    and (ends_at is null or ends_at > now())
  );

-- Intentionally no INSERT/UPDATE/DELETE policies for authenticated —
-- owners manage rows with the service role in the Supabase SQL editor / Table
-- Editor.

-- ─── Storage bucket (GIF / image tips) ───────────────────────────────────────
-- Public read so Image.network can load media without a signed URL.
-- Writes stay service-role / dashboard only (no policies for authenticated).

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'announcement-media',
  'announcement-media',
  true,
  5242880, -- 5 MB
  array['image/png', 'image/jpeg', 'image/webp', 'image/gif']
)
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

create policy "announcement_media_public_read"
  on storage.objects
  for select
  to public
  using (bucket_id = 'announcement-media');
