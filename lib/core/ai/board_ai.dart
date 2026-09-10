import 'dart:math';

import '../game_logic/engine/game_engine.dart';
import '../game_logic/models/game_state.dart';
import '../game_logic/models/move.dart';
import '../game_logic/models/piece.dart';
import '../game_logic/models/upgrade_profile.dart';
import 'ai_difficulty.dart';
import 'battle_odds.dart';
import 'board_evaluator.dart';
import 'move_generator.dart';

/// Picks board moves for an AI-controlled color.
abstract class BoardAi {
  /// The move [color] should play in [state], or null when it has none.
  /// `state.currentTurn` must be [color].
  Move? chooseMove(GameState state, PlayerColor color);

  /// The board AI playing at [profile]'s difficulty with a fleet of
  /// [ownUpgrades] against one of [oppUpgrades].
  static BoardAi forProfile(
    AiProfile profile, {
    required Random random,
    UpgradeProfile ownUpgrades = const UpgradeProfile(),
    UpgradeProfile oppUpgrades = const UpgradeProfile(),
  }) {
    return GreedyAi(
      profile: profile,
      random: random,
      ownUpgrades: ownUpgrades,
      oppUpgrades: oppUpgrades,
    );
  }
}

/// Plays a uniformly random legal move.
class RandomAi implements BoardAi {
  RandomAi(this._random);

  final Random _random;

  @override
  Move? chooseMove(GameState state, PlayerColor color) {
    final moves = MoveGenerator.generate(state, color);
    if (moves.isEmpty) return null;
    return moves[_random.nextInt(moves.length)];
  }
}

/// Looks one ply ahead: scores the position after every move and plays the
/// best, blurred by the profile's noise. A capture is a bet on its battle,
/// scored as the odds-weighted average of winning and losing it.
class GreedyAi implements BoardAi {
  GreedyAi({
    required AiProfile profile,
    required Random random,
    required UpgradeProfile ownUpgrades,
    required UpgradeProfile oppUpgrades,
  })  : _random = random,
        _noise = profile.evalNoise,
        _weights = profile.useThreatTerm
            ? EvalWeights.standard
            : EvalWeights.standard.copyWith(threat: 0),
        _ownUpgrades = ownUpgrades,
        _oppUpgrades = oppUpgrades;

  final Random _random;
  final double _noise;
  final EvalWeights _weights;
  final UpgradeProfile _ownUpgrades;
  final UpgradeProfile _oppUpgrades;

  @override
  Move? chooseMove(GameState state, PlayerColor color) {
    assert(state.currentTurn == color);
    final moves = MoveGenerator.generate(state, color);
    if (moves.isEmpty) return null;

    // Nothing below reads the history; don't copy it for every move.
    final root = state.copyWith(moveHistory: const []);
    final odds = BattleOdds.table(_ownUpgrades, _oppUpgrades);
    return _pickBest(
      [
        for (final move in moves)
          (move, _expectedScore(root, move, color, odds) + _drawNoise()),
      ],
      _random,
    );
  }

  double _expectedScore(
    GameState state,
    Move move,
    PlayerColor color,
    OddsTable odds,
  ) {
    final captured = move.capturedPiece;
    if (captured == null) {
      return _evaluate(GameEngine.applyMove(state, move), color);
    }
    final p = odds.of(move.piece.type, captured.type);
    final (won, lost) = _battleOutcomes(state, move);
    return p * _evaluate(won, color) + (1 - p) * _evaluate(lost, color);
  }

  double _evaluate(GameState state, PlayerColor color) =>
      BoardEvaluator.evaluate(
        state,
        color,
        w: _weights,
        povUpgrades: _ownUpgrades,
        oppUpgrades: _oppUpgrades,
      );

  double _drawNoise() =>
      _noise == 0 ? 0 : (_random.nextDouble() * 2 - 1) * _noise;
}

/// The positions after [capture]'s battle: (attacker won, attacker lost).
(GameState, GameState) _battleOutcomes(GameState state, Move capture) {
  final battle = GameEngine.applyMove(state, capture, triggerBattle: true);
  final attacker = capture.piece.color;
  return (
    GameEngine.resolveBattle(battle, capture, attacker).$1,
    GameEngine.resolveBattle(battle, capture, attacker.opposite).$1,
  );
}

/// The highest-scored move. Equal scores are broken at random, so the AI
/// does not replay the same game.
Move _pickBest(List<(Move, double)> scored, Random random) {
  final best = scored.map((entry) => entry.$2).reduce(max);
  final top = [
    for (final (move, score) in scored)
      if (score >= best - 1e-9) move,
  ];
  return top[random.nextInt(top.length)];
}
