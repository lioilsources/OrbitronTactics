import 'dart:math';

import '../game_logic/engine/battle_engine.dart';
import '../game_logic/models/battle_state.dart';
import '../game_logic/models/battle_unit.dart';
import '../game_logic/models/projectile.dart';
import '../game_logic/models/spot.dart';
import '../maneuvers/maneuver.dart';
import '../maneuvers/maneuver_catalog.dart';
import 'ai_difficulty.dart';
import 'battle_odds.dart';

/// What the AI pilot does this tick.
class BattleAiAction {
  /// The ship's new position, or null to hold still.
  final double? targetX;

  /// The ship's new altitude, or null to hold it.
  final double? targetAltitude;

  final bool activateShield;

  /// A maneuver to hand the ship over to, and which way round.
  final Maneuver? maneuver;
  final bool mirrored;

  const BattleAiAction({
    this.targetX,
    this.targetAltitude,
    this.activateShield = false,
    this.maneuver,
    this.mirrored = false,
  });
}

/// Pilots one ship in the battle arena: flies at the enemy ship's altitude
/// and aims at it, dodges incoming fire sideways or by climbing and diving,
/// raises the shield against hits it cannot avoid, and flies a maneuver when
/// cornered or when the enemy has walked into its sights.
///
/// Acts on the real [BattleState] through the same engine calls as a
/// player's input. Skill comes entirely from the [AiProfile].
class BattleAi {
  BattleAi({required AiProfile profile, required Random random})
      : _profile = profile,
        _random = random;

  /// Clearance beyond a shot's hit zone when getting out of its way.
  static const double _dodgeClearance = 0.03;

  /// Altitude aim is as sloppy as aim across, relative to each hit zone.
  static const double _altitudeErrorScale =
      BattleEngine.hitHalfAltitude / BattleEngine.hitHalfWidth;

  /// The shield goes up only this close to impact, so it also covers the
  /// shots that follow.
  static const int _shieldLeadMs = 120;

  /// A pilot considers a maneuver this often. Tying it to the steering
  /// decision instead had the best pilots flying one almost without a break.
  static const int _maneuverIntervalMs = 700;

  /// What the pilot reaches for when there is nowhere safe to steer, in
  /// order of preference.
  static const _escapes = [
    ManeuverFamily.roll,
    ManeuverFamily.loop,
    ManeuverFamily.dash,
    ManeuverFamily.sidestep,
  ];

  /// What it reaches for when the enemy is in its sights.
  static const _attacks = {
    ManeuverFamily.volley,
    ManeuverFamily.strike,
    ManeuverFamily.shadow,
    ManeuverFamily.signature,
  };

  final AiProfile _profile;
  final Random _random;

  int _sinceDecisionMs = 0;
  int _sinceManeuverMs = 0;
  Spot? _target;
  List<Maneuver>? _options;

  /// The enemy's last spots with their elapsedMs, oldest first.
  final List<(int, Spot)> _enemyTrack = [];

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

    _enemyTrack.add((state.elapsedMs, _spotOf(enemy)));
    if (_enemyTrack.length > 3) _enemyTrack.removeAt(0);
    final incoming = _incoming(state, isAttacker, enemy);

    final dangerous = _dangerous(incoming);

    // Steering reacts with a delay; between decisions the ship keeps
    // heading for its last target.
    _sinceDecisionMs += deltaMs;
    if (_sinceDecisionMs >= _profile.reactionMs) {
      _sinceDecisionMs = 0;
      _target = _chooseTarget(me, enemy, dangerous);
    }

    // Maneuvers are mulled on their own, slower clock.
    Maneuver? maneuver;
    var mirrored = false;
    _sinceManeuverMs += deltaMs;
    if (me.maneuver != null) {
      _sinceManeuverMs = 0;
    } else if (_sinceManeuverMs >= _maneuverIntervalMs) {
      _sinceManeuverMs = 0;
      final here = _spotOf(me);
      final cornered =
          _isHitBy(dangerous, here) && _dodge(here, dangerous) == null;
      (maneuver, mirrored) = _chooseManeuver(me, enemy, dangerous, cornered);
    }

