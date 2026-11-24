-- =============================================================
-- Warangal Ijtima Bus Booking — Supabase setup (run ONCE)
-- Supabase Dashboard -> SQL Editor -> New query -> paste all -> Run
-- =============================================================

-- 1) Tables ------------------------------------------------------
create table if not exists public.bookings (
  id             uuid primary key default gen_random_uuid(),
  pass_id        text not null,
  point_id       text not null,
  point_name     text,
  departure      text,
  zimmedar_name  text,
  zimmedar_phone text,
  passenger_name text not null,
  phone          text not null,
  seats          integer not null default 1,
  total_fare     integer not null default 0,
  status         text,
  note           text,
  created_at     timestamptz not null default now()
);

create table if not exists public.points (
  id             text primary key,
  name           text not null,
  departure      text,
  zimmedar_name  text,
  zimmedar_phone text,
  upi_id         text,
  qr_data_url    text,
  pin            text,
  sort_order     integer not null default 0
);

create table if not exists public.settings (
  key   text primary key,
  value text
);

create table if not exists public.config (
  key   text primary key,
  value text
);

-- 2) Random staff token (guards all admin writes in the DB) -----
insert into public.config (key, value)
values ('super_token', replace(gen_random_uuid()::text || gen_random_uuid()::text, '-', ''))
on conflict (key) do nothing;

create or replace function public.is_staff()
returns boolean
language sql stable security definer
as $$
  select coalesce(
    case when current_setting('request.headers', true) like '{%}'
      then (current_setting('request.headers', true)::jsonb ->> 'x-staff-token') =
           (select value from public.config where key = 'super_token')
      else false
    end,
    false
  );
$$;

-- 3) Row Level Security ------------------------------------------
alter table public.bookings enable row level security;
alter table public.points   enable row level security;
alter table public.settings enable row level security;
alter table public.config   enable row level security;
-- NOTE: public.config has NO policies on purpose -> the token
-- can never be read out through the API.

drop policy if exists "bookings_select"  on public.bookings;
create policy "bookings_select"  on public.bookings for select using (true);
drop policy if exists "bookings_insert"  on public.bookings;
create policy "bookings_insert"  on public.bookings for insert with check (true);
drop policy if exists "bookings_update"  on public.bookings;
create policy "bookings_update"  on public.bookings for update using (public.is_staff());
drop policy if exists "bookings_delete"  on public.bookings;
create policy "bookings_delete"  on public.bookings for delete using (public.is_staff());

drop policy if exists "points_select"  on public.points;
create policy "points_select"  on public.points for select using (true);
drop policy if exists "points_insert"  on public.points;
create policy "points_insert"  on public.points for insert with check (public.is_staff());
drop policy if exists "points_update"  on public.points;
create policy "points_update"  on public.points for update using (public.is_staff());
drop policy if exists "points_delete"  on public.points;
create policy "points_delete"  on public.points for delete using (public.is_staff());

drop policy if exists "settings_select" on public.settings;
create policy "settings_select" on public.settings for select using (true);
drop policy if exists "settings_write"  on public.settings;
create policy "settings_write"  on public.settings for all
  using (public.is_staff()) with check (public.is_staff());

-- 4) Seed default pickup points (only when table is empty) -------
insert into public.points (id, name, departure, zimmedar_name, zimmedar_phone, upi_id, qr_data_url, pin, sort_order)
select v.id, v.name, v.departure, v.zimmedar_name, v.zimmedar_phone, '', '', v.pin, v.so
from (values
  ('mehdipatnam',     'Mehdipatnam',                 'After Fajr Prayer (5:45 AM)', 'Mehdipatnam Zimmedar',      '9353490973', '1111', 1),
  ('yakhutpura',      'Yakhutpura',                  'After Fajr Prayer (5:30 AM)', 'Yakhutpura Zimmedar',       '7306959132', '2222', 2),
  ('chandrayangutta', 'Chandrayan Gutta',            'After Fajr Prayer (5:20 AM)', 'Chandrayan Gutta Zimmedar', '9353490973', '3333', 3),
  ('hassannagar',     'Faizane Madina Hassan Nagar', 'After Fajr Prayer (5:15 AM)', 'Hassan Nagar Zimmedar',     '7306959132', '4444', 4)
) as v(id, name, departure, zimmedar_name, zimmedar_phone, pin, so)
where not exists (select 1 from public.points)
on conflict (id) do nothing;

-- 5) Your STAFF TOKEN — copy the value from the Results panel ---
select 'STAFF_TOKEN = ' || value as token from public.config where key = 'super_token';
