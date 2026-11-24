# OrbitronTactics — CLAUDE.md

## Overview

Flutter 2-player chess variant with custom piece movement, power field domination victory conditions, and Supabase Realtime multiplayer. Supports local hot-seat, single player against an on-device AI, and cloud lobby.

The game is called Archion. Orbitron Tactics is the old name; the repo, the Dart package, the bundle ids and the store product ids keep it. User-facing text says Archion.

## Commands

```bash
flutter pub get
flutter run
flutter build apk
flutter build ios
flutter analyze
flutter test --exclude-tags slow   # what CI runs
flutter test --tags slow           # AI self-play: Hard vs Medium, ~1 min
dart run tools/variant_lab.dart [games] [ids]  # Medium vs Medium per board variant
```

## Architecture

```
lib/
├── main.dart
├── core/                    # App-wide utilities, theme, router
│   ├── ai/                  # Single-player AI: board search, battle pilot, fleet spending (pure Dart)
│   ├── constants/           # incl. supabase_constants.dart (--dart-define config)
│   ├── game_logic/          # Board rules, piece movement, win condition; board/ = BoardGeometry, BoardSpec
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
tools/                       # Asset generators: battle_audio, fleet_art, faction_art (see their READMEs)
docs/                        # Architecture notes, privacy policy, store listing, store/ screenshots
release.example.json         # --dart-define-from-file keys for release builds
```

## Game Rules

- 8×8 board (`BoardSpec.classic8`, the default) or a hexagon of side 6 (`BoardSpec.hex6`, single player and local games); other variants exist only in the core and `variant_lab`. Custom piece types and movement
- 5 power fields — control all five at the end of your turn to win (`VictoryChecker`)
- Threat indicators: red badge on pieces in danger
- Local hot-seat mode: two players, one device
- Battles in a figure world are fought by `WorldBalance.ground` (pawn, knight, rook, king melee) in hot-seat and single player; Space and network games by `WorldBalance.space`. Both units falling in one tick removes both pieces (`BattleState.isMutualDestruction`)
- The world (`PieceSkin`, stored as `piece_skin`) sets both the board pieces and the arena units: `classic` is Space (chess symbols on the board, fleet ships in the arena); figure worlds send their board figures into the arena standing (`unitArt`, `UnitPose`). `PieceSkin.free` is the one list of free worlds, the rest sell as `world_<slug>`

## Platforms

iOS, Android, Windows. Release steps that need accounts: `Prompts/10-RELEASE-checklist.md`.

## More

- `docs/architecture.md` — dependencies, single player AI, battle arena, maneuvers, worlds, fleet ship art, store, localization, telemetry, Supabase.
- `docs/lab/worlds-catalog.md` — world catalog. `docs/lab/duel-lab.md` — melee duel lab. `Prompts/` — implementation plans.
