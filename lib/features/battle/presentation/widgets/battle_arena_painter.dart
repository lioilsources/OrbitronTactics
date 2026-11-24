import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import '../../../../core/game_logic/engine/battle_engine.dart';
import '../../../../core/game_logic/models/battle_state.dart';
import '../../../../core/game_logic/models/battle_unit.dart';
import '../../../../core/game_logic/models/piece.dart';
import '../../../../core/game_logic/models/projectile.dart';
import '../../../../core/game_logic/models/spot.dart';
import '../../../../core/game_logic/models/strike_run.dart';
import '../../../../core/game_logic/models/weapon_type.dart';
import '../../../../core/maneuvers/maneuver.dart';
import '../../data/battle_element.dart';
import '../../data/unit_art.dart';
import 'arena_layout.dart';
import 'explosion_fx.dart';
import 'melee_fx.dart';

/// Paints the battle arena in portrait orientation: one ship at the top,
/// one at the bottom, projectiles travelling vertically between them.
///
/// The camera looks straight down, so altitude shows as size and shadow: a
/// climbing ship or shot grows and its shadow falls further off. Ships bank
/// into their turns, shots and their impacts take the shooter's element, and
/// the losing ship goes up in an explosion of its own element.
///
/// A [UnitPose.standing] unit — a figure from a figure world — is drawn
/// upright as on the board instead: it keeps one size whatever its
/// altitude (the altitude only moves it forward), does not bank, stands on
/// a contact shadow, and is turned around only for the player sitting
/// across the device in hot-seat.
///
/// A melee unit's strike is drawn in its phases: the wind-up telegraphs
/// where the blow lands and the striker leans back; the lunge carries the
/// figure along the line to the target with speed streaks (its logical
/// position stays home); a hit slashes across the target, which flashes
/// red; a block throws sparks and the striker recoils, washed out.
class BattleArenaPainter extends CustomPainter {
  final BattleState battleState;

  /// Whether the attacker's ship sits at the bottom edge of the arena.
  final bool attackerAtBottom;

  /// Fleet sprites, bow up. A ship without one — still loading, or missing —
  /// is drawn as the plain vector hull.
  final ui.Image? attackerSprite;
  final ui.Image? defenderSprite;

  /// How each side's unit is drawn, and whether its picture is flipped
  /// left to right.
  final UnitPose attackerPose;
  final UnitPose defenderPose;
  final bool attackerMirrored;
  final bool defenderMirrored;

  /// Whether a player sits across the device from the top unit (hot-seat),
  /// so a standing figure up there is turned to face them.
  final bool topPlayerAcross;

  /// How far each ship banks, -1 (hard left) to 1 (hard right).
  final double attackerBank;
  final double defenderBank;

  /// Battle time the effects are drawn at. It runs on past the end of the
  /// battle while the losing ship explodes.
  final int nowMs;

  BattleArenaPainter(
    this.battleState, {
    required this.attackerAtBottom,
    this.attackerSprite,
    this.defenderSprite,
    this.attackerPose = UnitPose.topDown,
    this.defenderPose = UnitPose.topDown,
    this.attackerMirrored = false,
    this.defenderMirrored = false,
    this.topPlayerAcross = false,
    this.attackerBank = 0,
    this.defenderBank = 0,
    int? nowMs,
  }) : nowMs = nowMs ?? battleState.elapsedMs;

  /// How long the losing ship's explosion plays after the battle ends.
  static const int destructionMs = 1100;

  static const int _impactMs = 450;
  static const int _shieldImpactMs = 300;

  static const Map<WeaponType, double> _projectileSizes = {
    WeaponType.rapidFire: 5.0,
    WeaponType.standard: 8.0,
    WeaponType.sniper: 4.0,
    WeaponType.heavyCannon: 12.0,
  };

  static const double _shipWidth = 40.0;
  static const double _shipHeight = 48.0;

