import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import '../../../../core/game_logic/models/battle_state.dart';
import '../../../../core/game_logic/models/battle_unit.dart';
import '../../../../core/game_logic/models/piece.dart';
import '../../../../core/game_logic/models/weapon_type.dart';

/// Paints the battle arena in portrait orientation: one ship at the top,
/// one at the bottom, projectiles travelling vertically between them.
class BattleArenaPainter extends CustomPainter {
  final BattleState battleState;

  /// Whether the attacker's ship sits at the bottom edge of the arena.
  final bool attackerAtBottom;

  /// Fleet sprites, bow up. A ship without one — still loading, or missing —
  /// is drawn as the plain vector hull.
  final ui.Image? attackerSprite;
  final ui.Image? defenderSprite;

  BattleArenaPainter(
    this.battleState, {
    required this.attackerAtBottom,
    this.attackerSprite,
    this.defenderSprite,
  });

  static const Map<WeaponType, Color> _projectileColors = {
    WeaponType.rapidFire: Colors.yellowAccent,
    WeaponType.standard: Colors.orangeAccent,
    WeaponType.sniper: Colors.lightBlueAccent,
    WeaponType.heavyCannon: Colors.redAccent,
  };

  static const Map<WeaponType, double> _projectileSizes = {
    WeaponType.rapidFire: 5.0,
    WeaponType.standard: 8.0,
    WeaponType.sniper: 4.0,
    WeaponType.heavyCannon: 12.0,
  };

  /// Vertical distance of each ship from its arena edge.
  static const double _shipMarginFraction = 0.12;

  static const double _shipWidth = 40.0;
  static const double _shipHeight = 48.0;

  /// Sprite size per unit as a fraction of the arena width. Most hulls fill
  /// about half their square's width, so this keeps them near the engine's
  /// hit width (0.14) — shots land where the hull is — with the heavier
  /// ships drawn larger.
  static const Map<PieceType, double> _spriteWidthFractions = {
    PieceType.pawn: 0.20,
    PieceType.knight: 0.22,
    PieceType.bishop: 0.22,
    PieceType.rook: 0.24,
    PieceType.queen: 0.26,
    PieceType.king: 0.28,
  };

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

    final yTop = size.height * _shipMarginFraction;
    final yBottom = size.height * (1 - _shipMarginFraction);
    final attackerY = attackerAtBottom ? yBottom : yTop;
    final defenderY = attackerAtBottom ? yTop : yBottom;

    // Draw projectiles (under the ships so shots emerge from the hull)
    for (final p in battleState.projectiles) {
      final weapon = p.fromAttacker
          ? battleState.attacker.stats.weaponType
          : battleState.defender.stats.weaponType;

      final color = _projectileColors[weapon] ?? Colors.white;
      final radius = (_projectileSizes[weapon] ?? 8.0) / 2;

      // Projectile travels straight from where its owner fired it
      final fromY = p.fromAttacker ? attackerY : defenderY;
      final toY = p.fromAttacker ? defenderY : attackerY;
      final y = fromY + (toY - fromY) * p.positionFraction;
      final x = p.xFraction * size.width;

      // Glow effect
      final glowPaint = Paint()
        ..color = color.withValues(alpha: 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(Offset(x, y), radius * 2.5, glowPaint);

      // Core
      final corePaint = Paint()..color = color;
      canvas.drawCircle(Offset(x, y), radius, corePaint);

      // Trail points back toward the shooter
      final trailPaint = Paint()
        ..color = color.withValues(alpha: 0.4)
        ..strokeWidth = radius * 0.8
        ..strokeCap = StrokeCap.round;
      const trailLength = 20.0;
      final trailDir = toY > fromY ? -1.0 : 1.0;
      canvas.drawLine(
        Offset(x, y),
        Offset(x, y + trailDir * trailLength),
        trailPaint,
      );
    }

    _drawShip(
      canvas,
      Offset(battleState.attacker.xFraction * size.width, attackerY),
      arena: size,
      unit: battleState.attacker,
      facingUp: attackerAtBottom,
      sprite: attackerSprite,
    );
    _drawShip(
      canvas,
      Offset(battleState.defender.xFraction * size.width, defenderY),
      arena: size,
      unit: battleState.defender,
      facingUp: !attackerAtBottom,
      sprite: defenderSprite,
    );
  }

