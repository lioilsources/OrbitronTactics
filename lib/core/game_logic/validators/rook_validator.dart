import '../models/board_state.dart';
import '../models/piece.dart';
import '../models/position.dart';
import 'path_checker.dart';
import 'piece_validator.dart';

/// Rook movement rules:
/// - Up to 4 squares in straight lines (horizontal + vertical)
/// - Standard sliding behavior (path must be clear)
class RookValidator implements PieceValidator {
  const RookValidator();

  @override
  List<Position> getLegalMoves(
    BoardState board,
    Position position,
    PlayerColor color,
  ) {
    final moves = <Position>[];

    // 4 straight directions: up, down, left, right
    const directions = [
      (0, 1),   // right
      (0, -1),  // left
      (1, 0),   // down (toward black)
      (-1, 0),  // up (toward white)
    ];

    for (final (dRow, dCol) in directions) {
      moves.addAll(
        PathChecker.getReachableSquares(board, position, dRow, dCol, 4, color),
      );
    }

    return moves;
  }
}
