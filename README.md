# OrbitronTactics

A strategic 2-player chess variant with custom piece movement rules, power field domination victory conditions, and real-time multiplayer via Supabase. Features local hot-seat mode, threat indicators, custom formations, and a cloud-based lobby system.

## Platforms

| Platform | Status |
|----------|--------|
| iOS | Supported |
| Android | Supported |
| Windows | Supported |

## Features

- 8×8 board with custom piece types and movement rules
- 5 power fields — control majority to win
- Real-time multiplayer via Supabase Realtime (Broadcast + Presence)
- Local hot-seat mode
- Threat indicators (red badge on endangered pieces)
- Disconnect handling via Supabase Presence
- 108 unit tests

## Tech Stack

- Flutter / Dart 3.10.7
- Riverpod 2.6.1 (StateNotifier pattern)
- Supabase Flutter 2.8.0
- Freezed 2.x (immutable models with JSON serialization)
- Pure Dart game logic (no Flutter dependencies)

## Build

```bash
# iOS
flutter run -d ios

# Android
flutter run -d android

# Tests
flutter test
```

## Documentation

- [CHANGELOG.md](CHANGELOG.md) — development history
- [GALLERY.md](GALLERY.md) — screenshots and videos
