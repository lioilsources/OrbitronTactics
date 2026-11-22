import 'dart:math';

import '../models/piece.dart';
import '../models/position.dart';

/// One step on a board, from white's point of view (forward = toward
/// higher rows).
///
/// On a [SquareGeometry] it is a plain row and column offset. On a
/// [HexGeometry] [dCol] is the change of the axial column instead: hex
/// offsets depend on the row's parity, axial ones do not, so a direction
/// stays a constant vector and steps add up.
class Direction {
  final int dRow;
  final int dCol;

  const Direction(this.dRow, this.dCol);

  Direction operator *(int times) => Direction(dRow * times, dCol * times);

  Direction operator +(Direction other) =>
      Direction(dRow + other.dRow, dCol + other.dCol);

  @override
  bool operator ==(Object other) =>
      other is Direction && other.dRow == dRow && other.dCol == dCol;

  @override
  int get hashCode => Object.hash(dRow, dCol);

  @override
  String toString() => 'Direction($dRow, $dCol)';
}

/// A knight's jump: where it lands and, for the long forward jumps, the
/// step whose square holding a rook (of either color) forbids it.
class KnightJump {
  final Direction delta;
  final Direction? blockedByRookAt;

  const KnightJump(this.delta, {this.blockedByRookAt});
}

/// How far a sliding piece reaches through edges ([straight]) and through
/// corners ([diagonal]).
typedef Reach = ({int straight, int diagonal});

/// The shape of a board and the movement rules that depend on it.
///
/// Every list of directions is ordered, and the validators keep that order:
/// on the classic board it is the order the moves were generated in before
/// the geometry existed, which the AI's tie-breaks depend on.
abstract class BoardGeometry {
  final int rows;
  final int cols;

  /// Squares that are not part of the board (rocks).
  final List<Position> blocked;

  const BoardGeometry({
    required this.rows,
    required this.cols,
    this.blocked = const [],
  });

  int get cellCount => rows * cols;

  /// Whether [p] is on the board and not blocked.
  bool contains(Position p) {
    if (p.row < 0 || p.row >= rows || p.col < 0 || p.col >= cols) {
      return false;
    }
    for (final b in blocked) {
      if (b.row == p.row && b.col == p.col) return false;
    }
    return true;
  }

  /// Steps through an edge.
  List<Direction> get straight;

  /// Steps through a corner.
  List<Direction> get diagonal;

  /// The Last Warrior's single steps.
  List<Direction> get adjacent;

  /// The edge steps whose squares a slide in corner direction [d] passes
  /// between, when they can block it. Empty when nothing blocks a corner
  /// step (the square board).
  List<Direction> cornerFlanks(Direction d) => const [];

  /// How many of [cornerFlanks]' squares must be taken to block the step.
  int get cornerBlockThreshold => 0;

  /// [from] moved [times] steps in [d]. May be off the board.
  Position step(Position from, Direction d, [int times = 1]);

  /// [d], seen from [color]'s side of the board.
  Direction forColor(Direction d, PlayerColor color) =>
      color == PlayerColor.white ? d : _flip(d);

  /// [d] mirrored across the horizontal axis. Every set of directions the
  /// rules use is left-right symmetric, so this equals turning it around.
  Direction _flip(Direction d);

  List<Direction> _oriented(List<Direction> ds, PlayerColor color) =>
      color == PlayerColor.white ? ds : [for (final d in ds) _flip(d)];

  /// Pawn moves without capture, sideways.
  List<Direction> sideways(PlayerColor color) =>
      _oriented(_pawnSideways, color);

  /// Pawn moves without capture, backward.
  List<Direction> backward(PlayerColor color) =>
      _oriented(_pawnBackward, color);

  /// Pawn moves that may capture, forward.
  List<Direction> forwardCapture(PlayerColor color) =>
      _oriented(_pawnCapture, color);

  List<Direction> get _pawnSideways;
  List<Direction> get _pawnBackward;
  List<Direction> get _pawnCapture;
  List<KnightJump> get _knightJumps;
  List<Direction> get _snipes;

  List<KnightJump> knightJumps(PlayerColor color) => color == PlayerColor.white
      ? _knightJumps
      : [
          for (final jump in _knightJumps)
            KnightJump(
              _flip(jump.delta),
              blockedByRookAt: jump.blockedByRookAt == null
                  ? null
                  : _flip(jump.blockedByRookAt!),
            ),
        ];

  /// Where a bishop's snipe from [from] may land (it jumps; the target
  /// still has to be on the board).
  List<Position> snipeTargets(Position from, PlayerColor color) => [
        for (final d in _oriented(_snipes, color)) step(from, d),
      ];

