import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:orbitron_tactics/core/ai/ai_difficulty.dart';
import 'package:orbitron_tactics/core/ai/fleet_progression.dart';
import 'package:orbitron_tactics/core/game_logic/models/fleet_progress.dart';
import 'package:orbitron_tactics/core/game_logic/models/piece.dart';
import 'package:orbitron_tactics/core/game_logic/models/upgrade_profile.dart';

void main() {
  /// A fleet with [totalLevels] levels spread over the unit types in order.
  FleetProgress fleetWithLevels(int totalLevels, {int credits = 0}) {
    final levels = <PieceType, int>{};
    var left = totalLevels;
    for (final type in PieceType.values) {
      if (left == 0) break;
      levels[type] = min(3, left);
      left -= levels[type]!;
    }
    return FleetProgress(credits: credits, profile: UpgradeProfile(levels: levels));
  }

  FleetProgress spend(
    FleetProgress ai, {
    required FleetProgress player,
    AiProfile profile = AiProfile.medium,
    Map<PieceType, int> fought = const {},
    Set<PieceType> lostRoyals = const {},
  }) {
    return FleetProgression.spend(
      ai,
      player,
      profile,
      battlesFoughtByType: fought,
      random: Random(1),
      lostRoyals: lostRoyals,
    );
  }

  group('FleetProgression.spend', () {
    test('never passes the rubber band', () {
      for (final profile in [AiProfile.easy, AiProfile.medium, AiProfile.hard]) {
        for (final playerLevels in [0, 2, 5, 17]) {
          final result = spend(
            const FleetProgress(credits: 100000),
            player: fleetWithLevels(playerLevels),
            profile: profile,
          );

          expect(result.totalLevels,
              min(playerLevels + profile.rubberBandOffset, 18),
              reason: '${profile.displayName} vs $playerLevels player levels');
        }
      }
    });

    test('with no offset and a fresh player it spends nothing', () {
      const ai = FleetProgress(credits: 1000);

      expect(spend(ai, player: const FleetProgress(), profile: AiProfile.easy),
          ai);
    });

    test('upgrades the unit that fought the most battles', () {
      final result = spend(
        const FleetProgress(credits: 100),
        player: fleetWithLevels(10),
        fought: {PieceType.rook: 3, PieceType.pawn: 1},
      );

      expect(result.profile.levels, {PieceType.rook: 1});
    });

    test('breaks ties by the cheapest upgrade', () {
      final result = spend(
        const FleetProgress(
          credits: 250,
          profile: UpgradeProfile(levels: {PieceType.pawn: 1}),
        ),
        player: fleetWithLevels(10),
      );

      // Two first levels at 100 each rather than the pawn's second at 250.
      expect(result.profile.levelFor(PieceType.pawn), 1);
      expect(result.totalLevels, 3);
      expect(result.credits, 50);
    });

    test('never raises a unit above level 3', () {
      final result = spend(
        const FleetProgress(credits: 100000),
        player: fleetWithLevels(18),
        profile: AiProfile.hard,
      );

      for (final type in PieceType.values) {
        expect(result.profile.levelFor(type), 3);
      }
      expect(result.credits, 100000 - 6 * (100 + 250 + 500));
    });

    test('keeps the credits it cannot spend', () {
      expect(
        spend(const FleetProgress(credits: 120), player: fleetWithLevels(10))
            .credits,
        20,
      );
      expect(
        spend(const FleetProgress(credits: 80), player: fleetWithLevels(10))
            .credits,
        80,
      );
    });

    test('Hard rebuilds a lost royal first', () {
      FleetProgress afterLosingQueen(AiProfile profile) => spend(
            const FleetProgress(credits: 100),
            player: fleetWithLevels(10),
            profile: profile,
            fought: {PieceType.pawn: 5},
            lostRoyals: {PieceType.queen},
          );

      expect(afterLosingQueen(AiProfile.hard).profile.levels,
          {PieceType.queen: 1});
      expect(afterLosingQueen(AiProfile.medium).profile.levels,
          {PieceType.pawn: 1});
    });
  });
}
