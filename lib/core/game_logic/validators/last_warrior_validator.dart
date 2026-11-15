import '../models/board_state.dart';
import '../models/piece.dart';
import '../models/position.dart';
import 'path_checker.dart';
import 'piece_validator.dart';

/// Last Warrior movement rules:
/// - One step to an adjacent square: all 8 directions on a square board
///   (like a standard chess king), the 6 edges on hex
/// - Applied when the piece's isLastWarrior flag is true
///   (which happens when the other royal piece was captured)
class LastWarriorValidator extends PieceValidator {
  const LastWarriorValidator();

  @override
  List<Position> getLegalMoves(
    BoardState board,
    Position position,
    PlayerColor color,
  ) =>
      PathChecker.slide(board, position, board.geometry.adjacent, 1, color);
}
