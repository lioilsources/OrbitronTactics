/// The 3×3 gesture grid, numbered like a phone keypad's rows:
///
///     0 1 2
///     3 4 5
///     6 7 8
///
/// The rules are Android's lock pattern: at least three different dots, and
/// dragging across a dot picks it up. A pattern that skips an unvisited dot
/// in between could never be drawn, so the catalog must not contain one.
class Pattern {
  const Pattern._();

  static const int side = 3;
  static const int dots = side * side;

  static int rowOf(int dot) => dot ~/ side;
  static int columnOf(int dot) => dot % side;

  /// The dot a straight drag from [from] to [to] passes over, or null when
  /// the two are neighbours or a knight's move apart.
  static int? between(int from, int to) {
    final rowSum = rowOf(from) + rowOf(to);
    final columnSum = columnOf(from) + columnOf(to);
    if (rowSum.isOdd || columnSum.isOdd) return null;
    final middle = (rowSum ~/ 2) * side + columnSum ~/ 2;
    return middle == from || middle == to ? null : middle;
  }

  /// Whether [gesture] can be drawn on the grid: three or more dots, none
  /// repeated, and every dot passed over already visited.
  static bool isValid(List<int> gesture) {
    if (gesture.length < 3) return false;
    if (gesture.any((dot) => dot < 0 || dot >= dots)) return false;
    if (gesture.toSet().length != gesture.length) return false;
    for (var i = 1; i < gesture.length; i++) {
      final skipped = between(gesture[i - 1], gesture[i]);
      if (skipped != null && !gesture.take(i).contains(skipped)) return false;
    }
    return true;
  }

  /// [gesture] flipped left to right — the mirror of a maneuver.
  static List<int> mirror(List<int> gesture) => [
        for (final dot in gesture)
          rowOf(dot) * side + (side - 1 - columnOf(dot)),
      ];

  static bool same(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
