import 'dart:math';
import 'dart:ui';

import '../../../../../core/game_logic/board/board_geometry.dart';
import '../../../../../core/game_logic/board/board_spec.dart';
import '../../../../../core/game_logic/models/piece.dart';
import '../../../../../core/game_logic/models/position.dart';
import '../../../../battle/data/unit_art.dart' show UnitPose;
import '../../../data/piece_skin.dart';

/// How a board leans back when its world's figures stand on it: a parallel
/// projection, no perspective.
class BoardTilt {
  const BoardTilt({required this.squash, required this.figureHeight});

  /// The vertical scale of the board, `k`: 1 keeps the cells as they are,
  /// less leans the board back.
  final double squash;

  /// The side of a figure's square picture, in cell widths. A figure
  /// taller than its cell reaches up over the cells behind it.
  final double figureHeight;

  @override
  bool operator ==(Object other) =>
      other is BoardTilt &&
      other.squash == squash &&
      other.figureHeight == figureHeight;

  @override
  int get hashCode => Object.hash(squash, figureHeight);

  @override
  String toString() => 'BoardTilt(k: $squash, height: $figureHeight)';
}

// The tilt of each board shape when its figures stand, from the P2 sample
// sheet; one line per shape.
const _hexTilt = BoardTilt(squash: 0.85, figureHeight: 1.25);
const _squareTilt = BoardTilt(squash: 1.0, figureHeight: 1.25);

/// The tilt of each board, by [BoardSpec.id], in a world of standing
/// figures.
const standingTilts = <String, BoardTilt>{
  'classic8': _squareTilt,
  'skirmish6': _squareTilt,
  'tall8x10': _squareTilt,
  'grand10': _squareTilt,
  'grand10_20': _squareTilt,
  'rocks8': _squareTilt,
  'hex6': _hexTilt,
  'hex6_either': _hexTilt,
  'hex6_open': _hexTilt,
  'hex6_edge_snipe': _hexTilt,
};

/// The tilt of [spec] in [world]: null (a flat board, pieces inside their
/// cells) for Space and its symbols, the board's [standingTilts] entry in a
/// world of standing figures.
BoardTilt? boardTiltFor(BoardSpec spec, PieceSkin world) {
  if (world.pose != UnitPose.standing) return null;
  return standingTilts[spec.id] ??
      (spec.geometry is HexGeometry ? _hexTilt : _squareTilt);
}

/// The shape of a standing figure inside its square picture, measured on
/// the image packs' alpha (median over the sixteen worlds; every pack
/// draws its ranks at the same heights).
class StandingFigure {
  const StandingFigure._();

  /// How far down the picture the plinth's centre sits; it stands on the
  /// cell's centre.
  static const plinthAnchor = 0.93;

  static const _top = {
    PieceType.king: 0.0,
    PieceType.queen: 0.066,
    PieceType.bishop: 0.145,
    PieceType.knight: 0.207,
    PieceType.rook: 0.266,
    PieceType.pawn: 0.406,
  };

  static const _width = {
    PieceType.king: 0.715,
    PieceType.queen: 0.668,
    PieceType.bishop: 0.562,
    PieceType.knight: 0.617,
    PieceType.rook: 0.629,
    PieceType.pawn: 0.453,
  };

  /// Where [type]'s figure starts, as a fraction of the picture from its
  /// top; it reaches down to the picture's bottom.
  static double topOf(PieceType type) => _top[type]!;

  /// How wide [type]'s figure is, as a fraction of the picture.
  static double widthOf(PieceType type) => _width[type]!;
}

/// Where every cell of a board sits on screen, for the painters, the piece
/// layer and the tap handler alike.
///
/// White's back row is at the bottom; [flipped] turns the whole board
/// around (180°) for black. Square cells fill a grid; hex cells are
/// pointy-top with odd rows shifted half a cell right, as [HexGeometry]
/// stores them.
///
/// With a [tilt] the board leans back: every vertical distance on it is
/// scaled by [BoardTilt.squash], figures stand on their cells' centres and
/// the board gets room on top for the back row's figures. Positions are
/// worked out on the flat board first ([flatCentreOf]) and then squashed,
/// so a flipped board turns around exactly like a flat one.
class BoardLayout {
  final BoardGeometry geometry;
  final bool flipped;

