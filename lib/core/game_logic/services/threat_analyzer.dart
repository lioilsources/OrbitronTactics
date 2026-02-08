import '../models/board_state.dart';
import '../models/piece.dart';
import '../models/position.dart';
import '../validators/bishop_validator.dart';
import '../validators/king_validator.dart';
import '../validators/knight_validator.dart';
import '../validators/last_warrior_validator.dart';
import '../validators/pawn_validator.dart';
import '../validators/piece_validator.dart';
import '../validators/queen_validator.dart';
import '../validators/rook_validator.dart';

/// Analyzes which pieces of a given player are under threat from the opponent.
class ThreatAnalyzer {
  const ThreatAnalyzer._();

  static const _validators = <PieceType, PieceValidator>{
    PieceType.pawn: PawnValidator(),
    PieceType.rook: RookValidator(),
    PieceType.knight: KnightValidator(),
    PieceType.bishop: BishopValidator(),
    PieceType.queen: QueenValidator(),
    PieceType.king: KingValidator(),
  };

  static const _lastWarriorValidator = LastWarriorValidator();

  static PieceValidator _validatorFor(Piece piece) {
    if (piece.isLastWarrior) return _lastWarriorValidator;
    return _validators[piece.type]!;
  }

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
      final validator = _validatorFor(piece);
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
