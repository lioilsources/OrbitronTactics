import 'dart:math' as math;

import 'package:uuid/uuid.dart';

import '../../maneuvers/maneuver.dart';
import '../models/battle_state.dart';
import '../models/battle_unit.dart';
import '../models/impact.dart';
import '../models/maneuver_run.dart';
import '../models/piece.dart';
import '../models/projectile.dart';
import '../models/shield_state.dart';
import '../models/spot.dart';
import '../models/upgrade_profile.dart';
import '../models/weapon_type.dart';
import 'unit_base_stats.dart';
import 'upgrade_engine.dart';

const _uuid = Uuid();

// Projectile travel speed: fraction per ms (crosses arena in ~600ms base)
const Map<WeaponType, double> _projectileSpeed = {
  WeaponType.rapidFire: 1.0 / 300,
  WeaponType.standard: 1.0 / 500,
  WeaponType.sniper: 1.0 / 250,
  WeaponType.heavyCannon: 1.0 / 700,
};

class BattleEngine {
  const BattleEngine._();

  /// A projectile hits when the target's ship center is within this
  /// horizontal distance (arena-width fraction) of the projectile's lane…
  static const double hitHalfWidth = 0.07;

  /// …and the ship flies within this altitude of the projectile's.
  static const double hitHalfAltitude = 0.12;

  /// Ships cannot move closer to the arena edge than this fraction.
  static const double shipEdgeMargin = 0.06;

  /// How long an impact stays in [BattleState.impacts].
  static const int impactMemoryMs = 1500;

  /// Energy a ship wins back each second for its maneuvers.
  static const double energyPerSecond = 12;

  /// Travel speed of [weapon]'s projectiles, in arena fractions per ms.
  static double projectileSpeed(WeaponType weapon) =>
      _projectileSpeed[weapon]!;

  static BattleUnit _makeUnit(Piece piece, UpgradeProfile profile) {
    final stats = UpgradeEngine.statsFor(piece.type, profile, unitBaseStats);
    return BattleUnit(
      piece: piece,
      stats: stats,
      currentHp: stats.maxHp,
      shieldState: const ShieldState(),
      nextAttackMs: stats.attackIntervalMs,
    );
  }

  static BattleState createBattle({
    required Piece attacker,
    required Piece defender,
    required UpgradeProfile attackerUpgrades,
    required UpgradeProfile defenderUpgrades,
  }) {
    return BattleState(
      attacker: _makeUnit(attacker, attackerUpgrades),
      defender: _makeUnit(defender, defenderUpgrades),
    );
  }

  static BattleState tick(BattleState state, int deltaMs) {
    if (state.isFinished) return state;

    final elapsedMs = state.elapsedMs + deltaMs;
    var attacker = state.attacker;
    var defender = state.defender;
    var projectiles = state.projectiles.toList();
    final impacts = [
      for (final impact in state.impacts)
        if (elapsedMs - impact.atMs < impactMemoryMs) impact,
    ];

    // A maneuver flies the ship and fires from its own plan. Both sides see
    // the enemy where this tick found it.
    final enemyOfAttacker = spotOf(defender);
    final enemyOfDefender = spotOf(attacker);
    attacker =
        _tickManeuver(attacker, enemyOfAttacker, elapsedMs, true, projectiles);
    defender =
        _tickManeuver(defender, enemyOfDefender, elapsedMs, false, projectiles);

    // Tick attack timers and fire
    attacker = _tickAttack(attacker, deltaMs, true, projectiles);
    defender = _tickAttack(defender, deltaMs, false, projectiles);

    // Tick shield cooldowns and win energy back
    attacker = _tickShield(_tickEnergy(attacker, deltaMs), deltaMs);
    defender = _tickShield(_tickEnergy(defender, deltaMs), deltaMs);

    // Move projectiles and resolve hits
    final attackerSpeed = projectileSpeed(attacker.stats.weaponType);
    final defenderSpeed = projectileSpeed(defender.stats.weaponType);
    final surviving = <Projectile>[];
    for (final p in projectiles) {
      final speed = p.fromAttacker ? attackerSpeed : defenderSpeed;
      final moved = p.copyWith(
        positionFraction: p.positionFraction + speed * deltaMs,
      );
      if (moved.positionFraction < 1.0) {
        surviving.add(moved);
        continue;
      }
      // Arrived at the enemy line — strikes only if the target didn't dodge
      final target = moved.fromAttacker ? defender : attacker;
      if (!_isHit(target, moved, elapsedMs)) continue;
      final shielded = target.shieldState.isActive;
      impacts.add(Impact(
        id: moved.id,
        onAttacker: !moved.fromAttacker,
        xFraction: moved.xFraction,
        altitude: moved.altitude,
        damage: moved.damage,
        shielded: shielded,
        atMs: elapsedMs,
      ));
      if (shielded) continue;
      if (moved.fromAttacker) {
        defender = _applyHit(defender, moved);
      } else {
        attacker = _applyHit(attacker, moved);
      }
    }

    // Check victory
    PlayerColor? winner;
    bool finished = false;
    if (!defender.isAlive) {
      winner = attacker.piece.color;
      finished = true;
    } else if (!attacker.isAlive) {
      winner = defender.piece.color;
      finished = true;
    }

    return state.copyWith(
      attacker: attacker,
      defender: defender,
      projectiles: surviving,
      impacts: impacts,
      elapsedMs: elapsedMs,
      isFinished: finished,
      winner: winner,
    );
  }

