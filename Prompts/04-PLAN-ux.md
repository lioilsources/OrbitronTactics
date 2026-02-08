# Phase 2: UI Polish Implementation Plan

## Context

OrbitronTactics Phase 1 (core game logic + local hot-seat) and Phase 3 (Supabase multiplayer transport) are complete. The UI is functional but static — pieces teleport to destinations, power fields are flat cyan rectangles, and the game over state is a simple banner. This plan adds animations and visual polish to make the game feel alive.

## Current State

- **GameBoard**: `ConsumerWidget` with 3-layer Stack (background painter, overlay painter, positioned pieces)
- **Pieces**: Unicode symbols (♔♕♖♗♘♙) in circular containers, positioned via static `Positioned` widgets
- **Power fields**: Static cyan rectangles with diamond symbol
- **Turn indicator**: Static green "TURN" badge
- **Game over**: Simple indigo banner at bottom of screen
- **No animation code exists anywhere in the UI**

## The Core Problem

When a move happens, `GameEngine.tryMove()` returns a new `GameState` with the piece already at its destination. Riverpod rebuilds instantly — pieces teleport. Animation must be a **UI-layer overlay**: capture animation params before the move, execute the move (state jumps), then show an animated piece sliding from old to new position while hiding the "real" piece at the destination.

---

## Implementation Steps

### Step 1: Convert GameBoard to ConsumerStatefulWidget
**File:** `lib/features/game/presentation/widgets/board/game_board.dart`

- Change `ConsumerWidget` → `ConsumerStatefulWidget` with `TickerProviderStateMixin`
- Move `build()` and `_handleTap()` into `_GameBoardState`
- Add 3 `AnimationController`s in `initState()`:
  - `_moveController` (200ms, easeInOut) — piece slide
  - `_captureController` (300ms, easeOut) — ghost fade+shrink
  - `_powerFieldGlowController` (1500ms, repeat+reverse) — pulsing glow
- Add private `_MoveAnimationData` and `_CaptureAnimationData` classes for ephemeral animation state

### Step 2: Piece Move Animation
**File:** `game_board.dart`

- In `_handleTap()`, before calling `tryMove()`:
  - Capture `fromPos`, `toPos`, `movingPiece`, `capturedPiece`
  - Set `_currentMoveAnim` state
  - Call `tryMove()` (state jumps to final)
  - Start `_moveController.forward(from: 0.0)`
- In `build()` piece rendering loop:
  - Skip rendering piece at `_currentMoveAnim.to` during animation
  - Add animated `Positioned` using `lerpDouble` between from/to positions
- On animation complete: null out `_currentMoveAnim`, normal rendering takes over
- Block input: `if (_moveController.isAnimating) return;` at top of `_handleTap()`

### Step 3: Capture Ghost Animation
**File:** `game_board.dart`

- When `capturedPiece != null` in Step 2, also set `_currentCaptureAnim` and start `_captureController`
- Render ghost piece at capture position: `Opacity` (1→0) + `Transform.scale` (1→0.5) over 300ms
- Ghost runs 100ms longer than move slide, creating a satisfying overlap

### Step 4: Power Field Animated Glow
**Files:** `game_board.dart`, `board_background_painter.dart`, `board_theme.dart`

- `_powerFieldGlowController` drives opacity oscillation 0.3↔0.6
- Pass `glowOpacity` + `BoardState` (for owner detection) + `repaint` listenable to `BoardBackgroundPainter`
- Color by owner: cyan=neutral, blue=white's piece on field, red=black's piece on field
- New `BoardTheme` constants: `powerFieldWhiteOwned`, `powerFieldBlackOwned`

### Step 5: Turn Indicator Pulse
**File:** `lib/features/game/presentation/screens/game_screen.dart`

- Convert `_PlayerInfoBar` from `StatelessWidget` → `StatefulWidget` with `SingleTickerProviderStateMixin`
- "TURN" badge wrapped in `ScaleTransition` (0.95↔1.05, 800ms, repeat+reverse)
- Start animation on `didUpdateWidget` when `isCurrentTurn` becomes true, stop when false

### Step 6: Game Over Overlay
**File:** `game_screen.dart`

- Replace `_GameOverBanner` with full-screen `_GameOverOverlay` (new `StatefulWidget`)
- Self-animates on mount: `SlideTransition` (offset 0,0.3→0,0) + `FadeTransition` (0→1), 400ms
- Semi-transparent black backdrop + centered card with amber border + glow shadow
- Victory icon by condition type + large winner text + New Game / Lobby buttons
- Wrap `GameScreen` body in a `Stack`: game UI as base, overlay on top when finished

### Step 7: Board Perspective Flip (LOW priority)
**Files:** `game_board.dart`, `board_background_painter.dart`, `board_overlay_painter.dart`

- `GameBoard` already has unused `flipBoard` parameter
- Flip row/col indexing instead of `Transform.rotate` (avoids text/tap compensation)
- Helper: `_visualRow(r) => flipBoard ? 7-r : r`
- Apply in piece rendering, tap handling, and painter position calculations
- Pass `flipBoard: true` when multiplayer mode as black player

---

## Files Modified

| File | Scope | Steps |
|------|-------|-------|
| `lib/features/game/presentation/widgets/board/game_board.dart` | **Major** | 1,2,3,4,7 |
| `lib/features/game/presentation/screens/game_screen.dart` | **Moderate** | 5,6 |
| `lib/features/game/presentation/widgets/board/board_background_painter.dart` | **Moderate** | 4,7 |
| `lib/features/game/presentation/widgets/board/board_overlay_painter.dart` | **Minor** | 7 |
| `lib/core/theme/board_theme.dart` | **Minor** | 4 |

**No changes to:** `piece_renderer.dart`, any provider, any file in `lib/core/game_logic/`, any test file.

---

## Verification

1. `flutter test` — all 90 existing tests pass (no game logic changes)
2. `flutter run` — verify:
   - Pieces slide smoothly when moved (200ms)
   - Captured pieces fade+shrink as ghost (300ms)
   - Power fields pulse with glow, color changes with ownership
   - "TURN" badge pulses when it's your turn
   - Game over shows animated overlay with victory details
   - Local hot-seat still works correctly
   - All 3 victory conditions still trigger properly
