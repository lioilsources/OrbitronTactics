import '../models/game_state.dart';
import '../models/move.dart';
import '../models/piece.dart';
import '../models/position.dart';
import '../models/game_phase.dart';
import 'bishop_validator.dart';
import 'king_validator.dart';
import 'knight_validator.dart';
import 'last_warrior_validator.dart';
import 'pawn_validator.dart';
import 'piece_validator.dart';
import 'queen_validator.dart';
import 'rook_validator.dart';

/// Central move validation dispatcher.
/// Validates a move against the full game state, then dispatches to
/// piece-specific validators for movement rules.
class MoveValidator {
  const MoveValidator._();

  static const _validators = <PieceType, PieceValidator>{
    PieceType.pawn: PawnValidator(),
    PieceType.rook: RookValidator(),
    PieceType.knight: KnightValidator(),
    PieceType.bishop: BishopValidator(),
    PieceType.queen: QueenValidator(),
    PieceType.king: KingValidator(),
  };

  static const _lastWarriorValidator = LastWarriorValidator();

  /// Get the appropriate validator for a piece.
  static PieceValidator _validatorFor(Piece piece) {
    if (piece.isLastWarrior) return _lastWarriorValidator;
    return _validators[piece.type]!;
  }

  /// Returns all legal moves for the piece at [position] in the current game state.
  static List<Position> getLegalMoves(GameState state, Position position) {
    if (state.phase != GamePhase.playing) return [];

    final piece = state.board.pieceAt(position);
    if (piece == null) return [];
    if (piece.color != state.currentTurn) return [];

    final validator = _validatorFor(piece);
    return validator.getLegalMoves(state.board, position, piece.color);
  }

  /// Validates whether a specific move is legal.
  /// Returns null if legal, or an error message if illegal.
  static String? validateMove(GameState state, Position from, Position to) {
    if (state.phase != GamePhase.playing) {
      return 'Game is not in playing phase';
    }

    final piece = state.board.pieceAt(from);
    if (piece == null) return 'No piece at source position';
    if (piece.color != state.currentTurn) return 'Not your turn';

    if (!to.isOnBoard) return 'Target position is off the board';

    if (state.board.isFriendly(to, piece.color)) {
      return 'Cannot capture your own piece';
    }

    final legalMoves = getLegalMoves(state, from);
    if (!legalMoves.contains(to)) {
      return 'Illegal move for this piece';
    }

    return null; // Move is valid
  }

  /// Creates a Move object from source and destination positions.
  /// Returns null if the move is illegal.
  static Move? createMove(GameState state, Position from, Position to) {
    final error = validateMove(state, from, to);
    if (error != null) return null;

    final piece = state.board.pieceAt(from)!;
    final capturedPiece = state.board.pieceAt(to);

    // Determine if this is a bishop snipe
    final isSnipe = piece.type == PieceType.bishop &&
        !piece.isLastWarrior &&
        from.col == to.col &&
        (to.row - from.row).abs() == 3;

    return Move(
      from: from,
      to: to,
      piece: piece,
      capturedPiece: capturedPiece,
      isSnipe: isSnipe,
    );
  }
}
