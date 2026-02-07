import '../models/board_state.dart';
import '../models/piece.dart';
import '../models/position.dart';
import 'piece_validator.dart';

/// Knight movement rules:
/// - Normal L-shape forward and sideways
/// - Backward: only "lower L" (1 backward, 2 sideways) — NOT tall L (2 backward, 1 sideways)
/// - Cannot make forward L-moves if a rook is directly in front of the knight
class KnightValidator implements PieceValidator {
  const KnightValidator();

  @override
  List<Position> getLegalMoves(
    BoardState board,
    Position position,
    PlayerColor color,
  ) {
    final moves = <Position>[];
    final dir = color.forwardDir;

    // Check if there's a rook (of either color) directly in front
    final frontPos = position.offset(dir, 0);
    final hasRookInFront = frontPos.isOnBoard &&
        board.pieceAt(frontPos)?.type == PieceType.rook;

    // Forward L-shapes (long leg forward)
    // (2 forward, 1 sideways) — blocked if rook in front
    if (!hasRookInFront) {
      for (final dCol in [-1, 1]) {
        final target = position.offset(dir * 2, dCol);
        if (target.isOnBoard && !board.isFriendly(target, color)) {
          moves.add(target);
        }
      }
    }

    // Forward L-shapes (short leg forward, long leg sideways)
    // (1 forward, 2 sideways) — NOT blocked by rook in front
    for (final dCol in [-2, 2]) {
      final target = position.offset(dir, dCol);
      if (target.isOnBoard && !board.isFriendly(target, color)) {
        moves.add(target);
      }
    }

    // Sideways L-shapes (long leg sideways, short leg forward/backward)
    // These are the same as (1 forward, 2 sideways) and (1 backward, 2 sideways)
    // (1 forward, 2 sideways) is already covered above.

    // Backward L-shapes — ONLY "lower L" (1 backward, 2 sideways)
    for (final dCol in [-2, 2]) {
      final target = position.offset(-dir, dCol);
      if (target.isOnBoard && !board.isFriendly(target, color)) {
        moves.add(target);
      }
    }

    // Backward "tall L" (2 backward, 1 sideways) — NOT ALLOWED

    return moves;
  }
}
