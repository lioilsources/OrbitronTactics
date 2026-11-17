# OrbitronTactics — architecture notes

Moved from `CLAUDE.md` so it stays short. Short map and commands live there.

## Dependencies

- `flutter_riverpod` — state management (StateNotifier)
- `freezed` / `json_serializable` — immutable game models
- `supabase_flutter` — lobby and realtime multiplayer
- `shared_preferences` — fleet progress, one JSON blob per fleet under `fleet_progress.<identity>`
- `flutter_soloud` 4.x — battle music and sound effects (SoLoud decodes OGG itself on every platform; 5.x needs a newer Flutter SDK)

## Single Player AI

- `GameMode.singlePlayer` in `GameStateNotifier`; `AiOpponentController` (`aiOpponentProvider`, watched by `GameScreen`) plays the AI's turns and books battle rewards and game results.
- `AiProfile` holds all tunables per difficulty. Easy/Medium use `GreedyAi` (one ply); Hard uses `SearchAi` (alpha-beta, captures as chance nodes weighted by `BattleOdds`), run via `compute()`.
- `BattleAi` pilots the AI ship; `BattleStateNotifier` applies its actions on the engine every tick.
- Fleet identities: `player`, `ai-easy`, `ai-medium`, `ai-hard`. `FleetProgression.spend` keeps an AI fleet's total upgrade levels within the player's plus the profile's rubber-band offset.

## Battle Arena

- `BattleEngine` ticks the fight. Ships have `xFraction` and `altitude` (0–1); a `Projectile` keeps its shooter's lane and altitude and hits only within `hitHalfWidth` and `hitHalfAltitude`. Shots arriving on target are logged in `BattleState.impacts` for the effects.
- `BattleScreen` input: in your half the finger's x sets the ship's position, dragging forward (toward the enemy) climbs and back dives. `ShipMovedEvent` carries both to the opponent; `BattleAi` returns a target position and altitude.
- `BattleArenaPainter` shows altitude as size and shadow, banks ships by their sideways speed (`ShipBank`), and draws shots and `ExplosionFx` in the shooter's `BattleElement` (pawn kinetic, knight water, bishop fire, rook ice, queen and king electric). The loser's explosion plays before the result overlay.
- `BattleAudio` (SoLoud) loops the attacker's theme and plays what `BattleSoundCues` finds between two battle states: each element's shot, the head of its explosion for an impact, the whole echoing explosion for the destroyed ship. Assets in `assets/audio/{music,sfx}/` (`BattleSounds`) come from `tools/battle_audio/`; the mute setting is saved as `battle_audio_muted`. Any audio failure only logs.
- `ArenaLayout` maps altitude to where a ship sits in its half — own edge at 0, just short of the divider at 1 — and its `travelFraction` is shared by the painter and the arena's input, so steering moves the ship exactly as far as the finger.

## Maneuvers

- `ManeuverCatalog.forShip` gives every ship twelve shared families in its own variant plus a signature: gesture (`Pattern`, Android lock-screen rules), keyframes anchored to the ship's origin, the enemy then or now, or the arena, bursts of fire, an untouchable window and the attitude the painter draws (roll, pitch, flip, boost). The mirrored gesture flies the maneuver with its sideways offsets negated.
- `BattleEngine.startManeuver` charges `BattleUnit.energy` (50 at the start, `maxEnergy` 100, `energyPerSecond` back) and stores a `ManeuverRun`; `tick` flies it, fires its bursts, lets shots pass through the untouchable window and refuses steering until it ends. `Overdrive` is the exception: the helm stays, only `fireRateScale` changes.
- `ManeuverPad` recognises the gesture (`PatternRecognizer`) and `BattleStateNotifier.startLocalManeuver` runs it, sending `ManeuverStartedEvent` with the anchors so the opponent's engine flies the same path. An unknown maneuver id is ignored.
- `BattleAi` reaches for one on its own 700 ms clock — cornered, or with the enemy in its hit zone. Tying it to the steering decision had the best pilots flying one almost without a break.
- Progress: `FleetProgress.maneuvers` (`ShipManeuvers`: owned, four armed, trained levels) and `battleWins` per ship. `FleetProgressNotifier.recordBattleWin` unlocks what the wins are worth, `buyManeuver`/`upgradeManeuver`/`armManeuvers`/`grantPack` do the rest. Single player only, like credits and skins.

## Fleet Ship Art

- `assets/fleets/<slug>/<unit>_<white|black>.png`: 10 fleets × 6 unit types × 2 colors, 256 px, bow up. `FleetSkin` (`features/battle/data/fleet_skin.dart`) maps slugs to asset paths; `fleet_skin_test` keeps the enum, the files and the pubspec asset folders in sync.
- `BattleArenaPainter` draws the sprites (decoded by `shipSpriteProvider`) sized as a fraction of the arena width and turns the top ship around; without a sprite it draws the vector hull.
- The player's fleet is `FleetProgress.skin`, picked in the Comcenter; each difficulty's is `AiProfile.fleetSkin`. Only single player uses them (`AiOpponentController.skinFor`); other modes fly `FleetSkin.fallback` (Vanguard).
- The sprites are generated on ComfyUI by `tools/fleet_art/` (see its README), which also covers re-rolling a ship and adding a fleet.

## Supabase Integration

- **Realtime Broadcast** — move sync between players (~20-50ms)
- **Presence** — detect opponent disconnect
- **DB** — lobby/session management

Config: `lib/core/constants/supabase_constants.dart` reads `SUPABASE_URL` and `SUPABASE_ANON_KEY` from `--dart-define`, with built-in defaults.
