import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:orbitron_tactics/core/ai/battle_odds.dart';
import 'package:orbitron_tactics/core/ai/board_ai.dart';
import 'package:orbitron_tactics/core/game_logic/engine/game_engine.dart';
import 'package:orbitron_tactics/core/game_logic/engine/power_field_generator.dart';
import 'package:orbitron_tactics/core/game_logic/models/game_state.dart';
import 'package:orbitron_tactics/core/game_logic/models/piece.dart';
import 'package:orbitron_tactics/core/game_logic/models/player.dart';
import 'package:orbitron_tactics/core/game_logic/models/upgrade_profile.dart';
import 'package:orbitron_tactics/core/game_logic/validators/move_validator.dart';

/// Outcome of one AI-versus-AI game.
class SelfPlayResult {
  /// Null when the game hit the ply limit or a side had no move.
  final PlayerColor? winner;
  final int plies;

  const SelfPlayResult(this.winner, this.plies);
}

/// A fresh game with default formations on a random power-field variant.
GameState selfPlayStart(Random random) {
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
    powerFields: PowerFieldGenerator.generateRandom(random),
  );
  final withWhite = GameEngine.applyFormation(
    created,
    PlayerColor.white,
    GameEngine.defaultFormation(PlayerColor.white),
  );
  return GameEngine.applyFormation(
    withWhite,
    PlayerColor.black,
    GameEngine.defaultFormation(PlayerColor.black),
  );
}

/// Plays [white] against [black] until the game ends or [maxPlies] moves
/// were played. Every AI move must be legal; battles are decided by a draw
/// against their [BattleOdds].
SelfPlayResult playGame(
  BoardAi white,
  BoardAi black,
  Random random, {
  int maxPlies = 300,
}) {
  const noUpgrades = UpgradeProfile();
  var state = selfPlayStart(random);
  var plies = 0;
  while (!state.isFinished && plies < maxPlies) {
    final color = state.currentTurn;
    final move =
        (color == PlayerColor.white ? white : black).chooseMove(state, color);
    if (move == null) break;
    expect(MoveValidator.createMove(state, move.from, move.to), move,
        reason: 'illegal move at ply $plies');

    final captured = move.capturedPiece;
    if (captured == null) {
      state = GameEngine.applyMove(state, move);
    } else {
      final p = BattleOdds.attackerWinProbability(
          move.piece, captured, noUpgrades, noUpgrades);
      final winner = random.nextDouble() < p ? color : color.opposite;
      final battle = GameEngine.applyMove(state, move, triggerBattle: true);
      state = GameEngine.resolveBattle(battle, move, winner).$1;
    }
    plies++;
  }
  return SelfPlayResult(state.isFinished ? state.winner : null, plies);
}