  /// The reach of a sliding piece.
  Reach reach(PieceType type);

  /// The row [color] starts on.
  int backRank(PlayerColor color) => color == PlayerColor.white ? 0 : rows - 1;

  /// The row a pawn of [color] must reach to win.
  int infiltrationRank(PlayerColor color) =>
      color == PlayerColor.white ? rows - 1 : 0;

  bool isInfiltration(Position p, PlayerColor color) =>
      p.row == infiltrationRank(color);

  /// Point-symmetric mirror about the board's centre.
  Position mirror(Position p) =>
      Position(row: rows - 1 - p.row, col: cols - 1 - p.col);

  /// A dense index of [p], for the AI's bit sets.
  int indexOf(Position p) => p.row * cols + p.col;

  /// Distance of [p]'s centre from the board's centre, in cell widths.
  double distanceFromCentre(Position p);

  /// Every square of the board, row by row.
  Iterable<Position> get cells sync* {
    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < cols; col++) {
        final p = Position(row: row, col: col);
        if (contains(p)) yield p;
      }
    }
  }
}

/// The classic square board.
class SquareGeometry extends BoardGeometry {
  const SquareGeometry({
    required super.rows,
    required super.cols,
    super.blocked,
  });

  static const _straight = [
    Direction(0, 1),
    Direction(0, -1),
    Direction(1, 0),
    Direction(-1, 0),
  ];

  static const _diagonal = [
    Direction(-1, -1),
    Direction(-1, 1),
    Direction(1, -1),
    Direction(1, 1),
  ];

  static const _adjacent = [
    Direction(-1, -1),
    Direction(-1, 0),
    Direction(-1, 1),
    Direction(0, -1),
    Direction(0, 1),
    Direction(1, -1),
    Direction(1, 0),
    Direction(1, 1),
  ];

  @override
  List<Direction> get straight => _straight;

  @override
  List<Direction> get diagonal => _diagonal;

  @override
  List<Direction> get adjacent => _adjacent;

  @override
  Position step(Position from, Direction d, [int times = 1]) => Position(
      row: from.row + d.dRow * times, col: from.col + d.dCol * times);

  @override
  Direction _flip(Direction d) => Direction(-d.dRow, d.dCol);

  @override
  List<Direction> get _pawnSideways => const [Direction(0, -1), Direction(0, 1)];

  @override
  List<Direction> get _pawnBackward => const [Direction(-1, 0)];

  @override
  List<Direction> get _pawnCapture => const [Direction(1, -1), Direction(1, 1)];

  /// Tall L forward (blocked by a rook in front), low L forward, low L
  /// backward. No tall L backward.
  @override
  List<KnightJump> get _knightJumps => const [
        KnightJump(Direction(2, -1), blockedByRookAt: Direction(1, 0)),
        KnightJump(Direction(2, 1), blockedByRookAt: Direction(1, 0)),
        KnightJump(Direction(1, -2)),
        KnightJump(Direction(1, 2)),
        KnightJump(Direction(-1, -2)),
        KnightJump(Direction(-1, 2)),
      ];

  /// Exactly three straight forward.
  @override
  List<Direction> get _snipes => const [Direction(3, 0)];

  @override
  Reach reach(PieceType type) => switch (type) {
        PieceType.rook => (straight: 4, diagonal: 0),
        PieceType.bishop => (straight: 0, diagonal: 3),
        PieceType.queen => (straight: 2, diagonal: 4),
        PieceType.king => (straight: 4, diagonal: 2),
        PieceType.pawn || PieceType.knight => (straight: 0, diagonal: 0),
      };

  @override
  double distanceFromCentre(Position p) {
    final dy = p.row - (rows - 1) / 2;
    final dx = p.col - (cols - 1) / 2;
    return sqrt(dx * dx + dy * dy);
  }
}

/// Where a hex bishop's snipe lands.
enum HexSnipe {
  /// Two corner steps straight forward (four rows).
  vertexForward,

  /// Three edge steps diagonally forward, to either side.
  edgeDiagonal,
}

/// What stops a hex slide through a corner, which passes between the two
/// hexes that share that corner.
enum CornerBlock {
  /// Nothing: only the landing hex counts (rules v0).
  open,

  /// Both hexes taken.
  both,

  /// Either hex taken.
  either,
}

/// A hex board: pointy-top hexes in horizontal rows, stored in offset
/// coordinates with odd rows shifted half a cell right. That keeps
/// `grid[row][col]`, the JSON and the AI's bit sets as they are.
///
/// Compass points are seen from white, north = forward. Edge neighbours
/// are E, W, NE, NW, SE, SW; corner neighbours N, S and four oblique ones.
/// A [Direction] here is (row change, axial column change).
class HexGeometry extends BoardGeometry {
  final HexSnipe snipe;
  final CornerBlock cornerBlock;

