import '../models/formation.dart';
import '../models/piece.dart';

/// Validates a player's starting formation.
class FormationValidator {
  const FormationValidator._();

  /// Validates a formation. Returns null if valid, or an error message.
  static String? validate(Formation formation, PlayerColor color) {
    final placements = formation.placements;

    // Check total piece count
    if (placements.length != 16) {
      return 'Must place exactly 16 pieces (got ${placements.length})';
    }

    // Check all pieces are within the player's first 2 rows
    final validRows = color == PlayerColor.white ? {0, 1} : {6, 7};
    for (final p in placements) {
      if (!validRows.contains(p.position.row)) {
        return 'Piece at ${p.position} is not in your starting rows';
      }
      if (p.position.col < 0 || p.position.col >= 8) {
        return 'Piece at ${p.position} is out of bounds';
      }
    }

    // Check no duplicate positions
    final positions = placements.map((p) => p.position).toSet();
    if (positions.length != placements.length) {
      return 'Multiple pieces on the same square';
    }

    // Check piece counts match requirements
    final counts = <PieceType, int>{};
    for (final p in placements) {
      if (p.piece.color != color) {
        return 'Cannot place opponent\'s piece';
      }
      counts[p.piece.type] = (counts[p.piece.type] ?? 0) + 1;
    }

    const required = {
      PieceType.pawn: 8,
      PieceType.rook: 2,
      PieceType.knight: 2,
      PieceType.bishop: 2,
      PieceType.queen: 1,
      PieceType.king: 1,
    };

    for (final entry in required.entries) {
      final actual = counts[entry.key] ?? 0;
      if (actual != entry.value) {
        return 'Need ${entry.value} ${entry.key.name}(s), got $actual';
      }
    }

    return null; // Valid
  }
}
