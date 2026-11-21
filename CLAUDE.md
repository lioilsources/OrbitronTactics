# OrbitronTactics — CLAUDE.md

## Overview

Flutter 2-player chess variant with custom piece movement, power field domination victory conditions, and Supabase Realtime multiplayer. Supports local hot-seat, single player against an on-device AI, and cloud lobby.

## Commands

```bash
flutter pub get
flutter run
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
│   ├── constants/           # incl. supabase_constants.dart (--dart-define config)
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
tools/                       # Asset generators: battle_audio, fleet_art, faction_art (see their READMEs)
docs/                        # Architecture notes, privacy policy, store listing, store/ screenshots
release.example.json         # --dart-define-from-file keys for release builds
```

## Game Rules

- 8×8 board, custom piece types and movement
- 5 power fields — control all five at the end of your turn to win (`VictoryChecker`)
- Threat indicators: red badge on pieces in danger
- Local hot-seat mode: two players, one device

## Platforms

iOS, Android, Windows. Release steps that need accounts: `Prompts/10-RELEASE-checklist.md`.

## More

- `docs/architecture.md` — dependencies, single player AI, battle arena, maneuvers, fleet ship art, store, localization, telemetry, Supabase.
- `docs/lab/worlds-catalog.md` — world catalog. `Prompts/` — implementation plans.
