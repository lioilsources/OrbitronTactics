import 'dart:ui';

import '../../../../../core/game_logic/models/piece.dart';
import '../../../../../core/game_logic/models/position.dart';
import 'board_layout.dart';

/// How far from a preferred cell's centre a tap on [layout] still lands on
/// it, in cell widths, for [resolveTap]. Hex cells are small on a phone
/// (11 across), so a tap there snaps within 0.8 of a cell; the square
/// board keeps exact taps, as it always had.
double tapReachFor(BoardLayout layout) => layout.isHex ? 0.8 : 0;

/// How far from a standing figure's head point ([BoardLayout.headOf]) a
/// tap still catches it, in cell widths: half a cell, so the heads of two
/// figures side by side never share a tap.
const headReach = 0.5;

/// The cell a tap at [point] means.
///
/// The cell under the finger wins when it is in [preferred] (cells where a
/// tap does something: move targets, the selected piece, own pieces with a
/// move) or in [heads]. On a board of standing figures, a tap on the head
/// of a figure in [heads] (within [headReach] of [BoardLayout.headOf])
/// comes next: the figure reaches up over the cell behind it, and that
/// cell holds nothing a tap could pick. Otherwise the nearest [preferred]
/// cell whose centre lies within [reach] × [BoardLayout.cellSize] of the
/// finger, measured on the flat board. Otherwise the cell under the
/// finger, or null off the board.
///
/// [heads] are the cells whose figure a tap may pick, with its type.
/// [reach] stays below 1.0: a neighbour's centre is one cell width away,
/// so a tap in the middle of an empty cell never snaps to it.
Position? resolveTap(
  BoardLayout layout,
  Offset point, {
  required Set<Position> preferred,
  Map<Position, PieceType> heads = const {},
  double reach = 0.8,
}) {
  assert(reach < 1.0, 'reach must stay below one cell width');
  final exact = layout.positionAt(point);
  if (exact != null &&
      (preferred.contains(exact) || heads.containsKey(exact))) {
    return exact;
  }

  if (layout.standing) {
    final limit = headReach * layout.cellSize;
    Position? best;
    var bestDistance = limit * limit;
    for (final MapEntry(key: p, value: type) in heads.entries) {
      final d = (layout.headOf(p, type) - point).distanceSquared;
      if (d < bestDistance) {
        bestDistance = d;
        best = p;
      }
    }
    if (best != null) return best;
  }

  if (reach <= 0) return exact;
  final limit = reach * layout.cellSize;
  final flat = layout.toFlat(point);
  Position? best;
  var bestDistance = limit * limit;
  for (final p in preferred) {
    final d = (layout.flatCentreOf(p) - flat).distanceSquared;
    if (d < bestDistance || (best == null && d == bestDistance)) {
      bestDistance = d;
      best = p;
    }
  }
  return best ?? exact;
}
