import '../models/board_state.dart';
import '../models/piece.dart';
import '../models/position.dart';
import 'path_checker.dart';
import 'piece_validator.dart';

/// Queen movement rules:
/// - Up to 4 squares diagonally, 2 straight (sliding; hex: 2 and 2)
class QueenValidator extends PieceValidator {
  const QueenValidator();

  @override
  List<Position> getLegalMoves(
    BoardState board,
    Position position,
    PlayerColor color,
  ) {
    final geometry = board.geometry;
    final reach = geometry.reach(PieceType.queen);
    return [
      ...PathChecker.slide(
          board, position, geometry.diagonal, reach.diagonal, color),
      ...PathChecker.slide(
          board, position, geometry.straight, reach.straight, color),
    ];
  }
}
