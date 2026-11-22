import '../models/board_state.dart';
import '../models/piece.dart';
import '../models/position.dart';
import 'path_checker.dart';
import 'piece_validator.dart';

/// King movement rules:
/// - Up to 4 squares straight, 2 diagonally (sliding; hex: 3 and 1)
class KingValidator extends PieceValidator {
  const KingValidator();

  @override
  List<Position> getLegalMoves(
    BoardState board,
    Position position,
    PlayerColor color,
  ) {
    final geometry = board.geometry;
    final reach = geometry.reach(PieceType.king);
    return [
      ...PathChecker.slide(
          board, position, geometry.straight, reach.straight, color),
      ...PathChecker.slide(
          board, position, geometry.diagonal, reach.diagonal, color),
    ];
  }
}
