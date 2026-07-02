# OrbitronTactics — CLAUDE.md

## Overview

Flutter 2-player chess variant with custom piece movement, power field domination victory conditions, and Supabase Realtime multiplayer. Supports local hot-seat and cloud lobby.

## Commands

```bash
flutter pub get
flutter run
flutter run -d ios
flutter run -d android
flutter build apk
flutter build ios
flutter analyze
flutter test
```

## Architecture

```
lib/
├── main.dart
├── core/                    # App-wide utilities, theme, router
│   ├── constants/
│   ├── game_logic/          # Board rules, piece movement, win condition
│   └── theme/
├── features/
│   ├── battle/              # Game screen — board rendering, move handling
│   ├── comcenter/           # Between-game lobby/settings screen
│   └── game/                # Game state management

supabase/                    # Supabase schema and migrations
```

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