  /// Sprite size per unit as a fraction of the arena width, at mid altitude.
  /// Most hulls fill about half their square's width, so this keeps them
  /// near the engine's hit width (0.14) — shots land where the hull is — with
  /// the heavier ships drawn larger.
  static const Map<PieceType, double> _spriteWidthFractions = {
    PieceType.pawn: 0.20,
    PieceType.knight: 0.22,
    PieceType.bishop: 0.22,
    PieceType.rook: 0.24,
    PieceType.queen: 0.26,
    PieceType.king: 0.28,
  };

  /// Hardest roll into a turn, and how far the nose swings with it, in
  /// radians.
  static const double _maxRoll = 0.7;
  static const double _maxYaw = 0.14;

  /// Drawn size at [altitude] relative to mid altitude: 0.7 low, 1.3 high.
  static double _altitudeScale(double altitude) => 0.7 + 0.6 * altitude;

  /// Size of every standing figure as a fraction of the arena width. All
  /// six share it: the figures' heights by rank are in the pictures.
  static const double _figureWidthFraction = 0.3;

  /// How high a figure jumps in a flip, as a fraction of its size.
  static const double _jumpHeight = 0.45;

  /// How far a striker leans, as an [Attitude.pitch]: about 10°.
  static const double _strikeLean = 0.58;

  /// How far short of its target's center a lunge ends, in unit sizes.
  static const double _lungeStandOff = 0.55;

  /// How far a blocked striker is thrown back, in unit sizes.
  static const double _recoil = 0.2;

  /// Whether a unit at the top of the arena is drawn turned around. A ship
  /// seen from above always points its bow at the enemy; a standing figure
  /// stays upright unless a player sits across the device (hot-seat).
  static bool drawsUpsideDown({
    required UnitPose pose,
    required bool atTop,
    required bool topPlayerAcross,
  }) =>
      atTop && (pose == UnitPose.topDown || topPlayerAcross);

  @override
  void paint(Canvas canvas, Size size) {
    // Arena background gradient — vertical
    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.purple.shade900.withValues(alpha: 0.3),
          Colors.blue.shade900.withValues(alpha: 0.3),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bgPaint);

