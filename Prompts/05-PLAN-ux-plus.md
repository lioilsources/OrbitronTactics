# Phase 2b: Threat Indicators for Endangered Pieces

## Context

After Phase 2 UI polish (animations, glow, overlays), the board still lacks a key piece of information: **which of my pieces are under threat?** After the opponent's move, the player sees the yellow last-move highlight but has no quick way to know which of their pieces can now be captured. This forces mental calculation every turn.

**Goal:** Show a small warning icon (⚠) on each of my pieces that an opponent piece can capture next turn. Visible only on the current player's turn, only on that player's own threatened pieces.

---

## Current State

- **Valid move indicators** exist: green dots (empty) + red brackets (captures) — shown when a piece is selected
- **Last move highlight**: yellow tint on from/to squares (27% opacity) — only visual after opponent's move
- **No threat detection** exists anywhere in the codebase
- **`MoveValidator.getLegalMoves(state, pos)`** checks `currentTurn` — can't call it for opponent pieces directly
- **`PieceValidator.getLegalMoves(board, pos, color)`** does NOT check turn — can be called for any color directly
- **`PieceRenderer.build(piece, size)`** returns a Widget (Container with circle + text) — no `isThreatened` parameter

---

## Implementation Steps

### Step 1: Create ThreatAnalyzer (pure Dart, game logic layer)
**New file:** `lib/core/game_logic/services/threat_analyzer.dart`

Compute which positions of the current player are under threat from opponent pieces.

```dart
class ThreatAnalyzer {
  /// Returns positions of [currentPlayer]'s pieces that can be captured
  /// by any [opponent] piece.
  static Set<Position> getThreatenedPositions(BoardState board, PlayerColor currentPlayer) {
    final opponent = currentPlayer.opposite;
    final opponentPieces = board.findPieces(color: opponent);
    final attackedSquares = <Position>{};

    for (final pos in opponentPieces) {
      final piece = board.pieceAt(pos)!;
      final validator = _validatorFor(piece);
      final moves = validator.getLegalMoves(board, pos, opponent);
      attackedSquares.addAll(moves);
    }

    // Filter to only positions where currentPlayer actually has a piece
    final myPieces = board.findPieces(color: currentPlayer).toSet();
    return attackedSquares.intersection(myPieces);
  }
}
```

Key insight: Use `PieceValidator.getLegalMoves(board, pos, color)` directly (bypasses the `currentTurn` check in `MoveValidator`). Need to duplicate the validator map or expose it — simplest is to replicate the `_validatorFor` logic (same static const map + last warrior check).

### Step 2: Compute threats in GameBoard on each build
**File:** `lib/features/game/presentation/widgets/board/game_board.dart`

In `build()`, after reading `gameState`, compute threatened positions:

```dart
final threatenedPositions = gameState.phase == GamePhase.playing
    ? ThreatAnalyzer.getThreatenedPositions(gameState.board, gameState.currentTurn)
    : <Position>{};
```

This runs every build. For an 8x8 board with ~16 opponent pieces, it's ~16 `getLegalMoves` calls per rebuild — negligible for a turn-based game.

### Step 3: Add threat icon to PieceRenderer
**File:** `lib/features/game/presentation/widgets/board/piece_renderer.dart`

Add optional `isThreatened` parameter to `PieceRenderer.build()`:

```dart
static Widget build(Piece piece, double size, {bool isThreatened = false}) {
  // ... existing Container ...
  return Stack(
    clipBehavior: Clip.none,
    children: [
      existingContainer,  // current circular piece widget
      if (isThreatened)
        Positioned(
          right: -2,
          top: -2,
          child: Container(
            width: size * 0.3,
            height: size * 0.3,
            decoration: BoxDecoration(
              color: BoardTheme.threatBadgeColor,  // red
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1),
            ),
            child: Center(
              child: Text('!', style: TextStyle(
                color: Colors.white,
                fontSize: size * 0.18,
                fontWeight: FontWeight.bold,
                height: 1.0,
              )),
            ),
          ),
        ),
    ],
  );
}
```

The icon is a small red circle with "!" in the top-right corner of the piece — clear, not obscuring the piece symbol, works at any scale.

### Step 4: Pass threat state from GameBoard to PieceRenderer
**File:** `lib/features/game/presentation/widgets/board/game_board.dart`

In the Layer 3 piece rendering loop, check if the position is threatened:

```dart
PieceRenderer.build(
  gameState.board.grid[row][col]!,
  squareSize,
  isThreatened: threatenedPositions.contains(Position(row: row, col: col)),
),
```

Same for animated piece (Layer 4) — no threat icon during animation (piece is moving, threat state is stale).

### Step 5: Add threat color to BoardTheme
**File:** `lib/core/theme/board_theme.dart`

```dart
// Threat indicator
static const threatBadgeColor = Color(0xFFD32F2F);  // dark red
```

### Step 6: Unit tests for ThreatAnalyzer
**New file:** `test/core/game_logic/services/threat_analyzer_test.dart`

Test cases:
- Pawn threatening diagonally forward
- Rook threatening along file/rank
- No threats when opponent has no captures available
- Multiple pieces threatening same piece
- Last Warrior threat range

---

## Files Modified

| File | Change | Scope |
|------|--------|-------|
| `lib/core/game_logic/services/threat_analyzer.dart` | **New** | Step 1 |
| `lib/features/game/presentation/widgets/board/game_board.dart` | **Minor** | Step 2, 4 |
| `lib/features/game/presentation/widgets/board/piece_renderer.dart` | **Moderate** | Step 3 |
| `lib/core/theme/board_theme.dart` | **Minor** | Step 5 |
| `test/core/game_logic/services/threat_analyzer_test.dart` | **New** | Step 6 |

**No changes to:** game logic models, validators, engine, providers, painters, game_screen.

---

## Verification

1. `flutter test` — all 90 existing tests + new ThreatAnalyzer tests pass
2. `flutter run` — verify:
   - Start game as White; no threats visible (first turn, nothing in danger yet)
   - Make a move, switch to Black's turn; Black sees ⚠ on any piece White can capture
   - Move Black, switch to White; White sees ⚠ on endangered pieces
   - Threat icons disappear on pieces that are no longer in danger
   - Threat icons on the same piece as Last Warrior glow don't conflict visually
   - Game over state — no threat icons shown
