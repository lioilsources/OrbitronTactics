import '../models/board_state.dart';
import '../models/piece.dart';
import '../models/position.dart';

/// Base interface for piece-specific movement validators.
abstract class PieceValidator {
  /// Returns all legal destination squares for the piece at [position].
  List<Position> getLegalMoves(
    BoardState board,
    Position position,
    PlayerColor color,
  );
}
