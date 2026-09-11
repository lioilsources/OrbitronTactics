import '../../../core/game_logic/models/piece.dart';

/// What a unit's shots are made of: it decides how they fly and explode.
enum BattleElement {
  /// Pawns fire plain slugs.
  kinetic,

  /// Knights.
  water,

  /// Bishops.
  fire,

  /// Rooks.
  ice,

  /// Queens and kings.
  electric;

  static BattleElement of(PieceType type) => switch (type) {
        PieceType.pawn => kinetic,
        PieceType.knight => water,
        PieceType.bishop => fire,
        PieceType.rook => ice,
        PieceType.queen || PieceType.king => electric,
      };
}
