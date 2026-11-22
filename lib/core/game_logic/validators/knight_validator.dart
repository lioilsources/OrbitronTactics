import '../models/board_state.dart';
import '../models/piece.dart';
import '../models/position.dart';
import 'piece_validator.dart';

/// Knight movement rules (the jumps come from the board's geometry):
/// - Normal L-shape forward and sideways
/// - Backward: only "lower L" (1 backward, 2 sideways) — NOT tall L (2 backward, 1 sideways)
/// - Cannot make forward L-moves if a rook is directly in front of the knight
class KnightValidator extends PieceValidator {
  const KnightValidator();

  @override
  List<Position> getLegalMoves(
    BoardState board,
    Position position,
    PlayerColor color,
  ) {
    final geometry = board.geometry;
    final moves = <Position>[];

    for (final jump in geometry.knightJumps(color)) {
      final blocker = jump.blockedByRookAt;
      if (blocker != null) {
        // A rook (of either color) on that square forbids the jump
        final square = geometry.step(position, blocker);
        if (geometry.contains(square) &&
            board.pieceAt(square)?.type == PieceType.rook) {
          continue;
        }
      }
      final target = geometry.step(position, jump.delta);
      if (geometry.contains(target) && !board.isFriendly(target, color)) {
        moves.add(target);
      }
    }

    return moves;
  }
}
