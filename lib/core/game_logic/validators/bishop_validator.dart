import '../models/board_state.dart';
import '../models/piece.dart';
import '../models/position.dart';
import 'path_checker.dart';
import 'piece_validator.dart';

/// Bishop movement rules:
/// - Max 3 squares diagonally (sliding, path must be clear)
/// - "Snipe": can jump to exactly 3 squares straight forward (ignores obstacles)
class BishopValidator implements PieceValidator {
  const BishopValidator();

  @override
  List<Position> getLegalMoves(
    BoardState board,
    Position position,
    PlayerColor color,
  ) {
    final moves = <Position>[];

    // Diagonal movement: up to 3 squares in all 4 diagonal directions
    for (final dRow in [-1, 1]) {
      for (final dCol in [-1, 1]) {
        moves.addAll(
          PathChecker.getReachableSquares(board, position, dRow, dCol, 3, color),
        );
      }
    }

    // Snipe: exactly 3 squares straight forward (jumps over pieces)
    final dir = color.forwardDir;
    final snipeTarget = position.offset(dir * 3, 0);
    if (snipeTarget.isOnBoard && !board.isFriendly(snipeTarget, color)) {
      moves.add(snipeTarget);
    }

    return moves;
  }
}
