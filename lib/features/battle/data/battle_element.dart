import 'package:flutter/painting.dart';

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

  /// What its shots, bursts, engine flame and maneuver pad are drawn in.
  Color get color => switch (this) {
        BattleElement.kinetic => const Color(0xFFFFFF8D),
        BattleElement.water => const Color(0xFF40A8FF),
        BattleElement.fire => const Color(0xFFFF6E40),
        BattleElement.ice => const Color(0xFFB8F4FF),
        BattleElement.electric => const Color(0xFF18FFFF),
      };
}
