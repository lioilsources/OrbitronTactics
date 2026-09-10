import 'dart:math';

import '../game_logic/models/game_state.dart';
import '../game_logic/models/move.dart';
import '../game_logic/models/piece.dart';
import '../game_logic/validators/move_validator.dart';
import 'ai_difficulty.dart';

/// Picks board moves for an AI-controlled color.
abstract class BoardAi {
  /// The move [color] should play in [state], or null when it has none.
  Move? chooseMove(GameState state, PlayerColor color);

  /// The board AI playing at [profile]'s difficulty.
  static BoardAi forProfile(AiProfile profile, {required Random random}) =>
      RandomAi(random);
}

/// Plays a uniformly random legal move.
class RandomAi implements BoardAi {
  RandomAi(this._random);

  final Random _random;

  @override
  Move? chooseMove(GameState state, PlayerColor color) {
    if (state.currentTurn != color) return null;
    final moves = [
      for (final from in state.board.findPieces(color: color))
        for (final to in MoveValidator.getLegalMoves(state, from))
          MoveValidator.createMove(state, from, to)!,
    ];
    if (moves.isEmpty) return null;
    return moves[_random.nextInt(moves.length)];
  }
}
