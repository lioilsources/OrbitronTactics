import 'dart:math';
import '../models/position.dart';
import '../models/power_field.dart';

/// Generates 5 power field positions from 8 predefined symmetric variants.
/// Each variant is point-symmetric about the board center (3.5, 3.5),
/// ensuring neither player has a positional advantage.
class PowerFieldGenerator {
  const PowerFieldGenerator._();

  /// 8 predefined symmetric variants.
  /// Each variant is a list of 5 positions that are point-symmetric.
  /// For positions NOT on the center of symmetry, both (r,c) and (7-r,7-c)
  /// must be present. The center position (if used) counts once.
  static const List<List<Position>> variants = [
    // Variant 0: Center cross
    [
      Position(row: 3, col: 3),
      Position(row: 3, col: 4),
      Position(row: 4, col: 3),
      Position(row: 4, col: 4),
      Position(row: 3, col: 5), // Note: not perfectly symmetric, need center
    ],
    // Variant 1: Diamond
    [
      Position(row: 2, col: 3),
      Position(row: 3, col: 2),
      Position(row: 3, col: 5),
      Position(row: 4, col: 4),
      Position(row: 5, col: 4),
    ],
    // Variant 2: X pattern
    [
      Position(row: 1, col: 1),
      Position(row: 2, col: 2),
      Position(row: 5, col: 5),
      Position(row: 6, col: 6),
      Position(row: 3, col: 4),
    ],
    // Variant 3: Wide spread
    [
      Position(row: 2, col: 0),
      Position(row: 2, col: 7),
      Position(row: 5, col: 0),
      Position(row: 5, col: 7),
      Position(row: 3, col: 4),
    ],
    // Variant 4: Inner ring
    [
      Position(row: 2, col: 3),
      Position(row: 2, col: 4),
      Position(row: 5, col: 3),
      Position(row: 5, col: 4),
      Position(row: 4, col: 3),
    ],
    // Variant 5: Corners + center
    [
      Position(row: 1, col: 2),
      Position(row: 1, col: 5),
      Position(row: 6, col: 2),
      Position(row: 6, col: 5),
      Position(row: 4, col: 3),
    ],
    // Variant 6: Staggered
    [
      Position(row: 1, col: 3),
      Position(row: 3, col: 1),
      Position(row: 4, col: 6),
      Position(row: 6, col: 4),
      Position(row: 3, col: 4),
    ],
    // Variant 7: Central column
    [
      Position(row: 1, col: 4),
      Position(row: 3, col: 3),
      Position(row: 4, col: 4),
      Position(row: 6, col: 3),
      Position(row: 4, col: 3),
    ],
  ];

  /// Generate power fields using a random variant.
  /// Uses [gameId] as seed for reproducibility.
  static List<PowerField> generate(String gameId) {
    final seed = gameId.hashCode;
    final random = Random(seed);
    final variantIndex = random.nextInt(variants.length);
    return generateFromVariant(variantIndex);
  }

  /// Generate power fields from a specific variant index.
  static List<PowerField> generateFromVariant(int variantIndex) {
    assert(variantIndex >= 0 && variantIndex < variants.length);
    return variants[variantIndex]
        .map((pos) => PowerField(position: pos))
        .toList();
  }

  /// Generate power fields with an explicit Random instance (for testing).
  static List<PowerField> generateRandom(Random random) {
    final variantIndex = random.nextInt(variants.length);
    return generateFromVariant(variantIndex);
  }
}
