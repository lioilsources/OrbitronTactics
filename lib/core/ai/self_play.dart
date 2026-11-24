import 'dart:math';

import '../game_logic/board/board_spec.dart';
import '../game_logic/engine/game_engine.dart';
import '../game_logic/engine/power_field_generator.dart';
import '../game_logic/models/game_state.dart';
import '../game_logic/models/move.dart';
import '../game_logic/models/piece.dart';
import '../game_logic/models/player.dart';
import '../game_logic/models/upgrade_profile.dart';
import '../game_logic/models/victory_condition.dart';
import '../worlds/world_balance.dart';
import 'battle_odds.dart';
import 'board_ai.dart';

/// Outcome of one AI-versus-AI game.
class SelfPlayResult {
  /// Null when the game hit the ply limit or a side had no move.
  final PlayerColor? winner;
  final int plies;

  /// Captures attempted, i.e. battles fought.
  final int captures;

  /// How the game was won; null when it was not.
  final VictoryCondition? victory;

  const SelfPlayResult(this.winner, this.plies,
      {this.captures = 0, this.victory});
}

/// A fresh game on [spec] with its default formations and power fields
/// drawn from [random].
GameState selfPlayStart(Random random, {BoardSpec spec = BoardSpec.classic8}) {
  final created = GameEngine.createGame(
    gameId: 'self-play',
    playerWhite: const Player(
      userId: 'white',
      displayName: 'White',
      color: PlayerColor.white,
    ),
    playerBlack: const Player(
      userId: 'black',
      displayName: 'Black',
      color: PlayerColor.black,
    ),
    powerFields: PowerFieldGenerator.generateFor(spec, random),
    spec: spec,
  );
  final withWhite = GameEngine.applyFormation(
    created,
    PlayerColor.white,
    GameEngine.defaultFormation(PlayerColor.white, spec: spec),
  );
  return GameEngine.applyFormation(
    withWhite,
    PlayerColor.black,
    GameEngine.defaultFormation(PlayerColor.black, spec: spec),
  );
}

/// Plays [white] against [black] on [spec] until the game ends or
/// [maxPlies] moves were played. Battles are decided by a draw against
/// their [BattleOdds] in [balance] — won, both fallen or lost. [onMove]
/// sees every move before it is played.
SelfPlayResult playSelfPlayGame(
  BoardAi white,
  BoardAi black,
  Random random, {
  int maxPlies = 300,
  BoardSpec spec = BoardSpec.classic8,
  WorldBalance balance = WorldBalance.space,
  void Function(GameState state, Move move, int ply)? onMove,
}) {
  const noUpgrades = UpgradeProfile();
  var state = selfPlayStart(random, spec: spec);
  var plies = 0;
  var captures = 0;
  while (!state.isFinished && plies < maxPlies) {
    final color = state.currentTurn;
    final move =
        (color == PlayerColor.white ? white : black).chooseMove(state, color);
    if (move == null) break;
    onMove?.call(state, move, plies);

    final captured = move.capturedPiece;
    if (captured == null) {
      state = GameEngine.applyMove(state, move);
    } else {
      captures++;
      final odds = BattleOdds.outcomes(
          move.piece, captured, noUpgrades, noUpgrades,
          balance: balance);
      final roll = random.nextDouble();
      final PlayerColor? winner = roll < odds.win
          ? color
          : roll < odds.win + odds.draw
              ? null
              : color.opposite;
      final battle = GameEngine.applyMove(state, move, triggerBattle: true);
      state = GameEngine.resolveBattle(battle, move, winner).$1;
    }
    plies++;
  }
  final finished = state.isFinished;
  return SelfPlayResult(
    finished ? state.winner : null,
    plies,
    captures: captures,
    victory: finished ? state.victoryCondition : null,
  );
}
