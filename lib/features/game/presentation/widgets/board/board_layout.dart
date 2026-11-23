import 'dart:math';
import 'dart:ui';

import '../../../../../core/game_logic/board/board_geometry.dart';
import '../../../../../core/game_logic/models/position.dart';

/// Where every cell of a board sits on screen, for the painters, the piece
/// layer and the tap handler alike.
///
/// White's back row is at the bottom; [flipped] turns the whole board
/// around (180°) for black. Square cells fill a grid; hex cells are
/// pointy-top with odd rows shifted half a cell right, as [HexGeometry]
/// stores them.
class BoardLayout {
  final BoardGeometry geometry;
  final bool flipped;

  /// Size of the whole board.
  final Size size;

  /// Width of one cell: a square's side, a hex's width across its flats.
  final double cellSize;

  /// Twice the column position of the leftmost hex centre (hex only).
  final int _minX2;

  BoardLayout._(this.geometry, this.flipped, this.size, this.cellSize,
      [this._minX2 = 0]);

  static int _x2(Position p) => 2 * p.col + (p.row & 1);

  bool get isHex => geometry is HexGeometry;

  /// The layout of [geometry] at [width].
  factory BoardLayout.fit(
    BoardGeometry geometry,
    double width, {
    bool flipped = false,
  }) {
    if (geometry is HexGeometry) {
      // Fit the cells themselves: a hexagon's cut corners leave grid
      // columns empty on some rows.
      final xs = geometry.cells.map(_x2);
      final minX2 = xs.reduce(min);
      final across = (xs.reduce(max) - minX2) / 2 + 1;
      final cell = width / across;
      final radius = cell / sqrt(3);
      final height = radius * (2 + 1.5 * (geometry.rows - 1));
      return BoardLayout._(
          geometry, flipped, Size(width, height), cell, minX2);
    }
    final cell = width / geometry.cols;
    return BoardLayout._(
        geometry, flipped, Size(width, cell * geometry.rows), cell);
  }

  /// The largest layout of [geometry] that fits in [box].
  factory BoardLayout.within(
    BoardGeometry geometry,
    Size box, {
    bool flipped = false,
  }) {
    final wide = BoardLayout.fit(geometry, box.width, flipped: flipped);
    if (!box.height.isFinite || wide.size.height <= box.height) return wide;
    return BoardLayout.fit(
        geometry, box.width * box.height / wide.size.height,
        flipped: flipped);
  }

  /// A hex's corner distance from its centre.
  double get _radius => cellSize / sqrt(3);

  /// The centre of [p] on screen.
  Offset centreOf(Position p) {
    final visualRow = geometry.rows - 1 - p.row;
    final Offset unflipped;
    if (isHex) {
      unflipped = Offset(
        ((_x2(p) - _minX2) / 2 + 0.5) * cellSize,
        _radius + visualRow * 1.5 * _radius,
      );
    } else {
      unflipped =
          Offset((p.col + 0.5) * cellSize, (visualRow + 0.5) * cellSize);
    }
    return flipped
        ? Offset(size.width - unflipped.dx, size.height - unflipped.dy)
        : unflipped;
  }

  /// The outline of [p]'s cell.
  Path cellPath(Position p, {double inset = 0}) {
    final c = centreOf(p);
    if (!isHex) {
      return Path()
        ..addRect(Rect.fromCenter(
            center: c,
            width: cellSize - 2 * inset,
            height: cellSize - 2 * inset));
    }
    final r = _radius - inset * 2 / sqrt(3);
    final path = Path();
    for (var i = 0; i < 6; i++) {
      final angle = pi / 2 + i * pi / 3; // pointy top: corners at ±90°
      final corner = c + Offset(r * cos(angle), r * sin(angle));
      if (i == 0) {
        path.moveTo(corner.dx, corner.dy);
      } else {
        path.lineTo(corner.dx, corner.dy);
      }
    }
    return path..close();
  }

  /// Which of the board's two (square) or three (hex) cell shades [p]
  /// gets, so that no two neighbours share one; 0 is the lightest. The
  /// square board keeps its light square at the bottom left.
  int shadeOf(Position p) {
    if (!isHex) return (geometry.rows - 1 - p.row + p.col) % 2;
    final q = p.col - (p.row >> 1);
    return (q - p.row) % 3;
  }

  /// The box a piece is drawn in on [p]: centred, [cellSize] wide.
  Rect pieceBox(Position p) =>
      Rect.fromCenter(center: centreOf(p), width: cellSize, height: cellSize);

  /// The cell under [point], or null off the board. The nearest centre is
  /// exact for hexes, whose cells are the Voronoi regions of their centres.
  Position? positionAt(Offset point) {
    Position? best;
    var bestDistance = double.infinity;
    for (final p in geometry.cells) {
      final d = (centreOf(p) - point).distanceSquared;
      if (d < bestDistance) {
        bestDistance = d;
        best = p;
      }
    }
    final limit = isHex ? _radius : cellSize * sqrt(2) / 2;
    return bestDistance <= limit * limit ? best : null;
  }
}
