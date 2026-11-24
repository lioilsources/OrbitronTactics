@Tags(['slow'])
library;

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:orbitron_tactics/core/ai/ai_difficulty.dart';
import 'package:orbitron_tactics/core/ai/board_ai.dart';
import 'package:orbitron_tactics/core/game_logic/models/piece.dart';
import 'package:orbitron_tactics/core/game_logic/models/upgrade_profile.dart';
import 'package:orbitron_tactics/core/worlds/world_balance.dart';

import 'self_play.dart';

void main() {
  test('Hard wins at least 70% of 20 seeded games against Medium', () {
    final (hard, medium) = _hardAgainstMedium(WorldBalance.space);
    expect(hard, greaterThanOrEqualTo(14));
    expect(hard, greaterThan(medium));
  });

  // The ground balance (melee, mutual destruction) is a closer game for
  // the board AI: over 60 seeds Hard wins 62 % against Medium's 32 %
  // (space: 67 % against 27 %). It must still clearly come out ahead.
  test('in the ground balance Hard wins at least half of 20 seeded games '
      'and more than Medium', () {
    final (hard, medium) = _hardAgainstMedium(WorldBalance.ground);
    expect(hard, greaterThanOrEqualTo(10));
    expect(hard, greaterThan(medium));
  });
}

/// Games won by Hard and by Medium in 20 seeded games played by [balance].
(int, int) _hardAgainstMedium(WorldBalance balance) {
  const noUpgrades = UpgradeProfile();
  // A fixed depth without a clock keeps the result independent of machine
  // speed. Depth 2 is what Hard reliably completes within its time budget
  // on slower phones; a fixed depth 3 would run for over half an hour.
  final hardProfile =
      AiProfile.hard.copyWith(searchDepth: 2, timeBudgetMs: 0);

  var hardWins = 0;
  var mediumWins = 0;
  for (var game = 0; game < 20; game++) {
    final hard = SearchAi(
      profile: hardProfile,
      random: Random(1000 + game),
      ownUpgrades: noUpgrades,
      oppUpgrades: noUpgrades,
      balance: balance,
    );
    final medium = GreedyAi(
      profile: AiProfile.medium,
      random: Random(2000 + game),
      ownUpgrades: noUpgrades,
      oppUpgrades: noUpgrades,
      balance: balance,
    );
    final hardColor = game.isEven ? PlayerColor.white : PlayerColor.black;

    final result = hardColor == PlayerColor.white
        ? playGame(hard, medium, Random(game), balance: balance)
        : playGame(medium, hard, Random(game), balance: balance);

    if (result.winner == hardColor) hardWins++;
    if (result.winner == hardColor.opposite) mediumWins++;
    printOnFailure('game $game: Hard ${hardColor.name}, '
        'winner ${result.winner?.name ?? 'none'} after ${result.plies} plies');
  }

  return (hardWins, mediumWins);
}
