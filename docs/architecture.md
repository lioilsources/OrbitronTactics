# OrbitronTactics — architecture notes

Moved from `CLAUDE.md` so it stays short. Short map and commands live there.

## Dependencies

- `flutter_riverpod` — state management (StateNotifier)
- `freezed` / `json_serializable` — immutable game models
- `supabase_flutter` — lobby and realtime multiplayer
- `shared_preferences` — fleet progress, one JSON blob per fleet under `fleet_progress.<identity>`
- `flutter_localizations` / `intl` — gen-l10n, English and Czech
- `purchases_flutter` — RevenueCat in-app purchases (one-time products only)
- `sentry_flutter` 9.x — crash reports (10.x needs Dart 3.12; 8.x breaks the Kotlin build)
- `package_info_plus` — app version for telemetry
- `flutter_soloud` 4.x — battle music and sound effects (SoLoud decodes OGG itself on every platform; 5.x needs a newer Flutter SDK)

## Single Player AI

- `GameMode.singlePlayer` in `GameStateNotifier`; `AiOpponentController` (`aiOpponentProvider`, watched by `GameScreen`) plays the AI's turns and books battle rewards and game results.
- `AiProfile` holds all tunables per difficulty. Easy/Medium use `GreedyAi` (one ply); Hard uses `SearchAi` (alpha-beta, captures as chance nodes weighted by `BattleOdds`), run via `compute()`.
- `BattleAi` pilots the AI ship; `BattleStateNotifier` applies its actions on the engine every tick.
- Fleet identities: `player`, `ai-easy`, `ai-medium`, `ai-hard`. `FleetProgression.spend` keeps an AI fleet's total upgrade levels within the player's plus the profile's rubber-band offset.

## Battle Arena

- `BattleEngine` ticks the fight. Ships have `xFraction` and `altitude` (0–1); a `Projectile` keeps its shooter's lane and altitude and hits only within `hitHalfWidth` and `hitHalfAltitude`. Shots arriving on target are logged in `BattleState.impacts` for the effects. After `ArenaRules.suddenDeathAfterMs` (45 s) sudden death grows the hit zone (`hitScaleAt`) until, `suddenDeathRampMs` (15 s) later, it covers the whole arena and no ship can dodge; `BattleAi` and the painter read the grown zone, the battle header shows SUDDEN DEATH.
- `BattleScreen` input: in your half the finger's x sets the ship's position, dragging forward (toward the enemy) climbs and back dives. `ShipMovedEvent` carries both to the opponent; `BattleAi` returns a target position and altitude.
- `BattleArenaPainter` shows altitude as size and shadow, banks ships by their sideways speed (`ShipBank`), and draws shots and `ExplosionFx` in the shooter's `BattleElement` (pawn kinetic, knight water, bishop fire, rook ice, queen and king electric). The loser's explosion plays before the result overlay.
- `BattleAudio` (SoLoud) loops the attacker's theme and plays what `BattleSoundCues` finds between two battle states: each element's shot, the head of its explosion for an impact, the whole echoing explosion for the destroyed ship. Assets in `assets/audio/{music,sfx}/` (`BattleSounds`) come from `tools/battle_audio/`; the mute setting is saved as `battle_audio_muted`. Any audio failure only logs.
- `ArenaLayout` maps altitude to where a ship sits in its half — own edge at 0, just short of the divider at 1 — and its `travelFraction` is shared by the painter and the arena's input, so steering moves the ship exactly as far as the finger.
- Melee (plans 12 and 14): `WorldBalance` (`lib/core/worlds/`) holds a world's unit stats and `ArenaRules`; `space` is today's `unitBaseStats`, `ground` (pawn, knight, rook and king up close; bishop and queen shoot) is every figure world's (`PieceSkin.balance`). `BattleEngine.createBattle(balance:)` stores it in `BattleState.balance`; `game_screen.dart` passes the chosen world's in hot-seat and single player (`GameMode.fightsInChosenWorld`), space in `localWifi` and online. A unit with `AttackStyle.melee` strikes instead of firing: wind-up (cancelled when the enemy leaves reach), untouchable lunge timed by range, recovery; a shield blocks and staggers. `ArenaRules` is the single source of the sudden-death rules (`suddenDeathAfterMs`, `suddenDeathRampMs`, `suddenDeathMaxScale`), read from the battle's own balance; sudden death grows a strike's reach (`reachHalfWidthAt`, `reachHalfAltitudeAt`) by the same `hitScaleAt` as the zone of shots, so two melee units cannot keep apart forever. `Duel` (`lib/core/ai/duel.dart`) runs headless seeded duels; `tools/duel_lab.dart` measures balance (`docs/lab/duel-lab.md`), `space_duel_regression_test` pins space.
- Mutual destruction (plan 14, decision 10): both units destroyed in one tick finish the battle with no winner (`BattleState.isMutualDestruction`). `GameEngine.resolveBattle(…, null)` takes both pieces off the board (the captured piece as in a won capture, the attacker as in a lost one), earns no credits and passes the turn; `BattleResolvedEvent` carries `mutualDestruction` with the attacker as `winner`, so an older client reads it as the attacker's win and a message without the flag is a plain win. The battle result says BOTH FALL / OBA PADLI and that a draw earns nothing; both units explode.
- The board AI counts a draw as losing both pieces: `BattleOdds.outcomes` splits a battle into win, draw and loss (`meleeMirrorDraw` for two melee units, `rangedMirrorDraw` otherwise, falling off with the time-to-kill gap); `OddsTable` keeps draws from `minSearchedDraw` (5 %) up, so in space none reaches the search and space play is unchanged. `GreedyAi` and `SearchAi` weigh a third outcome, `BoardEvaluator` values pieces and threats by the game's balance; `AiOpponentController` sends the balance's id into the `compute()` isolate (`WorldBalance.byId`).
- Melee drawing (`BattleArenaPainter`, `MeleeFx`): the wind-up telegraphs the impact zone as a flattened ellipse in the striker's element on the enemy's side with a faint line to it, the striker leaning back; the lunge draws the figure along that line (`StrikeRun.lungeAt`; the logical position stays home) leaning forward with white speed streaks; a hit (`Impact.melee`) slashes a glowing arc with a white star across the target, tinted red for a moment; a block throws yellow-white sparks and the striker recoils, washed out and leaning back, through its stagger. Sound (`BattleSoundCues.strikes`, `blocks`): a lunge plays the kinetic shot, a block the head of the kinetic explosion, a hit the striker's impact; new melee sounds are a separate step.

