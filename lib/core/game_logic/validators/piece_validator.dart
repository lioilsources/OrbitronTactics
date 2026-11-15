import '../models/board_state.dart';
import '../models/piece.dart';
import '../models/position.dart';

/// Base class for piece-specific movement validators.
abstract class PieceValidator {
  const PieceValidator();

  /// Returns all legal destination squares for the piece at [position].
  List<Position> getLegalMoves(
    BoardState board,
    Position position,
    PlayerColor color,
  );

  /// Whether the legal move from [from] to [to] is a snipe.
  bool isSnipe(
    BoardState board,
    Position from,
    Position to,
    PlayerColor color,
  ) =>
      false;
}
