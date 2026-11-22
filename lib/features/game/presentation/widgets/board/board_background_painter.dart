import 'package:flutter/material.dart';
import '../../../../../core/game_logic/models/board_state.dart';
import '../../../../../core/game_logic/models/piece.dart';
import '../../../../../core/game_logic/models/power_field.dart';
import '../../../../../core/theme/board_theme.dart';
import 'board_layout.dart';

/// CustomPainter that draws the board squares and power field highlights.
class BoardBackgroundPainter extends CustomPainter {
  final List<PowerField> powerFields;
  final BoardState board;
  final double glowOpacity;
  final bool flipBoard;

  /// Square colors; a piece skin pack brings its own.
  final Color lightSquare;
  final Color darkSquare;

  const BoardBackgroundPainter({
    required this.powerFields,
    required this.board,
    required this.glowOpacity,
    this.flipBoard = false,
    this.lightSquare = BoardTheme.lightSquare,
    this.darkSquare = BoardTheme.darkSquare,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final layout =
        BoardLayout.fit(board.geometry, size.width, flipped: flipBoard);
    final shades = layout.isHex
        ? [lightSquare, Color.lerp(lightSquare, darkSquare, 0.5)!, darkSquare]
        : [lightSquare, darkSquare];

    for (final cell in board.geometry.cells) {
      canvas.drawPath(
        layout.cellPath(cell),
        Paint()..color = shades[layout.shadeOf(cell)],
      );
    }

    // Draw power field highlights with ownership coloring and animated glow
    for (final pf in powerFields) {
      final outline = layout.cellPath(pf.position);

      // Determine owner color
      final piece = board.pieceAt(pf.position);
      Color fieldColor;
      Color borderColor;
      if (piece != null && piece.color == PlayerColor.white) {
        fieldColor = BoardTheme.powerFieldWhiteOwned;
        borderColor = BoardTheme.powerFieldWhiteBorder;
      } else if (piece != null && piece.color == PlayerColor.black) {
        fieldColor = BoardTheme.powerFieldBlackOwned;
        borderColor = BoardTheme.powerFieldBlackBorder;
      } else {
        fieldColor = BoardTheme.powerFieldColor;
        borderColor = BoardTheme.powerFieldBorder;
      }

      // Fill with animated opacity
      final pfPaint = Paint()..color = fieldColor.withValues(alpha: glowOpacity);
      canvas.drawPath(outline, pfPaint);

      // Border
      final pfBorderPaint = Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawPath(layout.cellPath(pf.position, inset: 1), pfBorderPaint);

      // Diamond symbol in center
      final center = layout.centreOf(pf.position);
      final diamondSize = layout.cellSize * 0.15;
      final diamondPath = Path()
        ..moveTo(center.dx, center.dy - diamondSize)
        ..lineTo(center.dx + diamondSize, center.dy)
        ..lineTo(center.dx, center.dy + diamondSize)
        ..lineTo(center.dx - diamondSize, center.dy)
        ..close();
      canvas.drawPath(
        diamondPath,
        Paint()..color = borderColor.withValues(alpha: 0.5),
      );
    }
  }

  @override
  bool shouldRepaint(BoardBackgroundPainter oldDelegate) {
    return powerFields != oldDelegate.powerFields ||
        board != oldDelegate.board ||
        glowOpacity != oldDelegate.glowOpacity ||
        flipBoard != oldDelegate.flipBoard ||
        lightSquare != oldDelegate.lightSquare ||
        darkSquare != oldDelegate.darkSquare;
  }
}
