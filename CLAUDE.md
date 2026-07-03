# OrbitronTactics — CLAUDE.md

## Overview

Flutter 2-player chess variant with custom piece movement, power field domination victory conditions, and Supabase Realtime multiplayer. Supports local hot-seat, cloud lobby, and a local co-op (nearby) mode with a real-time battle arena on capture.

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
│   ├── battle/              # Real-time battle arena (sim, netcode, Flame view)
│   ├── comcenter/           # Between-game upgrade shop (credits, unit levels)
│   └── game/                # Game state, board screens, lobby, transports

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

## Multiplayer Modes

- **Cloud (Supabase)** — turn-based; works on any connection incl. cellular
- **Local Co-op (nearby)** — P2P via Nearby Connections (Android) /
  MultipeerConnectivity (iOS); no shared wifi needed, but pairs
  same-platform devices only. Captures resolve in a host-authoritative
  real-time arena; winners earn credits for ComCenter unit upgrades.
  Requires wifi (gated via `connectivity_plus`) — on cellular data only the
  turn-based cloud mode is available.

## Platforms

iOS, Android, Windows.
