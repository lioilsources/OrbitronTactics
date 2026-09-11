import 'package:flutter_test/flutter_test.dart';
import 'package:orbitron_tactics/core/game_logic/models/piece.dart';
import 'package:orbitron_tactics/features/game/data/game_event.dart';

void main() {
  group('ShipMovedEvent', () {
    test('round-trips position and altitude', () {
      const event = ShipMovedEvent(
        color: PlayerColor.black,
        xFraction: 0.25,
        altitude: 0.8,
      );

      final decoded = GameEvent.fromJson(event.toJson()) as ShipMovedEvent;

      expect(
        (decoded.color, decoded.xFraction, decoded.altitude),
        (PlayerColor.black, 0.25, 0.8),
      );
    });

    test('a move from an app without altitude flies at the middle', () {
      final decoded = GameEvent.fromJson({
        'type': 'ship_moved',
        'color': 'white',
        'xFraction': 0.4,
      }) as ShipMovedEvent;

      expect(decoded.altitude, 0.5);
    });
  });
}
