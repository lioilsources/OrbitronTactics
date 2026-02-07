import 'package:flutter/material.dart';
import '../../../../../core/game_logic/models/piece.dart';
import '../../../../../core/theme/board_theme.dart';

/// Renders a piece as a styled text symbol with a colored circle background.
/// This is a placeholder until proper SVG/PNG assets are available.
class PieceRenderer {
  const PieceRenderer._();

  static const _symbols = {
    PieceType.king: '\u2654',   // ♔
    PieceType.queen: '\u2655',  // ♕
    PieceType.rook: '\u2656',   // ♖
    PieceType.bishop: '\u2657', // ♗
    PieceType.knight: '\u2658', // ♘
    PieceType.pawn: '\u2659',   // ♙
  };

  static String symbol(PieceType type) => _symbols[type] ?? '?';

  static Widget build(Piece piece, double size) {
    final isWhite = piece.color == PlayerColor.white;
    final bgColor = isWhite ? BoardTheme.whitePieceColor : BoardTheme.blackPieceColor;
    final borderColor = isWhite ? BoardTheme.whitePieceBorder : BoardTheme.blackPieceBorder;
    final textColor = isWhite ? Colors.black87 : Colors.white;

    return Container(
      width: size * 0.85,
      height: size * 0.85,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        border: Border.all(
          color: piece.isLastWarrior ? BoardTheme.lastWarriorGlow : borderColor,
          width: piece.isLastWarrior ? 2.5 : 1.5,
        ),
        boxShadow: [
          if (piece.isLastWarrior)
            BoxShadow(
              color: BoardTheme.lastWarriorGlow.withValues(alpha: 0.5),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 2,
            offset: const Offset(1, 1),
          ),
        ],
      ),
      child: Center(
        child: Text(
          symbol(piece.type),
          style: TextStyle(
            fontSize: size * 0.5,
            color: textColor,
            height: 1.0,
          ),
        ),
      ),
    );
  }
}
