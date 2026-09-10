import 'dart:math';

import '../game_logic/engine/battle_engine.dart';
import '../game_logic/engine/unit_base_stats.dart';
import '../game_logic/engine/upgrade_engine.dart';
import '../game_logic/models/piece.dart';
import '../game_logic/models/unit_stats.dart';
import '../game_logic/models/upgrade_profile.dart';
import '../game_logic/models/weapon_type.dart';

/// Estimates battle outcomes from unit stats, without simulating the arena.
class BattleOdds {
  const BattleOdds._();

  /// Steepness of the sigmoid over the relative time-to-kill difference.
  static const double steepness = 3;

  /// No estimate leaves these bounds: pilots dodge and shield, so no battle
  /// is ever certain.
  static const double minProbability = 0.1;
  static const double maxProbability = 0.9;

  /// A time-to-kill for units that cannot damage each other.
  static const int _never = 1 << 30;

  /// Probability that [attacker] wins its battle against [defender],
  /// clamped to [minProbability]–[maxProbability].
  static double attackerWinProbability(
    Piece attacker,
    Piece defender,
    UpgradeProfile attackerUpgrades,
    UpgradeProfile defenderUpgrades,
  ) {
    final attackerStats =
        UpgradeEngine.statsFor(attacker.type, attackerUpgrades, unitBaseStats);
    final defenderStats =
        UpgradeEngine.statsFor(defender.type, defenderUpgrades, unitBaseStats);
    final attackerTtk = timeToKillMs(attackerStats, defenderStats);
    final defenderTtk = timeToKillMs(defenderStats, attackerStats);

    final advantage =
        (defenderTtk - attackerTtk) / ((defenderTtk + attackerTtk) / 2);
    final p = 1 / (1 + exp(-steepness * advantage));
    return p.clamp(minProbability, maxProbability).toDouble();
  }

  /// Time for [shooter] to destroy [target] when neither ship moves: the
  /// killing shot leaves after `shots` attack intervals, then crosses the
  /// arena.
  static int timeToKillMs(UnitStats shooter, UnitStats target) {
    // Same rounding as the arena's hit resolution.
    final netDamage =
        shooter.damage - (shooter.damage * target.defenseRating).round();
    if (netDamage <= 0) return _never;
    final shots = (target.maxHp / netDamage).ceil();
    return shots * shooter.attackIntervalMs + travelMs(shooter.weaponType);
  }

  /// Time a [weapon]'s projectile takes to cross the arena.
  static int travelMs(WeaponType weapon) =>
      (1 / BattleEngine.projectileSpeed(weapon)).round();
}
