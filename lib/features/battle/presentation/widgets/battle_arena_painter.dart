import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import '../../../../core/game_logic/engine/battle_engine.dart';
import '../../../../core/game_logic/models/battle_state.dart';
import '../../../../core/game_logic/models/battle_unit.dart';
import '../../../../core/game_logic/models/piece.dart';
import '../../../../core/game_logic/models/projectile.dart';
import '../../../../core/game_logic/models/weapon_type.dart';
import '../../data/battle_element.dart';
import 'explosion_fx.dart';

/// Paints the battle arena in portrait orientation: one ship at the top,
/// one at the bottom, projectiles travelling vertically between them.
///
/// The camera looks straight down, so altitude shows as size and shadow: a
/// climbing ship or shot grows and its shadow falls further off. Ships bank
/// into their turns, shots and their impacts take the shooter's element, and
/// the losing ship goes up in an explosion of its own element.
class BattleArenaPainter extends CustomPainter {
  final BattleState battleState;

  /// Whether the attacker's ship sits at the bottom edge of the arena.
  final bool attackerAtBottom;

  /// Fleet sprites, bow up. A ship without one — still loading, or missing —
  /// is drawn as the plain vector hull.
  final ui.Image? attackerSprite;
  final ui.Image? defenderSprite;

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

  static const Map<BattleElement, Color> _elementColors = {
    BattleElement.kinetic: Colors.yellowAccent,
    BattleElement.water: Color(0xFF40A8FF),
    BattleElement.fire: Colors.deepOrangeAccent,
    BattleElement.ice: Color(0xFFB8F4FF),
    BattleElement.electric: Colors.cyanAccent,
  };

  /// Vertical distance of each ship from its arena edge.
  static const double _shipMarginFraction = 0.12;

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

  /// How far a ship moves forward over the full altitude range, as a
  /// fraction of the arena height: highest is this much ahead of lowest.
  static const double _altitudeLunge = 0.08;

  /// Drawn size at [altitude] relative to mid altitude: 0.7 low, 1.3 high.
  static double _altitudeScale(double altitude) => 0.7 + 0.6 * altitude;

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
    final yTop = size.height * _shipMarginFraction;
    final yBottom = size.height * (1 - _shipMarginFraction);
    // Climbing also carries a ship a little forward, toward the enemy, and
    // diving back, so a change of altitude reads at a glance.
    double shipY(BattleUnit unit, bool atBottom) =>
        (atBottom ? yBottom : yTop) +
        (atBottom ? -1 : 1) *
            (unit.altitude - 0.5) *
            size.height *
            _altitudeLunge;
    final attackerY = shipY(attacker, attackerAtBottom);
    final defenderY = shipY(defender, !attackerAtBottom);

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
            BattleEngine.hitHalfAltitude,
      );
    }

    // Once the battle is over the losing ship fades into its explosion.
    final BattleUnit? loser = !battleState.isFinished
        ? null
        : battleState.winner == attacker.piece.color
            ? defender
            : attacker;
    final destruction =
        ((nowMs - battleState.elapsedMs) / destructionMs).clamp(0.0, 1.0);
    final fading = 1 - (destruction / 0.35).clamp(0.0, 1.0);

    final attackerCenter = Offset(attacker.xFraction * size.width, attackerY);
    final defenderCenter = Offset(defender.xFraction * size.width, defenderY);
    final attackerSize = _drawShip(
      canvas,
      attackerCenter,
      arena: size,
      unit: attacker,
      facingUp: attackerAtBottom,
      sprite: attackerSprite,
      bank: attackerBank,
      opacity: identical(loser, attacker) ? fading : 1.0,
    );
    final defenderSize = _drawShip(
      canvas,
      defenderCenter,
      arena: size,
      unit: defender,
      facingUp: !attackerAtBottom,
      sprite: defenderSprite,
      bank: defenderBank,
      opacity: identical(loser, defender) ? fading : 1.0,
    );

    // Impacts burst in the shooter's element, as big as the shot is strong
    for (final impact in battleState.impacts) {
      final duration = impact.shielded ? _shieldImpactMs : _impactMs;
      final progress = (nowMs - impact.atMs) / duration;
      if (progress <= 0 || progress >= 1) continue;
      final shooter = impact.onAttacker ? defender : attacker;
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
    if (loser != null) {
      final loserIsAttacker = identical(loser, attacker);
      ExplosionFx.paint(
        canvas,
        loserIsAttacker ? attackerCenter : defenderCenter,
        element: BattleElement.of(loser.piece.type),
        radius: (loserIsAttacker ? attackerSize : defenderSize) * 1.1,
        progress: destruction,
        seed: loser.piece.type.index,
      );
    }
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
    final color = _elementColors[element]!;
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
    required double bank,
    required double opacity,
  }) {
    final scale = _altitudeScale(unit.altitude);
    final double shipSize;
    final double shieldRadius;
    if (sprite != null) {
      // Never much more than the gap to the arena edge allows.
      shipSize = math.min(
        arena.width * _spriteWidthFractions[unit.piece.type]! * scale,
        arena.height * _shipMarginFraction * 2.2,
      );
      shieldRadius = shipSize * 0.55;
    } else {
      shipSize = _shipHeight * scale;
      shieldRadius = shipSize * 0.7;
    }
    if (opacity <= 0) return shipSize;

    // The higher the ship, the further off and softer its shadow falls.
    final shadowAt =
        center + const Offset(1, 1) * shipSize * (0.06 + 0.22 * unit.altitude);
    final shadowColor =
        Colors.black.withValues(alpha: (0.45 - 0.2 * unit.altitude) * opacity);
    final blur = 1 + 4 * unit.altitude;
    _inShipFrame(canvas, shadowAt, shipSize, facingUp: facingUp, bank: bank, () {
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
              center: Offset.zero, width: _shipWidth * scale, height: shipSize),
          Paint()
            ..color = shadowColor
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur),
        );
      }
    });

    _inShipFrame(canvas, center, shipSize, facingUp: facingUp, bank: bank, () {
      if (sprite != null) {
        _drawSprite(
          canvas,
          sprite,
          shipSize,
          Paint()
            ..filterQuality = FilterQuality.medium
            ..color = Colors.white.withValues(alpha: opacity),
        );
      } else {
        canvas.scale(scale);
        _drawVectorShip(canvas, unit: unit, opacity: opacity);
      }
    });

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
  /// nose swings that way and the dipping wing recedes — and turned bow down
  /// for the top ship.
  void _inShipFrame(
    Canvas canvas,
    Offset center,
    double shipSize,
    VoidCallback draw, {
    required bool facingUp,
    required double bank,
  }) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(bank * _maxYaw * (facingUp ? 1 : -1));
    canvas.transform((Matrix4.identity()
          ..setEntry(3, 2, 0.6 / shipSize)
          ..rotateY(-bank * _maxRoll))
        .storage);
    if (!facingUp) canvas.rotate(math.pi);
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
