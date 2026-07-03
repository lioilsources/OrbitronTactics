-- Per-user unit upgrade levels and battle credits (ComCenter)
create table if not exists public.user_upgrades (
  user_id text primary key,
  credits integer not null default 0,
  upgrades jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

-- RLS: mirrors the games table's open MVP policy (no auth for MVP)
alter table public.user_upgrades enable row level security;

create policy "Anyone can read user_upgrades"
  on public.user_upgrades for select
  using (true);

create policy "Anyone can insert user_upgrades"
  on public.user_upgrades for insert
  with check (true);

create policy "Anyone can update user_upgrades"
  on public.user_upgrades for update
  using (true);
