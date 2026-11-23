import '../board/board_spec.dart';
import '../models/formation.dart';
import '../models/piece.dart';

/// Validates a player's starting formation.
class FormationValidator {
  const FormationValidator._();

  /// Validates a formation. Returns null if valid, or an error message.
  static String? validate(
    Formation formation,
    PlayerColor color, {
    BoardSpec spec = BoardSpec.classic8,
  }) {
    final placements = formation.placements;

    // Check total piece count
    if (placements.length != spec.armySize) {
      return 'Must place exactly ${spec.armySize} pieces '
          '(got ${placements.length})';
    }

    // Check all pieces are within the player's starting rows
    final validRows = spec.formationRowsFor(color);
    for (final p in placements) {
      if (!validRows.contains(p.position.row)) {
        return 'Piece at ${p.position} is not in your starting rows';
      }
      if (!spec.geometry.contains(p.position)) {
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

    for (final entry in spec.army.entries) {
      final actual = counts[entry.key] ?? 0;
      if (actual != entry.value) {
        return 'Need ${entry.value} ${entry.key.name}(s), got $actual';
      }
    }

    return null; // Valid
  }
}
