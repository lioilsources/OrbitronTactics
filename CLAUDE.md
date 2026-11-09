# OrbitronTactics — CLAUDE.md

## Overview

Flutter 2-player chess variant with custom piece movement, power field domination victory conditions, and Supabase Realtime multiplayer. Supports local hot-seat, single player against an on-device AI, and cloud lobby.

## Commands

```bash
flutter pub get
flutter run
flutter run -d ios
flutter run -d android
flutter build apk
flutter build ios
flutter analyze
flutter test --exclude-tags slow   # what CI runs
flutter test --tags slow           # AI self-play: Hard vs Medium, ~1 min
```

## Architecture

```
lib/
├── main.dart
├── core/                    # App-wide utilities, theme, router
│   ├── ai/                  # Single-player AI: board search, battle pilot, fleet spending (pure Dart)
│   ├── constants/
│   ├── game_logic/          # Board rules, piece movement, win condition
│   ├── maneuvers/           # Maneuver catalog, gestures, flight paths (pure Dart)
│   ├── telemetry/           # Telemetry interface (pure Dart)
│   └── theme/
├── features/
│   ├── battle/              # Game screen — board rendering, move handling
│   ├── comcenter/           # Between-game lobby/settings screen
│   ├── store/               # In-app purchases: catalog, entitlements, RevenueCat
│   ├── game/                # Game state management
│   ├── onboarding/          # How to play, first-battle hint
│   ├── progress/            # Fleet progress (credits, upgrades, record) saved on device
│   └── telemetry/           # Product events to Supabase, Sentry breadcrumbs

assets/fleets/               # Battle ship sprites, one folder per fleet
assets/audio/                # Battle music and effects (tools/battle_audio)
lib/l10n/                    # English and Czech (ARB, generated localizations, content_cs.dart)
supabase/                    # Supabase schema and migrations
docs/                        # Privacy policy, store listing, store/ screenshots and feature graphics
release.example.json         # --dart-define-from-file keys for release builds
```

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
- Pack families (`ManeuverTier.pack`, `PackUnlock`): `spiral` (Ace pack), `phantom` (Phantom pack: `Maneuver.cloaks`, no shots, longest untouchable window, the painter fades the ship) and `strafe` (Striker pack: two passes over the enemy). `maneuver_pack_balance_test` (slow) keeps a pack maneuver at or under 58 % against its closest earnable one; both land at 44 %. `BattleAi` takes a fixed `maneuvers` loadout for it.
- Progress: `FleetProgress.maneuvers` (`ShipManeuvers`: owned, four armed, trained levels) and `battleWins` per ship. `FleetProgressNotifier.recordBattleWin` unlocks what the wins are worth, `buyManeuver`/`upgradeManeuver`/`armManeuvers`/`grantPack` do the rest. Single player only, like credits and skins.

## Fleet Ship Art

- `assets/fleets/<slug>/<unit>_<white|black>.png`: 10 fleets × 6 unit types × 2 colors, 256 px, bow up. `FleetSkin` (`features/battle/data/fleet_skin.dart`) maps slugs to asset paths; `fleet_skin_test` keeps the enum, the files and the pubspec asset folders in sync.
- `BattleArenaPainter` draws the sprites (decoded by `shipSpriteProvider`) sized as a fraction of the arena width and turns the top ship around; without a sprite it draws the vector hull.
- The player's fleet is `FleetProgress.skin`, picked in the Comcenter; each difficulty's is `AiProfile.fleetSkin`. Only single player uses them (`AiOpponentController.skinFor`); other modes fly `FleetSkin.fallback` (Vanguard).

## Store

