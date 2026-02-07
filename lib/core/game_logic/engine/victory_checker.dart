import '../models/board_state.dart';
import '../models/piece.dart';
import '../models/position.dart';
import '../models/victory_condition.dart';

/// Checks all 3 victory conditions after a move.
class VictoryChecker {
  const VictoryChecker._();

  /// Check victory conditions for the player who just moved.
  /// Returns null if no winner yet.
  static VictoryCondition? checkVictory(
    BoardState board,
    PlayerColor playerWhoJustMoved,
  ) {
    // 1. Royal Elimination — did we capture both opponent's royals?
    final opponent = playerWhoJustMoved.opposite;
    final opponentKings =
        board.findPieces(type: PieceType.king, color: opponent);
    final opponentQueens =
        board.findPieces(type: PieceType.queen, color: opponent);
    if (opponentKings.isEmpty && opponentQueens.isEmpty) {
      return const VictoryCondition.royalElimination();
    }

    // 2. Infiltration — does the player have a pawn on the opponent's back rank?
    final infiltrationRank = playerWhoJustMoved.infiltrationRank;
    for (int col = 0; col < 8; col++) {
      final pos = Position(row: infiltrationRank, col: col);
      final piece = board.pieceAt(pos);
      if (piece != null &&
          piece.color == playerWhoJustMoved &&
          piece.type == PieceType.pawn) {
        return VictoryCondition.infiltration(pawnPosition: pos);
      }
    }

    // 3. Power Field Domination — control all 5 power fields at end of turn
    if (board.powerFields.isNotEmpty &&
        board.powerFieldCount(playerWhoJustMoved) ==
            board.powerFields.length) {
      return const VictoryCondition.powerFieldDomination();
    }

    return null;
  }
}
