import '../models/board_state.dart';
import '../models/piece.dart';
import '../models/position.dart';
import 'piece_validator.dart';

/// Pawn movement rules:
/// - CANNOT move straight forward
/// - Can move sideways (left/right) and backward — but CANNOT capture
/// - Can move AND capture diagonally forward
class PawnValidator implements PieceValidator {
  const PawnValidator();

  @override
  List<Position> getLegalMoves(
    BoardState board,
    Position position,
    PlayerColor color,
  ) {
    final moves = <Position>[];
    final dir = color.forwardDir;

    // Sideways movement (no capture)
    for (final dCol in [-1, 1]) {
      final target = position.offset(0, dCol);
      if (target.isOnBoard && board.isEmpty(target)) {
        moves.add(target);
      }
    }

    // Backward movement (no capture)
    final backward = position.offset(-dir, 0);
    if (backward.isOnBoard && board.isEmpty(backward)) {
      moves.add(backward);
    }

    // Diagonal forward (move AND capture)
    for (final dCol in [-1, 1]) {
      final target = position.offset(dir, dCol);
      if (target.isOnBoard && !board.isFriendly(target, color)) {
        // Can move to empty square OR capture enemy
        moves.add(target);
      }
    }

    return moves;
  }
}
