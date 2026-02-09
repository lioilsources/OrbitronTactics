# OrbitronTactics — Alpha Release 0.1.0-alpha.1

**Build date:** 2026-02-09
**APK:** `build/app/outputs/flutter-apk/app-release.apk` (49 MB)
**Platform:** Android (debug-signed, sideload only)
**Version:** `0.1.0-alpha.1+1`

---

## What is OrbitronTactics?

OrbitronTactics is a strategic two-player board game inspired by chess but with unique mechanics: power field control points, sniping, pawn infiltration, and the Last Warrior transformation. It is played on an 8x8 board with 16 pieces per player.

---

## Game Rules

### Pieces (16 per player)
8 Pawns, 2 Rooks, 2 Knights, 2 Bishops, 1 Queen, 1 King

### Movement Rules

| Piece | Movement | Special |
|-------|----------|---------|
| **Pawn** | Sideways & backward: move only (no capture). Diagonal forward: move AND capture. Straight forward: impossible. | Reaching opponent's back rank = instant win (Infiltration) |
| **Rook** | Up to 4 squares in straight lines (sliding) | — |
| **Bishop** | Up to 3 squares diagonally (sliding) | **Snipe:** Can jump exactly 3 squares straight forward (ignores obstacles) |
| **Knight** | Standard L-shape forward & sideways | Backward: only "low L" (1 back + 2 sideways). Blocked if a Rook is directly in front |
| **Queen** | Up to 4 squares diagonally + up to 2 squares straight (sliding) | — |
| **King** | Up to 4 squares straight + up to 2 squares diagonally (sliding) | — |

### Special Rules

- **Last Warrior:** When a player's King OR Queen is captured, the surviving royal piece transforms into a Last Warrior — gaining the ability to move 1 square in all 8 directions (like a standard chess king). Other pieces are unaffected.
- **Power Fields:** 5 control points placed randomly on the board (from 8 symmetric variants, ensuring fairness). A power field is "controlled" when any piece occupies it.

### Victory Conditions (3 ways to win)

1. **Power Field Domination** — Control all 5 power fields at the end of your turn
2. **Royal Elimination** — Capture both the opponent's King AND Queen
3. **Pawn Infiltration** — Move any Pawn to the opponent's back rank

---

## Current Game Modes

### Local Hot-Seat (fully working)
Two players share a single device, taking turns. The board does not flip between turns (both players see White's perspective at the bottom).

### Online Multiplayer (infrastructure ready, not fully tested)
Supabase Realtime Broadcast transport is implemented. A lobby screen allows creating/joining games. Requires Supabase cloud project credentials via `--dart-define`.

---

## UI Features in This Release

### Board & Pieces
- 8x8 board rendered with CustomPainter (3-layer architecture)
- Unicode piece symbols (♔ ♕ ♖ ♗ ♘ ♙) in circular containers
- White and Black pieces with distinct styling
- Last Warrior pieces have an orange glow effect

### Interactions
- Tap a piece to select it (green highlight)
- Valid moves shown as green dots (empty squares) or red corner brackets (captures)
- Tap a valid target to execute the move
- Tap the same piece again to deselect
- Tap another friendly piece to switch selection
- Last move highlighted in yellow on both from/to squares

### Animations
- **Piece movement:** 200ms smooth slide from origin to destination
- **Capture:** 300ms fade-out + shrink ghost of the captured piece
- **Power field glow:** Pulsing opacity (1.5s cycle), color changes by owner — cyan (neutral), blue (White controls), red (Black controls)
- **Turn indicator:** "TURN" badge pulses subtly (scale 0.95–1.05)
- **Game over:** Full-screen overlay slides up with fade-in, shows victory icon + condition text + "New Game" / "Back" buttons

### Threat Indicators
- Pieces that can be captured by the opponent on their next move show a red "!" badge in the top-right corner
- Only visible on the current player's turn, only on that player's own pieces
- Helps players quickly identify which pieces are in danger before making their move

### Board Flip (multiplayer)
- `flipBoard` parameter implemented — when playing as Black in multiplayer, the board is rotated so Black's pieces appear at the bottom
- Not active in local hot-seat mode

---

## Technical Details

- **Framework:** Flutter 3.38.7 / Dart 3.10.7
- **State management:** Riverpod (StateNotifier)
- **Models:** Freezed (immutable, JSON-serializable)
- **Game logic:** Pure Dart (no Flutter dependencies), fully testable
- **Tests:** 100 unit tests passing (71 game logic + 19 networking + 10 threat analyzer)
- **Rendering:** CustomPainter (board background + overlay) + Flutter widgets (pieces)

### Project Architecture
```
lib/
├── core/
│   ├── game_logic/       # Pure Dart — validators, engine, models, services
│   ├── theme/            # Board colors and visual constants
│   └── constants/        # Supabase config (dart-define)
└── features/
    └── game/
        ├── data/         # Transport, session, repository, events
        └── presentation/ # Screens, providers, widgets/board
```

---

## Known Limitations

1. **No release signing** — APK is debug-signed; cannot be uploaded to Google Play. For alpha testing, install via `adb install` or direct APK transfer.
2. **Default launcher icon** — Still uses the Flutter default icon, not a custom OrbitronTactics icon.
3. **No formation selection** — Both players start with the same default formation. Custom formation placement (drag & drop) is planned for a future release.
4. **No sound effects or haptic feedback.**
5. **No game replay or move history viewer.**
6. **Multiplayer not battle-tested** — Transport layer is implemented but has not been verified on two separate devices over the internet.
7. **No authentication** — Multiplayer uses player names only (no accounts, no ratings).
8. **Board does not flip in hot-seat mode** — Both players see the board from White's perspective.

---

## How to Install (Android)

### Option A: Direct APK install
1. Transfer `app-release.apk` to your Android device
2. Open the file and allow installation from unknown sources
3. Tap Install

### Option B: ADB
```bash
adb install build/app/outputs/flutter-apk/app-release.apk
```

### Option C: Build from source
```bash
flutter build apk --release
# Or with Supabase for multiplayer:
flutter build apk --release \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

---

## Commit History

| Commit | Description |
|--------|-------------|
| `29c9b15` | Phase 1: Core game logic, board UI, and local hot-seat mode |
| `485ac0b` | Phase 3: Abstract transport layer + mock networking |
| `977693e` | Phase 3: Supabase multiplayer transport + lobby UI |
| `b97d918` | Secure Supabase config + cloud deployment plan |
| `91f48ad` | Phase 2: UI polish — animations, power field glow, game over overlay |
| `e259e35` | Phase 2b: Threat indicators — red badge on endangered pieces |

---

## What's Next

- **Formation screen** — Drag & drop piece placement before the game starts
- **Custom piece assets** — SVG/PNG replacing Unicode symbols
- **Sound effects & haptics**
- **Multiplayer testing** on real devices over the internet
- **Authentication & ratings**
- **Release signing** for Google Play distribution