  /// Null for a flat board with pieces inside their cells.
  final BoardTilt? tilt;

  /// Size of the whole board, the room on top for figures included.
  final Size size;

  /// Width of one cell: a square's side, a hex's width across its flats.
  final double cellSize;

  /// Twice the column position of the leftmost hex centre (hex only).
  final int _minX2;

  /// Height of the flat board, before squashing.
  final double _flatHeight;

  /// Room above the board for the back row's figures.
  final double _top;

  BoardLayout._(
    this.geometry,
    this.flipped,
    this.tilt,
    this.size,
    this.cellSize,
    this._flatHeight,
    this._top, [
    this._minX2 = 0,
  ]);

  static int _x2(Position p) => 2 * p.col + (p.row & 1);

  /// How far above the squashed board the back row's figures reach.
  static double _topRoom(BoardGeometry geometry, double cell, BoardTilt? tilt) {
    if (tilt == null) return 0;
    final firstCentre = geometry is HexGeometry ? cell / sqrt(3) : cell / 2;
    final reach = StandingFigure.plinthAnchor * tilt.figureHeight * cell;
    return max(0, reach - tilt.squash * firstCentre);
  }

  bool get isHex => geometry is HexGeometry;

  /// Whether figures stand on this board rather than lie inside cells.
  bool get standing => tilt != null;

  double get _squash => tilt?.squash ?? 1;

  /// The layout of [geometry] at [width].
  factory BoardLayout.fit(
    BoardGeometry geometry,
    double width, {
    bool flipped = false,
    BoardTilt? tilt,
  }) {
    final k = tilt?.squash ?? 1;
    if (geometry is HexGeometry) {
      // Fit the cells themselves: a hexagon's cut corners leave grid
      // columns empty on some rows.
      final xs = geometry.cells.map(_x2);
      final minX2 = xs.reduce(min);
      final across = (xs.reduce(max) - minX2) / 2 + 1;
      final cell = width / across;
      final radius = cell / sqrt(3);
      final flat = radius * (2 + 1.5 * (geometry.rows - 1));
      final top = _topRoom(geometry, cell, tilt);
      return BoardLayout._(geometry, flipped, tilt,
          Size(width, top + k * flat), cell, flat, top, minX2);
    }
    final cell = width / geometry.cols;
    final flat = cell * geometry.rows;
    final top = _topRoom(geometry, cell, tilt);
    return BoardLayout._(geometry, flipped, tilt,
        Size(width, top + k * flat), cell, flat, top);
  }

  /// The largest layout of [geometry] that fits in [box].
  factory BoardLayout.within(
    BoardGeometry geometry,
    Size box, {
    bool flipped = false,
    BoardTilt? tilt,
  }) {
    final wide =
        BoardLayout.fit(geometry, box.width, flipped: flipped, tilt: tilt);
    if (!box.height.isFinite || wide.size.height <= box.height) return wide;
    return BoardLayout.fit(
        geometry, box.width * box.height / wide.size.height,
        flipped: flipped, tilt: tilt);
  }

  /// A hex's corner distance from its centre.
  double get _radius => cellSize / sqrt(3);

  /// The centre of [p] on the flat board, before squashing; flipping
  /// already applied.
  Offset flatCentreOf(Position p) {
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
        ? Offset(size.width - unflipped.dx, _flatHeight - unflipped.dy)
        : unflipped;
  }

  /// [flat], a point on the flat board, on screen.
  Offset toScreen(Offset flat) => Offset(flat.dx, _top + _squash * flat.dy);

  /// [screen], a point on screen, back on the flat board.
  Offset toFlat(Offset screen) =>
      Offset(screen.dx, (screen.dy - _top) / _squash);

