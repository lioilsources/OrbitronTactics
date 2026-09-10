import 'dart:math';

import '../game_logic/engine/battle_engine.dart';
import '../game_logic/models/battle_state.dart';
import '../game_logic/models/battle_unit.dart';
import '../game_logic/models/projectile.dart';
import 'ai_difficulty.dart';
import 'battle_odds.dart';

/// What the AI pilot does this tick.
class BattleAiAction {
  /// The ship's new position, or null to hold still.
  final double? targetX;
  final bool activateShield;

  const BattleAiAction({this.targetX, this.activateShield = false});
}

/// Pilots one ship in the battle arena: aims at the enemy ship, dodges
/// incoming fire and raises the shield against hits it cannot avoid.
///
/// Acts on the real [BattleState] through the same engine calls as a
/// player's input. Skill comes entirely from the [AiProfile].
class BattleAi {
  BattleAi({required AiProfile profile, required Random random})
      : _profile = profile,
        _random = random;

  /// Clearance beyond a shot's hit zone when stepping out of its lane.
  static const double _dodgeClearance = 0.03;

  /// The shield goes up only this close to impact, so it also covers the
  /// shots that follow.
  static const int _shieldLeadMs = 120;

  final AiProfile _profile;
  final Random _random;

  int _sinceDecisionMs = 0;
  double? _targetX;

  /// The enemy's last positions as (elapsedMs, x), oldest first.
  final List<(int, double)> _enemyTrack = [];

  /// Shots the shield was already considered against — one roll per shot.
  final Set<String> _shieldRolled = {};

  BattleAiAction decide(
    BattleState state, {
    required bool isAttacker,
    required int deltaMs,
  }) {
    if (state.isFinished) return const BattleAiAction();
    final me = isAttacker ? state.attacker : state.defender;
    final enemy = isAttacker ? state.defender : state.attacker;

    _enemyTrack.add((state.elapsedMs, enemy.xFraction));
    if (_enemyTrack.length > 3) _enemyTrack.removeAt(0);
    final incoming = _incoming(state, isAttacker, enemy);

    // Steering reacts with a delay; between decisions the ship keeps
    // heading for its last target.
    _sinceDecisionMs += deltaMs;
    if (_sinceDecisionMs >= _profile.reactionMs) {
      _sinceDecisionMs = 0;
      _targetX = _chooseTarget(me, enemy, incoming);
    }
    final target = _targetX ?? me.xFraction;
    final step = _profile.maxShipSpeed * deltaMs / 1000;
    final newX = me.xFraction + (target - me.xFraction).clamp(-step, step);

    return BattleAiAction(
      targetX: (newX - me.xFraction).abs() > 1e-9 ? newX : null,
      // The shield is reconsidered every tick: waiting for the next
      // steering decision would be too late.
      activateShield: _shouldShield(me, target, incoming),
    );
  }

  /// Enemy shots in flight, with their time to impact in ms.
  List<(Projectile, double)> _incoming(
    BattleState state,
    bool isAttacker,
    BattleUnit enemy,
  ) {
    final speed = BattleEngine.projectileSpeed(enemy.stats.weaponType);
    return [
      for (final shot in state.projectiles)
        if (shot.fromAttacker != isAttacker)
          (shot, (1 - shot.positionFraction) / speed),
    ];
  }

  double _chooseTarget(
    BattleUnit me,
    BattleUnit enemy,
    List<(Projectile, double)> incoming,
  ) {
    var aim = enemy.xFraction;
    if (_profile.predictOpponent && _enemyTrack.length > 1) {
      // Lead the enemy by how far it moves while our shot is in flight.
      final (fromMs, fromX) = _enemyTrack.first;
      final (toMs, toX) = _enemyTrack.last;
      if (toMs > fromMs) {
        final velocity = (toX - fromX) / (toMs - fromMs);
        aim += velocity * BattleOdds.travelMs(me.stats.weaponType);
      }
    }
    aim = _clampToArena(aim);

    // Dodging comes before aiming.
    final dangerous = [
      for (final (shot, eta) in incoming)
        if (eta < _profile.dodgeWindowMs) shot,
    ];
    if (_isHitBy(dangerous, aim)) aim = _dodge(aim, dangerous);

    aim += _profile.aimError * (_random.nextDouble() * 2 - 1);
    return _clampToArena(aim);
  }

  /// The nearest spot beside a dangerous shot's lane that no dangerous shot
  /// hits, preferring the side of [aim] with fewer shots.
  double _dodge(double aim, List<Projectile> dangerous) {
    final clearance = BattleEngine.hitHalfWidth + _dodgeClearance;
    final spots = [
      for (final shot in dangerous) ...[
        shot.xFraction - clearance,
        shot.xFraction + clearance,
      ],
    ].where((x) => x == _clampToArena(x) && !_isHitBy(dangerous, x)).toList();
    // Nowhere safe: stay, and leave it to the shield.
    if (spots.isEmpty) return aim;

    int shotsOnSide(double x) =>
        dangerous.where((shot) => (shot.xFraction < aim) == (x < aim)).length;
    spots.sort((a, b) {
      final bySide = shotsOnSide(a).compareTo(shotsOnSide(b));
      return bySide != 0 ? bySide : (a - aim).abs().compareTo((b - aim).abs());
    });
    return spots.first;
  }

  bool _shouldShield(
    BattleUnit me,
    double target,
    List<(Projectile, double)> incoming,
  ) {
    if (!me.shieldState.canActivate) return false;
    final speedPerMs = _profile.maxShipSpeed / 1000;
    for (final (shot, eta) in incoming) {
      if (eta > _shieldLeadMs || _shieldRolled.contains(shot.id)) continue;

      // Where the ship will be at impact, still heading for its target.
      final travel = speedPerMs * eta;
      final xAtImpact =
          me.xFraction + (target - me.xFraction).clamp(-travel, travel);
      final cannotDodge = _isHitBy([shot], xAtImpact);
      final netDamage =
          shot.damage - (shot.damage * me.stats.defenseRating).round();
      final lethal = _isHitBy([shot], me.xFraction) && netDamage >= me.currentHp;
      if (!cannotDodge && !lethal) continue;

      _shieldRolled.add(shot.id);
      if (_random.nextDouble() < _profile.shieldSkill) return true;
    }
    return false;
  }

  static bool _isHitBy(Iterable<Projectile> shots, double x) => shots
      .any((shot) => (shot.xFraction - x).abs() <= BattleEngine.hitHalfWidth);

  static double _clampToArena(double x) => x
      .clamp(BattleEngine.shipEdgeMargin, 1 - BattleEngine.shipEdgeMargin)
      .toDouble();
}
