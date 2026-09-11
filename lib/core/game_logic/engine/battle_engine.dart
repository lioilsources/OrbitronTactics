import 'package:uuid/uuid.dart';

import '../models/battle_state.dart';
import '../models/battle_unit.dart';
import '../models/impact.dart';
import '../models/piece.dart';
import '../models/projectile.dart';
import '../models/shield_state.dart';
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

    // Tick attack timers and fire
    attacker = _tickAttack(attacker, deltaMs, true, projectiles);
    defender = _tickAttack(defender, deltaMs, false, projectiles);

    // Tick shield cooldowns
    attacker = _tickShield(attacker, deltaMs);
    defender = _tickShield(defender, deltaMs);

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
      if (!_isHit(target, moved)) continue;
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

  static BattleUnit _tickAttack(
    BattleUnit unit,
    int deltaMs,
    bool isAttacker,
    List<Projectile> projectiles,
  ) {
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
          nextAttackMs: unit.stats.attackIntervalMs + next);
    }
    return unit.copyWith(nextAttackMs: next);
  }

  static bool _isHit(BattleUnit target, Projectile p) =>
      (target.xFraction - p.xFraction).abs() <= hitHalfWidth &&
      (target.altitude - p.altitude).abs() <= hitHalfAltitude;

  /// Move a ship to [xFraction] (clamped to the arena, minus edge margin)
  /// and, when given, to [altitude] (clamped to 0–1).
  static BattleState moveShip(
    BattleState state,
    bool isAttacker,
    double xFraction, {
    double? altitude,
  }) {
    if (state.isFinished) return state;
    final unit = isAttacker ? state.attacker : state.defender;
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

  static BattleState activateShield(BattleState state, bool isAttacker) {
    final unit = isAttacker ? state.attacker : state.defender;
    if (!unit.shieldState.canActivate) return state;
    final activated = unit.copyWith(
      shieldState: unit.shieldState.copyWith(
        isActive: true,
        activeRemainingMs: unit.stats.shieldDurationMs,
      ),
    );
    return isAttacker
        ? state.copyWith(attacker: activated)
        : state.copyWith(defender: activated);
  }
}
