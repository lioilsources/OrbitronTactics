-- Games table for OrbitronTactics multiplayer
create table if not exists public.games (
  id uuid primary key default gen_random_uuid(),
  status text not null default 'waiting' check (status in ('waiting', 'playing', 'finished')),
  white_player_name text,
  black_player_name text,
  game_state jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Enable realtime for the games table
alter publication supabase_realtime add table public.games;

-- RLS: anyone can read games, anyone can insert/update (no auth for MVP)
alter table public.games enable row level security;

create policy "Anyone can read games"
  on public.games for select
  using (true);

create policy "Anyone can insert games"
  on public.games for insert
  with check (true);

create policy "Anyone can update games"
  on public.games for update
  using (true);
