import 'dart:ui' show Size;

/// Where a ship sits in its half of the arena.
///
/// Altitude is the engine's hit dimension, and this is how it reads on a
/// screen seen from straight above: the lowest ship sits at its own edge,
/// the highest one just short of the divider. Steering forward covers the
/// same distance the finger does, so [travelFraction] is shared by the
/// painter and the arena's input.
class ArenaLayout {
  const ArenaLayout._();

  /// Gap between a ship at its lowest and its own edge of the arena, as a
  /// fraction of the arena height.
  static const double edgeMargin = 0.08;

  /// Gap between a ship at its highest and the divider.
  static const double frontMargin = 0.06;

  /// How much of the arena's height a ship crosses over the full altitude
  /// range.
  static const double travelFraction = 0.5 - edgeMargin - frontMargin;

  /// The y of a ship flying at [altitude] (0–1) in the half it fights from.
  static double shipY(
    double altitude, {
    required bool atBottom,
    required Size arena,
  }) {
    final travelled = altitude * travelFraction * arena.height;
    return atBottom
        ? arena.height * (1 - edgeMargin) - travelled
        : arena.height * edgeMargin + travelled;
  }
}
