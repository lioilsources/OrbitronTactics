import '../models/board_state.dart';
import '../models/piece.dart';

/// Handles the Last Warrior transformation:
/// When a King or Queen is captured, the surviving royal piece of that color
/// becomes a Last Warrior (moves only +1 in all directions).
class LastWarriorRule {
  const LastWarriorRule._();

  /// Apply the Last Warrior rule after a royal piece is captured.
  /// Returns the updated board state, or null if no transformation needed.
  static BoardState? apply(
    BoardState board,
    Piece capturedPiece,
  ) {
    if (!capturedPiece.isRoyal) return null;

    final color = capturedPiece.color;
    final capturedType = capturedPiece.type;

    // Find the surviving royal piece of the same color
    final survivingType =
        capturedType == PieceType.king ? PieceType.queen : PieceType.king;

    final survivingPositions = board.findPieces(
      type: survivingType,
      color: color,
    );

    if (survivingPositions.isEmpty) {
      // Both royals are gone — game over (handled by VictoryChecker)
      return null;
    }

    // Transform the surviving royal into a Last Warrior
    final pos = survivingPositions.first;
    final survivingPiece = board.pieceAt(pos)!;
    final lastWarrior = survivingPiece.copyWith(isLastWarrior: true);

    return board.setPiece(pos, lastWarrior);
  }
}
