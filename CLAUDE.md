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
│   └── theme/
├── features/
│   ├── battle/              # Game screen — board rendering, move handling
│   ├── comcenter/           # Between-game lobby/settings screen
│   ├── game/                # Game state management
│   └── progress/            # Fleet progress (credits, upgrades, record) saved on device

supabase/                    # Supabase schema and migrations
```

## Dependencies

- `flutter_riverpod` — state management (StateNotifier)
- `freezed` / `json_serializable` — immutable game models
- `supabase_flutter` — lobby and realtime multiplayer
- `shared_preferences` — fleet progress, one JSON blob per fleet under `fleet_progress.<identity>`

## Single Player AI

- `GameMode.singlePlayer` in `GameStateNotifier`; `AiOpponentController` (`aiOpponentProvider`, watched by `GameScreen`) plays the AI's turns and books battle rewards and game results.
- `AiProfile` holds all tunables per difficulty. Easy/Medium use `GreedyAi` (one ply); Hard uses `SearchAi` (alpha-beta, captures as chance nodes weighted by `BattleOdds`), run via `compute()`.
- `BattleAi` pilots the AI ship; `BattleStateNotifier` applies its actions on the engine every tick.
- Fleet identities: `player`, `ai-easy`, `ai-medium`, `ai-hard`. `FleetProgression.spend` keeps an AI fleet's total upgrade levels within the player's plus the profile's rubber-band offset.

## Supabase Integration

- **Realtime Broadcast** — move sync between players (~20-50ms)
- **Presence** — detect opponent disconnect
- **DB** — lobby/session management

Configure in app: set Supabase URL and anon key (check `lib/core/` for config).

## Game Rules

- 8×8 board, custom piece types and movement
- 5 power fields — control majority to win
- Threat indicators: red badge on pieces in danger
- Local hot-seat mode: two players, one device

## Platforms

iOS, Android, Windows.
