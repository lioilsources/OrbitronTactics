import 'dart:math';

import '../game_logic/engine/game_engine.dart';
import '../game_logic/models/game_state.dart';
import '../game_logic/models/move.dart';
import '../game_logic/models/piece.dart';
import '../game_logic/models/position.dart';
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
    if (profile.searchDepth > 0) {
      return SearchAi(
        profile: profile,
        random: random,
        ownUpgrades: ownUpgrades,
        oppUpgrades: oppUpgrades,
      );
    }
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
        _weights = _weightsFor(profile),
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

/// Looks [AiProfile.searchDepth] plies ahead with negamax and alpha-beta,
/// deepening iteratively until [AiProfile.timeBudgetMs] runs out.
///
/// A capture is a chance node: the odds-weighted average of both battle
/// outcomes, each searched with a full window — no pruning inside. Past
/// the horizon, likely captures are followed one ply further.
class SearchAi implements BoardAi {
  SearchAi({
    required AiProfile profile,
    required Random random,
    required UpgradeProfile ownUpgrades,
    required UpgradeProfile oppUpgrades,
  })  : _maxDepth = max(1, profile.searchDepth),
        _timeBudgetMs = profile.timeBudgetMs,
        _random = random,
        _weights = _weightsFor(profile),
        _ownUpgrades = ownUpgrades,
        _oppUpgrades = oppUpgrades,
        _ownOdds = BattleOdds.table(ownUpgrades, oppUpgrades),
        _oppOdds = BattleOdds.table(oppUpgrades, ownUpgrades);

  /// Past the horizon, only captures at least this likely are followed...
  static const double _quiescenceMinOdds = 0.6;

  /// ...for this many plies. A second ply multiplies the cost of a depth-3
  /// search by about 2.5 while rarely changing the chosen move.
  static const int _quiescencePlies = 1;

  /// A root score above this means a forced win was found.
  static const double _forcedWin = BoardEvaluator.win / 2;

  final int _maxDepth;
  final int _timeBudgetMs;
  final Random _random;
  final EvalWeights _weights;
  final UpgradeProfile _ownUpgrades;
  final UpgradeProfile _oppUpgrades;
  final OddsTable _ownOdds;
  final OddsTable _oppOdds;

  final Stopwatch _clock = Stopwatch();

  /// Per ply, the two quiet moves that most recently caused a cutoff.
  final List<List<Move?>> _killers =
      List.generate(8, (_) => List<Move?>.filled(2, null));

  late PlayerColor _color;
  var _fieldMask = 0;
  var _nodes = 0;
  var _timed = false;

  @override
  Move? chooseMove(GameState state, PlayerColor color) {
    assert(state.currentTurn == color);
    _color = color;
    // Nothing below reads the history; don't copy it for every node.
    final root = state.copyWith(moveHistory: const []);
    _fieldMask = 0;
    for (final field in root.board.powerFields) {
      _fieldMask |= _bit(field.position);
    }
    for (final slots in _killers) {
      slots.fillRange(0, slots.length, null);
    }

    var moves = _ordered(MoveGenerator.generate(root, color), color);
    if (moves.isEmpty) return null;

    _clock
      ..reset()
      ..start();
    Move? best;
    for (var depth = 1; depth <= _maxDepth; depth++) {
      // The first iteration always completes, so there is always a move.
      _timed = depth > 1 && _timeBudgetMs > 0;
      try {
        final scored = _searchRoot(root, moves, depth);
        best = _pickBest(scored, _random);
        // The best move first tightens the next iteration's window.
        moves = [best, for (final move in moves) if (move != best) move];
        if (scored.any((entry) => entry.$2 > _forcedWin)) break;
      } on _SearchTimeout {
        break;
      }
    }
    _clock.stop();
    return best;
  }

  /// Scores every root move. Moves that cannot beat the best so far get an
  /// upper bound below it, so only true ties reach the random tie-break.
  List<(Move, double)> _searchRoot(GameState root, List<Move> moves, int depth) {
    final scored = <(Move, double)>[];
    var alpha = double.negativeInfinity;
    for (final move in moves) {
      final value =
          _moveValue(root, move, _color, depth, alpha, double.infinity, 1);
      scored.add((move, value));
      alpha = max(alpha, value - 2 * _tieTolerance);
    }
    return scored;
  }

  /// Value of [move] for [toMove]; the child position sits at [ply].
  double _moveValue(
    GameState state,
    Move move,
    PlayerColor toMove,
    int depth,
    double alpha,
    double beta,
    int ply,
  ) {
    final opponent = toMove.opposite;
    final captured = move.capturedPiece;
    if (captured == null) {
      return -_negamax(GameEngine.applyMove(state, move), opponent, depth - 1,
          -beta, -alpha, ply);
    }

    final p = _oddsFor(toMove).of(move.piece.type, captured.type);
    final (won, lost) = _battleOutcomes(state, move);
    return p *
            -_negamax(won, opponent, depth - 1, double.negativeInfinity,
                double.infinity, ply) +
        (1 - p) *
            -_negamax(lost, opponent, depth - 1, double.negativeInfinity,
                double.infinity, ply);
  }

