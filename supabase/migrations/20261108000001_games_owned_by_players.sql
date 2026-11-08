-- Games belong to the players in them.
--
-- Every app install signs in anonymously (Supabase Auth, anonymous sign-ins
-- enabled), so each player has a uid. A host opens a game as white, a
-- second player joins it as black through join_game(), and from then on only
-- those two can see or change it. Open games stay visible to everyone
-- signed in, for the lobby. Old games are deleted every ten minutes.
--
-- protocol is the network protocol of the app that opened the game; the
-- lobby lists only games of its own protocol, so two app versions that
-- cannot talk to each other are never paired.

alter table public.games
  add column if not exists white_uid uuid default auth.uid(),
  add column if not exists black_uid uuid,
  add column if not exists protocol integer not null default 0;

-- Games from before players had ids belong to no one.
delete from public.games where white_uid is null;

alter table public.games alter column white_uid set not null;

alter table public.games
  add constraint games_white_name_length
    check (char_length(white_player_name) <= 40) not valid,
  add constraint games_black_name_length
    check (char_length(black_player_name) <= 40) not valid;

create index if not exists games_waiting_idx
  on public.games (protocol, created_at desc)
  where status = 'waiting';

-- Old policies let anyone read and rewrite any game.
drop policy if exists "Anyone can read games" on public.games;
drop policy if exists "Anyone can insert games" on public.games;
drop policy if exists "Anyone can update games" on public.games;

-- Signed-in players only, and only the columns the app writes. The uids are
-- set by the column default (white) and join_game (black), never by a client.
revoke all on public.games from anon;
revoke insert, update, delete on public.games from authenticated;
grant select on public.games to authenticated;
grant insert (status, white_player_name, protocol) on public.games to authenticated;
grant update (status, game_state, updated_at) on public.games to authenticated;

create policy "Players see open games and their own"
  on public.games for select to authenticated
  using (status = 'waiting' or auth.uid() in (white_uid, black_uid));

create policy "Players open games as white"
  on public.games for insert to authenticated
  with check (
    white_uid = auth.uid() and black_uid is null and status = 'waiting'
  );

create policy "Players update their own games"
  on public.games for update to authenticated
  using (auth.uid() in (white_uid, black_uid))
  with check (auth.uid() in (white_uid, black_uid));

-- Takes the black seat of an open game. False when the game is gone, already
-- taken, or the caller's own.
create or replace function public.join_game(p_game_id uuid, p_player_name text)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  joined integer;
begin
  if auth.uid() is null then
    raise exception 'join_game needs a signed-in player';
  end if;

  update public.games
     set black_uid = auth.uid(),
         black_player_name = left(p_player_name, 40),
         status = 'playing',
         updated_at = now()
   where id = p_game_id
     and status = 'waiting'
     and black_uid is null
     and white_uid <> auth.uid();

  get diagnostics joined = row_count;
  return joined = 1;
end;
$$;

revoke all on function public.join_game(uuid, text) from public, anon;
grant execute on function public.join_game(uuid, text) to authenticated;

-- Open games nobody joined within half an hour, and anything untouched for a
-- day.
create or replace function public.delete_stale_games()
returns void
language sql
security definer
set search_path = ''
as $$
  delete from public.games
   where (status = 'waiting' and created_at < now() - interval '30 minutes')
      or updated_at < now() - interval '1 day';
$$;

revoke all on function public.delete_stale_games() from public, anon, authenticated;

-- pg_cron ships with Supabase; a plain local Postgres may not have it.
do $$
begin
  if exists (select 1 from pg_available_extensions where name = 'pg_cron') then
    create extension if not exists pg_cron with schema pg_catalog;
    perform cron.schedule(
      'delete-stale-games',
      '*/10 * * * *',
      'select public.delete_stale_games()'
    );
  end if;
end
$$;
