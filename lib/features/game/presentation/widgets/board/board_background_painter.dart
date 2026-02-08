import 'package:flutter/material.dart';
import '../../../../../core/game_logic/models/board_state.dart';
import '../../../../../core/game_logic/models/piece.dart';
import '../../../../../core/game_logic/models/power_field.dart';
import '../../../../../core/theme/board_theme.dart';

/// CustomPainter that draws the board squares and power field highlights.
class BoardBackgroundPainter extends CustomPainter {
  final List<PowerField> powerFields;
  final BoardState board;
  final double glowOpacity;
  final bool flipBoard;

  const BoardBackgroundPainter({
    required this.powerFields,
    required this.board,
    required this.glowOpacity,
    this.flipBoard = false,
  });

  int _vRow(int r) => flipBoard ? 7 - r : r;
  int _vCol(int c) => flipBoard ? 7 - c : c;

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

    // Draw power field highlights with ownership coloring and animated glow
    for (final pf in powerFields) {
      final vr = _vRow(pf.position.row);
      final vc = _vCol(pf.position.col);
      final rect = Rect.fromLTWH(
        vc * squareSize,
        vr * squareSize,
        squareSize,
        squareSize,
      );

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
      canvas.drawRect(rect, pfPaint);

      // Border
      final pfBorderPaint = Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawRect(rect.deflate(1), pfBorderPaint);

      // Diamond symbol in center
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
        Paint()..color = borderColor.withValues(alpha: 0.5),
      );
    }
  }

  @override
  bool shouldRepaint(BoardBackgroundPainter oldDelegate) {
    return powerFields != oldDelegate.powerFields ||
        board != oldDelegate.board ||
        glowOpacity != oldDelegate.glowOpacity ||
        flipBoard != oldDelegate.flipBoard;
  }
}