  /// Where [unit] is in the arena's flight space.
  static Spot spotOf(BattleUnit unit) =>
      (x: unit.xFraction, altitude: unit.altitude);

  /// Hands [unit]'s ship over to [maneuver].
  ///
  /// Does nothing when the ship is already flying one or cannot pay for it;
  /// [force] skips the price, for a maneuver an opponent already started on
  /// their device. [origin] and [enemyAtStart] then carry their anchors, so
  /// both devices fly the same path.
  static BattleState startManeuver(
    BattleState state,
    bool isAttacker,
    Maneuver maneuver, {
    int level = 1,
    bool mirrored = false,
    bool force = false,
    Spot? origin,
    Spot? enemyAtStart,
  }) {
    if (state.isFinished) return state;
    final unit = isAttacker ? state.attacker : state.defender;
    final enemy = isAttacker ? state.defender : state.attacker;
    if (unit.maneuver != null) return state;
    final cost = maneuver.costAt(level);
    if (!force && unit.energy < cost) return state;

    final flying = unit.copyWith(
      energy: math.max(0, unit.energy - cost),
      maneuver: ManeuverRun(
        id: maneuver.id,
        level: level,
        mirrored: mirrored,
        startedMs: state.elapsedMs,
        origin: origin ?? spotOf(unit),
        enemyAtStart: enemyAtStart ?? spotOf(enemy),
      ),
    );
    final started = isAttacker
        ? state.copyWith(attacker: flying)
        : state.copyWith(defender: flying);
    return maneuver.shield
        ? activateShield(started, isAttacker,
            ignoreCooldown: maneuver.ignoresShieldCooldown)
        : started;
  }

  static BattleUnit _tickEnergy(BattleUnit unit, int deltaMs) => unit.copyWith(
        energy: math.min(
          BattleUnit.maxEnergy,
          unit.energy + energyPerSecond * deltaMs / 1000,
        ),
      );

  /// Flies [unit] along its maneuver and fires the bursts it has reached.
  static BattleUnit _tickManeuver(
    BattleUnit unit,
    Spot enemyLive,
    int elapsedMs,
    bool isAttacker,
    List<Projectile> projectiles,
  ) {
    final run = unit.maneuver;
    if (run == null) return unit;
    final maneuver = run.maneuver;
    final progress = run.progressAt(elapsedMs);

    var flying = unit;
    if (!maneuver.keepsControl) {
      final pose = run.poseAt(elapsedMs, enemyLive);
      flying = unit.copyWith(
        xFraction:
            pose.x.clamp(shipEdgeMargin, 1.0 - shipEdgeMargin).toDouble(),
        altitude: pose.altitude.clamp(0.0, 1.0).toDouble(),
      );
    }

    var fired = run.firedCues;
    for (var cue = 0; cue < maneuver.fire.length; cue++) {
      if (fired.contains(cue) || maneuver.fire[cue].t > progress) continue;
      _fireBurst(flying, maneuver, maneuver.fire[cue], run.level, isAttacker,
          projectiles);
      fired = {...fired, cue};
    }

    if (progress >= 1) {
      // Back to the trigger, but not with a full interval to wait out.
      return flying.copyWith(
        clearManeuver: true,
        nextAttackMs: math.min(flying.nextAttackMs, 200),
      );
    }
    return flying.copyWith(maneuver: run.withFired(fired));
  }

