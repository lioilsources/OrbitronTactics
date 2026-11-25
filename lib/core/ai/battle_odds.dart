import 'dart:math';

import '../game_logic/engine/battle_engine.dart';
import '../game_logic/engine/upgrade_engine.dart';
import '../game_logic/models/piece.dart';
import '../game_logic/models/unit_stats.dart';
import '../game_logic/models/upgrade_profile.dart';
import '../game_logic/models/weapon_type.dart';
import '../worlds/world_balance.dart';

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

  /// Share of even battles (equal time-to-kill) in which both units fall in
  /// the same tick, when both fight up close and kill in
  /// [drawReferenceTtkMs]: their strikes start on the same cue and land
  /// together. Longer fights drift out of step, so the share falls with
  /// the time-to-kill to the power [drawTtkExponent]. Fitted to
  /// `tools/duel_lab.dart`: ground mirrors of pawns 32 %, knights 18 %,
  /// rooks 11 %, kings 4 %.
  static const double meleeMirrorDraw = 0.32;
  static const int drawReferenceTtkMs = 3200;
  static const double drawTtkExponent = 1.5;

  /// The same when at least one side shoots: shots rarely arrive in one
  /// tick (the lab: 13 % for bishops, 0–3 % for the other mirrors).
  static const double rangedMirrorDraw = 0.04;

  /// How fast the draw share falls off as one side gets the upper hand:
  /// it halves at about this relative time-to-kill difference.
  static const double drawWidth = 0.12;

  /// A [table] leaves draws less likely than this out: searching a third
  /// outcome for every capture costs depth, and in space no draw gets here.
  static const double minSearchedDraw = 0.05;

  /// Probability that [attacker] wins its battle against [defender],
  /// counting mutual destruction as half a win, clamped to
  /// [minProbability]–[maxProbability]. [outcomes] splits it into win,
  /// draw and loss.
  static double attackerWinProbability(
    Piece attacker,
    Piece defender,
    UpgradeProfile attackerUpgrades,
    UpgradeProfile defenderUpgrades, {
    WorldBalance balance = WorldBalance.space,
  }) =>
      outcomes(attacker, defender, attackerUpgrades, defenderUpgrades,
              balance: balance)
          .score;

  /// The chances of [attacker] winning, of both units falling together
  /// (both pieces leave the board) and of [attacker] losing.
  static BattleOutcomeOdds outcomes(
    Piece attacker,
    Piece defender,
    UpgradeProfile attackerUpgrades,
    UpgradeProfile defenderUpgrades, {
    WorldBalance balance = WorldBalance.space,
  }) {
    final attackerStats =
        UpgradeEngine.statsFor(attacker.type, attackerUpgrades, balance.units);
    final defenderStats =
        UpgradeEngine.statsFor(defender.type, defenderUpgrades, balance.units);
    final attackerTtk = timeToKillMs(attackerStats, defenderStats);
    final defenderTtk = timeToKillMs(defenderStats, attackerStats);

    final advantage =
        (defenderTtk - attackerTtk) / ((defenderTtk + attackerTtk) / 2);
    final p = (1 / (1 + exp(-steepness * advantage)))
        .clamp(minProbability, maxProbability)
        .toDouble();
    final meanTtk = (attackerTtk + defenderTtk) / 2;
    final base = attackerStats.isMelee && defenderStats.isMelee
        ? min(
            meleeMirrorDraw,
            meleeMirrorDraw *
                pow(drawReferenceTtkMs / meanTtk, drawTtkExponent))
        : rangedMirrorDraw;
    final spread = advantage / drawWidth;
    final closeness = exp(-spread * spread * ln2);
    // A draw takes half a point from each side's share.
    final draw = min(base * closeness, 2 * min(p, 1 - p)).toDouble();
    return BattleOutcomeOdds(win: p - draw / 2, draw: draw);
  }

  /// Time for [shooter] to destroy [target] when neither ship moves: the
  /// killing shot leaves after `shots` attack intervals, then crosses the
  /// arena. A melee unit strikes at range 1, each strike taking at least its
  /// wind-up, lunge and recovery.
  static int timeToKillMs(UnitStats shooter, UnitStats target) {
    // Same rounding as the arena's hit resolution.
    final netDamage =
        shooter.damage - (shooter.damage * target.defenseRating).round();
    if (netDamage <= 0) return _never;
    final shots = (target.maxHp / netDamage).ceil();
    final melee = shooter.melee;
    if (melee != null) {
      final reach = melee.windupMs + melee.dashMsAt(1);
      final cycle = max(shooter.attackIntervalMs, reach + melee.recoverMs);
      // The first strike waits one interval, like the first shot.
      return shooter.attackIntervalMs + (shots - 1) * cycle + reach;
    }
    return shots * shooter.attackIntervalMs + travelMs(shooter.weaponType);
  }

  /// Time from an attack leaving [stats]' unit to it landing: the shot's
  /// flight, or a strike's wind-up and lunge at range 1.
  static int leadMs(UnitStats stats) {
    final melee = stats.melee;
    if (melee == null) return travelMs(stats.weaponType);
    return melee.windupMs + melee.dashMsAt(1);
  }

  /// Time a [weapon]'s projectile takes to cross the arena.
  static int travelMs(WeaponType weapon) =>
      (1 / BattleEngine.projectileSpeed(weapon)).round();

  static final Map<(String, int), OddsTable> _tables = {};

  /// [attackerWinProbability] for every type pairing of a fleet with
  /// [attackerUpgrades] attacking a fleet with [defenderUpgrades]. Cached
  /// per world and pair of upgrade levels — the search asks millions of times.
  static OddsTable table(
    UpgradeProfile attackerUpgrades,
    UpgradeProfile defenderUpgrades, {
    WorldBalance balance = WorldBalance.space,
  }) {
    final key = (
      balance.id,
      _levelsKey(attackerUpgrades) * 4096 + _levelsKey(defenderUpgrades),
    );
    return _tables[key] ??= () {
      final all = [
        for (final attacker in PieceType.values)
          for (final defender in PieceType.values)
            outcomes(
              Piece(type: attacker, color: PlayerColor.white),
              Piece(type: defender, color: PlayerColor.black),
              attackerUpgrades,
              defenderUpgrades,
              balance: balance,
            ),
      ];
      return OddsTable._(
        [for (final odds in all) odds.score],
        [
          for (final odds in all)
            odds.draw < minSearchedDraw ? 0.0 : odds.draw,
        ],
      );
    }();
  }

  /// Cache key of an upgrade profile: one base-4 digit per piece type.
  static int _levelsKey(UpgradeProfile upgrades) {
    var key = 0;
    for (final type in PieceType.values) {
      key = key * 4 + upgrades.levelFor(type).clamp(0, 3);
    }
    return key;
  }
}