  /// The centre of [p] on screen.
  Offset centreOf(Position p) => toScreen(flatCentreOf(p));

  /// The outline of [p]'s cell.
  Path cellPath(Position p, {double inset = 0}) {
    if (!isHex) return Path()..addRect(cellRect(p, inset: inset));
    final c = centreOf(p);
    final r = _radius - inset * 2 / sqrt(3);
    final path = Path();
    for (var i = 0; i < 6; i++) {
      final angle = pi / 2 + i * pi / 3; // pointy top: corners at ±90°
      final corner = c + Offset(r * cos(angle), _squash * r * sin(angle));
      if (i == 0) {
        path.moveTo(corner.dx, corner.dy);
      } else {
        path.lineTo(corner.dx, corner.dy);
      }
    }
    return path..close();
  }

  /// The box around [p]'s cell: a square's cell itself, [cellSize] wide
  /// and squashed like the board.
  Rect cellRect(Position p, {double inset = 0}) => Rect.fromCenter(
        center: centreOf(p),
        width: cellSize - 2 * inset,
        height: _squash * (cellSize - 2 * inset),
      );

  /// Which of the board's two (square) or three (hex) cell shades [p]
  /// gets, so that no two neighbours share one; 0 is the lightest. The
  /// square board keeps its light square at the bottom left.
  int shadeOf(Position p) {
    if (!isHex) return (geometry.rows - 1 - p.row + p.col) % 2;
    final q = p.col - (p.row >> 1);
    return (q - p.row) % 3;
  }

  /// The box a piece is drawn in on [p]. Flat: centred, [cellSize] wide.
  /// Standing: the figure's square picture, [BoardTilt.figureHeight] cells
  /// on a side, its plinth's centre on the cell's centre.
  Rect pieceBox(Position p) {
    final c = centreOf(p);
    final t = tilt;
    if (t == null) {
      return Rect.fromCenter(center: c, width: cellSize, height: cellSize);
    }
    final side = t.figureHeight * cellSize;
    return Rect.fromLTWH(c.dx - side / 2,
        c.dy - StandingFigure.plinthAnchor * side, side, side);
  }

  /// The part of [pieceBox] that [type]'s standing figure fills: from its
  /// top down to the picture's bottom, [StandingFigure.widthOf] wide.
  Rect figureOutline(Position p, PieceType type) {
    final box = pieceBox(p);
    final width = StandingFigure.widthOf(type) * box.width;
    return Rect.fromLTRB(
      box.center.dx - width / 2,
      box.top + StandingFigure.topOf(type) * box.height,
      box.center.dx + width / 2,
      box.bottom,
    );
  }

  /// The second point a tap catches [type]'s standing figure on [p] by:
  /// halfway up the figure.
  Offset headOf(Position p, PieceType type) => figureOutline(p, type).center;

  /// [cells] in the order their pieces are painted: back to front by their
  /// place on screen, left to right within a row.
  List<Position> inDrawOrder(Iterable<Position> cells) {
    final sorted = cells.toList();
    sorted.sort((a, b) {
      final ca = centreOf(a);
      final cb = centreOf(b);
      final byY = ca.dy.compareTo(cb.dy);
      return byY != 0 ? byY : ca.dx.compareTo(cb.dx);
    });
    return sorted;
  }

  /// The cell under [point], or null off the board. The point goes back
  /// to the flat board first, where the nearest centre is exact for hexes,
  /// whose cells are the Voronoi regions of their centres.
  Position? positionAt(Offset point) {
    final flat = toFlat(point);
    Position? best;
    var bestDistance = double.infinity;
    for (final p in geometry.cells) {
      final d = (flatCentreOf(p) - flat).distanceSquared;
      if (d < bestDistance) {
        bestDistance = d;
        best = p;
      }
    }
    final limit = isHex ? _radius : cellSize * sqrt(2) / 2;
    return bestDistance <= limit * limit ? best : null;
  }
}
