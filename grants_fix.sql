-- GRANTS FIX: tables created via SQL editor are not auto-granted to anon
-- config table is intentionally NOT granted to anon (keeps super_token hidden;
-- is_staff() is security definer so it can still read it server-side)
grant usage on schema public to anon, authenticated, service_role;
grant select, insert, update, delete on public.bookings to anon, authenticated, service_role;
grant select, insert, update, delete on public.points to anon, authenticated, service_role;
grant select, insert, update, delete on public.settings to anon, authenticated, service_role;
alter default privileges in schema public grant select, insert, update, delete on tables to anon, authenticated, service_role;
select 'grants ok' as status;