  const HexGeometry({
    required super.rows,
    required super.cols,
    super.blocked,
    this.snipe = HexSnipe.vertexForward,
    this.cornerBlock = CornerBlock.both,
  }) : assert(rows % 2 == 0, 'point symmetry needs an even row count');

  static const east = Direction(0, 1);
  static const west = Direction(0, -1);
  static const northEast = Direction(1, 0);
  static const northWest = Direction(1, -1);
  static const southEast = Direction(-1, 1);
  static const southWest = Direction(-1, 0);

  static const north = Direction(2, -1); // NE + NW
  static const south = Direction(-2, 1);
  static const eastNorthEast = Direction(1, 1); // E + NE
  static const westNorthWest = Direction(1, -2); // W + NW
  static const eastSouthEast = Direction(-1, 2); // E + SE
  static const westSouthWest = Direction(-1, -1); // W + SW

  static const _straight = [
    east,
    west,
    northEast,
    northWest,
    southEast,
    southWest,
  ];

  static const _diagonal = [
    north,
    south,
    eastNorthEast,
    westNorthWest,
    eastSouthEast,
    westSouthWest,
  ];

  @override
  List<Direction> get straight => _straight;

  @override
  List<Direction> get diagonal => _diagonal;

  @override
  List<Direction> get adjacent => _straight;

  @override
  List<Direction> cornerFlanks(Direction d) {
    if (cornerBlock == CornerBlock.open) return const [];
    for (var i = 0; i < _straight.length; i++) {
      for (var j = i + 1; j < _straight.length; j++) {
        if (_straight[i] + _straight[j] == d) return [_straight[i], _straight[j]];
      }
    }
    return const [];
  }

  @override
  int get cornerBlockThreshold => switch (cornerBlock) {
        CornerBlock.open => 0,
        CornerBlock.both => 2,
        CornerBlock.either => 1,
      };

  @override
  Position step(Position from, Direction d, [int times = 1]) {
    final q = from.col - (from.row >> 1) + d.dCol * times;
    final row = from.row + d.dRow * times;
    return Position(row: row, col: q + (row >> 1));
  }

  /// (x, r) → (x, −r) with x = q + r/2, so q' = q + r.
  @override
  Direction _flip(Direction d) => Direction(-d.dRow, d.dCol + d.dRow);

  @override
  List<Direction> get _pawnSideways => const [west, east];

  @override
  List<Direction> get _pawnBackward => const [southWest, southEast];

  @override
  List<Direction> get _pawnCapture => const [northWest, northEast];

  /// Two edge steps and one turned by 60°: two jumps for every row change
  /// of ±1, ±2 and ±3. All six forward, back only by one row. A rook on the
  /// first step's square blocks the jumps two and three rows forward.
  @override
  List<KnightJump> get _knightJumps => const [
        // Three rows forward.
        KnightJump(Direction(3, -2), blockedByRookAt: northWest), // NW NW NE
        KnightJump(Direction(3, -1), blockedByRookAt: northEast), // NE NE NW
        // Two rows forward.
        KnightJump(Direction(2, -3), blockedByRookAt: northWest), // NW NW W
        KnightJump(Direction(2, 1), blockedByRookAt: northEast), // NE NE E
        // One row forward.
        KnightJump(Direction(1, -3)), // W W NW
        KnightJump(Direction(1, 2)), // E E NE
        // One row back.
        KnightJump(Direction(-1, -2)), // W W SW
        KnightJump(Direction(-1, 3)), // E E SE
      ];

  @override
  List<Direction> get _snipes => switch (snipe) {
        HexSnipe.vertexForward => const [Direction(4, -2)],
        HexSnipe.edgeDiagonal => const [Direction(3, -3), Direction(3, 0)],
      };

  @override
  Reach reach(PieceType type) => switch (type) {
        PieceType.rook => (straight: 3, diagonal: 0),
        PieceType.bishop => (straight: 0, diagonal: 2),
        PieceType.queen => (straight: 2, diagonal: 2),
        PieceType.king => (straight: 3, diagonal: 1),
        PieceType.pawn || PieceType.knight => (straight: 0, diagonal: 0),
      };

  @override
  double distanceFromCentre(Position p) {
    final x = p.col + (p.row & 1) / 2;
    final dx = x - (cols - 0.5) / 2;
    final dy = (p.row - (rows - 1) / 2) * sqrt(3) / 2;
    return sqrt(dx * dx + dy * dy);
  }
}