    final here = _spotOf(me);
    final target = _target ?? here;
    final next = _toward(here, target, _profile.maxShipSpeed * deltaMs / 1000);

    return BattleAiAction(
      targetX: (next.x - here.x).abs() > 1e-9 ? next.x : null,
      targetAltitude:
          (next.altitude - here.altitude).abs() > 1e-9 ? next.altitude : null,
      // The shield is reconsidered every tick: waiting for the next
      // steering decision would be too late.
      activateShield: _shouldShield(me, target, incoming),
      maneuver: maneuver,
      mirrored: mirrored,
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

  List<Projectile> _dangerous(List<(Projectile, double)> incoming) => [
        for (final (shot, eta) in incoming)
          if (eta < _profile.dodgeWindowMs) shot,
      ];

  /// Where to steer.
  Spot _chooseTarget(
    BattleUnit me,
    BattleUnit enemy,
    List<Projectile> dangerous,
  ) {
    var aimX = enemy.xFraction;
    var aimAltitude = enemy.altitude;
    if (_profile.predictOpponent && _enemyTrack.length > 1) {
      // Lead the enemy by how far it moves while our shot is in flight.
      final (fromMs, from) = _enemyTrack.first;
      final (toMs, to) = _enemyTrack.last;
      if (toMs > fromMs) {
        final lead = BattleOdds.travelMs(me.stats.weaponType) / (toMs - fromMs);
        aimX += (to.x - from.x) * lead;
        aimAltitude += (to.altitude - from.altitude) * lead;
      }
    }
    var aim = _clamp((x: aimX, altitude: aimAltitude));

    // Dodging comes before aiming; with nowhere safe to go, stay and let
    // the shield or a maneuver deal with it.
    if (_isHitBy(dangerous, aim)) aim = _dodge(aim, dangerous) ?? aim;

    return _clamp((
      x: aim.x + _profile.aimError * _jitter(),
      altitude:
          aim.altitude + _profile.aimError * _altitudeErrorScale * _jitter(),
    ));
  }

  /// The nearest spot out of a dangerous shot's way — beside its lane, or
  /// above or below its altitude — preferring the side of [aim] with fewer
  /// shots. Null when every way out is covered.
  Spot? _dodge(Spot aim, List<Projectile> dangerous) {
    final clearX = BattleEngine.hitHalfWidth + _dodgeClearance;
    final clearAltitude = BattleEngine.hitHalfAltitude + _dodgeClearance;
    final spots = <Spot>[
      for (final shot in dangerous) ...[
        (x: shot.xFraction - clearX, altitude: aim.altitude),
        (x: shot.xFraction + clearX, altitude: aim.altitude),
        (x: aim.x, altitude: shot.altitude - clearAltitude),
        (x: aim.x, altitude: shot.altitude + clearAltitude),
      ],
    ].where((spot) => spot == _clamp(spot) && !_isHitBy(dangerous, spot)).toList();
    if (spots.isEmpty) return null;

    int shotsOnSide(Spot spot) => spot.x != aim.x
        ? dangerous
            .where((shot) => (shot.xFraction < aim.x) == (spot.x < aim.x))
            .length
        : dangerous
            .where((shot) =>
                (shot.altitude < aim.altitude) == (spot.altitude < aim.altitude))
            .length;
    double distance(Spot spot) =>
        max((spot.x - aim.x).abs(), (spot.altitude - aim.altitude).abs());
    spots.sort((a, b) {
      final bySide = shotsOnSide(a).compareTo(shotsOnSide(b));
      return bySide != 0 ? bySide : distance(a).compareTo(distance(b));
    });
    return spots.first;
  }

  /// A maneuver to fly, if this pilot knows one worth flying now: an escape
  /// when steering has nowhere to go, an attack when the enemy is in the
  /// hit zone.
  (Maneuver?, bool) _chooseManeuver(
    BattleUnit me,
    BattleUnit enemy,
    List<Projectile> dangerous,
    bool cornered,
  ) {
    final affordable = [
      for (final maneuver in _optionsFor(me))
        if (me.canAfford(maneuver.costAt(1))) maneuver,
    ];
    if (affordable.isEmpty) return (null, false);

    if (cornered && _random.nextDouble() < _profile.maneuverSkill) {
      for (final family in _escapes) {
        for (final maneuver in affordable) {
          if (maneuver.family != family) continue;
          // Away from the shots.
          final fromRight =
              dangerous.any((shot) => shot.xFraction >= me.xFraction);
          return (maneuver, fromRight);
        }
      }
    }

    if (_inSights(me, enemy) &&
        _random.nextDouble() < _profile.maneuverSkill * 0.4) {
      final attacks = [
        for (final maneuver in affordable)
          if (_attacks.contains(maneuver.family)) maneuver,
      ];
      if (attacks.isNotEmpty) {
        return (attacks[_random.nextInt(attacks.length)], me.xFraction > 0.5);
      }
    }
    return (null, false);
  }

  /// The maneuvers this pilot knows: the easier families, and for the best
  /// pilots their ship's signature as well.
  List<Maneuver> _optionsFor(BattleUnit me) {
    if (_options != null) return _options!;
    if (_profile.maneuverCount <= 0) return _options = const [];
    final all = ManeuverCatalog.forShip(me.piece.type);
    final signature =
        all.where((maneuver) => maneuver.family == ManeuverFamily.signature);
    final rest = all.where((maneuver) =>
        maneuver.family != ManeuverFamily.signature &&
        maneuver.tier != ManeuverTier.pack);
    return _options = _profile.maneuverCount >= 6
        ? [...rest.take(_profile.maneuverCount - 1), ...signature]
        : rest.take(_profile.maneuverCount).toList();
  }

  bool _inSights(BattleUnit me, BattleUnit enemy) =>
      (me.xFraction - enemy.xFraction).abs() <= BattleEngine.hitHalfWidth &&
      (me.altitude - enemy.altitude).abs() <= BattleEngine.hitHalfAltitude;

  bool _shouldShield(
    BattleUnit me,
    Spot target,
    List<(Projectile, double)> incoming,
  ) {
    if (!me.shieldState.canActivate) return false;
    final here = _spotOf(me);
    final speedPerMs = _profile.maxShipSpeed / 1000;
    for (final (shot, eta) in incoming) {
      if (eta > _shieldLeadMs || _shieldRolled.contains(shot.id)) continue;

      // Where the ship will be at impact, still heading for its target.
      final atImpact = _toward(here, target, speedPerMs * eta);
      final cannotDodge = _isHitBy([shot], atImpact);
      final netDamage =
          shot.damage - (shot.damage * me.stats.defenseRating).round();
      final lethal = _isHitBy([shot], here) && netDamage >= me.currentHp;
      if (!cannotDodge && !lethal) continue;

      _shieldRolled.add(shot.id);
      if (_random.nextDouble() < _profile.shieldSkill) return true;
    }
    return false;
  }

  double _jitter() => _random.nextDouble() * 2 - 1;

  static Spot _spotOf(BattleUnit unit) =>
      (x: unit.xFraction, altitude: unit.altitude);

  /// [from] moved toward [to] by at most [step] along each axis.
  static Spot _toward(Spot from, Spot to, double step) => (
        x: from.x + (to.x - from.x).clamp(-step, step),
        altitude: from.altitude + (to.altitude - from.altitude).clamp(-step, step),
      );

  static bool _isHitBy(Iterable<Projectile> shots, Spot spot) =>
      shots.any((shot) =>
          (shot.xFraction - spot.x).abs() <= BattleEngine.hitHalfWidth &&
          (shot.altitude - spot.altitude).abs() <= BattleEngine.hitHalfAltitude);

  static Spot _clamp(Spot spot) => (
        x: spot.x
            .clamp(BattleEngine.shipEdgeMargin, 1 - BattleEngine.shipEdgeMargin)
            .toDouble(),
        altitude: spot.altitude.clamp(0.0, 1.0).toDouble(),
      );
}
