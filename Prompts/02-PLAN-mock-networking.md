# OrbitronTactics - Phase 3: Mock Networking Layer

## Stav

Implementován abstraktní transport layer s in-memory mockem. Architektura je připravená na budoucí Supabase nebo WebSocket implementaci.

---

## Co je hotové

### GameEvent (`lib/features/game/data/game_event.dart`)
Sealed union eventů vyměňovaných mezi hráči:
- `MoveMadeEvent` — tah s plným `Move` objektem
- `FormationLockedEvent` — hráč zamkl formaci
- `GameStartedEvent` — oba hráči ready, hra začíná
- `GameOverEvent` — konec hry (vítěz + důvod)
- `PlayerJoinedEvent` — hráč se připojil
- `PlayerLeftEvent` — hráč odešel

Všechny eventy mají `toJson()` / `fromJson()` pro budoucí serializaci přes síť.

### GameTransport (`lib/features/game/data/game_transport.dart`)
Abstraktní interface:
```dart
abstract class GameTransport {
  Stream<GameEvent> get events;    // příchozí eventy od soupeře
  void send(GameEvent event);      // odeslat event soupeři
  bool get isConnected;
  Future<void> connect();
  Future<void> disconnect();
  void dispose();
}
```

**LocalGameTransport** — in-memory implementace:
- `createPair()` → dvě propojené instance
- Co jedna pošle, druhá přijme (a naopak)
- Pro hot-seat testing a lokální hru

### GameSession (`lib/features/game/data/game_session.dart`)
Koordinátor multiplayer hry:
- Vlastní `GameTransport` + lokální `GameState`
- Validuje vlastnictví figurek (hráč může táhnout jen svými)
- Aplikuje tahy lokálně + posílá soupeři
- Přijímá a aplikuje tahy soupeře
- `stateStream` pro reaktivní UI updaty
- `createLocalGame()` — vytvoří spárovanou dvojici sessions

### GameStateProvider (upraven)
Rozšířen o dva režimy:
- `GameMode.hotSeat` — přímé aplikování tahů (jako dřív)
- `GameMode.multiplayer` — deleguje na `GameSession`
- `attachSession(session)` — napojí session, poslouchá stateStream
- `startLocalMultiplayerGame()` — vytvoří spárovanou lokální hru

---

## Testy (19 nových, 90 celkem)

### game_transport_test.dart (9 testů)
- Vytvoření páru transportů
- Obousměrné odesílání eventů
- Nedoručení při odpojeném peeru
- Connection state tracking
- JSON round-trip pro MoveMade, GameStarted, GameOver, PlayerJoined

### game_session_test.dart (10 testů)
- Obě sessions startují v playing phase
- White goes first
- Hráč vidí tahy jen svých figurek
- Tah se přenese na soupeře
- Plný cyklus: white → black → white
- Black nemůže táhnout na white turn
- Neplatný tah vrací false
- Historie tahů se synchronizuje
- stateStream emituje při lokálním tahu
- stateStream emituje při vzdáleném tahu

---

## Architektura

```
GameTransport (abstract)
├── LocalGameTransport     ← ✅ hotové (in-memory, same-process)
├── SupabaseTransport      ← ❌ budoucí (internet přes Supabase Broadcast)
└── WebSocketTransport     ← ❌ budoucí (WiFi P2P, desktop LAN)

GameSession
├── Vlastní transport + game state
├── Validuje ownership figurek
├── Posílá eventy soupeři
└── Přijímá a aplikuje eventy soupeře

GameStateNotifier
├── hotSeat mode → přímý GameEngine (bez transportu)
└── multiplayer mode → deleguje na GameSession
```

---

## Co zbývá pro plný networking

### Varianta A: Supabase Broadcast (doporučeno pro MVP)
- [ ] Supabase projekt (CLI nebo ruční setup)
- [ ] `SupabaseGameTransport implements GameTransport`
- [ ] Broadcast kanál `game:{gameId}`
- [ ] Párování hráčů (sdílení game ID / matchmaking queue)
- [ ] Lobby UI (vytvořit/připojit se ke hře)
- [ ] Reconnect handling
- [ ] Volitelně: Edge Functions pro server-side validaci

### Varianta B: WebSocket P2P (lokální WiFi)
- [ ] `WebSocketGameTransport implements GameTransport`
- [ ] Host vytvoří WebSocket server
- [ ] Client se připojí na host IP/port
- [ ] mDNS discovery (volitelně)
- [ ] Lobby UI (host/join)

### Varianta C: WebRTC (přímé P2P přes internet)
- [ ] Signaling server (minimální)
- [ ] `WebRtcGameTransport implements GameTransport`
- [ ] NAT traversal (STUN/TURN)

### Společné (nezávislé na variantě)
- [ ] Lobby / matchmaking screen
- [ ] Connection status indikátor v UI
- [ ] Error handling (timeout, disconnect)
- [ ] Rematch flow

---

## Poznámky
- Supabase CLI zatím není nainstalované — proto mock-first přístup
- Díky abstraktnímu `GameTransport` lze přidat libovolný backend bez změny game logic
- Všechny 90 testů passing (71 Phase 1 + 19 Phase 3)