  void _drawShip(
    Canvas canvas,
    Offset center, {
    required Size arena,
    required BattleUnit unit,
    required bool facingUp,
    required ui.Image? sprite,
  }) {
    final double shieldRadius;
    if (sprite != null) {
      // Never more than the gap to the arena edge allows.
      final extent = math.min(
        arena.width * _spriteWidthFractions[unit.piece.type]!,
        arena.height * _shipMarginFraction * 2,
      );
      _drawSprite(canvas, center, sprite, extent, facingUp: facingUp);
      shieldRadius = extent * 0.55;
    } else {
      _drawVectorShip(canvas, center, unit: unit, facingUp: facingUp);
      shieldRadius = _shipHeight * 0.7;
    }

    // Shield bubble
    if (unit.shieldState.isActive) {
      canvas.drawCircle(
        center,
        shieldRadius,
        Paint()
          ..color = Colors.cyanAccent.withValues(alpha: 0.2)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );
      canvas.drawCircle(
        center,
        shieldRadius,
        Paint()
          ..color = Colors.cyanAccent.withValues(alpha: 0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
    }
  }

  /// Sprites are drawn bow up; the ship facing down is turned half around.
  void _drawSprite(
    Canvas canvas,
    Offset center,
    ui.Image sprite,
    double size, {
    required bool facingUp,
  }) {
    // Faint halo, so dark hulls stand out against the dark arena
    canvas.drawCircle(
      center,
      size * 0.4,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.1)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, size * 0.15),
    );

    canvas.save();
    canvas.translate(center.dx, center.dy);
    if (!facingUp) canvas.rotate(math.pi);
    canvas.drawImageRect(
      sprite,
      Rect.fromLTWH(0, 0, sprite.width.toDouble(), sprite.height.toDouble()),
      Rect.fromCenter(center: Offset.zero, width: size, height: size),
      Paint()..filterQuality = FilterQuality.medium,
    );
    canvas.restore();
  }

  void _drawVectorShip(
    Canvas canvas,
    Offset center, {
    required BattleUnit unit,
    required bool facingUp,
  }) {
    final isWhite = unit.piece.color == PlayerColor.white;
    final hullColor = isWhite ? Colors.grey.shade200 : Colors.blueGrey.shade700;
    final outlineColor = isWhite ? Colors.white : Colors.blueGrey.shade200;
    final dir = facingUp ? -1.0 : 1.0;

    // Engine glow behind the tail
    final enginePaint = Paint()
      ..color = Colors.amber.withValues(alpha: 0.7)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(
      Offset(center.dx, center.dy - dir * (_shipHeight / 2 + 2)),
      5,
      enginePaint,
    );

    // Hull: arrowhead pointing at the enemy, notched tail
    final path = Path()
      ..moveTo(center.dx, center.dy + dir * _shipHeight / 2)
      ..lineTo(center.dx - _shipWidth / 2, center.dy - dir * _shipHeight / 2)
      ..lineTo(center.dx, center.dy - dir * _shipHeight / 4)
      ..lineTo(center.dx + _shipWidth / 2, center.dy - dir * _shipHeight / 2)
      ..close();

    canvas.drawPath(path, Paint()..color = hullColor);
    canvas.drawPath(
      path,
      Paint()
        ..color = outlineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Cockpit
    canvas.drawCircle(
      Offset(center.dx, center.dy + dir * _shipHeight / 8),
      4,
      Paint()..color = Colors.cyanAccent.withValues(alpha: 0.9),
    );
  }

  @override
  bool shouldRepaint(BattleArenaPainter oldDelegate) => true;
}
