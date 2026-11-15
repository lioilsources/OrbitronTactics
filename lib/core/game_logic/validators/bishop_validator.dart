import '../models/board_state.dart';
import '../models/piece.dart';
import '../models/position.dart';
import 'path_checker.dart';
import 'piece_validator.dart';

/// Bishop movement rules:
/// - Slides through corners: up to 3 squares on a square board, 2 on hex
/// - "Snipe": jumps (ignoring obstacles) to the geometry's snipe target —
///   exactly 3 squares straight forward on a square board
class BishopValidator extends PieceValidator {
  const BishopValidator();

  @override
  List<Position> getLegalMoves(
    BoardState board,
    Position position,
    PlayerColor color,
  ) {
    final geometry = board.geometry;
    final moves = PathChecker.slide(board, position, geometry.diagonal,
        geometry.reach(PieceType.bishop).diagonal, color);

    // On hex the snipe target may also be reachable by sliding.
    for (final target in geometry.snipeTargets(position, color)) {
      if (geometry.contains(target) &&
          !board.isFriendly(target, color) &&
          !moves.contains(target)) {
        moves.add(target);
      }
    }

    return moves;
  }

  @override
  bool isSnipe(
    BoardState board,
    Position from,
    Position to,
    PlayerColor color,
  ) =>
      board.geometry.snipeTargets(from, color).contains(to);
}
