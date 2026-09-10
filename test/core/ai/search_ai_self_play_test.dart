@Tags(['slow'])
library;

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:orbitron_tactics/core/ai/ai_difficulty.dart';
import 'package:orbitron_tactics/core/ai/board_ai.dart';
import 'package:orbitron_tactics/core/game_logic/models/piece.dart';
import 'package:orbitron_tactics/core/game_logic/models/upgrade_profile.dart';

import 'self_play.dart';

void main() {
  test('Hard wins at least 70% of 20 seeded games against Medium', () {
    const noUpgrades = UpgradeProfile();
    // A fixed depth without a clock keeps the result independent of machine
    // speed. Depth 2 is what Hard reliably completes within its time budget
    // on slower phones; a fixed depth 3 would run for over half an hour.
    final hardProfile =
        AiProfile.hard.copyWith(searchDepth: 2, timeBudgetMs: 0);

    var hardWins = 0;
    for (var game = 0; game < 20; game++) {
      final hard = SearchAi(
        profile: hardProfile,
        random: Random(1000 + game),
        ownUpgrades: noUpgrades,
        oppUpgrades: noUpgrades,
      );
      final medium = GreedyAi(
        profile: AiProfile.medium,
        random: Random(2000 + game),
        ownUpgrades: noUpgrades,
        oppUpgrades: noUpgrades,
      );
      final hardColor = game.isEven ? PlayerColor.white : PlayerColor.black;

      final result = hardColor == PlayerColor.white
          ? playGame(hard, medium, Random(game))
          : playGame(medium, hard, Random(game));

      if (result.winner == hardColor) hardWins++;
      printOnFailure('game $game: Hard ${hardColor.name}, '
          'winner ${result.winner?.name ?? 'none'} after ${result.plies} plies');
    }

    expect(hardWins, greaterThanOrEqualTo(14));
  });
}
