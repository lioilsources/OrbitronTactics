import 'package:flutter/material.dart';
import '../../../../../core/game_logic/models/board_state.dart';
import '../../../../../core/game_logic/models/position.dart';
import '../../../../../core/theme/board_theme.dart';

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

  int _vRow(int r) => flipBoard ? 7 - r : r;
  int _vCol(int c) => flipBoard ? 7 - c : c;

  @override
  void paint(Canvas canvas, Size size) {
    final squareSize = size.width / 8;

    // Draw last move highlight
    if (lastMoveFrom != null) {
      _drawSquareHighlight(
          canvas, lastMoveFrom!, squareSize, BoardTheme.lastMoveHighlight);
    }
    if (lastMoveTo != null) {
      _drawSquareHighlight(
          canvas, lastMoveTo!, squareSize, BoardTheme.lastMoveHighlight);
    }

    // Draw selected square
    if (selectedPosition != null) {
      _drawSquareHighlight(
          canvas, selectedPosition!, squareSize, BoardTheme.selectedSquare);
    }

    // Draw valid move indicators
    for (final move in validMoves) {
      final isCapture = board.pieceAt(move) != null;
      if (isCapture) {
        _drawCaptureIndicator(canvas, move, squareSize);
      } else {
        _drawMoveIndicator(canvas, move, squareSize);
      }
    }
  }

  void _drawSquareHighlight(
    Canvas canvas,
    Position pos,
    double squareSize,
    Color color,
  ) {
    final rect = Rect.fromLTWH(
      _vCol(pos.col) * squareSize,
      _vRow(pos.row) * squareSize,
      squareSize,
      squareSize,
    );
    canvas.drawRect(rect, Paint()..color = color);
  }

  void _drawMoveIndicator(Canvas canvas, Position pos, double squareSize) {
    final center = Offset(
      _vCol(pos.col) * squareSize + squareSize / 2,
      _vRow(pos.row) * squareSize + squareSize / 2,
    );
    canvas.drawCircle(
      center,
      squareSize * 0.15,
      Paint()..color = BoardTheme.validMoveIndicator,
    );
  }

  void _drawCaptureIndicator(Canvas canvas, Position pos, double squareSize) {
    final rect = Rect.fromLTWH(
      _vCol(pos.col) * squareSize,
      _vRow(pos.row) * squareSize,
      squareSize,
      squareSize,
    );
    // Draw corner brackets
    final paint = Paint()
      ..color = BoardTheme.captureIndicator
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final cornerSize = squareSize * 0.25;
    final inset = squareSize * 0.05;

    // Top-left corner
    canvas.drawLine(
      Offset(rect.left + inset, rect.top + inset + cornerSize),
      Offset(rect.left + inset, rect.top + inset),
      paint,
    );
    canvas.drawLine(
      Offset(rect.left + inset, rect.top + inset),
      Offset(rect.left + inset + cornerSize, rect.top + inset),
      paint,
    );

    // Top-right corner
    canvas.drawLine(
      Offset(rect.right - inset - cornerSize, rect.top + inset),
      Offset(rect.right - inset, rect.top + inset),
      paint,
    );
    canvas.drawLine(
      Offset(rect.right - inset, rect.top + inset),
      Offset(rect.right - inset, rect.top + inset + cornerSize),
      paint,
    );

    // Bottom-left corner
    canvas.drawLine(
      Offset(rect.left + inset, rect.bottom - inset - cornerSize),
      Offset(rect.left + inset, rect.bottom - inset),
      paint,
    );
    canvas.drawLine(
      Offset(rect.left + inset, rect.bottom - inset),
      Offset(rect.left + inset + cornerSize, rect.bottom - inset),
      paint,
    );

    // Bottom-right corner
    canvas.drawLine(
      Offset(rect.right - inset - cornerSize, rect.bottom - inset),
      Offset(rect.right - inset, rect.bottom - inset),
      paint,
    );
    canvas.drawLine(
      Offset(rect.right - inset, rect.bottom - inset - cornerSize),
      Offset(rect.right - inset, rect.bottom - inset),
      paint,
    );
  }

  @override
  bool shouldRepaint(BoardOverlayPainter oldDelegate) {
    return selectedPosition != oldDelegate.selectedPosition ||
        validMoves != oldDelegate.validMoves ||
        lastMoveFrom != oldDelegate.lastMoveFrom ||
        lastMoveTo != oldDelegate.lastMoveTo ||
        flipBoard != oldDelegate.flipBoard;
  }
}
