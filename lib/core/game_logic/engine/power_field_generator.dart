import 'dart:math';
import '../board/board_geometry.dart';
import '../board/board_spec.dart';
import '../models/position.dart';
import '../models/power_field.dart';

/// Generates the power fields of a game.
///
/// The classic board picks one of 8 predefined variants (kept as they are,
/// although not all of them are exactly symmetric). Other boards without
/// fixed variants get [symmetric] fields: half picked at random, the other
/// half their point mirror, plus one central field for an odd count.
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

  /// Generate power fields for a game on [spec].
  /// Uses [gameId] as seed for reproducibility.
  static List<PowerField> generate(
    String gameId, {
    BoardSpec spec = BoardSpec.classic8,
  }) {
    final seed = gameId.hashCode;
    final random = Random(seed);
    return generateFor(spec, random);
  }

  /// Power fields for a game on [spec], drawn from [random].
  static List<PowerField> generateFor(BoardSpec spec, Random random) {
    final fixed = spec.powerFieldVariants;
    if (fixed != null) {
      return [
        for (final pos in fixed[random.nextInt(fixed.length)])
          PowerField(position: pos),
      ];
    }
    return [
      for (final pos in symmetric(spec.geometry, spec.powerFieldCount, random,
          marginRows: spec.formationRows))
        PowerField(position: pos),
    ];
  }

  /// [count] point-symmetric fields on [geometry], outside the first
  /// [marginRows] rows of either side. For an odd count one field is a
  /// cell closest to the board's centre; when the board has no cell on the
  /// centre itself, that one field is the only asymmetry.
  static List<Position> symmetric(
    BoardGeometry geometry,
    int count,
    Random random, {
    int marginRows = 2,
  }) {
    final band = [
      for (final cell in geometry.cells)
        if (cell.row >= marginRows && cell.row < geometry.rows - marginRows)
          cell,
    ];

    final fields = <Position>[];
    Position? centre;
    if (count.isOdd) {
      final nearest = band
          .map(geometry.distanceFromCentre)
          .reduce(min);
      final candidates = [
        for (final cell in band)
          if (geometry.distanceFromCentre(cell) - nearest < 1e-9) cell,
      ];
      centre = candidates[random.nextInt(candidates.length)];
    }

    // One representative per mirror pair.
    final pool = [
      for (final cell in band)
        if (geometry.indexOf(cell) < geometry.indexOf(geometry.mirror(cell)) &&
            geometry.contains(geometry.mirror(cell)) &&
            cell != centre &&
            geometry.mirror(cell) != centre)
          cell,
    ];
    final pairs = count ~/ 2;
    if (pool.length < pairs) {
      throw ArgumentError('Board too small for $count power fields');
    }
    for (var i = 0; i < pairs; i++) {
      final cell = pool.removeAt(random.nextInt(pool.length));
      fields
        ..add(cell)
        ..add(geometry.mirror(cell));
    }
    if (centre != null) fields.add(centre);
    return fields;
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
