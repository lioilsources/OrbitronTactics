import 'package:uuid/uuid.dart';

import '../models/battle_state.dart';
import '../models/battle_unit.dart';
import '../models/piece.dart';
import '../models/projectile.dart';
import '../models/shield_state.dart';
import '../models/upgrade_profile.dart';
import 'unit_base_stats.dart';
import 'upgrade_engine.dart';

const _uuid = Uuid();

// Projectile travel speed: fraction per ms (crosses arena in ~600ms base)
const Map<String, double> _projectileSpeed = {
  'rapidFire': 1.0 / 300,
  'standard': 1.0 / 500,
  'sniper': 1.0 / 250,
  'heavyCannon': 1.0 / 700,
};

class BattleEngine {
  const BattleEngine._();

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

    var attacker = state.attacker;
    var defender = state.defender;
    var projectiles = state.projectiles.toList();

    // Tick attack timers and fire
    attacker = _tickAttack(attacker, deltaMs, true, projectiles);
    defender = _tickAttack(defender, deltaMs, false, projectiles);

    // Tick shield cooldowns
    attacker = _tickShield(attacker, deltaMs);
    defender = _tickShield(defender, deltaMs);

    // Move projectiles and resolve hits
    final speed = _speedFor(attacker.stats.weaponType.name,
        defender.stats.weaponType.name);
    final surviving = <Projectile>[];
    for (final p in projectiles) {
      final moved = p.copyWith(
        positionFraction: p.positionFraction + speed(p) * deltaMs,
      );
      if (moved.positionFraction >= 1.0) {
        // Hit!
        if (moved.fromAttacker) {
          if (!defender.shieldState.isActive) {
            defender = _applyHit(defender, moved);
          }
        } else {
          if (!attacker.shieldState.isActive) {
            attacker = _applyHit(attacker, moved);
          }
        }
      } else {
        surviving.add(moved);
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
      elapsedMs: state.elapsedMs + deltaMs,
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
      ));
      return unit.copyWith(
          nextAttackMs: unit.stats.attackIntervalMs + next);
    }
    return unit.copyWith(nextAttackMs: next);
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

  static double Function(Projectile) _speedFor(
      String attackerWeapon, String defenderWeapon) {
    return (Projectile p) {
      final weapon = p.fromAttacker ? attackerWeapon : defenderWeapon;
      return _projectileSpeed[weapon] ?? (1.0 / 500);
    };
  }
}