  /// Value of [state] for [toMove], the side about to move.
  double _negamax(
    GameState state,
    PlayerColor toMove,
    int depth,
    double alpha,
    double beta,
    int ply,
  ) {
    _tick();
    if (state.isFinished) return _terminal(state, toMove, ply);
    if (depth <= 0) {
      return _quiesce(state, toMove, alpha, beta, ply, _quiescencePlies);
    }

    final moves =
        _ordered(MoveGenerator.generate(state, toMove), toMove, ply: ply);
    if (moves.isEmpty) return _evaluate(state, toMove, moves);

    var best = double.negativeInfinity;
    for (final move in moves) {
      final value =
          _moveValue(state, move, toMove, depth, alpha, beta, ply + 1);
      if (value > best) best = value;
      if (best > alpha) alpha = best;
      if (alpha >= beta) {
        _rememberKiller(move, ply);
        break;
      }
    }
    return best;
  }

  /// Static value, extended by captures [toMove] is likely to win so the
  /// horizon doesn't cut a battle exchange in half.
  double _quiesce(
    GameState state,
    PlayerColor toMove,
    double alpha,
    double beta,
    int ply,
    int pliesLeft,
  ) {
    _tick();
    if (state.isFinished) return _terminal(state, toMove, ply);
    final moves = MoveGenerator.generate(state, toMove);
    final standPat = _evaluate(state, toMove, moves);
    if (pliesLeft == 0 || standPat >= beta) return standPat;
    if (standPat > alpha) alpha = standPat;

    final odds = _oddsFor(toMove);
    final opponent = toMove.opposite;
    var best = standPat;
    for (final move in moves) {
      final captured = move.capturedPiece;
      if (captured == null) break; // Captures come first.
      final p = odds.of(move.piece.type, captured.type);
      if (p < _quiescenceMinOdds) continue;

      final (won, lost) = _battleOutcomes(state, move);
      final value = p *
              -_quiesce(won, opponent, double.negativeInfinity,
                  double.infinity, ply + 1, pliesLeft - 1) +
          (1 - p) *
              -_quiesce(lost, opponent, double.negativeInfinity,
                  double.infinity, ply + 1, pliesLeft - 1);
      if (value > best) best = value;
      if (best > alpha) alpha = best;
      if (alpha >= beta) break;
    }
    return best;
  }

  /// Captures by expected gain, then this ply's killer moves, then moves
  /// onto power fields, then the rest.
  List<Move> _ordered(List<Move> moves, PlayerColor toMove, {int? ply}) {
    final odds = _oddsFor(toMove);
    final targetUpgrades = toMove == _color ? _oppUpgrades : _ownUpgrades;
    final killers =
        ply != null && ply < _killers.length ? _killers[ply] : const <Move?>[];
    double priority(Move move) {
      final captured = move.capturedPiece;
      if (captured != null) {
        return 4 +
            odds.of(move.piece.type, captured.type) *
                BoardEvaluator.pieceValue(captured, targetUpgrades);
      }
      final killer = killers.indexOf(move);
      if (killer >= 0) return 3 - killer * 0.5;
      return _fieldMask & _bit(move.to) != 0 ? 1 : 0;
    }

    final prioritized = [for (final move in moves) (move, priority(move))]
      ..sort((a, b) => b.$2.compareTo(a.$2));
    return [for (final (move, _) in prioritized) move];
  }

  void _rememberKiller(Move move, int ply) {
    if (move.capturedPiece != null || ply >= _killers.length) return;
    final slots = _killers[ply];
    if (slots[0] == move) return;
    slots[1] = slots[0];
    slots[0] = move;
  }

  /// [moves] may pass in [toMove]'s generated moves to spare regenerating.
  double _evaluate(GameState state, PlayerColor toMove, [List<Move>? moves]) {
    final own = toMove == _color;
    return BoardEvaluator.evaluate(
      state,
      toMove,
      w: _weights,
      povUpgrades: own ? _ownUpgrades : _oppUpgrades,
      oppUpgrades: own ? _oppUpgrades : _ownUpgrades,
      povMoves: moves,
    );
  }

  OddsTable _oddsFor(PlayerColor attacker) =>
      attacker == _color ? _ownOdds : _oppOdds;

  /// A finished game; sooner wins and later losses score higher.
  static double _terminal(GameState state, PlayerColor toMove, int ply) {
    final score = BoardEvaluator.win - ply;
    return state.winner == toMove ? score : -score;
  }

  void _tick() {
    if (_timed &&
        (++_nodes & 0xff) == 0 &&
        _clock.elapsedMilliseconds >= _timeBudgetMs) {
      throw const _SearchTimeout();
    }
  }
}

class _SearchTimeout implements Exception {
  const _SearchTimeout();
}

/// Scores closer than this count as equal.
const double _tieTolerance = 1e-9;

EvalWeights _weightsFor(AiProfile profile) => profile.useThreatTerm
    ? EvalWeights.standard
    : EvalWeights.standard.copyWith(threat: 0);

int _bit(Position position) => 1 << (position.row * 8 + position.col);

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
      if (score >= best - _tieTolerance) move,
  ];
  return top[random.nextInt(top.length)];
}
