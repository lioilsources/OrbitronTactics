import 'package:flutter/material.dart';
import '../../../../../core/game_logic/models/board_state.dart';
import '../../../../../core/game_logic/models/position.dart';
import '../../../../../core/theme/board_theme.dart';
import 'board_layout.dart';

/// CustomPainter that draws selection highlights, valid move indicators,
/// and last move highlights on top of the board.
class BoardOverlayPainter extends CustomPainter {
  final Position? selectedPosition;
  final List<Position> validMoves;
  final Position? lastMoveFrom;
  final Position? lastMoveTo;
  final BoardState board;
  final bool flipBoard;

  const BoardOverlayPainter({
    required this.selectedPosition,
    required this.validMoves,
    required this.lastMoveFrom,
    required this.lastMoveTo,
    required this.board,
    this.flipBoard = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final layout =
        BoardLayout.fit(board.geometry, size.width, flipped: flipBoard);

    void highlight(Position pos, Color color) =>
        canvas.drawPath(layout.cellPath(pos), Paint()..color = color);

    if (lastMoveFrom != null) {
      highlight(lastMoveFrom!, BoardTheme.lastMoveHighlight);
    }
    if (lastMoveTo != null) {
      highlight(lastMoveTo!, BoardTheme.lastMoveHighlight);
    }
    if (selectedPosition != null) {
      highlight(selectedPosition!, BoardTheme.selectedSquare);
    }

    for (final move in validMoves) {
      if (board.pieceAt(move) != null) {
        _drawCaptureIndicator(canvas, layout, move);
      } else {
        canvas.drawCircle(
          layout.centreOf(move),
          layout.cellSize * 0.15,
          Paint()..color = BoardTheme.validMoveIndicator,
        );
      }
    }
  }

  void _drawCaptureIndicator(Canvas canvas, BoardLayout layout, Position pos) {
    final paint = Paint()
      ..color = BoardTheme.captureIndicator
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    if (layout.isHex) {
      canvas.drawPath(
          layout.cellPath(pos, inset: layout.cellSize * 0.06), paint);
      return;
    }

    final rect = layout.pieceBox(pos);
    final cornerSize = layout.cellSize * 0.25;
    final inset = layout.cellSize * 0.05;
    final inner = rect.deflate(inset);
    for (final (corner, dx, dy) in [
      (inner.topLeft, 1.0, 1.0),
      (inner.topRight, -1.0, 1.0),
      (inner.bottomLeft, 1.0, -1.0),
      (inner.bottomRight, -1.0, -1.0),
    ]) {
      canvas.drawLine(corner, corner + Offset(dx * cornerSize, 0), paint);
      canvas.drawLine(corner, corner + Offset(0, dy * cornerSize), paint);
    }
  }

  @override
  bool shouldRepaint(BoardOverlayPainter oldDelegate) {
    return selectedPosition != oldDelegate.selectedPosition ||
        validMoves != oldDelegate.validMoves ||
        lastMoveFrom != oldDelegate.lastMoveFrom ||
        lastMoveTo != oldDelegate.lastMoveTo ||
        board != oldDelegate.board ||
        flipBoard != oldDelegate.flipBoard;
  }
}
