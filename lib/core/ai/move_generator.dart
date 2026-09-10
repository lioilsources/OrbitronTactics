import '../game_logic/models/game_state.dart';
import '../game_logic/models/move.dart';
import '../game_logic/models/piece.dart';
import '../game_logic/validators/move_validator.dart';
import '../game_logic/validators/validator_registry.dart';

/// Enumerates legal moves for the AI.
class MoveGenerator {
  const MoveGenerator._();

  /// All legal moves of [color], whatever `state.currentTurn` is — the
  /// search and the evaluation look at both sides. Captures come first.
  /// Empty once the game is finished.
  static List<Move> generate(GameState state, PlayerColor color) {
    if (state.isFinished) return const <Move>[];

    final board = state.board;
    final captures = <Move>[];
    final quiet = <Move>[];
    for (final from in board.findPieces(color: color)) {
      final piece = board.pieceAt(from)!;
      for (final to in validatorFor(piece).getLegalMoves(board, from, color)) {
        final move = MoveValidator.buildMove(board, from, to);
        (move.capturedPiece == null ? quiet : captures).add(move);
      }
    }
    return [...captures, ...quiet];
  }
}
