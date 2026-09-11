import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/battle_element.dart';

/// Procedural explosions, one look per [BattleElement]: sparks off a slug,
/// a splash of water, a fireball, flying ice shards, an electric burst.
class ExplosionFx {
  const ExplosionFx._();

  /// Paints [element]'s explosion around [center], [radius] across at its
  /// fullest and [progress] of the way through (0–1). The same [seed] keeps
  /// an explosion's particles in place from frame to frame.
  static void paint(
    Canvas canvas,
    Offset center, {
    required BattleElement element,
    required double radius,
    required double progress,
    required int seed,
  }) {
    if (progress <= 0 || progress >= 1 || radius <= 0) return;
    final burst = _Burst(canvas, center, radius, progress, seed);
    switch (element) {
      case BattleElement.kinetic:
        burst.kinetic();
      case BattleElement.water:
        burst.water();
      case BattleElement.fire:
        burst.fire();
      case BattleElement.ice:
        burst.ice();
      case BattleElement.electric:
        burst.electric();
    }
  }
}

class _Burst {
  _Burst(this.canvas, this.center, this.radius, this.t, this.seed);

  final Canvas canvas;
  final Offset center;
  final double radius;

  /// Progress, 0–1.
  final double t;
  final int seed;

  /// Fast start, slow finish.
  double get _out => 1 - math.pow(1 - t, 3).toDouble();
  double get _fade => 1 - t;

  /// A fresh generator with the explosion's seed: the same particles every
  /// frame.
  math.Random get _particles => math.Random(seed);

  Offset _polar(double angle, double distance) =>
      center + Offset(math.cos(angle), math.sin(angle)) * distance;

  static Paint _fill(Color color, double alpha, {double blur = 0}) {
    final paint = Paint()
      ..color = color.withValues(alpha: alpha.clamp(0.0, 1.0));
    if (blur > 0) paint.maskFilter = MaskFilter.blur(BlurStyle.normal, blur);
    return paint;
  }

  static Paint _stroke(Color color, double alpha, double width) => Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..color = color.withValues(alpha: alpha.clamp(0.0, 1.0));

  /// A white flash with sparks and debris flying off.
  void kinetic() {
    final random = _particles;
    // The flash burns out fast, from yellow to orange; a lingering faded
    // yellow would turn green on the dark arena.
    final flash = math.pow(_fade, 3).toDouble();
    canvas.drawCircle(center, radius * (0.25 + 0.35 * _out),
        _fill(Colors.white, flash, blur: radius * 0.15));
    canvas.drawCircle(
      center,
      radius * 0.3 * _fade,
      _fill(Color.lerp(Colors.yellowAccent, Colors.deepOrange, t)!, flash),
    );

    final sparkColor = Color.lerp(Colors.yellowAccent, Colors.orange, t)!;
    for (var i = 0; i < 12; i++) {
      final angle = random.nextDouble() * 2 * math.pi;
      final reach = radius * (0.5 + 0.5 * random.nextDouble()) * _out;
      canvas.drawLine(
        _polar(angle, reach * 0.6),
        _polar(angle, reach),
        _stroke(sparkColor, _fade, math.max(1.0, radius * 0.06) * _fade),
      );
    }
    for (var i = 0; i < 6; i++) {
      final angle = random.nextDouble() * 2 * math.pi;
      canvas.drawCircle(
        _polar(angle, radius * 0.8 * _out * random.nextDouble()),
        radius * 0.05,
        _fill(Colors.blueGrey.shade300, _fade),
      );
    }
  }

  /// A mist of spray with splash rings and droplets.
  void water() {
    final random = _particles;
    final mist = radius * (0.4 + 0.6 * _out);
    canvas.drawCircle(
      center,
      mist,
      Paint()
        ..shader = RadialGradient(colors: [
          Colors.white.withValues(alpha: 0.45 * _fade),
          Colors.lightBlueAccent.withValues(alpha: 0.35 * _fade),
          Colors.lightBlueAccent.withValues(alpha: 0),
        ]).createShader(Rect.fromCircle(center: center, radius: mist)),
    );
    canvas.drawCircle(center, radius * _out,
        _stroke(Colors.lightBlueAccent, _fade, radius * 0.12 * _fade));
    canvas.drawCircle(center, radius * 0.6 * _out,
        _stroke(Colors.white, 0.8 * _fade, radius * 0.06 * _fade));

    for (var i = 0; i < 16; i++) {
      final angle = random.nextDouble() * 2 * math.pi;
      final reach = radius * (0.3 + 0.9 * random.nextDouble());
      final size = radius * (0.04 + 0.06 * random.nextDouble()) * _fade;
      final color =
          Color.lerp(Colors.white, Colors.blueAccent, random.nextDouble())!;
      canvas.drawCircle(_polar(angle, reach * _out), size, _fill(color, _fade));
    }
  }