    // Center divider — horizontal
    final dividerPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      dividerPaint,
    );

    final attacker = battleState.attacker;
    final defender = battleState.defender;
    // Altitude is how far up its half a ship has flown: at its own edge when
    // lowest, just short of the divider when highest.
    final attackerY = ArenaLayout.shipY(attacker.altitude,
        atBottom: attackerAtBottom, arena: size);
    final defenderY = ArenaLayout.shipY(defender.altitude,
        atBottom: !attackerAtBottom, arena: size);

    // Draw projectiles (under the ships so shots emerge from the hull)
    for (final p in battleState.projectiles) {
      final shooter = p.fromAttacker ? attacker : defender;
      final target = p.fromAttacker ? defender : attacker;
      // Projectile travels straight from where its owner fired it
      final fromY = p.fromAttacker ? attackerY : defenderY;
      final toY = p.fromAttacker ? defenderY : attackerY;
      _drawProjectile(
        canvas,
        Offset(p.xFraction * size.width,
            fromY + (toY - fromY) * p.positionFraction),
        projectile: p,
        weapon: shooter.stats.weaponType,
        element: BattleElement.of(shooter.piece.type),
        headingDown: toY > fromY,
        onTarget: (p.altitude - target.altitude).abs() <=
            BattleEngine.hitHalfAltitudeAt(battleState.elapsedMs),
      );
    }

    // Once the battle is over the losing ship fades into its explosion;
    // after mutual destruction both do.
    final finished = battleState.isFinished;
    final mutual = battleState.isMutualDestruction;
    final attackerLost = finished &&
        (mutual || battleState.winner != attacker.piece.color);
    final defenderLost = finished &&
        (mutual || battleState.winner != defender.piece.color);
    final destruction =
        ((nowMs - battleState.elapsedMs) / destructionMs).clamp(0.0, 1.0);
    final fading = 1 - (destruction / 0.35).clamp(0.0, 1.0);

    final attackerHome = Offset(attacker.xFraction * size.width, attackerY);
    final defenderHome = Offset(defender.xFraction * size.width, defenderY);
    final attackerUnitSize =
        _unitSize(size, attacker, attackerPose, attackerSprite);
    final defenderUnitSize =
        _unitSize(size, defender, defenderPose, defenderSprite);
    final attackerStrike = _strikeLook(attacker, attackerHome,
        atBottom: attackerAtBottom, arena: size, unitSize: attackerUnitSize);
    final defenderStrike = _strikeLook(defender, defenderHome,
        atBottom: !attackerAtBottom, arena: size, unitSize: defenderUnitSize);
    _drawStrikeUnderlay(canvas, attacker, attackerStrike, attackerUnitSize);
    _drawStrikeUnderlay(canvas, defender, defenderStrike, defenderUnitSize);

    final attackerCenter = attackerStrike.center;
    final defenderCenter = defenderStrike.center;
    final attackerSize = _drawShip(
      canvas,
      attackerCenter,
      arena: size,
      unit: attacker,
      facingUp: attackerAtBottom,
      sprite: attackerSprite,
      pose: attackerPose,
      mirrored: attackerMirrored,
      bank: attackerBank,
      opacity: attackerLost ? fading : 1.0,
      enemy: (x: defender.xFraction, altitude: defender.altitude),
      lean: attackerStrike.lean,
      tint: _struckTint(isAttacker: true) ?? attackerStrike.tint,
    );
    final defenderSize = _drawShip(
      canvas,
      defenderCenter,
      arena: size,
      unit: defender,
      facingUp: !attackerAtBottom,
      sprite: defenderSprite,
      pose: defenderPose,
      mirrored: defenderMirrored,
      bank: defenderBank,
      opacity: defenderLost ? fading : 1.0,
      enemy: (x: attacker.xFraction, altitude: attacker.altitude),
      lean: defenderStrike.lean,
      tint: _struckTint(isAttacker: false) ?? defenderStrike.tint,
    );

    // Impacts burst in the shooter's element, as big as the shot is strong;
    // a strike slashes across its target or sparks off the shield.
    for (final impact in battleState.impacts) {
      final shooter = impact.onAttacker ? defender : attacker;
      if (impact.melee) {
        final progress = (nowMs - impact.atMs) / MeleeFx.contactMs;
        final target = impact.onAttacker ? attackerHome : defenderHome;
        final from = impact.onAttacker ? defenderHome : attackerHome;
        final unitSize =
            impact.onAttacker ? attackerUnitSize : defenderUnitSize;
        if (impact.shielded) {
          MeleeFx.blockSpark(
            canvas,
            at: target + _toward(target, from) * unitSize * 0.45,
            size: unitSize,
            progress: progress,
            seed: impact.id.hashCode,
          );
        } else {
          MeleeFx.slash(
            canvas,
            from: from,
            target: target,
            size: unitSize,
            color: BattleElement.of(shooter.piece.type).color,
            progress: progress,
          );
        }
        continue;
      }
      final duration = impact.shielded ? _shieldImpactMs : _impactMs;
      final progress = (nowMs - impact.atMs) / duration;
      if (progress <= 0 || progress >= 1) continue;
      final radius = size.width *
          0.09 *
          math.sqrt(impact.damage / 20) *
          _altitudeScale(impact.altitude) *
          (impact.shielded ? 0.75 : 1.0);
      ExplosionFx.paint(
        canvas,
        Offset(impact.xFraction * size.width,
            impact.onAttacker ? attackerY : defenderY),
        element: BattleElement.of(shooter.piece.type),
        radius: math.min(radius, size.width * 0.16),
        progress: progress,
        seed: impact.id.hashCode,
      );
    }

    // The loser goes up in its own element, as big as its ship
    if (attackerLost) {
      ExplosionFx.paint(
        canvas,
        attackerCenter,
        element: BattleElement.of(attacker.piece.type),
        radius: attackerSize * 1.1,
        progress: destruction,
        seed: attacker.piece.type.index,
      );
    }
    if (defenderLost) {
      ExplosionFx.paint(
        canvas,
        defenderCenter,
        element: BattleElement.of(defender.piece.type),
        radius: defenderSize * 1.1,
        progress: destruction,
        seed: defender.piece.type.index + PieceType.values.length,
      );
    }
  }

  /// The unit vector from [from] toward [to]; zero when they coincide.
  static Offset _toward(Offset from, Offset to) {
    final d = to - from;
    final length = d.distance;
    return length < 1e-6 ? Offset.zero : d / length;
  }

  /// A red flash on a unit a strike has just hit.
  ColorFilter? _struckTint({required bool isAttacker}) {
    for (final impact in battleState.impacts.reversed) {
      if (!impact.melee || impact.shielded) continue;
      if (impact.onAttacker != isAttacker) continue;
      final progress = (nowMs - impact.atMs) / MeleeFx.contactMs;
      if (progress < 0 || progress >= 1) continue;
      return ColorFilter.mode(
        Colors.redAccent.withValues(alpha: 0.55 * (1 - progress)),
        BlendMode.srcATop,
      );
    }
    return null;
  }

  /// How [unit] is drawn through its strike: where (home, or out along the
  /// lunge), leaning which way and tinted how, plus what the wind-up
  /// telegraphs. A unit without a strike stands at [home].
  _StrikeLook _strikeLook(
    BattleUnit unit,
    Offset home, {
    required bool atBottom,
    required Size arena,
    required double unitSize,
  }) {
    final strike = unit.strike;
    final melee = unit.stats.melee;
    if (strike == null || melee == null) return _StrikeLook(home);
    final now = battleState.elapsedMs;
    final target = Offset(
      strike.target.x * arena.width,
      ArenaLayout.shipY(strike.target.altitude.clamp(0.0, 1.0),
          atBottom: !atBottom, arena: arena),
    );
    final direction = _toward(home, target);
    final reach = math.max(
        0.0, (target - home).distance - unitSize * _lungeStandOff);
    switch (strike.phaseAt(now)) {
      case StrikePhase.windup:
        final progress = strike.windupMs <= 0
            ? 1.0
            : (now - strike.startedMs) / strike.windupMs;
        return _StrikeLook(
          home,
          lean: Attitude(pitch: -_strikeLean * progress.clamp(0.0, 1.0)),
          telegraph: target,
          telegraphProgress: progress,
          telegraphHalfWidth: BattleEngine.reachHalfWidthAt(
                  melee, now, battleState.balance.arena) *
              arena.width,
        );
      case StrikePhase.dash:
        final lunge = strike.lungeAt(now);
        return _StrikeLook(
          home + direction * reach * lunge,
          lean: const Attitude(pitch: _strikeLean),
          streaks: direction,
          streakStrength: 1,
        );
      case StrikePhase.recover:
        final staggered = strike.recoverMs > melee.recoverMs;
        final progress = strike.recoverMs <= 0
            ? 1.0
            : ((now - strike.contactMs) / strike.recoverMs).clamp(0.0, 1.0);
        if (staggered) {
          // Thrown back off the shield, then finding its feet.
          final left = 1 - progress;
          return _StrikeLook(
            home - direction * unitSize * _recoil * left,
            lean: Attitude(pitch: -_strikeLean * left),
            tint: ColorFilter.mode(
              Colors.white.withValues(alpha: 0.45 * left),
              BlendMode.srcATop,
            ),
          );
        }
        final lunge = strike.lungeAt(now);
        return _StrikeLook(
          home + direction * reach * lunge,
          lean: Attitude(pitch: _strikeLean * lunge),
        );
      case StrikePhase.done:
        return _StrikeLook(home);
    }
  }

  /// What a strike draws under the units: the wind-up's impact zone and
  /// the lunge's speed streaks, in [unit]'s element.
  void _drawStrikeUnderlay(
    Canvas canvas,
    BattleUnit unit,
    _StrikeLook look,
    double unitSize,
  ) {
    final color = BattleElement.of(unit.piece.type).color;
    final telegraph = look.telegraph;
    if (telegraph != null) {
      MeleeFx.telegraph(
        canvas,
        from: look.center,
        target: telegraph,
        halfWidth: look.telegraphHalfWidth,
        color: color,
        progress: look.telegraphProgress,
      );
    }
    final streaks = look.streaks;
    if (streaks != null) {
      MeleeFx.speedStreaks(
        canvas,
        at: look.center,
        direction: streaks,
        size: unitSize,
        strength: look.streakStrength,
      );
    }
  }

  /// The drawn size of [unit]: a standing figure's is the same for all.
  static double _unitSize(
    Size arena,
    BattleUnit unit,
    UnitPose pose,
    ui.Image? sprite,
  ) {
    if (pose == UnitPose.standing) {
      return math.min(arena.width * _figureWidthFraction, arena.height * 0.22);
    }
    final scale = _altitudeScale(unit.altitude);
    if (sprite != null) {
      // Never much more than the gap to the arena edge allows.
      return math.min(
        arena.width * _spriteWidthFractions[unit.piece.type]! * scale,
        arena.height * 0.2,
      );
    }
    return _shipHeight * scale;
  }

  void _drawProjectile(
    Canvas canvas,
    Offset at, {
    required Projectile projectile,
    required WeaponType weapon,
    required BattleElement element,
    required bool headingDown,
    required bool onTarget,
  }) {
    final radius =
        (_projectileSizes[weapon] ?? 8.0) / 2 * _altitudeScale(projectile.altitude);
    final color = element.color;
    // A shot flying past its target's altitude cannot hit: it is dimmed.
    final opacity = onTarget ? 1.0 : 0.35;
    // The trail points back toward the shooter
    final back = headingDown ? -1.0 : 1.0;

    // Shadow, further off the higher the shot flies
    canvas.drawCircle(
      at + const Offset(1, 1) * radius * (1 + 3 * projectile.altitude),
      radius * 0.8,
      Paint()..color = Colors.black.withValues(alpha: 0.3 * opacity),
    );

    // Glow effect
    canvas.drawCircle(
      at,
      radius * 2.5,
      Paint()
        ..color = color.withValues(alpha: 0.3 * opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // Trail
    final trail = Paint()
      ..color = color.withValues(alpha: 0.5 * opacity)
      ..strokeWidth = radius * 0.8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final trailLength = radius * 5;
    switch (element) {
      case BattleElement.electric:
        final zigzag = Path()..moveTo(at.dx, at.dy);
        for (var i = 1; i <= 4; i++) {
          zigzag.lineTo(at.dx + (i.isOdd ? radius : -radius),
              at.dy + back * trailLength * i / 4);
        }
        canvas.drawPath(zigzag, trail..strokeWidth = radius * 0.4);
      case BattleElement.fire:
        for (var i = 1; i <= 3; i++) {
          canvas.drawCircle(
            at + Offset(0, back * radius * 1.6 * i),
            radius * (1 - i * 0.22),
            Paint()
              ..color = Color.lerp(Colors.orangeAccent, Colors.redAccent, i / 3)!
                  .withValues(alpha: 0.6 * opacity),
          );
        }
      case BattleElement.kinetic || BattleElement.water || BattleElement.ice:
        canvas.drawLine(at, at + Offset(0, back * trailLength), trail);
    }

    // Core
    final core = Paint()
      ..color = switch (element) {
        BattleElement.fire => Colors.yellowAccent,
        BattleElement.electric => Colors.white,
        _ => color,
      }
          .withValues(alpha: opacity);
    if (element == BattleElement.ice) {
      canvas.drawPath(
        Path()
          ..moveTo(at.dx, at.dy - radius * 1.4)
          ..lineTo(at.dx + radius * 0.8, at.dy)
          ..lineTo(at.dx, at.dy + radius * 1.4)
          ..lineTo(at.dx - radius * 0.8, at.dy)
          ..close(),
        core,
      );
    } else {
      canvas.drawCircle(at, radius, core);
    }

    // A ring marks a shot on its target's altitude
    if (onTarget) {
      canvas.drawCircle(
        at,
        radius * 1.6,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.7)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
    }
  }

  /// Draws [unit]'s ship — its shadow on the arena floor, the ship banked
  /// into its turn, its shield — and returns the ship's drawn size.
  double _drawShip(
    Canvas canvas,
    Offset center, {
    required Size arena,
    required BattleUnit unit,
    required bool facingUp,
    required ui.Image? sprite,
    required UnitPose pose,
    required bool mirrored,
    required double bank,
    required double opacity,
    required Spot enemy,
    Attitude lean = Attitude.level,
    ColorFilter? tint,
  }) {
    final standing = pose == UnitPose.standing;
    final scale = standing ? 1.0 : _altitudeScale(unit.altitude);
    final upsideDown = drawsUpsideDown(
        pose: pose, atTop: !facingUp, topPlayerAcross: topPlayerAcross);
    final shipSize = _unitSize(arena, unit, pose, sprite);
    final shieldRadius =
        standing || sprite != null ? shipSize * 0.55 : shipSize * 0.7;
    if (opacity <= 0) return shipSize;

    final run = unit.maneuver;
    // A cloaked ship all but vanishes while shots pass through it.
    if (run != null &&
        run.maneuver.cloaks &&
        run.untouchableAt(battleState.elapsedMs)) {
      opacity *= 0.15;
    }
    final flown =
        run?.poseAt(battleState.elapsedMs, enemy).attitude ?? Attitude.level;
    // A strike leans the unit on top of what its maneuver holds.
    final attitude = Attitude(
      roll: flown.roll,
      pitch: flown.pitch + lean.pitch,
      flip: flown.flip,
      boost: flown.boost,
    );
    final element = BattleElement.of(unit.piece.type);

    // Runs [draw] in the unit's frame at [at], held as [held] asks.
    void inFrame(Offset at, Attitude held, VoidCallback draw,
        {bool lifted = true}) {
      if (standing) {
        _inFigureFrame(canvas, at, shipSize, draw,
            upsideDown: upsideDown,
            mirrored: mirrored,
            attitude: held,
            lifted: lifted);
      } else {
        _inShipFrame(canvas, at, shipSize, draw,
            facingUp: !upsideDown, bank: bank, attitude: held);
      }
    }

    // A maneuver leaves afterimages. Its flight is a function of time, so
    // the ship's own poses a moment ago come straight back out of the run.
    if (run != null) {
      for (var back = 3; back >= 1; back--) {
        final wasMs = battleState.elapsedMs - back * 60;
        if (wasMs <= run.startedMs) continue;
        final was = run.poseAt(wasMs, enemy);
        final ghost = Offset(
          was.x.clamp(0.0, 1.0) * arena.width,
          ArenaLayout.shipY(was.altitude.clamp(0.0, 1.0),
              atBottom: facingUp, arena: arena),
        );
        final alpha = 0.07 * (4 - back) * opacity;
        inFrame(ghost, was.attitude, () {
          if (sprite != null) {
            _drawSprite(canvas, sprite, shipSize,
                Paint()..color = Colors.white.withValues(alpha: alpha));
          } else {
            canvas.scale(scale);
            _drawVectorShip(canvas, unit: unit, opacity: alpha);
          }
        });
      }
    }

    if (standing) {
      // A figure stands on the arena floor: a soft contact shadow under its
      // plinth, which stays put while the figure jumps.
      inFrame(center, attitude, lifted: false, () {
        canvas.drawOval(
          Rect.fromCenter(
              center: Offset(0, shipSize * 0.44),
              width: shipSize * 0.62,
              height: shipSize * 0.16),
          Paint()
            ..color = Colors.black.withValues(alpha: 0.45 * opacity)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, shipSize * 0.04),
        );
      });
    } else {
      // The higher the ship, the further off and softer its shadow falls.
      final shadowAt = center +
          const Offset(1, 1) * shipSize * (0.06 + 0.22 * unit.altitude);
      final shadowColor = Colors.black
          .withValues(alpha: (0.45 - 0.2 * unit.altitude) * opacity);
      final blur = 1 + 4 * unit.altitude;
      inFrame(shadowAt, attitude, () {
        if (sprite != null) {
          _drawSprite(
            canvas,
            sprite,
            shipSize * 0.9,
            Paint()
              ..colorFilter = ColorFilter.mode(shadowColor, BlendMode.srcIn)
              ..imageFilter = ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          );
        } else {
          canvas.drawOval(
            Rect.fromCenter(
                center: Offset.zero,
                width: _shipWidth * scale,
                height: shipSize),
            Paint()
              ..color = shadowColor
              ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur),
          );
        }
      });
    }

    // A figure kicks up dust where a ship's engines would burn.
    if (standing && attitude.boost > 0) {
      inFrame(center, attitude, lifted: false, () {
        final dust = Paint()
          ..color = const Color(0xFFB8A27A)
              .withValues(alpha: 0.45 * attitude.boost * opacity)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, shipSize * 0.06);
        for (final side in const [-1.0, 1.0]) {
          canvas.drawCircle(
            Offset(side * shipSize * 0.3, shipSize * 0.42),
            shipSize * 0.12 * (0.5 + attitude.boost),
            dust,
          );
        }
      });
    }

    // Engines burning through a maneuver
    if (!standing && attitude.boost > 0) {
      inFrame(center, attitude, () {
        canvas.drawCircle(
          Offset(0, shipSize * 0.55),
          shipSize * 0.22 * (0.5 + attitude.boost),
          Paint()
            ..color = element.color
                .withValues(alpha: 0.55 * attitude.boost * opacity)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, shipSize * 0.12),
        );
      });
    }

    inFrame(center, attitude, () {
      if (sprite != null) {
        _drawSprite(
          canvas,
          sprite,
          shipSize,
          Paint()
            ..filterQuality = FilterQuality.medium
            ..color = Colors.white.withValues(alpha: opacity)
            ..colorFilter = tint,
        );
      } else {
        canvas.scale(scale);
        _drawVectorShip(canvas, unit: unit, opacity: opacity);
      }
    });

    // Shots pass through a ship in its untouchable window
    if (run != null && run.untouchableAt(battleState.elapsedMs)) {
      final pulse = 0.45 + 0.3 * math.sin(battleState.elapsedMs / 70);
      canvas.drawCircle(
        center,
        shipSize * 0.62,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = element.color.withValues(alpha: pulse * opacity),
      );
    }

    // Shield bubble
    if (unit.shieldState.isActive) {
      canvas.drawCircle(
        center,
        shieldRadius,
        Paint()
          ..color = Colors.cyanAccent.withValues(alpha: 0.2 * opacity)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );
      canvas.drawCircle(
        center,
        shieldRadius,
        Paint()
          ..color = Colors.cyanAccent.withValues(alpha: 0.6 * opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
    }
    return shipSize;
  }

  /// Runs [draw] in a ship's frame at [center]: banked into its turn — the
  /// nose swings that way and the dipping wing recedes — held as its
  /// maneuver asks, and turned bow down for the top ship.
  void _inShipFrame(
    Canvas canvas,
    Offset center,
    double shipSize,
    VoidCallback draw, {
    required bool facingUp,
    required double bank,
    Attitude attitude = Attitude.level,
  }) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(bank * _maxYaw * (facingUp ? 1 : -1));
    canvas.transform((Matrix4.identity()
          ..setEntry(3, 2, 0.6 / shipSize)
          ..rotateY(-bank * _maxRoll - attitude.roll * 2 * math.pi)
          ..rotateX(attitude.pitch * 0.45 + attitude.flip * math.pi))
        .storage);
    if (!facingUp) canvas.rotate(math.pi);
    draw();
    canvas.restore();
  }

  /// Runs [draw] in a standing figure's frame at [center]: upright, turned
  /// around only when [upsideDown], flipped when [mirrored], and posed by
  /// its maneuver — a roll spins it about its upright axis, a flip is a
  /// jump (skipped unless [lifted]), a pitch leans it the way it faces.
  void _inFigureFrame(
    Canvas canvas,
    Offset center,
    double size,
    VoidCallback draw, {
    required bool upsideDown,
    required bool mirrored,
    required Attitude attitude,
    bool lifted = true,
  }) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    if (upsideDown) canvas.rotate(math.pi);
    if (lifted) {
      final jump = math.sin(attitude.flip * math.pi / 2).abs();
      canvas.translate(0, -jump * size * _jumpHeight);
    }
    // Lean about the feet, toward the side the figure faces.
    final feet = size * 0.44;
    canvas.translate(0, feet);
    canvas.rotate(attitude.pitch * 0.3 * (mirrored ? -1 : 1));
    canvas.translate(0, -feet);
    canvas.transform((Matrix4.identity()
          ..setEntry(3, 2, 0.6 / size)
          ..rotateY(attitude.roll * 2 * math.pi))
        .storage);
    if (mirrored) canvas.scale(-1, 1);
    draw();
    canvas.restore();
  }

  /// Draws [sprite] bow up, [size] across, centered on the canvas origin.
  void _drawSprite(Canvas canvas, ui.Image sprite, double size, Paint paint) {
    canvas.drawImageRect(
      sprite,
      Rect.fromLTWH(0, 0, sprite.width.toDouble(), sprite.height.toDouble()),
      Rect.fromCenter(center: Offset.zero, width: size, height: size),
      paint,
    );
  }

  /// Draws the vector hull bow up, centered on the canvas origin.
  void _drawVectorShip(
    Canvas canvas, {
    required BattleUnit unit,
    required double opacity,
  }) {
    final isWhite = unit.piece.color == PlayerColor.white;
    final hullColor = isWhite ? Colors.grey.shade200 : Colors.blueGrey.shade700;
    final outlineColor = isWhite ? Colors.white : Colors.blueGrey.shade200;

    // Engine glow behind the tail
    final enginePaint = Paint()
      ..color = Colors.amber.withValues(alpha: 0.7 * opacity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(const Offset(0, _shipHeight / 2 + 2), 5, enginePaint);

    // Hull: arrowhead pointing at the enemy, notched tail
    final path = Path()
      ..moveTo(0, -_shipHeight / 2)
      ..lineTo(-_shipWidth / 2, _shipHeight / 2)
      ..lineTo(0, _shipHeight / 4)
      ..lineTo(_shipWidth / 2, _shipHeight / 2)
      ..close();

    canvas.drawPath(
        path, Paint()..color = hullColor.withValues(alpha: opacity));
    canvas.drawPath(
      path,
      Paint()
        ..color = outlineColor.withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Cockpit
    canvas.drawCircle(
      const Offset(0, -_shipHeight / 8),
      4,
      Paint()..color = Colors.cyanAccent.withValues(alpha: 0.9 * opacity),
    );
  }

  @override
  bool shouldRepaint(BattleArenaPainter oldDelegate) => true;
}

/// How a unit is drawn at one moment of its strike.
class _StrikeLook {
  /// Where the unit is drawn; its logical position stays home.
  final Offset center;
  final Attitude lean;
  final ColorFilter? tint;

  /// Where the wind-up says the blow lands, while it does.
  final Offset? telegraph;
  final double telegraphProgress;
  final double telegraphHalfWidth;

  /// The lunge's heading, while it runs.
  final Offset? streaks;
  final double streakStrength;

  const _StrikeLook(
    this.center, {
    this.lean = Attitude.level,
    this.tint,
    this.telegraph,
    this.telegraphProgress = 0,
    this.telegraphHalfWidth = 0,
    this.streaks,
    this.streakStrength = 0,
  });
}
