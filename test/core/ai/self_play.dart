import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:orbitron_tactics/core/ai/board_ai.dart';
import 'package:orbitron_tactics/core/ai/self_play.dart';
import 'package:orbitron_tactics/core/game_logic/board/board_spec.dart';
import 'package:orbitron_tactics/core/game_logic/validators/move_validator.dart';
import 'package:orbitron_tactics/core/worlds/world_balance.dart';

export 'package:orbitron_tactics/core/ai/self_play.dart'
    show SelfPlayResult, selfPlayStart;

/// Plays [white] against [black] until the game ends or [maxPlies] moves
/// were played. Every AI move must be legal; battles are decided by a draw
/// against their odds.
SelfPlayResult playGame(
  BoardAi white,
  BoardAi black,
  Random random, {
  int maxPlies = 300,
  BoardSpec spec = BoardSpec.classic8,
  WorldBalance balance = WorldBalance.space,
}) {
  return playSelfPlayGame(
    white,
    black,
    random,
    maxPlies: maxPlies,
    spec: spec,
    balance: balance,
    onMove: (state, move, ply) => expect(
        MoveValidator.createMove(state, move.from, move.to), move,
        reason: 'illegal move at ply $ply'),
  );
}