## Maneuvers

- `ManeuverCatalog.forShip(ship, balance:)` gives every ship twelve shared families in its own variant plus a signature: gesture (`Pattern`, Android lock-screen rules), keyframes anchored to the ship's origin, the enemy then or now, or the arena, bursts of fire, an untouchable window and the attitude the painter draws (roll, pitch, flip, boost). The mirrored gesture flies the maneuver with its sideways offsets negated.
- `BattleEngine.startManeuver` charges `BattleUnit.energy` (50 at the start, `maxEnergy` 100, `energyPerSecond` back) and stores a `ManeuverRun`; `tick` flies it, fires its bursts, lets shots pass through the untouchable window and refuses steering until it ends. `Overdrive` is the exception: the helm stays, only `fireRateScale` changes.
- `ManeuverPad` recognises the gesture (`PatternRecognizer`) and `BattleStateNotifier.startLocalManeuver` runs it, sending `ManeuverStartedEvent` with the anchors so the opponent's engine flies the same path. An unknown maneuver id is ignored.
- A melee unit flies the same maneuvers with contact bursts (`FireCue.contact`; `ManeuverCatalog.forShip`/`byId` with its balance, which the engine reads from `BattleState.balance`): each burst is one blow, without a shot's flight, only within range 1 and reach, carrying the burst's damage times `ArenaRules.contactDamageScale` (0.15 in ground, tuned in the duel lab: a blow does not miss in flight the way most shots do); a volley becomes three blows, Overdrive shortens the strike interval. Ids, gestures and paths are unchanged. Standing worlds name three families by how a figure moves (`maneuverName(standing:)`: Leap / Výskok, Tumble / Kotoul, Flurry / Smršť).
- `BattleAi` reaches for one on its own 700 ms clock — cornered, or with the enemy in its hit zone. Tying it to the steering decision had the best pilots flying one almost without a break.
- Pack families (`ManeuverTier.pack`, `PackUnlock`): `spiral` (Ace pack), `phantom` (Phantom pack: `Maneuver.cloaks`, no shots, longest untouchable window, the painter fades the ship) and `strafe` (Striker pack: two passes over the enemy). `maneuver_pack_balance_test` (slow) keeps a pack maneuver at or under 58 % against its closest earnable one; both land at 44 %. `BattleAi` takes a fixed `maneuvers` loadout for it.
- Progress: `FleetProgress.maneuvers` (`ShipManeuvers`: owned, four armed, trained levels) and `battleWins` per ship. `FleetProgressNotifier.recordBattleWin` unlocks what the wins are worth, `buyManeuver`/`upgradeManeuver`/`armManeuvers`/`grantPack` do the rest. Single player only, like credits and skins.
- `dart run tools/dump_maneuvers.dart <dir>` writes the whole catalog out as a TSV plus flight paths sampled through `Maneuver.poseAt`. The olin.now store gallery animates them (`make import-fleets` there); sampling here rather than re-deriving the easing in JavaScript is what keeps the two from drifting.

## Worlds

