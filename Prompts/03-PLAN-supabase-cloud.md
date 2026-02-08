# OrbitronTactics - Phase 3: Supabase Cloud Multiplayer

## Stav

Implementován kompletní Supabase multiplayer stack s cloud projektem.
Migrace aplikována, lobby UI hotové, 90 testů passing.

---

## Co je hotové

### Supabase Cloud Setup
- Projekt: `sgyqrkaajmgpyutmmyqj.supabase.co`
- CLI nainstalováno (v2.75.0), projekt linknutý
- Migrace aplikována (`supabase db push`)
- Credentials přes `--dart-define` (ne hardcoded v kódu)

### Databáze (`supabase/migrations/20260207000001_create_games.sql`)
```sql
games (
  id          uuid primary key,
  status      text ('waiting' | 'playing' | 'finished'),
  white_player_name text,
  black_player_name text,
  game_state  jsonb,
  created_at  timestamptz,
  updated_at  timestamptz
)
```
- RLS: open access (no auth for MVP)
- Realtime enabled

### SupabaseGameTransport (`lib/features/game/data/supabase_game_transport.dart`)
- Implementuje `GameTransport` interface
- Supabase Realtime Broadcast kanál `game:{gameId}`
- JSON serializace/deserializace game eventů
- Connect/disconnect/dispose lifecycle
- Self-broadcast enabled pro debugging

### GameRepository (`lib/features/game/data/game_repository.dart`)
- `createGame()` — vloží waiting game, vrátí ID
- `joinGame()` — přidá black playera, nastaví status=playing
- `listWaitingGames()` — vrátí open games
- `watchWaitingGames()` — realtime stream (Supabase Postgres Changes)
- `finishGame()` — nastaví status=finished

### Lobby UI (`lib/features/game/presentation/screens/lobby_screen.dart`)
- **LobbyScreen**: jméno hráče, Create Game / Local Game tlačítka, seznam open games
- **WaitingScreen**: host čeká na oponenta, zobrazí game ID
- Joiner se připojí jako black, pošle `PlayerJoinedEvent` přes broadcast
- Host přijme event, oba navigují na `GameScreen`

### Konfigurace
- `SupabaseConstants` — `--dart-define` pro URL + anon key
- `.env` soubor (gitignored) pro lokální dev
- `Supabase.initialize()` v `main.dart`

### Providers
- `supabaseClientProvider` — Supabase.instance.client
- `gameRepositoryProvider` — GameRepository
- `waitingGamesProvider` — StreamProvider s realtime updates

---

## Spuštění

```bash
# S cloud Supabase
flutter run \
  --dart-define=SUPABASE_URL=https://sgyqrkaajmgpyutmmyqj.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=tvůj-anon-key

# Nebo s .env (manuální export)
source .env && flutter run \
  --dart-define=SUPABASE_URL=$SUPABASE_URL \
  --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY

# Lokální hra (bez Supabase)
flutter run
```

---

## Architektura

```
                    ┌─────────────────────┐
                    │   Supabase Cloud     │
                    │  ┌───────────────┐   │
                    │  │ games table   │   │
                    │  │ (lobby CRUD)  │   │
                    │  └───────────────┘   │
                    │  ┌───────────────┐   │
                    │  │  Broadcast    │   │
                    │  │ game:{gameId} │   │
                    │  └───┬───────┬───┘   │
                    └──────┼───────┼───────┘
                           │       │
              ┌────────────┘       └────────────┐
              │                                 │
    ┌─────────┴──────────┐           ┌──────────┴─────────┐
    │   Player 1 (White) │           │   Player 2 (Black) │
    │                    │           │                     │
    │ LobbyScreen        │           │ LobbyScreen         │
    │   → Create Game    │           │   → Join Game       │
    │   → WaitingScreen  │           │                     │
    │                    │           │                     │
    │ GameSession        │  events   │ GameSession         │
    │  ├ SupabaseTransport ◄────────► SupabaseTransport   │
    │  ├ GameEngine      │           │  ├ GameEngine       │
    │  └ stateStream     │           │  └ stateStream      │
    │                    │           │                     │
    │ GameStateNotifier  │           │ GameStateNotifier   │
    │  └ GameScreen      │           │  └ GameScreen       │
    └────────────────────┘           └─────────────────────┘
```

---

## Co zbývá

### Krátkodobě
- [ ] E2E test na dvou zařízeních/emulátorech
- [ ] Reconnect handling (ztráta spojení)
- [ ] Game cleanup (smazání starých waiting games)
- [ ] Error handling v lobby UI (timeout, network errors)

### Střednědobě
- [ ] Auth (Supabase Auth — email/password nebo anonymous)
- [ ] Server-side validace tahů (Edge Functions)
- [ ] Matchmaking (random pairing)
- [ ] Game replay (ukládání tahů do DB)

### Dlouhodobě
- [ ] WebSocket P2P transport (lokální WiFi bez serveru)
- [ ] Spectator mode
- [ ] Rating system

---

## Testy
- 90 testů celkem (71 Phase 1 + 19 Phase 3 transport/session)
- Transport + session testy používají LocalGameTransport (in-memory mock)
- E2E Supabase test vyžaduje running instance
