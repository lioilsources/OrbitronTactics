import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/maneuvers/maneuver_pattern.dart';

/// A gesture drawn small: the dots it runs through, joined in order, with a
/// head at the end so its direction shows.
class PatternGlyph extends StatelessWidget {
  const PatternGlyph({
    super.key,
    required this.pattern,
    required this.color,
    this.size = 28,
    this.dimmed = false,
  });

  final List<int> pattern;
  final Color color;
  final double size;
  final bool dimmed;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _GlyphPainter(
            pattern,
            dimmed ? color.withValues(alpha: 0.3) : color,
          ),
        ),
      );
}

class _GlyphPainter extends CustomPainter {
  _GlyphPainter(this.pattern, this.color);

  final List<int> pattern;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    Offset dotAt(int dot) => Offset(
          size.width * (0.2 + 0.3 * Pattern.columnOf(dot)),
          size.height * (0.2 + 0.3 * Pattern.rowOf(dot)),
        );
    final unit = size.shortestSide;

    final rest = Paint()..color = color.withValues(alpha: 0.25);
    for (var dot = 0; dot < Pattern.dots; dot++) {
      canvas.drawCircle(dotAt(dot), unit * 0.05, rest);
    }
    if (pattern.length < 2) return;

    final start = dotAt(pattern.first);
    final line = Path()..moveTo(start.dx, start.dy);
    for (final dot in pattern.skip(1)) {
      final at = dotAt(dot);
      line.lineTo(at.dx, at.dy);
    }
    canvas.drawPath(
      line,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = unit * 0.07
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawCircle(start, unit * 0.07, Paint()..color = color);

    // Where the gesture ends up
    final end = dotAt(pattern.last);
    final previous = dotAt(pattern[pattern.length - 2]);
    final angle = math.atan2(end.dy - previous.dy, end.dx - previous.dx);
    final head = unit * 0.17;
    canvas.drawPath(
      Path()
        ..moveTo(end.dx + math.cos(angle) * head * 0.7,
            end.dy + math.sin(angle) * head * 0.7)
        ..lineTo(end.dx + math.cos(angle + 2.5) * head,
            end.dy + math.sin(angle + 2.5) * head)
        ..lineTo(end.dx + math.cos(angle - 2.5) * head,
            end.dy + math.sin(angle - 2.5) * head)
        ..close(),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_GlyphPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.pattern != pattern;
}
