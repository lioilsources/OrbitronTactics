import 'dart:ui';

import '../../../../../core/game_logic/models/position.dart';
import 'board_layout.dart';

/// How far from a preferred cell's centre a tap on [layout] still lands on
/// it, in cell widths, for [resolveTap]. Hex cells are small on a phone
/// (11 across), so a tap there snaps within 0.8 of a cell; the square
/// board keeps exact taps, as it always had.
double tapReachFor(BoardLayout layout) => layout.isHex ? 0.8 : 0;

/// The cell a tap at [point] means.
///
/// The cell under the finger wins when it is in [preferred] (cells where a
/// tap does something: move targets, the selected piece, own pieces with a
/// move). Otherwise the nearest [preferred] cell whose centre lies within
/// [reach] × [BoardLayout.cellSize] of the finger. Otherwise the cell
/// under the finger, or null off the board.
///
/// [reach] stays below 1.0: a neighbour's centre is one cell width away,
/// so a tap in the middle of an empty cell never snaps to it.
Position? resolveTap(
  BoardLayout layout,
  Offset point, {
  required Set<Position> preferred,
  double reach = 0.8,
}) {
  assert(reach < 1.0, 'reach must stay below one cell width');
  final exact = layout.positionAt(point);
  if (exact != null && preferred.contains(exact)) return exact;
  if (reach <= 0) return exact;

  final limit = reach * layout.cellSize;
  Position? best;
  var bestDistance = limit * limit;
  for (final p in preferred) {
    final d = (layout.centreOf(p) - point).distanceSquared;
    if (d < bestDistance || (best == null && d == bestDistance)) {
      bestDistance = d;
      best = p;
    }
  }
  return best ?? exact;
}
