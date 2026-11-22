import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:orbitron_tactics/core/ai/cell_set.dart';
import 'package:orbitron_tactics/core/game_logic/board/board_geometry.dart';
import 'package:orbitron_tactics/core/game_logic/board/board_spec.dart';
import 'package:orbitron_tactics/core/game_logic/engine/formation_validator.dart';
import 'package:orbitron_tactics/core/game_logic/engine/game_engine.dart';
import 'package:orbitron_tactics/core/game_logic/engine/power_field_generator.dart';
import 'package:orbitron_tactics/core/game_logic/models/board_state.dart';
import 'package:orbitron_tactics/core/game_logic/models/piece.dart';
import 'package:orbitron_tactics/core/game_logic/models/position.dart';
import 'package:orbitron_tactics/core/game_logic/validators/move_validator.dart';
import 'package:orbitron_tactics/core/game_logic/validators/validator_registry.dart';

import '../test_helpers.dart';

/// [pieces] on an empty board of [spec].
BoardState specBoard(BoardSpec spec, Map<Position, Piece> pieces) {
  var board = BoardState.empty(const [], spec: spec);
  for (final entry in pieces.entries) {
    board = board.setPiece(entry.key, entry.value);
  }
  return board;
}

List<Position> movesOf(BoardState board, Position from) {
  final piece = board.pieceAt(from)!;
  return validatorFor(piece).getLegalMoves(board, from, piece.color);
}

/// Centre of a hex cell, in cell widths.
(double, double) hexCentre(Position p) =>
    (p.col + (p.row & 1) / 2, p.row * sqrt(3) / 2);

double hexDistance(Position a, Position b) {
  final (ax, ay) = hexCentre(a);
  final (bx, by) = hexCentre(b);
  return sqrt((ax - bx) * (ax - bx) + (ay - by) * (ay - by));
}

/// Hex rules on a plain 8×8 rectangle of hexes, so the cases need not
/// dodge a hexagon's cut corners.
BoardSpec hexRect(
        {CornerBlock cornerBlock = CornerBlock.both,
        HexSnipe snipe = HexSnipe.vertexForward}) =>
    BoardSpec(
      id: 'hex_rect_test',
      geometry: HexGeometry(
          rows: 8, cols: 8, cornerBlock: cornerBlock, snipe: snipe),
      layout: const [<PieceType?>[]],
    );

