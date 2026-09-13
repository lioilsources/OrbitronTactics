import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbitron_tactics/core/game_logic/models/piece.dart';
import 'package:orbitron_tactics/core/maneuvers/maneuver.dart';
import 'package:orbitron_tactics/core/maneuvers/maneuver_catalog.dart';
import 'package:orbitron_tactics/core/maneuvers/pattern_recognizer.dart';
import 'package:orbitron_tactics/features/battle/presentation/widgets/maneuver_pad.dart';

void main() {
  const padSize = 96.0;
  final sidestep = ManeuverCatalog.forShip(PieceType.knight)
      .firstWhere((maneuver) => maneuver.family == ManeuverFamily.sidestep);

  ManeuverSlot? flown;
  bool? flownMirrored;

  setUp(() {
    flown = null;
    flownMirrored = null;
  });

  Future<void> pumpPad(
    WidgetTester tester, {
    double energy = 100,
    bool enabled = true,
  }) =>
      tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: ManeuverPad(
              slots: [(maneuver: sidestep, level: 1)],
              energy: energy,
              accent: Colors.cyanAccent,
              enabled: enabled,
              size: padSize,
              onManeuver: (slot, {required bool mirrored}) {
                flown = slot;
                flownMirrored = mirrored;
              },
            ),
          ),
        ),
      ));

  /// Drags a finger over the centre of every dot of [gesture] in turn.
  Future<void> draw(WidgetTester tester, List<int> gesture) async {
    final origin = tester.getTopLeft(find.byType(ManeuverPad));
    Offset dotAt(int dot) {
      final (x, y) = PatternRecognizer.centreOf(dot);
      return origin + Offset(x * padSize, y * padSize);
    }

    final finger = await tester.startGesture(dotAt(gesture.first));
    for (final dot in gesture.skip(1)) {
      await finger.moveTo(dotAt(dot));
      await tester.pump();
    }
    await finger.up();
    // Long enough for the pad's rejection flash to finish.
    await tester.pump(const Duration(milliseconds: 300));
  }

  group('ManeuverPad', () {
    testWidgets('an armed gesture flies its maneuver', (tester) async {
      await pumpPad(tester);

      await draw(tester, sidestep.pattern);

      expect(flown?.maneuver.id, sidestep.id);
      expect(flownMirrored, isFalse);
    });

    testWidgets('the mirrored gesture flies it mirrored', (tester) async {
      await pumpPad(tester);

      await draw(tester, [5, 4, 3]);

      expect(flown?.maneuver.id, sidestep.id);
      expect(flownMirrored, isTrue);
    });

    testWidgets('a gesture nobody armed does nothing', (tester) async {
      await pumpPad(tester);

      await draw(tester, [0, 1, 2]);

      expect(flown, isNull);
    });

    testWidgets('without the energy the pad refuses', (tester) async {
      await pumpPad(tester, energy: 5);

      await draw(tester, sidestep.pattern);

      expect(flown, isNull);
    });

    testWidgets('a pad in the middle of a maneuver is deaf', (tester) async {
      await pumpPad(tester, enabled: false);

      await draw(tester, sidestep.pattern);

      expect(flown, isNull);
    });
  });
}
