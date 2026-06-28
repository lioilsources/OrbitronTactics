import 'package:flutter/material.dart';
import '../../../../core/game_logic/models/battle_state.dart';
import '../../../../core/game_logic/models/weapon_type.dart';

class BattleArenaPainter extends CustomPainter {
  final BattleState battleState;

  BattleArenaPainter(this.battleState);

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

  @override
  void paint(Canvas canvas, Size size) {
    // Draw arena background gradient
    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.blue.shade900.withValues(alpha: 0.3),
          Colors.purple.shade900.withValues(alpha: 0.3),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bgPaint);

    // Center divider
    final dividerPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      dividerPaint,
    );

    // Draw projectiles
    for (final p in battleState.projectiles) {
      final weapon = p.fromAttacker
          ? battleState.attacker.stats.weaponType
          : battleState.defender.stats.weaponType;

      final color = _projectileColors[weapon] ?? Colors.white;
      final radius = (_projectileSizes[weapon] ?? 8.0) / 2;

      // Projectile travels from left (attacker) to right (defender) or vice versa
      final x = p.fromAttacker
          ? p.positionFraction * size.width
          : (1.0 - p.positionFraction) * size.width;
      final y = size.height / 2 + (p.fromAttacker ? -10.0 : 10.0);

      // Glow effect
      final glowPaint = Paint()
        ..color = color.withValues(alpha: 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(Offset(x, y), radius * 2.5, glowPaint);

      // Core
      final corePaint = Paint()..color = color;
      canvas.drawCircle(Offset(x, y), radius, corePaint);

      // Trail
      final trailPaint = Paint()
        ..color = color.withValues(alpha: 0.4)
        ..strokeWidth = radius * 0.8
        ..strokeCap = StrokeCap.round;
      final trailLength = 20.0;
      final trailEnd = p.fromAttacker
          ? Offset(x - trailLength, y)
          : Offset(x + trailLength, y);
      canvas.drawLine(Offset(x, y), trailEnd, trailPaint);
    }
  }

  @override
  bool shouldRepaint(BattleArenaPainter oldDelegate) => true;
}
