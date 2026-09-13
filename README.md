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
- Ten fleets of ship art for the battle arena
- Battle arena with altitude, banking ships and elemental explosions
- Battle music per attacking unit type and sound effects per element
- Maneuvers drawn as gestures: 11–13 per ship, armed four at a time
- Threat indicators (red badge on endangered pieces)
- Disconnect handling via Supabase Presence
- 295 unit and widget tests

## Single Player

Pick a difficulty and your color in the lobby. The AI plays the board and flies its own ship in every battle.

| Difficulty | Board | Arena |
|------------|-------|-------|
| Easy | One move ahead, noisy judgement, ignores threats | Slow reactions and ship, sloppy aim, rarely shields |
| Medium | One move ahead, weighs battle odds and threats | Quicker reactions and dodging |
| Hard | Searches up to three plies, captures weighed by battle odds, within an 800 ms budget on a background isolate | Fast reactions, leads its aim, dodges early, shields reliably |

Difficulty is skill only; unit strength comes from **fleet progress**. Battles earn credits for the winner's fleet. You spend yours in the Comcenter, while each difficulty has its own AI fleet that upgrades itself after every game — never more than 0 / 1 / 2 levels (Easy / Medium / Hard) ahead of your fleet. Credits, upgrades and win/loss records are saved on the device.

Every fleet has its own ship art, a white and a black ship for each unit type. Pick one of ten fleets in the Comcenter; Easy, Medium and Hard fly Star Nomads, Iron Armada and Void Hive.

## Battle

A capture is decided in a realtime arena. Drag across your half to dodge, forward to climb and back to dive — your ship travels the whole of its half, from its own edge to just short of the divider. A shot flies at the altitude it was fired from and only hits a ship at about that altitude, so to hit the enemy you have to fly where it can hit you too. Each unit fires its own element and explodes in it: pawns slugs, knights water, bishops fire, rooks ice, queens and kings electricity.

## Maneuvers

Let go of the helm and draw a gesture on the 3×3 pad, as on a lock screen, and the ship takes over: it flies the maneuver and fires from its own plan. A sidestep drops onto the enemy's altitude, a loop goes over the top with shots passing underneath, a barrel roll rides through a lane, a dash crosses the arena, a shadow sticks to the enemy wherever it goes — and every ship has a signature of its own, from the knight's Leap to the king's Crown. The mirrored gesture flies the mirrored maneuver.

Maneuvers cost energy: a ship starts a battle half charged and wins 12 back a second, so there is room for one every few seconds. Four are armed at a time, on a pad that shows what they cost and what they look like.

New ones are earned by winning battles with that ship, bought with credits in the Comcenter, or come in a pack. Owned maneuvers can be trained twice: cheaper, quicker, and either an extra shot or a longer window where shots pass through.

The attacker's unit type picks the battle music, and every element has its own shot and an explosion with a long echo. The speaker button in the battle header turns the sound off.

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
