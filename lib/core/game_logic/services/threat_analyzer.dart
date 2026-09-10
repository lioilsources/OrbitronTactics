import '../models/board_state.dart';
import '../models/piece.dart';
import '../models/position.dart';
import '../validators/validator_registry.dart';

/// Analyzes which pieces of a given player are under threat from the opponent.
class ThreatAnalyzer {
  const ThreatAnalyzer._();

  /// Returns positions of [player]'s pieces that can be captured
  /// by any opponent piece on the next move.
  static Set<Position> getThreatenedPositions(
    BoardState board,
    PlayerColor player,
  ) {
    final opponent = player.opposite;
    final opponentPieces = board.findPieces(color: opponent);
    final myPiecePositions = board.findPieces(color: player).toSet();
    final threatened = <Position>{};

    for (final pos in opponentPieces) {
      final piece = board.pieceAt(pos)!;
      final validator = validatorFor(piece);
      final moves = validator.getLegalMoves(board, pos, opponent);
      for (final move in moves) {
        if (myPiecePositions.contains(move)) {
          threatened.add(move);
        }
      }
    }

    return threatened;
  }
}
