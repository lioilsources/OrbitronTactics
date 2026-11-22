import '../models/board_state.dart';
import '../models/piece.dart';
import '../models/position.dart';
import 'piece_validator.dart';

/// Pawn movement rules:
/// - CANNOT move straight forward
/// - Can move sideways (left/right) and backward — but CANNOT capture
/// - Can move AND capture diagonally forward
/// (hex: E/W and SE/SW without capture, NE/NW with)
class PawnValidator extends PieceValidator {
  const PawnValidator();

  @override
  List<Position> getLegalMoves(
    BoardState board,
    Position position,
    PlayerColor color,
  ) {
    final geometry = board.geometry;
    final moves = <Position>[];

    // Sideways, then backward movement (no capture)
    for (final d in [
      ...geometry.sideways(color),
      ...geometry.backward(color),
    ]) {
      final target = geometry.step(position, d);
      if (geometry.contains(target) && board.isEmpty(target)) {
        moves.add(target);
      }
    }

    // Diagonal forward (move AND capture)
    for (final d in geometry.forwardCapture(color)) {
      final target = geometry.step(position, d);
      if (geometry.contains(target) && !board.isFriendly(target, color)) {
        // Can move to empty square OR capture enemy
        moves.add(target);
      }
    }

    return moves;
  }
}
