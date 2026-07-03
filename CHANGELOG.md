# Changelog

## [03/07/2026]
- Local Co-op (nearby) mode: P2P discovery + transport via Nearby Connections
  (Android) / MultipeerConnectivity (iOS) — no shared wifi router needed.
  Note: pairs same-platform devices only (Android↔Android, iOS↔iOS).
- Archon-style real-time battle arena on capture (host-authoritative, Flame)
- Unit leveling: battle credits, ComCenter upgrade screen, per-ship stats
  (HP/damage/fire rate/defense) and an activatable shield in the arena
- Connectivity gating: on cellular data the game is turn-based cloud play
  only; local co-op requires wifi
- Android: runtime Nearby/Bluetooth permissions, AGP 8 namespace backfill for
  the legacy nearby plugin

## [12/02/2026]
- Disconnect handling for multiplayer via Supabase Presence
- Fix turn bar visibility and multiplayer networking bugs

## [09/02/2026]
- Release APK added to project root for easy distribution
- Alpha 0.1.0-alpha.1: Android release build

## [08/02/2026]
- Phase 2b: Threat indicators — red badge on endangered pieces
- Phase 2: UI polish — animations, power field glow, game over overlay
- Supabase config secured, cloud deployment plan documented

## [07/02/2026]
- Phase 3: Supabase multiplayer transport + lobby UI
- Phase 3: Abstract transport layer + mock networking
- Phase 1: Core game logic, board UI, and local hot-seat mode
