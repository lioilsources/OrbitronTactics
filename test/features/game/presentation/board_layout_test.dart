import 'dart:math';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:orbitron_tactics/core/game_logic/board/board_geometry.dart';
import 'package:orbitron_tactics/core/game_logic/board/board_spec.dart';
import 'package:orbitron_tactics/core/game_logic/models/position.dart';
import 'package:orbitron_tactics/features/game/presentation/widgets/board/board_layout.dart';

void main() {
  const hex = HexGeometry.hexagon(6);

  group('square board', () {
    final layout = BoardLayout.fit(BoardSpec.classic8.geometry, 400);

    test('keeps the classic grid: white row 0 at the bottom', () {
      expect(layout.size, const Size(400, 400));
      expect(layout.cellSize, 50);
      expect(layout.centreOf(const Position(row: 0, col: 0)),
          const Offset(25, 375));
      expect(layout.shadeOf(const Position(row: 0, col: 0)), 1);
    });

    test('flipped turns it around', () {
      final flipped =
          BoardLayout.fit(BoardSpec.classic8.geometry, 400, flipped: true);
      expect(flipped.centreOf(const Position(row: 0, col: 0)),
          const Offset(375, 25));
    });
  });

  group('hex board', () {
    for (final flipped in [false, true]) {
      final layout = BoardLayout.fit(hex, 340, flipped: flipped);

      test('a tap on a cell centre finds that cell (flipped: $flipped)', () {
        for (final p in hex.cells) {
          expect(layout.positionAt(layout.centreOf(p)), p);
        }
      });

      test('every cell lies inside the board (flipped: $flipped)', () {
        final bounds = Offset.zero & layout.size;
        for (final p in hex.cells) {
          final box = layout.cellPath(p).getBounds();
          expect(bounds.inflate(0.01).contains(box.topLeft), isTrue);
          expect(bounds.inflate(0.01).contains(box.bottomRight), isTrue);
        }
      });
    }

    final layout = BoardLayout.fit(hex, 340);

    test('edge neighbours sit one cell width apart, in other shades', () {
      const from = Position(row: 5, col: 5);
      for (final d in hex.straight) {
        final to = hex.step(from, d);
        expect((layout.centreOf(to) - layout.centreOf(from)).distance,
            closeTo(layout.cellSize, 1e-9));
        expect(layout.shadeOf(to), isNot(layout.shadeOf(from)));
      }
    });

    test('forward (north) is up the screen for white', () {
      const from = Position(row: 2, col: 3);
      final to = hex.step(from, HexGeometry.north);
      final delta = layout.centreOf(to) - layout.centreOf(from);
      expect(delta.dx, closeTo(0, 1e-9));
      expect(delta.dy, lessThan(0));
    });

    test('a tap outside every hex finds nothing', () {
      expect(layout.positionAt(const Offset(1, 1)), isNull);
    });

    test('the hexagon fills the width: the long row spans it', () {
      final left = layout.cellPath(const Position(row: 5, col: 0)).getBounds();
      final right =
          layout.cellPath(const Position(row: 5, col: 10)).getBounds();
      expect(left.left, closeTo(0, 1e-9));
      expect(right.right, closeTo(layout.size.width, 1e-9));
    });
  });

  group('tilted board', () {
    const hexTilt = BoardTilt(squash: 0.85, figureHeight: 1.25);
    const squareTilt = BoardTilt(squash: 1.0, figureHeight: 1.25);
    const leanSquare = BoardTilt(squash: 0.72, figureHeight: 1.5);
    final boards = [
      (hex, hexTilt),
      (BoardSpec.classic8.geometry, squareTilt),
      (BoardSpec.classic8.geometry, leanSquare),
    ];

    for (final (geometry, tilt) in boards) {
      for (final flipped in [false, true]) {
        final layout =
            BoardLayout.fit(geometry, 360, flipped: flipped, tilt: tilt);
        final name = '${geometry.runtimeType} $tilt flipped: $flipped';

        test('every cell centre finds its cell ($name)', () {
          for (final p in geometry.cells) {
            expect(layout.positionAt(layout.centreOf(p)), p);
          }
        });

        test('a tap near the edge of a squashed cell stays in it ($name)',
            () {
          for (final p in geometry.cells) {
            final c = layout.centreOf(p);
            final half = 0.45 * tilt.squash * layout.cellSize;
            expect(layout.positionAt(c + Offset(0, half)), p);
            expect(layout.positionAt(c - Offset(0, half)), p);
          }
        });

        test('the board has room for the back row on top ($name)', () {
          final flat = BoardLayout.fit(geometry, 360, flipped: flipped);
          final top = StandingFigure.plinthAnchor *
                  tilt.figureHeight *
                  layout.cellSize -
              tilt.squash * (flat.centreOf(geometry.cells.first).dy -
                  flat.cellPath(geometry.cells.first).getBounds().top);
          expect(layout.cellSize, flat.cellSize);
          // Only the vertical extent changes: squashed, plus the room.
          final room = layout.size.height - tilt.squash * flat.size.height;
          expect(room, greaterThan(0));
          final bounds = Offset.zero & layout.size;
          for (final p in geometry.cells) {
            final box = layout.pieceBox(p);
            expect(box.top, greaterThanOrEqualTo(-1e-9), reason: '$p');
            expect(box.bottom, lessThanOrEqualTo(layout.size.height + 1e-9));
            final cell = layout.cellPath(p).getBounds();
            expect(bounds.inflate(0.01).contains(cell.topLeft), isTrue);
            expect(bounds.inflate(0.01).contains(cell.bottomRight), isTrue);
          }
          // The tallest back-row figure just touches the top.
          final highest = geometry.cells
              .map((p) => layout.pieceBox(p).top)
              .reduce(min);
          expect(highest, closeTo(0, 1e-9));
          expect(room, closeTo(top, 1e-3)); // Path bounds are single precision.
        });

        test('figures stand on their cells ($name)', () {
          for (final p in geometry.cells) {
            final box = layout.pieceBox(p);
            final c = layout.centreOf(p);
            expect(box.width, closeTo(tilt.figureHeight * layout.cellSize, 1e-9));
            expect(box.center.dx, closeTo(c.dx, 1e-9));
            expect(box.top + StandingFigure.plinthAnchor * box.height,
                closeTo(c.dy, 1e-9));
          }
        });

        test('pieces are painted back to front ($name)', () {
          final order = layout.inDrawOrder(geometry.cells.toList().reversed);
          expect(order.toSet(), geometry.cells.toSet());
          for (var i = 1; i < order.length; i++) {
            final a = layout.centreOf(order[i - 1]);
            final b = layout.centreOf(order[i]);
            expect(a.dy < b.dy || (a.dy == b.dy && a.dx < b.dx), isTrue);
          }
        });
      }
    }

    test('vertical distances shrink by the squash, horizontal ones stay', () {
      final flat = BoardLayout.fit(hex, 360);
      final tilted = BoardLayout.fit(hex, 360, tilt: hexTilt);
      const a = Position(row: 5, col: 5);
      const b = Position(row: 7, col: 5);
      const c = Position(row: 5, col: 7);
      expect((tilted.centreOf(b) - tilted.centreOf(a)).dy,
          closeTo(0.85 * (flat.centreOf(b) - flat.centreOf(a)).dy, 1e-9));
      expect((tilted.centreOf(c) - tilted.centreOf(a)).dx,
          closeTo((flat.centreOf(c) - flat.centreOf(a)).dx, 1e-9));
    });

    test('a flipped tilted board turns the flat one around', () {
      final up = BoardLayout.fit(hex, 360, tilt: hexTilt);
      final down = BoardLayout.fit(hex, 360, flipped: true, tilt: hexTilt);
      expect(down.size, up.size);
      for (final p in hex.cells) {
        final mirrored = up.flatCentreOf(p);
        final turned = down.flatCentreOf(p);
        expect(turned.dx, closeTo(up.size.width - mirrored.dx, 1e-9));
        expect(down.toFlat(down.centreOf(p)).dy, closeTo(turned.dy, 1e-9));
      }
    });
  });
}
