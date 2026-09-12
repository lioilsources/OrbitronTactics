import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:orbitron_tactics/features/battle/presentation/widgets/arena_layout.dart';

void main() {
  const arena = Size(360, 600);

  double bottomAt(double altitude) =>
      ArenaLayout.shipY(altitude, atBottom: true, arena: arena);
  double topAt(double altitude) =>
      ArenaLayout.shipY(altitude, atBottom: false, arena: arena);

  group('ArenaLayout', () {
    test('the bottom ship flies from its own edge up to the divider', () {
      expect(bottomAt(0),
          closeTo(arena.height * (1 - ArenaLayout.edgeMargin), 0.001));
      expect(bottomAt(1),
          closeTo(arena.height * (0.5 + ArenaLayout.frontMargin), 0.001));
    });

    test('the top ship mirrors it', () {
      expect(topAt(0), closeTo(arena.height * ArenaLayout.edgeMargin, 0.001));
      expect(topAt(1),
          closeTo(arena.height * (0.5 - ArenaLayout.frontMargin), 0.001));
    });

    test('climbing moves a ship toward the enemy, diving back', () {
      for (var step = 1; step <= 10; step++) {
        final lower = (step - 1) / 10;
        final higher = step / 10;
        expect(bottomAt(higher), lessThan(bottomAt(lower)));
        expect(topAt(higher), greaterThan(topAt(lower)));
      }
    });

    test('no ship leaves its own half', () {
      for (var step = 0; step <= 10; step++) {
        final altitude = step / 10;
        expect(bottomAt(altitude), greaterThan(arena.height / 2));
        expect(bottomAt(altitude), lessThan(arena.height));
        expect(topAt(altitude), lessThan(arena.height / 2));
        expect(topAt(altitude), greaterThan(0));
      }
    });

    test('the full altitude range covers travelFraction of the arena', () {
      expect(bottomAt(0) - bottomAt(1),
          closeTo(arena.height * ArenaLayout.travelFraction, 0.001));
    });
  });
}
