import '../models/board_state.dart';
import '../models/piece.dart';
import '../models/position.dart';
import 'path_checker.dart';
import 'piece_validator.dart';

/// Queen movement rules:
/// - Up to 4 squares diagonally (sliding)
/// - Up to 2 squares in straight lines (sliding)
class QueenValidator implements PieceValidator {
  const QueenValidator();

  @override
  List<Position> getLegalMoves(
    BoardState board,
    Position position,
    PlayerColor color,
  ) {
    final moves = <Position>[];

    // Diagonal: up to 4 squares
    for (final dRow in [-1, 1]) {
      for (final dCol in [-1, 1]) {
        moves.addAll(
          PathChecker.getReachableSquares(
              board, position, dRow, dCol, 4, color),
        );
      }
    }

    // Straight: up to 2 squares
    const straightDirs = [
      (0, 1),
      (0, -1),
      (1, 0),
      (-1, 0),
    ];
    for (final (dRow, dCol) in straightDirs) {
      moves.addAll(
        PathChecker.getReachableSquares(
            board, position, dRow, dCol, 2, color),
      );
    }

    return moves;
  }
}
