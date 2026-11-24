import 'dart:math' as math;

import 'package:flutter/painting.dart';

const _white = Color(0xFFFFFFFF);

/// The drawn phases of a melee strike in the table arena: the wind-up's
/// telegraph, the lunge's speed streaks, the slash of a hit and the sparks
/// of a block. Pure drawing; where and when comes from the strike.
class MeleeFx {
  const MeleeFx._();

  /// How long a hit's slash and a block's sparks stay on screen.
  static const int contactMs = 320;

  /// The wind-up: where the blow will land, a flattened ellipse in the
  /// striker's [color] around [target] on the enemy's side, faint fill and
  /// a stronger rim, and a faint line from the striker at [from].
  /// [progress] (0–1) of the wind-up tightens the rim as the blow nears.
  static void telegraph(
    Canvas canvas, {
    required Offset from,
    required Offset target,
    required double halfWidth,
    required Color color,
    required double progress,
  }) {
    final t = progress.clamp(0.0, 1.0);
    canvas.drawLine(
      from,
      target,
      Paint()
        ..color = color.withValues(alpha: 0.18 + 0.12 * t)
        ..strokeWidth = 1.5,
    );
    final zone = Rect.fromCenter(
      center: target,
      width: halfWidth * 2,
      height: halfWidth * 0.7,
    );
    canvas.drawOval(
      zone,
      Paint()..color = color.withValues(alpha: 0.14 + 0.1 * t),
    );
    canvas.drawOval(
      zone,
      Paint()
        ..color = color.withValues(alpha: 0.55 + 0.35 * t)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5 + 1.5 * t,
    );
  }

  /// Short white streaks behind a lunging figure at [at], moving along
  /// [direction] (a unit vector); [size] is the figure's.
  static void speedStreaks(
    Canvas canvas, {
    required Offset at,
    required Offset direction,
    required double size,
    required double strength,
  }) {
    if (strength <= 0) return;
    final back = -direction;
    final across = Offset(-direction.dy, direction.dx);
    final paint = Paint()
      ..color = _white.withValues(alpha: 0.55 * strength)
      ..strokeWidth = math.max(1.0, size * 0.025)
      ..strokeCap = StrokeCap.round;
    for (final lane in const [-0.22, 0.0, 0.22]) {
      final start = at + back * size * 0.35 + across * size * lane;
      final length = size * (lane == 0 ? 0.45 : 0.3) * strength;
      canvas.drawLine(start, start + back * length, paint);
    }
  }

  /// A hit: a thick glowing arc in the striker's [color] over [target],
  /// swung across from [from], and a white star flash. [progress] 0–1.
  static void slash(
    Canvas canvas, {
    required Offset from,
    required Offset target,
    required double size,
    required Color color,
    required double progress,
  }) {
    if (progress <= 0 || progress >= 1) return;
    final fade = 1 - progress;
    final toward = target - from;
    final heading = toward.direction;
    final radius = size * 0.42;
    final arc = Rect.fromCircle(center: target, radius: radius);
    // The blade sweeps across the target, square to the lunge.
    final start = heading + math.pi / 2 + 0.9;
    final sweep = -1.8 * math.min(1.0, progress * 2.5);
    canvas.drawArc(
      arc,
      start,
      sweep,
      false,
      Paint()
        ..color = color.withValues(alpha: 0.5 * fade)
        ..style = PaintingStyle.stroke
        ..strokeWidth = size * 0.16
        ..strokeCap = StrokeCap.round
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, size * 0.06),
    );
    canvas.drawArc(
      arc,
      start,
      sweep,
      false,
      Paint()
        ..color = Color.lerp(color, _white, 0.5)!
            .withValues(alpha: 0.95 * fade)
        ..style = PaintingStyle.stroke
        ..strokeWidth = size * 0.06
        ..strokeCap = StrokeCap.round,
    );
    _star(canvas, target, size * 0.28 * (0.6 + 0.4 * fade),
        _white.withValues(alpha: fade));
  }

  /// A block: a yellow-white burst of sparks at [at], where the blow met
  /// the shield. [progress] 0–1.
  static void blockSpark(
    Canvas canvas, {
    required Offset at,
    required double size,
    required double progress,
    required int seed,
  }) {
    if (progress <= 0 || progress >= 1) return;
    final fade = 1 - progress;
    canvas.drawCircle(
      at,
      size * 0.22 * (0.5 + progress),
      Paint()
        ..color = const Color(0xFFFFF59D).withValues(alpha: 0.6 * fade)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, size * 0.08),
    );
    final random = math.Random(seed);
    final spark = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(1.0, size * 0.03);
    for (var i = 0; i < 10; i++) {
      final angle = random.nextDouble() * 2 * math.pi;
      final reach = size * (0.2 + 0.35 * random.nextDouble());
      final dir = Offset(math.cos(angle), math.sin(angle));
      final inner = at + dir * reach * progress;
      final outer = at + dir * reach * (0.25 + progress);
      spark.color = Color.lerp(const Color(0xFFFFEB3B), _white,
              random.nextDouble())!
          .withValues(alpha: fade);
      canvas.drawLine(inner, outer, spark);
    }
    _star(canvas, at, size * 0.16 * fade, _white.withValues(alpha: fade));
  }

  static void _star(Canvas canvas, Offset at, double radius, Color color) {
    if (radius <= 0) return;
    final path = Path();
    const points = 4;
    for (var i = 0; i < points * 2; i++) {
      final r = i.isEven ? radius : radius * 0.25;
      final angle = i * math.pi / points - math.pi / 2;
      final p = at + Offset(math.cos(angle), math.sin(angle)) * r;
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }
}