  static void _fireBurst(
    BattleUnit unit,
    Maneuver maneuver,
    FireCue cue,
    int level,
    bool isAttacker,
    List<Projectile> projectiles,
  ) {
    final shots = maneuver.shotsAt(cue, level);
    for (var shot = 0; shot < shots; shot++) {
      final lane = shots == 1 ? 0.0 : cue.spread * (shot - (shots - 1) / 2);
      projectiles.add(Projectile(
        id: _uuid.v4(),
        positionFraction: 0.0,
        damage: math.max(1, (unit.stats.damage * cue.damage).round()),
        fromAttacker: isAttacker,
        xFraction: (unit.xFraction + lane).clamp(0.0, 1.0).toDouble(),
        altitude: unit.altitude,
      ));
    }
  }

  static BattleUnit _tickAttack(
    BattleUnit unit,
    int deltaMs,
    bool isAttacker,
    List<Projectile> projectiles,
  ) {
    final run = unit.maneuver;
    // A maneuver fires from its plan instead — unless it leaves the helm.
    if (run != null && !run.maneuver.keepsControl) return unit;
    final rate = run == null ? 1.0 : run.maneuver.fireRateScale;

    final next = unit.nextAttackMs - deltaMs;
    if (next <= 0) {
      projectiles.add(Projectile(
        id: _uuid.v4(),
        positionFraction: 0.0,
        damage: unit.stats.damage,
        fromAttacker: isAttacker,
        xFraction: unit.xFraction,
        altitude: unit.altitude,
      ));
      return unit.copyWith(
          nextAttackMs: (unit.stats.attackIntervalMs * rate).round() + next);
    }
    return unit.copyWith(nextAttackMs: next);
  }

  static bool _isHit(BattleUnit target, Projectile p, int elapsedMs) =>
      !(target.maneuver?.untouchableAt(elapsedMs) ?? false) &&
      (target.xFraction - p.xFraction).abs() <= hitHalfWidth &&
      (target.altitude - p.altitude).abs() <= hitHalfAltitude;

  /// Move a ship to [xFraction] (clamped to the arena, minus edge margin)
  /// and, when given, to [altitude] (clamped to 0–1).
  ///
  /// A ship in the middle of a maneuver flies its plan; steering waits.
  static BattleState moveShip(
    BattleState state,
    bool isAttacker,
    double xFraction, {
    double? altitude,
  }) {
    if (state.isFinished) return state;
    final unit = isAttacker ? state.attacker : state.defender;
    final run = unit.maneuver;
    if (run != null && !run.maneuver.keepsControl) return state;
    final moved = unit.copyWith(
      xFraction:
          xFraction.clamp(shipEdgeMargin, 1.0 - shipEdgeMargin).toDouble(),
      altitude: altitude?.clamp(0.0, 1.0).toDouble(),
    );
    return isAttacker
        ? state.copyWith(attacker: moved)
        : state.copyWith(defender: moved);
  }

  static BattleUnit _tickShield(BattleUnit unit, int deltaMs) {
    var shield = unit.shieldState;
    if (shield.isActive) {
      final remaining = shield.activeRemainingMs - deltaMs;
      if (remaining <= 0) {
        shield = shield.copyWith(
          isActive: false,
          activeRemainingMs: 0,
          cooldownRemainingMs: unit.stats.shieldCooldownMs,
        );
      } else {
        shield = shield.copyWith(activeRemainingMs: remaining);
      }
    } else if (shield.isOnCooldown) {
      final remaining = shield.cooldownRemainingMs - deltaMs;
      shield = shield.copyWith(
        cooldownRemainingMs: remaining < 0 ? 0 : remaining,
      );
    }
    return unit.copyWith(shieldState: shield);
  }

  static BattleUnit _applyHit(BattleUnit unit, Projectile p) {
    final absorbed = (p.damage * unit.stats.defenseRating).round();
    final net = (p.damage - absorbed).clamp(0, p.damage);
    final newHp = (unit.currentHp - net).clamp(0, unit.stats.maxHp);
    return unit.copyWith(currentHp: newHp);
  }

  /// Raises the shield; [ignoreCooldown] is for maneuvers that bring their
  /// own (the rook's Bulwark).
  static BattleState activateShield(
    BattleState state,
    bool isAttacker, {
    bool ignoreCooldown = false,
  }) {
    final unit = isAttacker ? state.attacker : state.defender;
    if (!unit.shieldState.canActivate && !ignoreCooldown) return state;
    final activated = unit.copyWith(
      shieldState: unit.shieldState.copyWith(
        isActive: true,
        activeRemainingMs: unit.stats.shieldDurationMs,
        cooldownRemainingMs: 0,
      ),
    );
    return isAttacker
        ? state.copyWith(attacker: activated)
        : state.copyWith(defender: activated);
  }
}
