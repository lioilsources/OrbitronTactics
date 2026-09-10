import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:orbitron_tactics/core/ai/board_ai.dart';
import 'package:orbitron_tactics/core/game_logic/models/game_phase.dart';
import 'package:orbitron_tactics/core/game_logic/models/piece.dart';
import 'package:orbitron_tactics/core/game_logic/validators/move_validator.dart';

import '../game_logic/test_helpers.dart';

void main() {
  group('RandomAi', () {
    test('plays only legal moves', () {
      final state = defaultGameState();
      final ai = RandomAi(Random(7));

      for (var i = 0; i < 50; i++) {
        final move = ai.chooseMove(state, PlayerColor.white)!;
        expect(MoveValidator.createMove(state, move.from, move.to), move);
      }
    });

    test('returns null once the game is over', () {
      final state = defaultGameState().copyWith(
        phase: GamePhase.finished,
        winner: PlayerColor.black,
      );

      expect(RandomAi(Random(7)).chooseMove(state, PlayerColor.white), isNull);
    });
  });
}
