import '../models/board_state.dart';
import '../models/piece.dart';
import '../models/position.dart';
import 'path_checker.dart';
import 'piece_validator.dart';

/// Rook movement rules:
/// - Slides through edges: up to 4 squares on a square board, 3 on hex
/// - Standard sliding behavior (path must be clear)
class RookValidator extends PieceValidator {
  const RookValidator();

  @override
  List<Position> getLegalMoves(
    BoardState board,
    Position position,
    PlayerColor color,
  ) {
    final geometry = board.geometry;
    return PathChecker.slide(board, position, geometry.straight,
        geometry.reach(PieceType.rook).straight, color);
  }
}
