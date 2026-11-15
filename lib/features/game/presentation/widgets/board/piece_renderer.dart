import 'package:flutter/material.dart';
import '../../../../../core/game_logic/models/piece.dart';
import '../../../../../core/theme/board_theme.dart';
import '../../../data/piece_skin.dart';

/// Renders a piece: in the [PieceSkin.classic] skin as a styled text symbol
/// with a colored circle background, in an image pack as its figure.
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

  /// [piece] in a [size]-wide square, drawn in [skin]. [classicMarks] adds
  /// the classic symbol in a corner of an image pack's figure.
  static Widget build(
    Piece piece,
    double size, {
    bool isThreatened = false,
    PieceSkin skin = PieceSkin.classic,
    bool classicMarks = false,
  }) {
    final pieceWidget = skin.isImagePack
        ? _imagePiece(piece, size, skin, classicMarks: classicMarks)
        : _classicPiece(piece, size);

    if (!isThreatened) return pieceWidget;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        pieceWidget,
        Positioned(
          right: -2,
          top: -2,
          child: Container(
            width: size * 0.3,
            height: size * 0.3,
            decoration: BoxDecoration(
              color: BoardTheme.threatBadgeColor,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1),
            ),
            child: Center(
              child: Text(
                '!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: size * 0.18,
                  fontWeight: FontWeight.bold,
                  height: 1.0,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  static Widget _classicPiece(Piece piece, double size) {
    final isWhite = piece.color == PlayerColor.white;
    final bgColor = isWhite ? BoardTheme.whitePieceColor : BoardTheme.blackPieceColor;
    final borderColor = isWhite ? BoardTheme.whitePieceBorder : BoardTheme.blackPieceBorder;
    final textColor = isWhite ? Colors.black87 : Colors.white;

    final pieceWidget = Container(
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

    return pieceWidget;
  }

  /// An image pack's figure, bottom-aligned in the square. The black army
  /// is mirrored so it faces the white one.
  static Widget _imagePiece(
    Piece piece,
    double size,
    PieceSkin skin, {
    required bool classicMarks,
  }) {
    final isWhite = piece.color == PlayerColor.white;
    final extent = size * 0.85;
    final asset = skin.assetFor(piece.type, piece.color)!;

    return SizedBox(
      width: extent,
      height: extent,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (piece.isLastWarrior)
            Positioned.fill(
              child: DecoratedBox(
                key: const ValueKey('last-warrior-glow'),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: BoardTheme.lastWarriorGlow.withValues(alpha: 0.25),
                  border: Border.all(
                      color: BoardTheme.lastWarriorGlow, width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: BoardTheme.lastWarriorGlow.withValues(alpha: 0.5),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
          Positioned.fill(
            child: Transform.flip(
              flipX: !isWhite,
              child: Image.asset(
                asset,
                fit: BoxFit.contain,
                alignment: Alignment.bottomCenter,
                // A missing figure falls back to the classic symbol.
                errorBuilder: (_, _, _) => Center(
                  child: Text(
                    symbol(piece.type),
                    style: TextStyle(
                      fontSize: size * 0.5,
                      color: isWhite ? Colors.white : Colors.black87,
                      height: 1.0,
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (classicMarks)
            Positioned(
              left: -2,
              bottom: -2,
              child: Container(
                key: const ValueKey('classic-mark'),
                width: size * 0.3,
                height: size * 0.3,
                decoration: BoxDecoration(
                  color: isWhite
                      ? BoardTheme.whitePieceColor
                      : BoardTheme.blackPieceColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isWhite
                        ? BoardTheme.whitePieceBorder
                        : BoardTheme.blackPieceBorder,
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    symbol(piece.type),
                    style: TextStyle(
                      fontSize: size * 0.2,
                      color: isWhite ? Colors.black87 : Colors.white,
                      height: 1.0,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
