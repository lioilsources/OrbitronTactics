import '../board/board_geometry.dart';
import '../models/board_state.dart';
import '../models/piece.dart';
import '../models/position.dart';

/// Shared utility for checking path obstruction for sliding pieces.
class PathChecker {
  const PathChecker._();

  /// Returns all reachable positions along [direction] from [start],
  /// up to [maxDistance] steps.
  /// Stops at the edge of the board or a blocked square, and at the first
  /// occupied square:
  /// - includes it if enemy (can capture)
  /// - excludes it if friendly
  static List<Position> getReachableSquares(
    BoardState board,
    Position start,
    Direction direction,
    int maxDistance,
    PlayerColor color,
  ) {
    final geometry = board.geometry;
    final results = <Position>[];
    var current = start;

    for (int i = 0; i < maxDistance; i++) {
      current = geometry.step(current, direction);
      if (!geometry.contains(current)) break;

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

  /// Every square reachable sliding up to [maxDistance] steps in each of
  /// [directions], in that order.
  static List<Position> slide(
    BoardState board,
    Position start,
    List<Direction> directions,
    int maxDistance,
    PlayerColor color,
  ) {
    if (maxDistance <= 0) return <Position>[];
    return [
      for (final direction in directions)
        ...getReachableSquares(board, start, direction, maxDistance, color),
    ];
  }
}