- The world is `PieceSkin` (`features/game/data/piece_skin.dart`), still stored as `piece_skin`: `classic` is Space (shown as Space / Vesmír), chess symbols on the board and the fleet in the arena (`isSpace`, `pose` = `UnitPose.topDown`); the 16 figure worlds draw their figures on the board and in the arena (`UnitPose.standing`). It applies to every game mode.
- `unitArt(world, fleet, type, color)` (`features/battle/data/unit_art.dart`) says what a unit fights as: the fleet's ship in Space, the board figure — plinth and all, black mirrored — elsewhere. No plinth-less battle variant ships with the app. `sideFleetProvider` (single player via `AiOpponentController.skinFor`, else `FleetSkin.fallback`) and `sideUnitArtProvider` are the one place `game_screen.dart` takes both sides' art from when it opens `BattleScreen(attackerArt:, defenderArt:)`.
- `BattleArenaPainter` draws a standing unit upright at one size for all six types (`_figureWidthFraction`; ranks are in the pictures), on a contact shadow, without bank or altitude scaling: altitude only moves it forward (`ArenaLayout`). The top figure is turned around only in hot-seat (`drawsUpsideDown`). Maneuver attitudes: roll spins it about its upright axis, flip is a jump, pitch a lean, boost kicks up dust; no engine flames. The hit zone stays readable through the shots: one off its target's altitude is dimmed, one on it carries a ring.
- Figure worlds fight by `WorldBalance.ground` on one device (see Battle Arena: melee); elements and their colors are the same in every world. The UNITS tab's cards say MELEE or RANGED where a world has both, and How to play explains strikes, blocks and mutual destruction.
- `PieceSkin.free` is the one list of free worlds (Space, Rome × Carthage, Knights × Orcs, Heaven × Hell); `premium` is everything else.
- Comcenter tabs: WORLD (`PieceSkinPicker` with `FleetPicker` while in Space, the classic marks toggle in a figure world), UNITS, MANEUVERS, STORE. The lobby's `_WorldRow` opens the Comcenter.

## Fleet Ship Art

- `assets/fleets/<slug>/<unit>_<white|black>.png`: 10 fleets × 6 unit types × 2 colors, 256 px, bow up. `FleetSkin` (`features/battle/data/fleet_skin.dart`) maps slugs to asset paths; `fleet_skin_test` keeps the enum, the files and the pubspec asset folders in sync.
- `BattleArenaPainter` draws the sprites (decoded by `shipSpriteProvider`) sized as a fraction of the arena width and turns the top ship around; without a sprite it draws the vector hull.
- The player's fleet is `FleetProgress.skin`, picked on the Comcenter's WORLD tab while in Space; each difficulty's is `AiProfile.fleetSkin`. Only single player uses them (`AiOpponentController.skinFor`, through `sideFleetProvider`); other modes fly `FleetSkin.fallback` (Vanguard). Fleets show only in the Space world.
- The sprites are generated on ComfyUI by `tools/fleet_art/` (see its README), which also covers re-rolling a ship and adding a fleet.

## Store

- Free game, no ads; the store sells looks and sidegrades. `FleetSkin.premium` marks six fleets; Vanguard and the AI fleets are free.
- `StoreCatalog` lists the products as `com.ol1n.orbitrontactics.pack.<packId>` (`commander`, `world_<slug>`, `fleet_<slug>`, `<pack id>`, `music_<slug>`), the same id on Google Play and the App Store; every product costs USD 0.99, the Commander Edition (everything) USD 4.99. `Entitlements` answers what is owned: a product, a bundle covering it, or a `legacyFleets` slug kept from before the store.
- `PurchaseService`: `RevenueCatPurchaseService` when the build has `REVENUECAT_GOOGLE_KEY` / `REVENUECAT_APPLE_KEY`, `DebugPurchaseService` (free, saved on device) in debug builds, else `UnavailablePurchaseService`. No RevenueCat entitlements or offerings: the app maps product ids itself.
- `EntitlementsNotifier` (`entitlementsProvider`) caches in `store.entitlements`, syncs at start, grants owned packs with `FleetProgressNotifier.grantPack`, and swaps an unowned premium fleet or world for the fallback (refunds); buying a world chooses it. The first launch with a store grandfathers the premium fleet the player flies; the first launch since worlds are sold (a cache without `legacyWorlds`, `Entitlements.worldsSettled` false) grandfathers the world the player plays in.
- Music: `BattleMusic` (`standard`, premium `retro` from `assets/audio/music_retro/`, built by `tools/battle_audio/chiptune.py`); `chosenBattleMusicProvider` keeps the pick in `battle_music`, `battleMusicProvider` falls back to standard when it is not owned; `BattleAudio.start(music:)` and `preview`.
- UI: Comcenter Store tab (`StoreTab`, Restore purchases), `showStoreItemSheet` from locked world and fleet cards and pack maneuvers.

