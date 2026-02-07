import 'package:flutter/material.dart';

class BoardTheme {
  const BoardTheme._();

  // Board square colors
  static const lightSquare = Color(0xFF8B7355);
  static const darkSquare = Color(0xFF5C4033);

  // Power field highlight
  static const powerFieldColor = Color(0x6000BCD4);
  static const powerFieldBorder = Color(0xFF00BCD4);

  // Selection & move highlights
  static const selectedSquare = Color(0x8800E676);
  static const validMoveIndicator = Color(0x6600E676);
  static const captureIndicator = Color(0x66FF5252);
  static const lastMoveHighlight = Color(0x44FFFF00);

  // Piece colors
  static const whitePieceColor = Color(0xFFF5F5F5);
  static const whitePieceBorder = Color(0xFFBDBDBD);
  static const blackPieceColor = Color(0xFF212121);
  static const blackPieceBorder = Color(0xFF424242);

  // Last Warrior glow
  static const lastWarriorGlow = Color(0xFFFF9800);
}