- Free game, no ads; the store sells looks and sidegrades. `FleetSkin.premium` marks six fleets; Vanguard and the AI fleets are free.
- `StoreCatalog` lists the products (`bundle.commander`, `bundle.fleets`, `fleet.<slug>`, `pack.<id>`, `music.<slug>`); the ids are the Google Play and App Store product ids. `Entitlements` answers what is owned: a product, a bundle covering it, or a `legacyFleets` slug kept from before the store.
- `PurchaseService`: `RevenueCatPurchaseService` when the build has `REVENUECAT_GOOGLE_KEY` / `REVENUECAT_APPLE_KEY`, `DebugPurchaseService` (free, saved on device) in debug builds, else `UnavailablePurchaseService`. No RevenueCat entitlements or offerings: the app maps product ids itself.
- `EntitlementsNotifier` (`entitlementsProvider`) caches in `store.entitlements`, syncs at start, grants owned packs with `FleetProgressNotifier.grantPack`, and swaps an unowned premium skin for the fallback (refunds). The first launch with a store grandfathers the premium skin the player flies.
- Music: `BattleMusic` (`standard`, premium `retro` from `assets/audio/music_retro/`, built by `tools/battle_audio/chiptune.py`); `chosenBattleMusicProvider` keeps the pick in `battle_music`, `battleMusicProvider` falls back to standard when it is not owned; `BattleAudio.start(music:)` and `preview`.
- UI: Comcenter Store tab (`StoreTab`, Restore purchases), `showStoreItemSheet` from locked fleet cards and pack maneuvers.

## Localization

- English (template) and Czech in `lib/l10n/app_{en,cs}.arb`; `flutter gen-l10n` writes the tracked `app_localizations*.dart` next to them. Use `context.l10n` (falls back to English without delegates, as in widget tests).
- Catalog content stays English in pure Dart; `AppLocalizations.content()`, `maneuverName`, `storeTitle` and so on translate it from `content_cs.dart`. `l10n_test` fails when a key, placeholder or catalog text is missing in Czech or a Czech entry is stale.
- `resolveAppLocale`: Czech for a Czech device, English for everything else (Flutter's own fallback would pick Czech, the first supported locale).
- Fleet names stay proper nouns; the game's default player names (White, Black, Orbitron AI) are mapped for display in `game_screen.dart`.

## Store screenshots

`STORE_SCREENSHOTS=1 flutter test test/store_screenshots` renders `docs/store/` (skipped otherwise). It loads Roboto and Material Icons from the Flutter SDK and DejaVu Sans for chess symbols from this machine, fakes store prices, and picks a battle frame from simulated duels. `OrbitronTacticsApp` takes `home`, `locale` and `theme` for it.

## Telemetry and onboarding

- `Telemetry.event(name, props)` never throws. `SupabaseTelemetry` inserts into `app_events` (insert-only RLS) and adds a Sentry breadcrumb; tests use `NoTelemetry` / `RecordingTelemetry`. Events: `app_opened`, `game_started`, `game_finished`, `store_opened`, `store_item_viewed`, `purchase_started`, `purchase`, `restore`.
- Sentry starts only with `SENTRY_DSN`; no PII, no tracing.
- `OnboardingStore` (`onboardingStoreProvider`, everything seen by default): `HowToPlayScreen` on first launch, `_ControlsHint` over the arena until the first touch.

## Supabase Integration

- **Realtime Broadcast** — move sync between players (~20-50ms)
- **Presence** — detect opponent disconnect
- **DB** — lobby/session management
- **Auth** — every install signs in anonymously (`GameRepository.ensureSignedIn`). RLS: open games visible to signed-in players, a game otherwise only to its `white_uid`/`black_uid`; the black seat only through `join_game()`. `pg_cron` deletes stale games. `GameRepository.protocol` must be bumped when a `GameEvent` changes incompatibly.

Configure in app: set Supabase URL and anon key (check `lib/core/` for config). Release keys: `release.example.json`, built with `--dart-define-from-file=release.json`.

## Game Rules

- 8×8 board, custom piece types and movement
- 5 power fields — control majority to win
- Threat indicators: red badge on pieces in danger
- Local hot-seat mode: two players, one device

## Platforms

iOS, Android. Release steps that need accounts: `Prompts/10-RELEASE-checklist.md`.
