import '../models/board_state.dart';
import '../models/piece.dart';
import '../models/position.dart';

/// Shared utility for checking path obstruction for sliding pieces.
class PathChecker {
  const PathChecker._();

  /// Returns true if all squares between [from] and [to] (exclusive) are empty.
  /// Works for straight lines and diagonals.
  static bool isPathClear(BoardState board, Position from, Position to) {
    final dRow = (to.row - from.row).sign;
    final dCol = (to.col - from.col).sign;

    var current = from.offset(dRow, dCol);
    while (current != to) {
      if (!board.isEmpty(current)) return false;
      current = current.offset(dRow, dCol);
    }
    return true;
  }

  /// Returns all reachable positions along a direction from [start],
  /// up to [maxDistance] squares.
  /// Stops at the first occupied square:
  /// - includes it if enemy (can capture)
  /// - excludes it if friendly
  static List<Position> getReachableSquares(
    BoardState board,
    Position start,
    int dRow,
    int dCol,
    int maxDistance,
    PlayerColor color,
  ) {
    final results = <Position>[];
    var current = start;

    for (int i = 0; i < maxDistance; i++) {
      current = current.offset(dRow, dCol);
      if (!current.isOnBoard) break;

      if (board.isEmpty(current)) {
        results.add(current);
      } else if (board.isEnemy(current, color)) {
        results.add(current); // Can capture
        break; // Blocked after capture
      } else {
        break; // Friendly piece blocks
      }
    }
    return results;
  }
}
