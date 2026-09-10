import 'dart:math';

import '../game_logic/engine/upgrade_engine.dart';
import '../game_logic/models/fleet_progress.dart';
import '../game_logic/models/piece.dart';
import 'ai_difficulty.dart';

/// How an AI fleet spends the credits it wins.
class FleetProgression {
  const FleetProgression._();

  /// Spends [ai]'s credits on upgrades without letting its total upgrade
  /// level pass [player]'s plus the profile's rubber-band offset. Credits it
  /// cannot spend are kept.
  ///
  /// Each purchase goes to the affordable unit that fought the most battles,
  /// then the cheapest upgrade, then a random one. Hard first rebuilds a
  /// royal it lost this game ([lostRoyals]).
  static FleetProgress spend(
    FleetProgress ai,
    FleetProgress player,
    AiProfile profile, {
    required Map<PieceType, int> battlesFoughtByType,
    required Random random,
    Set<PieceType> lostRoyals = const {},
  }) {
    final levelCap = player.totalLevels + profile.rubberBandOffset;
    var fleet = ai;
    while (fleet.totalLevels < levelCap) {
      final affordable = [
        for (final type in PieceType.values)
          if (fleet.upgraded(type) != null) type,
      ];
      if (affordable.isEmpty) break;

      var pool = affordable;
      if (profile.difficulty == AiDifficulty.hard) {
        final royals = pool.where(lostRoyals.contains).toList();
        if (royals.isNotEmpty) pool = royals;
      }
      pool = _keepBest(pool, (type) => battlesFoughtByType[type] ?? 0);
      final current = fleet;
      pool = _keepBest(pool,
          (type) => -UpgradeEngine.upgradeCost(current.profile.levelFor(type)));
      fleet = fleet.upgraded(pool[random.nextInt(pool.length)])!;
    }
    return fleet;
  }

  /// The members of [pool] with the highest [score].
  static List<PieceType> _keepBest(
    List<PieceType> pool,
    int Function(PieceType type) score,
  ) {
    final best = pool.map(score).reduce(max);
    return [
      for (final type in pool)
        if (score(type) == best) type,
    ];
  }
}
