import 'package:flutter/material.dart';
import '../../../../../core/game_logic/models/power_field.dart';
import '../../../../../core/theme/board_theme.dart';

/// CustomPainter that draws the board squares and power field highlights.
class BoardBackgroundPainter extends CustomPainter {
  final List<PowerField> powerFields;

  const BoardBackgroundPainter({required this.powerFields});

  @override
  void paint(Canvas canvas, Size size) {
    final squareSize = size.width / 8;

    // Draw squares
    for (int row = 0; row < 8; row++) {
      for (int col = 0; col < 8; col++) {
        final isLight = (row + col) % 2 == 0;
        final paint = Paint()
          ..color = isLight ? BoardTheme.lightSquare : BoardTheme.darkSquare;

        final rect = Rect.fromLTWH(
          col * squareSize,
          row * squareSize,
          squareSize,
          squareSize,
        );
        canvas.drawRect(rect, paint);
      }
    }

    // Draw power field highlights
    final pfPaint = Paint()..color = BoardTheme.powerFieldColor;
    final pfBorderPaint = Paint()
      ..color = BoardTheme.powerFieldBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    for (final pf in powerFields) {
      final rect = Rect.fromLTWH(
        pf.position.col * squareSize,
        pf.position.row * squareSize,
        squareSize,
        squareSize,
      );
      canvas.drawRect(rect, pfPaint);
      canvas.drawRect(rect.deflate(1), pfBorderPaint);

      // Draw a small diamond in the center of the power field
      final center = rect.center;
      final diamondSize = squareSize * 0.15;
      final diamondPath = Path()
        ..moveTo(center.dx, center.dy - diamondSize)
        ..lineTo(center.dx + diamondSize, center.dy)
        ..lineTo(center.dx, center.dy + diamondSize)
        ..lineTo(center.dx - diamondSize, center.dy)
        ..close();
      canvas.drawPath(
        diamondPath,
        Paint()..color = BoardTheme.powerFieldBorder.withValues(alpha: 0.5),
      );
    }
  }

  @override
  bool shouldRepaint(BoardBackgroundPainter oldDelegate) {
    return powerFields != oldDelegate.powerFields;
  }
}
