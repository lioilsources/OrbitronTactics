import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/game_logic/models/game_phase.dart';
import '../../../../../core/game_logic/models/position.dart';
import '../../providers/board_interaction_provider.dart';
import '../../providers/game_state_provider.dart';
import 'board_background_painter.dart';
import 'board_overlay_painter.dart';
import 'piece_renderer.dart';

/// The main interactive game board widget.
/// Composes background painter, piece layer, overlay painter, and gesture handling.
class GameBoard extends ConsumerWidget {
  final bool flipBoard;

  const GameBoard({super.key, this.flipBoard = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameStateProvider);
    final interaction = ref.watch(boardInteractionProvider);

    // Get last move for highlighting
    Position? lastMoveFrom;
    Position? lastMoveTo;
    if (gameState.moveHistory.isNotEmpty) {
      final lastMove = gameState.moveHistory.last;
      lastMoveFrom = lastMove.from;
      lastMoveTo = lastMove.to;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final boardSize = constraints.maxWidth;
        final squareSize = boardSize / 8;

        return GestureDetector(
          onTapUp: (details) => _handleTap(
            details.localPosition,
            squareSize,
            ref,
          ),
          child: SizedBox(
            width: boardSize,
            height: boardSize,
            child: Stack(
              children: [
                // Layer 1: Board background (squares + power fields)
                CustomPaint(
                  size: Size(boardSize, boardSize),
                  painter: BoardBackgroundPainter(
                    powerFields: gameState.board.powerFields,
                  ),
                ),

                // Layer 2: Overlay (highlights, valid moves)
                CustomPaint(
                  size: Size(boardSize, boardSize),
                  painter: BoardOverlayPainter(
                    selectedPosition: interaction.selectedPosition,
                    validMoves: interaction.validMoves,
                    lastMoveFrom: lastMoveFrom,
                    lastMoveTo: lastMoveTo,
                    board: gameState.board,
                  ),
                ),

                // Layer 3: Pieces
                for (int row = 0; row < 8; row++)
                  for (int col = 0; col < 8; col++)
                    if (gameState.board.grid[row][col] != null)
                      _buildPiece(
                        gameState.board.grid[row][col]!,
                        row,
                        col,
                        squareSize,
                      ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPiece(
    dynamic piece,
    int row,
    int col,
    double squareSize,
  ) {
    return Positioned(
      left: col * squareSize + squareSize * 0.075,
      top: row * squareSize + squareSize * 0.075,
      child: PieceRenderer.build(piece, squareSize),
    );
  }

  void _handleTap(Offset localPosition, double squareSize, WidgetRef ref) {
    final col = (localPosition.dx / squareSize).floor().clamp(0, 7);
    final row = (localPosition.dy / squareSize).floor().clamp(0, 7);
    final tappedPos = Position(row: row, col: col);

    final gameState = ref.read(gameStateProvider);
    final interaction = ref.read(boardInteractionProvider);
    final gameNotifier = ref.read(gameStateProvider.notifier);
    final interactionNotifier = ref.read(boardInteractionProvider.notifier);

    if (gameState.phase != GamePhase.playing) return;

    // If a piece is already selected
    if (interaction.selectedPosition != null) {
      // If tapping the same piece, deselect
      if (interaction.selectedPosition == tappedPos) {
        interactionNotifier.clearSelection();
        return;
      }

      // If tapping a valid move target, make the move
      if (interaction.validMoves.contains(tappedPos)) {
        final success = gameNotifier.tryMove(
          interaction.selectedPosition!,
          tappedPos,
        );
        interactionNotifier.clearSelection();
        if (!success) {
          // Move failed (shouldn't happen if validMoves is correct)
        }
        return;
      }

      // If tapping another friendly piece, select it instead
      final piece = gameState.board.pieceAt(tappedPos);
      if (piece != null && piece.color == gameState.currentTurn) {
        final validMoves = gameNotifier.getLegalMoves(tappedPos);
        interactionNotifier.selectPiece(tappedPos, validMoves);
        return;
      }

      // Tapping empty/enemy square that's not a valid move — deselect
      interactionNotifier.clearSelection();
      return;
    }

    // No piece selected — try to select one
    final piece = gameState.board.pieceAt(tappedPos);
    if (piece != null && piece.color == gameState.currentTurn) {
      final validMoves = gameNotifier.getLegalMoves(tappedPos);
      interactionNotifier.selectPiece(tappedPos, validMoves);
    }
  }
}
