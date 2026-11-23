-- Product events (games started, store opened, purchases), written by the
-- app and read only from the dashboard. No names, emails or device ids:
-- uid is the anonymous player, props a few plain values.

create table if not exists public.app_events (
  id bigint generated always as identity primary key,
  created_at timestamptz not null default now(),
  uid uuid not null default auth.uid(),
  name text not null check (char_length(name) <= 40),
  props jsonb not null default '{}'::jsonb check (pg_column_size(props) <= 2048),
  app_version text check (char_length(app_version) <= 24),
  platform text check (char_length(platform) <= 16)
);

create index if not exists app_events_name_created_idx
  on public.app_events (name, created_at desc);

alter table public.app_events enable row level security;

revoke all on public.app_events from anon, authenticated;
grant insert (name, props, app_version, platform) on public.app_events to authenticated;

create policy "Players write their own events"
  on public.app_events for insert to authenticated
  with check (uid = auth.uid());

-- Events older than a year go.
do $$
begin
  if exists (select 1 from pg_extension where extname = 'pg_cron') then
    perform cron.schedule(
      'delete-old-app-events',
      '17 3 * * *',
      'delete from public.app_events where created_at < now() - interval ''1 year'''
    );
  end if;
end
$$;
