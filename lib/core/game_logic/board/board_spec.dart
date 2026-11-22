import 'package:freezed_annotation/freezed_annotation.dart';

import '../engine/power_field_generator.dart';
import '../models/piece.dart';
import '../models/position.dart';
import 'board_geometry.dart';

const _r = PieceType.rook;
const _n = PieceType.knight;
const _b = PieceType.bishop;
const _q = PieceType.queen;
const _k = PieceType.king;
const _p = PieceType.pawn;

/// The hexagon's army, on the 11 columns of its grid: the back row's six
/// cells (columns 3–8), knights at both ends of the next (2 and 8) and a
/// pawn on every cell of the third (2–9).
const _hexLayout = <List<PieceType?>>[
  [null, null, null, _r, _b, _q, _k, _b, _r, null, null],
  [null, null, _n, null, null, null, null, null, _n, null, null],
  [null, null, _p, _p, _p, _p, _p, _p, _p, _p, null],
];

/// A board variant: its shape, where the armies start and the power
/// fields. The single source of a board's tunable numbers.
class BoardSpec {
  final String id;
  final BoardGeometry geometry;

  /// The default formation, from the back rank forward, columns left to
  /// right as white sees them. Null = empty square. Black uses the same
  /// columns on its own rows, as on a chess board.
  final List<List<PieceType?>> layout;

  /// How many power fields a game on this board has.
  final int powerFieldCount;

  /// Fixed power-field variants. Null = generated point-symmetric for each
  /// game (see [PowerFieldGenerator.symmetric]).
  final List<List<Position>>? powerFieldVariants;

  const BoardSpec({
    required this.id,
    required this.geometry,
    required this.layout,
    this.powerFieldCount = 5,
    this.powerFieldVariants,
  });

  int get rows => geometry.rows;
  int get cols => geometry.cols;
  List<Position> get blocked => geometry.blocked;

  /// How many rows of each side a formation may use.
  int get formationRows => layout.length;

  /// The rows [color]'s formation may use.
  Set<int> formationRowsFor(PlayerColor color) => {
        for (var i = 0; i < formationRows; i++)
          color == PlayerColor.white ? i : rows - 1 - i,
      };

  /// How many pieces of each type an army has.
  Map<PieceType, int> get army {
    final counts = {for (final type in PieceType.values) type: 0};
    for (final row in layout) {
      for (final type in row) {
        if (type != null) counts[type] = counts[type]! + 1;
      }
    }
    return counts;
  }

  int get armySize => army.values.fold(0, (sum, n) => sum + n);

  @override
  bool operator ==(Object other) => other is BoardSpec && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'BoardSpec($id)';

  static const _classicLayout = [
    [_r, _n, _b, _q, _k, _b, _n, _r],
    [_p, _p, _p, _p, _p, _p, _p, _p],
  ];

  /// The classic 8×8 board, the default.
  static const classic8 = BoardSpec(
    id: 'classic8',
    geometry: SquareGeometry(rows: 8, cols: 8),
    layout: _classicLayout,
    powerFieldVariants: PowerFieldGenerator.variants,
  );

  /// 6×6, 12 pieces, 3 power fields: a short game for phones.
  static const skirmish6 = BoardSpec(
    id: 'skirmish6',
    geometry: SquareGeometry(rows: 6, cols: 6),
    layout: [
      [_r, _n, _q, _k, _b, _r],
      [_p, _p, _p, _p, _p, _p],
    ],
    powerFieldCount: 3,
  );

  /// 8 columns × 10 rows: a longer approach, the same width.
  static const tall8x10 = BoardSpec(
    id: 'tall8x10',
    geometry: SquareGeometry(rows: 10, cols: 8),
    layout: _classicLayout,
  );

  /// 10×10 with the classic 16 pieces, gaps on the wings.
  static const grand10 = BoardSpec(
    id: 'grand10',
    geometry: SquareGeometry(rows: 10, cols: 10),
    layout: [
      [null, _r, _n, _b, _q, _k, _b, _n, _r, null],
      [null, _p, _p, _p, _p, _p, _p, _p, _p, null],
    ],
  );

  /// 10×10 with 20 pieces: ten pawns, a third knight and bishop.
  static const grand10x20 = BoardSpec(
    id: 'grand10_20',
    geometry: SquareGeometry(rows: 10, cols: 10),
    layout: [
      [_r, _n, _b, _n, _q, _k, _b, _n, _b, _r],
      [_p, _p, _p, _p, _p, _p, _p, _p, _p, _p],
    ],
  );

  /// 8×8 with four point-symmetric rocks on the wings.
  static const rocks8 = BoardSpec(
    id: 'rocks8',
    geometry: SquareGeometry(
      rows: 8,
      cols: 8,
      blocked: [
        Position(row: 3, col: 1),
        Position(row: 4, col: 1),
        Position(row: 3, col: 6),
        Position(row: 4, col: 6),
      ],
    ),
    layout: _classicLayout,
  );

  /// Hexagon with six cells a side (91 cells): a slide through a corner
  /// stops when both hexes beside the corner are taken; the bishop snipes
  /// two corner steps forward.
  static const hex6 = BoardSpec(
    id: 'hex6',
    geometry: HexGeometry.hexagon(6),
    layout: _hexLayout,
  );

  /// [hex6], a corner slide stops when either hex beside it is taken.
  static const hex6Either = BoardSpec(
    id: 'hex6_either',
    geometry: HexGeometry.hexagon(6, cornerBlock: CornerBlock.either),
    layout: _hexLayout,
  );

  /// [hex6] with nothing stopping a corner slide (rules v0).
  static const hex6Open = BoardSpec(
    id: 'hex6_open',
    geometry: HexGeometry.hexagon(6, cornerBlock: CornerBlock.open),
    layout: _hexLayout,
  );

  /// [hex6], the bishop snipes three edge steps diagonally forward.
  static const hex6EdgeSnipe = BoardSpec(
    id: 'hex6_edge_snipe',
    geometry: HexGeometry.hexagon(6, snipe: HexSnipe.edgeDiagonal),
    layout: _hexLayout,
  );

  static const all = [
    classic8,
    skirmish6,
    tall8x10,
    grand10,
    grand10x20,
    rocks8,
    hex6,
    hex6Either,
    hex6Open,
    hex6EdgeSnipe,
  ];

  /// The spec called [id]; throws a [FormatException] for an unknown one.
  static BoardSpec byId(String id) {
    for (final spec in all) {
      if (spec.id == id) return spec;
    }
    throw FormatException('Unknown board spec', id);
  }
}

/// Stores a [BoardSpec] in JSON by its id.
class BoardSpecConverter implements JsonConverter<BoardSpec, String> {
  const BoardSpecConverter();

  @override
  BoardSpec fromJson(String json) => BoardSpec.byId(json);

  @override
  String toJson(BoardSpec spec) => spec.id;
}