## Localization

- English (template) and Czech in `lib/l10n/app_{en,cs}.arb`; `flutter gen-l10n` writes the tracked `app_localizations*.dart` next to them. Use `context.l10n` (falls back to English without delegates, as in widget tests).
- Catalog content stays English in pure Dart; `AppLocalizations.content()`, `maneuverName`, `storeTitle` and so on translate it from `content_cs.dart`. `l10n_test` fails when a key, placeholder or catalog text is missing in Czech or a Czech entry is stale.
- `resolveAppLocale`: Czech for a Czech device, English for everything else (Flutter's own fallback would pick Czech, the first supported locale).
- Fleet names stay proper nouns; the game's default player names (White, Black, Orbitron AI) are mapped for display in `game_screen.dart`.

## Store screenshots

`STORE_SCREENSHOTS=1 flutter test test/store_screenshots` renders `docs/store/` (skipped otherwise). It loads Roboto and Material Icons from the Flutter SDK and DejaVu Sans for chess symbols from this machine, fakes store prices, and picks a battle frame from simulated duels. `OrbitronTacticsApp` takes `home`, `locale` and `theme` for it.

## Board shapes

- `BoardSpec` (`lib/core/game_logic/board/`) names a board: its `BoardGeometry` (`SquareGeometry` or `HexGeometry`), layout and power fields. `BoardState.spec` travels in the JSON; a missing one is `classic8`.
- Hex (`hex6`): a hexagon with six cells a side (91 cells, rows of 6 to 11) cut out of an 11×11 grid by `HexGeometry.hexagon`; pointy-top hexes in horizontal rows, offset coordinates with odd rows shifted half a cell right. A slide through a corner stops when both hexes beside the corner are taken (`CornerBlock.both`); `docs/lab/variant-lab.md` has the numbers behind that choice.
- `BoardLayout` (`features/game/presentation/widgets/board/`) places every cell on screen for both painters, the piece layer and taps (nearest cell centre). `resolveTap` (`tap_resolver.dart`, same folder) makes hex taps tolerant: a tap off every useful cell snaps to the nearest move target, selected piece or own piece with a move within `tapReachFor(layout)` = 0.8 cell widths; the square board keeps exact taps (reach 0). In a world of standing figures (`PieceSkin.pose`) the board tilts: `boardTiltFor(spec, world)` takes the board's `BoardTilt` (squash `k`, figure height in cells) from `standingTilts`, the one table keyed by board id (P2 defaults: hex k 0.85, square k 1.0, figures 1.25 cells; Space stays flat). `BoardLayout` works on the flat board (`flatCentreOf`) and squashes it (`toScreen`/`toFlat`), so `positionAt` stays exact and flipped boards turn around alike; `size` adds room on top for the back row. Figures stand with their plinth's centre (`StandingFigure.plinthAnchor` = 0.93 of the picture) on the cell's centre, painted back to front (`inDrawOrder`); highlights and power fields go through `cellPath`/`cellRect` and squash with the board. `resolveTap` catches a standing figure on its head (`headOf`, half its height, within half a cell) when the cell under the finger holds nothing a tap could pick. The lobby's board picker applies to single player and local games; online and WiFi games stay on `classic8`.

## Telemetry and onboarding

- `Telemetry.event(name, props)` never throws. `SupabaseTelemetry` inserts into `app_events` (insert-only RLS) once the install is signed in, i.e. has played online; before that events are only Sentry breadcrumbs and adds a Sentry breadcrumb; tests use `NoTelemetry` / `RecordingTelemetry`. Events: `app_opened`, `game_started`, `game_finished`, `store_opened`, `store_item_viewed`, `purchase_started`, `purchase`, `restore`.
- Sentry starts only with `SENTRY_DSN`; no PII, no tracing.
- `OnboardingStore` (`onboardingStoreProvider`, everything seen by default): `HowToPlayScreen` on first launch, `_ControlsHint` over the arena until the first touch.

## Supabase Integration

- **Realtime Broadcast** — move sync between players (~20-50ms)
- **Presence** — detect opponent disconnect
- **DB** — lobby/session management
- **Auth** — an install signs in anonymously on its first online action (`GameRepository.ensureSignedIn`, called by every repository method); telemetry never signs in. RLS: open games visible to signed-in players, a game otherwise only to its `white_uid`/`black_uid`; the black seat only through `join_game()`. `pg_cron` deletes stale games. `GameRepository.protocol` must be bumped when a `GameEvent` changes incompatibly.

Config: `lib/core/constants/supabase_constants.dart` reads `SUPABASE_URL` and `SUPABASE_ANON_KEY` from `--dart-define`, with built-in defaults.
Release keys: `release.example.json`, built with `--dart-define-from-file=release.json`.
