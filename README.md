# OrbitronTactics

A strategic 2-player chess variant with custom piece movement rules, power field domination victory conditions, and real-time multiplayer via Supabase. Features local hot-seat mode, a single-player mode against an on-device AI, threat indicators, custom formations, and a cloud-based lobby system.

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
- Single Player against an on-device AI, with fleet progress
- Threat indicators (red badge on endangered pieces)
- Disconnect handling via Supabase Presence
- 189 unit and widget tests

## Single Player

Pick a difficulty and your color in the lobby. The AI plays the board and flies its own ship in every battle.

| Difficulty | Board | Arena |
|------------|-------|-------|
| Easy | One move ahead, noisy judgement, ignores threats | Slow reactions and ship, sloppy aim, rarely shields |
| Medium | One move ahead, weighs battle odds and threats | Quicker reactions and dodging |
| Hard | Searches up to three plies, captures weighed by battle odds, within an 800 ms budget on a background isolate | Fast reactions, leads its aim, dodges early, shields reliably |

Difficulty is skill only; unit strength comes from **fleet progress**. Battles earn credits for the winner's fleet. You spend yours in the Comcenter, while each difficulty has its own AI fleet that upgrades itself after every game — never more than 0 / 1 / 2 levels (Easy / Medium / Hard) ahead of your fleet. Credits, upgrades and win/loss records are saved on the device.

## Tech Stack

- Flutter / Dart 3.10.7
- Riverpod 2.6.1 (StateNotifier pattern)
- Supabase Flutter 2.8.0
- Freezed 2.x (immutable models with JSON serialization)
- shared_preferences (fleet progress)
- Pure Dart game logic and AI (no Flutter dependencies)

## Build

```bash
# iOS
flutter run -d ios

# Android
flutter run -d android

# Tests (as CI runs them)
flutter test --exclude-tags slow

# AI self-play, Hard vs Medium (~1 min)
flutter test --tags slow
```

## Documentation

- [CHANGELOG.md](CHANGELOG.md) — development history
- [GALLERY.md](GALLERY.md) — screenshots and videos
