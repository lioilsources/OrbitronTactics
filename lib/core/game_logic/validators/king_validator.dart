import '../models/board_state.dart';
import '../models/piece.dart';
import '../models/position.dart';
import 'path_checker.dart';
import 'piece_validator.dart';

/// King movement rules:
/// - Up to 4 squares in straight lines (sliding)
/// - Up to 2 squares diagonally (sliding)
class KingValidator implements PieceValidator {
  const KingValidator();

  @override
  List<Position> getLegalMoves(
    BoardState board,
    Position position,
    PlayerColor color,
  ) {
    final moves = <Position>[];

    // Straight: up to 4 squares
    const straightDirs = [
      (0, 1),
      (0, -1),
      (1, 0),
      (-1, 0),
    ];
    for (final (dRow, dCol) in straightDirs) {
      moves.addAll(
        PathChecker.getReachableSquares(
            board, position, dRow, dCol, 4, color),
      );
    }

    // Diagonal: up to 2 squares
    for (final dRow in [-1, 1]) {
      for (final dCol in [-1, 1]) {
        moves.addAll(
          PathChecker.getReachableSquares(
              board, position, dRow, dCol, 2, color),
        );
      }
    }

    return moves;
  }
}