void main() {
  const hex = HexGeometry(rows: 8, cols: 8);

  group('HexGeometry', () {
    test('edge steps go one cell, corner steps √3, from either row parity',
        () {
      for (final from in [pos(3, 3), pos(4, 4)]) {
        for (final d in hex.straight) {
          expect(hexDistance(from, hex.step(from, d)), closeTo(1, 1e-9));
        }
        for (final d in hex.diagonal) {
          expect(hexDistance(from, hex.step(from, d)), closeTo(sqrt(3), 1e-9));
        }
      }
    });

    test('a corner step north is two rows straight ahead', () {
      for (final from in [pos(2, 3), pos(3, 3)]) {
        final to = hex.step(from, HexGeometry.north);
        expect(to.row, from.row + 2);
        expect(hexCentre(to).$1, hexCentre(from).$1);
      }
    });

    test('the mirror is a point mirror of the cell centres', () {
      for (final cell in hex.cells) {
        final (x, y) = hexCentre(cell);
        final (mx, my) = hexCentre(hex.mirror(cell));
        expect(x + mx, closeTo(7.5, 1e-9));
        expect(y + my, closeTo(7 * sqrt(3) / 2, 1e-9));
      }
    });

    test('black sees the directions turned around', () {
      final white = hex.forwardCapture(PlayerColor.white);
      final black = hex.forwardCapture(PlayerColor.black);
      final from = pos(4, 4);
      expect(white.map((d) => hex.step(from, d).row), everyElement(5));
      expect(black.map((d) => hex.step(from, d).row), everyElement(3));
    });
  });

  group('hexagon', () {
    const hexagon = HexGeometry.hexagon(6);

    test('has 91 cells in rows of 6 to 11 and back', () {
      expect(hexagon.cells, hasLength(91));
      final widths = [
        for (var row = 0; row < hexagon.rows; row++)
          hexagon.cells.where((c) => c.row == row).length,
      ];
      expect(widths, [6, 7, 8, 9, 10, 11, 10, 9, 8, 7, 6]);
    });

    test('every row is centred on the middle cell', () {
      final (cx, _) = hexCentre(pos(5, 5));
      for (var row = 0; row < hexagon.rows; row++) {
        final xs = [
          for (final c in hexagon.cells)
            if (c.row == row) hexCentre(c).$1,
        ];
        expect((xs.first + xs.last) / 2, closeTo(cx, 1e-9));
      }
    });

    test('the mirror is a point mirror through the middle cell', () {
      final (cx, cy) = hexCentre(pos(5, 5));
      for (final cell in hexagon.cells) {
        final mirrored = hexagon.mirror(cell);
        expect(hexagon.contains(mirrored), isTrue);
        final (x, y) = hexCentre(cell);
        final (mx, my) = hexCentre(mirrored);
        expect(x + mx, closeTo(2 * cx, 1e-9));
        expect(y + my, closeTo(2 * cy, 1e-9));
      }
    });
  });

  group('hex rules', () {
    final spec = hexRect();

    test('pawn: E/W and SE/SW without capture, NE/NW with', () {
      final from = pos(3, 3);
      final board = specBoard(spec, {
        from: whitePawn,
        pos(3, 4): blackPawn, // E: blocked, no capture
        pos(4, 4): blackPawn, // NE (odd row): capture
      });
      final moves = movesOf(board, from);
      expect(moves, containsAll([pos(3, 2), pos(2, 3), pos(2, 4), pos(4, 3)]));
      expect(moves, contains(pos(4, 4)));
      expect(moves, isNot(contains(pos(3, 4))));
      expect(moves, hasLength(5));
    });

    test('rook slides up to 3 through edges', () {
      final moves = movesOf(specBoard(spec, {pos(4, 3): whiteRook}), pos(4, 3));
      expect(moves, contains(pos(4, 0)));
      expect(moves, isNot(contains(pos(4, 7))));
      expect(moves, contains(pos(4, 6)));
    });

    test('king: 3 through edges, 1 through corners; queen 2 and 2', () {
      final from = pos(3, 3);
      final king = movesOf(specBoard(spec, {from: whiteKing}), from);
      expect(king, contains(hex.step(from, HexGeometry.east, 3)));
      expect(king, contains(hex.step(from, HexGeometry.north)));
      expect(king, isNot(contains(hex.step(from, HexGeometry.north, 2))));
      final queen =
          movesOf(specBoard(spec, {pos(3, 3): whiteQueen}), pos(3, 3));
      expect(queen, contains(hex.step(pos(3, 3), HexGeometry.north, 2)));
      expect(queen, isNot(contains(hex.step(pos(3, 3), HexGeometry.east, 3))));
    });

    group('a corner slide between two hexes', () {
      final from = pos(2, 3);
      final north = hex.step(from, HexGeometry.north);

      List<Position> bishopMoves(BoardSpec spec, List<Direction> taken) =>
          movesOf(
              specBoard(spec, {
                from: whiteBishop,
                for (final d in taken) hex.step(from, d): whitePawn,
              }),
              from);

      test('either: stops when either hex is taken', () {
        expect(bishopMoves(hexRect(cornerBlock: CornerBlock.either), []), contains(north));
        expect(bishopMoves(hexRect(cornerBlock: CornerBlock.either), [HexGeometry.northEast]),
            isNot(contains(north)));
        expect(bishopMoves(hexRect(cornerBlock: CornerBlock.either), [HexGeometry.northWest]),
            isNot(contains(north)));
      });

      test('both (default): stops only when both are taken', () {
        expect(bishopMoves(spec, [HexGeometry.northEast]),
            contains(north));
        expect(
            bishopMoves(spec,
                [HexGeometry.northEast, HexGeometry.northWest]),
            isNot(contains(north)));
      });

      test('open: never stops (rules v0)', () {
        expect(
            bishopMoves(hexRect(cornerBlock: CornerBlock.open),
                [HexGeometry.northEast, HexGeometry.northWest]),
            contains(north));
      });

      test('a blocked first step also blocks the second', () {
        // The queen reaches two corner steps; pawns on both hexes beside
        // the second corner stop her after the first.
        final mid = hex.step(from, HexGeometry.north);
        final moves = movesOf(
            specBoard(spec, {
              from: whiteQueen,
              hex.step(mid, HexGeometry.northEast): whitePawn,
              hex.step(mid, HexGeometry.northWest): whitePawn,
            }),
            from);
        expect(moves, contains(mid));
        expect(moves, isNot(contains(hex.step(mid, HexGeometry.north))));
      });
    });

    test('knight: six jumps forward, two back by one row', () {
      final from = pos(3, 3);
      final moves = movesOf(specBoard(spec, {from: whiteKnight}), from);
      expect(moves, hasLength(8));
      final rows = moves.map((p) => p.row - from.row).toList()..sort();
      expect(rows, [-1, -1, 1, 1, 2, 2, 3, 3]);
      for (final to in moves) {
        expect(hexDistance(from, to), closeTo(sqrt(7), 1e-9));
      }
    });

    test('a rook on the front neighbour blocks that side\'s long jumps', () {
      final from = pos(2, 3);
      final ne = hex.step(from, HexGeometry.northEast);
      final open = movesOf(specBoard(spec, {from: whiteKnight}), from);
      final blocked =
          movesOf(specBoard(spec, {from: whiteKnight, ne: blackRook}), from);
      final lost = open.where((p) => !blocked.contains(p)).toList();
      expect(lost, hasLength(2));
      for (final to in lost) {
        expect(to.row - from.row, greaterThanOrEqualTo(2));
        expect(hexCentre(to).$1, greaterThan(hexCentre(from).$1));
      }
    });

    test('bishop snipes two corner steps forward over pieces', () {
      final from = pos(1, 3);
      final target = hex.step(from, HexGeometry.north, 2);
      final board = specBoard(spec, {
        from: whiteBishop,
        hex.step(from, HexGeometry.north): blackPawn,
        target: blackRook,
      });
      final moves = movesOf(board, from);
      expect(moves, contains(target));
      expect(moves.where((p) => p == target), hasLength(1));
      final state = gameStateWith(board: board);
      expect(MoveValidator.createMove(state, from, target)!.isSnipe, isTrue);
      final slide = hex.step(from, HexGeometry.eastNorthEast);
      expect(MoveValidator.createMove(state, from, slide)!.isSnipe, isFalse);
    });

    test('the edge-snipe variant jumps three edges diagonally forward', () {
      final edge = hexRect(snipe: HexSnipe.edgeDiagonal);
      final from = pos(1, 3);
      // Blocked northward, so two corner steps north need a snipe
      final moves = movesOf(
          specBoard(edge, {
            from: whiteBishop,
            hex.step(from, HexGeometry.north): whitePawn,
          }),
          from);
      expect(moves, contains(hex.step(from, HexGeometry.northEast, 3)));
      expect(moves, contains(hex.step(from, HexGeometry.northWest, 3)));
      expect(moves, isNot(contains(hex.step(from, HexGeometry.north, 2))));
    });

    test('the Last Warrior steps through the six edges', () {
      final moves =
          movesOf(specBoard(spec, {pos(4, 4): whiteLastWarrior}), pos(4, 4));
      expect(moves, hasLength(6));
    });
  });

  group('rocks8', () {
    const spec = BoardSpec.rocks8;

    test('rocks stop slides and are no target', () {
      final moves = movesOf(specBoard(spec, {pos(3, 3): whiteRook}), pos(3, 3));
      expect(moves, contains(pos(3, 2)));
      expect(moves, isNot(contains(pos(3, 1))));
      expect(moves, isNot(contains(pos(3, 0))));
    });

    test('a knight jumps over a rock', () {
      final moves =
          movesOf(specBoard(spec, {pos(2, 1): whiteKnight}), pos(2, 1));
      expect(moves, contains(pos(4, 0))); // over the rock on (3, 1)
    });

    test('rocks are point-symmetric', () {
      for (final rock in spec.blocked) {
        expect(spec.blocked, contains(spec.geometry.mirror(rock)));
      }
    });
  });

  group('BoardSpec', () {
    test('every default formation is valid on its own board', () {
      for (final spec in BoardSpec.all) {
        for (final color in PlayerColor.values) {
          final formation = GameEngine.defaultFormation(color, spec: spec);
          expect(FormationValidator.validate(formation, color, spec: spec),
              isNull,
              reason: '${spec.id} ${color.name}');
        }
      }
      expect(BoardSpec.classic8.armySize, 16);
      expect(BoardSpec.skirmish6.armySize, 12);
      expect(BoardSpec.grand10.armySize, 16);
      expect(BoardSpec.grand10x20.armySize, 20);
    });

    test('the classic formation does not fit another board\'s rules', () {
      final formation = GameEngine.defaultFormation(PlayerColor.white);
      expect(
          FormationValidator.validate(formation, PlayerColor.white,
              spec: BoardSpec.skirmish6),
          isNotNull);
    });

    test('an unknown id is rejected', () {
      expect(() => BoardSpec.byId('moon'), throwsFormatException);
    });

    test('every board fits a CellSet', () {
      for (final spec in BoardSpec.all) {
        expect(spec.geometry.cellCount, lessThanOrEqualTo(CellSet.capacity));
      }
    });
  });

  group('BoardState JSON', () {
    test('a board without a spec reads as classic8', () {
      final board = boardWith({pos(0, 0): whiteKing});
      final decoded = BoardState.fromJson({
        'grid': [
          for (final row in board.grid) [for (final p in row) p?.toJson()],
        ],
        'powerFields': const [],
      });
      expect(decoded.spec, BoardSpec.classic8);
      expect(decoded.pieceAt(pos(0, 0)), whiteKing);
    });

    test('a hex board keeps its spec', () {
      final board = specBoard(BoardSpec.hex6, {pos(1, 3): blackPawn});
      final json = {
        'grid': [
          for (final row in board.grid) [for (final p in row) p?.toJson()],
        ],
        'powerFields': const [],
        'spec': board.toJson()['spec'],
      };
      final decoded = BoardState.fromJson(json);
      expect(decoded.spec, BoardSpec.hex6);
      expect(decoded, board);
    });
  });

  group('symmetric power fields', () {
    final generated = [
      for (final spec in BoardSpec.all)
        if (spec.powerFieldVariants == null) spec,
    ];

    test('are point-symmetric but for one central field', () {
      for (final spec in generated) {
        final geometry = spec.geometry;
        final centre = geometry.cells
            .map(geometry.distanceFromCentre)
            .reduce(min);
        for (var seed = 0; seed < 50; seed++) {
          final fields = PowerFieldGenerator.generateFor(spec, Random(seed))
              .map((f) => f.position)
              .toList();
          final reason = '${spec.id} seed $seed: $fields';
          expect(fields, hasLength(spec.powerFieldCount), reason: reason);
          expect(fields.toSet(), hasLength(fields.length), reason: reason);
          // The central field pairs with nothing, even where it is its
          // own mirror (the hexagon's middle cell).
          final unpaired = [
            for (final p in fields)
              if (!fields.contains(geometry.mirror(p)) ||
                  geometry.mirror(p) == p)
                p,
          ];
          expect(unpaired.length, spec.powerFieldCount.isOdd ? 1 : 0,
              reason: reason);
          for (final p in unpaired) {
            expect(geometry.distanceFromCentre(p), closeTo(centre, 1e-9),
                reason: reason);
          }
          for (final p in fields) {
            expect(geometry.contains(p), isTrue, reason: reason);
            expect(spec.formationRowsFor(PlayerColor.white), isNot(contains(p.row)),
                reason: reason);
            expect(spec.formationRowsFor(PlayerColor.black), isNot(contains(p.row)),
                reason: reason);
          }
        }
      }
    });

    test('the classic board keeps its eight variants', () {
      final fields = PowerFieldGenerator.generateFor(
              BoardSpec.classic8, Random(3))
          .map((f) => f.position)
          .toList();
      expect(PowerFieldGenerator.variants, anyElement(equals(fields)));
      expect(
          PowerFieldGenerator.generate('game-1')
              .map((f) => f.position)
              .toList(),
          PowerFieldGenerator.variants[
              Random('game-1'.hashCode).nextInt(8)]);
    });
  });

  group('CellSet', () {
    test('holds cells in both words', () {
      final set = CellSet();
      expect(set.isEmpty, isTrue);
      for (final i in [0, 63, 64, 99, 127]) {
        set.add(i);
      }
      for (var i = 0; i < 128; i++) {
        expect(set.contains(i), [0, 63, 64, 99, 127].contains(i), reason: '$i');
      }
      set.clear();
      expect(set.isEmpty, isTrue);
    });
  });
}