  /// A fireball with flames licking outward, then smoke.
  void fire() {
    final random = _particles;
    final ball = radius * (0.3 + 0.7 * _out);
    final heat = t < 0.35 ? 1.0 : 1 - (t - 0.35) / 0.65;
    // The fireball cools from white-hot to a dull red; faded yellow would
    // turn green on the dark arena.
    final cooling = (t / 0.6).clamp(0.0, 1.0);
    canvas.drawCircle(
      center,
      ball,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Color.lerp(Colors.white, Colors.orangeAccent, cooling)!
                .withValues(alpha: heat),
            Color.lerp(Colors.yellowAccent, Colors.deepOrange, cooling)!
                .withValues(alpha: heat),
            Color.lerp(Colors.deepOrange, Colors.red.shade800, cooling)!
                .withValues(alpha: 0.8 * heat),
            Colors.red.shade900.withValues(alpha: 0),
          ],
          stops: const [0, 0.25, 0.6, 1],
        ).createShader(Rect.fromCircle(center: center, radius: ball)),
    );

    final flameColor = Color.lerp(Colors.yellow, Colors.red, t)!;
    for (var i = 0; i < 14; i++) {
      final angle = random.nextDouble() * 2 * math.pi;
      final reach = radius * (0.4 + 0.6 * random.nextDouble());
      final size = radius * (0.1 + 0.12 * random.nextDouble()) * _fade;
      canvas.drawCircle(
          _polar(angle, reach * _out), size, _fill(flameColor, _fade));
    }

    if (t > 0.3) {
      final smoke = (t - 0.3) / 0.7;
      for (var i = 0; i < 6; i++) {
        final angle = random.nextDouble() * 2 * math.pi;
        canvas.drawCircle(
          _polar(angle, radius * 0.6 * smoke),
          radius * (0.2 + 0.2 * smoke),
          _fill(Colors.grey.shade800, 0.35 * _fade, blur: radius * 0.1),
        );
      }
    }
  }

  /// A cold flash, a six-sided frost ring and shards spinning away.
  void ice() {
    final random = _particles;
    const frost = Color(0xFFB8F4FF);
    canvas.drawCircle(center, radius * 0.5,
        _fill(const Color(0xFFE0FAFF), math.pow(_fade, 3).toDouble(),
            blur: radius * 0.2));

    final ring = Path();
    for (var i = 0; i < 6; i++) {
      final corner = _polar(i * math.pi / 3, radius * 0.85 * _out);
      if (i == 0) {
        ring.moveTo(corner.dx, corner.dy);
      } else {
        ring.lineTo(corner.dx, corner.dy);
      }
    }
    canvas.drawPath(
        ring..close(), _stroke(frost, _fade, radius * 0.05 * _fade));

    for (var i = 0; i < 10; i++) {
      final angle = random.nextDouble() * 2 * math.pi;
      final reach = radius * (0.35 + 0.65 * random.nextDouble());
      final length = radius * (0.18 + 0.18 * random.nextDouble());
      final spin = (random.nextDouble() - 0.5) * 6;
      final at = _polar(angle, reach * _out);
      final shard = Path()
        ..moveTo(0, -length / 2)
        ..lineTo(length * 0.18, 0)
        ..lineTo(0, length / 2)
        ..lineTo(-length * 0.18, 0)
        ..close();
      canvas
        ..save()
        ..translate(at.dx, at.dy)
        ..rotate(angle + math.pi / 2 + spin * t)
        ..drawPath(shard, _fill(Colors.white, 0.9 * _fade))
        ..drawPath(shard, _stroke(Colors.lightBlueAccent, _fade, 1))
        ..restore();
    }
  }

  /// A flash and shock ring with crackling bolts forking outward.
  void electric() {
    final random = _particles;
    // The bolts' shape re-forks every sixteenth of the explosion.
    final crackle = math.Random(seed * 31 + (t * 16).floor());

    canvas.drawCircle(center, radius * (0.2 + 0.3 * _fade),
        _fill(Colors.white, _fade * _fade, blur: radius * 0.2));
    canvas.drawCircle(center, radius * _out,
        _stroke(Colors.cyanAccent, _fade, radius * 0.06 * _fade));

    const segments = 5;
    for (var i = 0; i < 7; i++) {
      final angle = random.nextDouble() * 2 * math.pi;
      final reach =
          radius * (0.6 + 0.4 * random.nextDouble()) * (0.35 + 0.65 * _out);
      final across = Offset(-math.sin(angle), math.cos(angle));
      final bolt = Path()..moveTo(center.dx, center.dy);
      for (var s = 1; s <= segments; s++) {
        final point = _polar(angle, reach * s / segments) +
            across * (crackle.nextDouble() - 0.5) * radius * 0.25;
        bolt.lineTo(point.dx, point.dy);
      }
      canvas.drawPath(
        bolt,
        _stroke(Colors.cyanAccent, 0.5 * _fade, radius * 0.1 * _fade)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.05),
      );
      canvas.drawPath(
          bolt, _stroke(Colors.white, _fade, math.max(1.0, radius * 0.035)));
    }

    for (var i = 0; i < 8; i++) {
      final angle = random.nextDouble() * 2 * math.pi;
      canvas.drawCircle(
        _polar(angle, radius * _out * random.nextDouble()),
        radius * 0.03,
        _fill(Colors.white, _fade),
      );
    }
  }
}
