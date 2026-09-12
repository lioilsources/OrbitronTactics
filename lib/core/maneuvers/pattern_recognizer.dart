import 'maneuver_pattern.dart';

/// Collects a gesture from a finger dragging over the 3×3 grid, in the unit
/// square: (0,0) is the top left corner of the pad, (1,1) the bottom right.
///
/// Behaves like Android's lock pattern — a dot joins the gesture when the
/// finger comes close enough, and dragging across an unvisited dot picks it
/// up on the way.
class PatternRecognizer {
  PatternRecognizer({this.hitRadius = 0.18});

  /// How close to a dot's centre the finger has to come, as a fraction of
  /// the pad's side.
  final double hitRadius;

  final List<int> _gesture = [];

  /// The dots collected so far, in order.
  List<int> get gesture => List.unmodifiable(_gesture);

  bool get isEmpty => _gesture.isEmpty;

  /// The centre of [dot] in the unit square.
  static (double x, double y) centreOf(int dot) =>
      (0.2 + 0.3 * Pattern.columnOf(dot), 0.2 + 0.3 * Pattern.rowOf(dot));

  void reset() => _gesture.clear();

  /// Feeds the finger's position; call on every touch and move event.
  void touch(double x, double y) {
    final dot = _dotAt(x, y);
    if (dot == null || _gesture.contains(dot)) return;
    final last = _gesture.isEmpty ? null : _gesture.last;
    if (last != null) {
      final skipped = Pattern.between(last, dot);
      if (skipped != null && !_gesture.contains(skipped)) _gesture.add(skipped);
    }
    _gesture.add(dot);
  }

  /// Ends the gesture and returns it, or an empty list when it is too short
  /// to be one.
  List<int> end() {
    final drawn = _gesture.length < 3 ? <int>[] : List<int>.from(_gesture);
    _gesture.clear();
    return drawn;
  }

  int? _dotAt(double x, double y) {
    for (var dot = 0; dot < Pattern.dots; dot++) {
      final (centreX, centreY) = centreOf(dot);
      final dx = x - centreX;
      final dy = y - centreY;
      if (dx * dx + dy * dy <= hitRadius * hitRadius) return dot;
    }
    return null;
  }
}
