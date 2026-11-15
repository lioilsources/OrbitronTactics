import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:orbitron_tactics/core/ai/ai_difficulty.dart';
import 'package:orbitron_tactics/core/ai/board_ai.dart';
import 'package:orbitron_tactics/core/game_logic/board/board_spec.dart';

import 'self_play.dart';

void main() {
  for (final spec in BoardSpec.all) {
    test('Medium plays only legal moves on ${spec.id}', () {
      for (var game = 0; game < 2; game++) {
        final result = playGame(
          BoardAi.forProfile(AiProfile.medium, random: Random(10 + game)),
          BoardAi.forProfile(AiProfile.medium, random: Random(20 + game)),
          Random(game),
          maxPlies: 150,
          spec: spec,
        );
        expect(result.plies, greaterThan(0));
      }
    });
  }
}
