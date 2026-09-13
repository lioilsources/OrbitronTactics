import 'package:flutter_test/flutter_test.dart';
import 'package:orbitron_tactics/core/game_logic/models/piece.dart';
import 'package:orbitron_tactics/features/game/data/game_event.dart';

void main() {
  group('ManeuverStartedEvent', () {
    test('round-trips the maneuver and what it is flown against', () {
      const event = ManeuverStartedEvent(
        color: PlayerColor.black,
        maneuverId: 'knight.signature',
        level: 3,
        mirrored: true,
        originX: 0.25,
        originAltitude: 0.4,
        enemyX: 0.7,
        enemyAltitude: 0.9,
      );

      final decoded = GameEvent.fromJson(event.toJson()) as ManeuverStartedEvent;

      expect(decoded.color, PlayerColor.black);
      expect(decoded.maneuverId, 'knight.signature');
      expect(decoded.level, 3);
      expect(decoded.mirrored, isTrue);
      expect((decoded.originX, decoded.originAltitude), (0.25, 0.4));
      expect((decoded.enemyX, decoded.enemyAltitude), (0.7, 0.9));
    });

    test('an event without the extras flies level one, unmirrored', () {
      final decoded = GameEvent.fromJson({
        'type': 'maneuver_started',
        'color': 'white',
        'maneuverId': 'pawn.sidestep',
      }) as ManeuverStartedEvent;

      expect(decoded.level, 1);
      expect(decoded.mirrored, isFalse);
      expect(decoded.originAltitude, 0.5);
    });
  });
}
