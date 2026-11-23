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
}