/// How a battle may end: the attacker wins, both fall together, or the
/// defender wins.
class BattleOutcomeOdds {
  final double win;
  final double draw;

  const BattleOutcomeOdds({required this.win, required this.draw});

  double get loss => 1 - win - draw;

  /// The attacker's share with a draw as half a win.
  double get score => win + draw / 2;
}

/// Attacker win probabilities for every attacker/defender type pairing of
/// two fleets; see [BattleOdds.table].
class OddsTable {
  const OddsTable._(this._probabilities, this._draws);

  final List<double> _probabilities;
  final List<double> _draws;

  /// The attacker's share, a draw counting half; see
  /// [BattleOdds.attackerWinProbability].
  double of(PieceType attacker, PieceType defender) =>
      _probabilities[_index(attacker, defender)];

  /// The chance that both units fall together.
  double drawOf(PieceType attacker, PieceType defender) =>
      _draws[_index(attacker, defender)];

  /// The chance that the attacker wins outright.
  double winOf(PieceType attacker, PieceType defender) {
    final i = _index(attacker, defender);
    return _probabilities[i] - _draws[i] / 2;
  }

  /// The chance that the defender's piece leaves the board: the attacker
  /// wins, or both fall.
  double takesOf(PieceType attacker, PieceType defender) {
    final i = _index(attacker, defender);
    return _probabilities[i] + _draws[i] / 2;
  }

  static int _index(PieceType attacker, PieceType defender) =>
      attacker.index * PieceType.values.length + defender.index;
}
