import 'package:flutter_test/flutter_test.dart';
import 'package:orbitron_tactics/core/game_logic/board/board_spec.dart';
import 'package:orbitron_tactics/core/game_logic/models/position.dart';
import 'package:orbitron_tactics/features/game/presentation/widgets/board/board_layout.dart';
import 'package:orbitron_tactics/features/game/presentation/widgets/board/tap_resolver.dart';

void main() {
  /// The cells one cell width from [p]'s centre.
  List<Position> neighboursOf(BoardLayout layout, Position p) => [
        for (final q in layout.geometry.cells)
          if (q != p &&
              ((layout.centreOf(q) - layout.centreOf(p)).distance -
                          layout.cellSize)
                      .abs() <
                  1e-6)
            q,
      ];

  /// The unit vector from [from]'s centre to [to]'s.
  Offset towards(BoardLayout layout, Position from, Position to) {
    final d = layout.centreOf(to) - layout.centreOf(from);
    return d / d.distance;
  }

  for (final flipped in [false, true]) {
    group('hex board (flipped: $flipped)', () {
      final layout =
          BoardLayout.fit(BoardSpec.hex6.geometry, 360, flipped: flipped);
      final cell = layout.cellSize;
      // A cell in the middle of the board: all six neighbours exist.
      const middle = Position(row: 5, col: 5);

      test('the middle cell has six neighbours one cell apart', () {
        expect(neighboursOf(layout, middle), hasLength(6));
      });

      test('the default reach is below one cell', () {
        expect(tapReachFor(layout), 0.8);
      });

      test('a tap just beside a target lands on it', () {
        final target = middle;
        for (final empty in neighboursOf(layout, target)) {
          final point = layout.centreOf(target) +
              towards(layout, target, empty) * (0.7 * cell);
          expect(layout.positionAt(point), empty);
          expect(
              resolveTap(layout, point, preferred: {target}), target);
        }
      });

      test('a tap beyond the reach keeps the cell under the finger', () {
        final empty = neighboursOf(layout, middle).first;
        final point = layout.centreOf(middle) +
            towards(layout, middle, empty) * (0.85 * cell);
        expect(resolveTap(layout, point, preferred: {middle}), empty);
      });

      test('a preferred cell under the finger beats a nearer one', () {
        final other = neighboursOf(layout, middle).first;
        final point = layout.centreOf(middle) +
            towards(layout, middle, other) * (0.45 * cell);
        expect(resolveTap(layout, point, preferred: {middle, other}),
            middle);
      });

      test('between two targets the nearer one wins', () {
        final around = neighboursOf(layout, middle);
        // Two neighbours of the middle cell that neighbour each other.
        final first = around.first;
        final second = around.firstWhere((q) =>
            q != first && neighboursOf(layout, first).contains(q));
        final point = layout.centreOf(middle) +
            towards(layout, middle, first) * (0.3 * cell) +
            towards(layout, middle, second) * (0.15 * cell);
        expect(layout.positionAt(point), middle);
        expect(resolveTap(layout, point, preferred: {first, second}),
            first);
        final mirrored = layout.centreOf(middle) +
            towards(layout, middle, first) * (0.15 * cell) +
            towards(layout, middle, second) * (0.3 * cell);
        expect(resolveTap(layout, mirrored, preferred: {first, second}),
            second);
      });

      test('a tap in the middle of an empty cell never snaps away', () {
        final around = neighboursOf(layout, middle).toSet();
        expect(
            resolveTap(layout, layout.centreOf(middle), preferred: around),
            middle);
      });

      test('with nothing preferred a tap is exact', () {
        for (final p in layout.geometry.cells) {
          expect(resolveTap(layout, layout.centreOf(p), preferred: {}), p);
        }
      });

      test('off the board and out of reach is nothing', () {
        expect(
            resolveTap(layout, const Offset(-100, -100),
                preferred: {middle}),
            isNull);
      });
    });

    group('square board (flipped: $flipped)', () {
      final layout =
          BoardLayout.fit(BoardSpec.classic8.geometry, 360, flipped: flipped);
      final cell = layout.cellSize;
      const target = Position(row: 3, col: 3);
      const empty = Position(row: 3, col: 4);

      test('keeps exact taps: the default reach is zero', () {
        expect(tapReachFor(layout), 0);
        final point = layout.centreOf(target) +
            towards(layout, target, empty) * (0.7 * cell);
        expect(
            resolveTap(layout, point,
                preferred: {target}, reach: tapReachFor(layout)),
            empty);
      });

      test('with a reach it snaps like the hex board', () {
        final point = layout.centreOf(target) +
            towards(layout, target, empty) * (0.7 * cell);
        expect(resolveTap(layout, point, preferred: {target}), target);
        expect(
            resolveTap(layout, layout.centreOf(empty),
                preferred: {target}),
            empty);
      });
    });
  }
}
