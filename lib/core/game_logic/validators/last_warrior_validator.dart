import '../models/board_state.dart';
import '../models/piece.dart';
import '../models/position.dart';
import 'piece_validator.dart';

/// Last Warrior movement rules:
/// - +1 square in all 8 directions (like a standard chess king)
/// - Applied when the piece's isLastWarrior flag is true
///   (which happens when the other royal piece was captured)
class LastWarriorValidator implements PieceValidator {
  const LastWarriorValidator();

  @override
  List<Position> getLegalMoves(
    BoardState board,
    Position position,
    PlayerColor color,
  ) {
    final moves = <Position>[];

    for (int dRow = -1; dRow <= 1; dRow++) {
      for (int dCol = -1; dCol <= 1; dCol++) {
        if (dRow == 0 && dCol == 0) continue;
        final target = position.offset(dRow, dCol);
        if (target.isOnBoard && !board.isFriendly(target, color)) {
          moves.add(target);
        }
      }
    }

    return moves;
  }
}
