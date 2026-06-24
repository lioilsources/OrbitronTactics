import 'package:flutter_test/flutter_test.dart';
import 'package:orbitron_tactics/features/battle/model/battle_simulation.dart';
import 'package:orbitron_tactics/features/battle/net/battle_controller.dart';
import 'package:orbitron_tactics/features/battle/net/battle_link.dart';

/// Pump the microtask/event queue so in-memory link messages are delivered.
Future<void> _flush() => Future<void>.delayed(Duration.zero);

void main() {
  group('BattleController - host-authoritative loop', () {
    test('host and guest converge on the same winner', () async {
      const config = BattleConfig(shipMaxHp: 24, asteroidCount: 0);
      final (linkA, linkB) = LocalBattleLink.createPair();

      final host = BattleController.host(
        link: linkA,
        localRole: BattleRole.attacker,
        seed: 5,
        config: config,
      );
      final guest = BattleController.guest(
        link: linkB,
        localRole: BattleRole.defender,
        seed: 5,
        config: config,
      );

      // Attacker pours fire into the idle defender.
      host.localInput = const BattleInput(thrust: true, fire: true);
      guest.localInput = BattleInput.idle;

      for (int i = 0; i < config.maxTicks && !host.finished; i++) {
        host.tick();
        guest.tick();
        if (i % 8 == 0) await _flush();
      }
      await _flush();
      await _flush();

      expect(host.finished, isTrue);
      expect(host.winner, BattleRole.attacker);
      // The result propagated to the guest.
      expect(guest.winner, BattleRole.attacker);

      host.dispose();
      guest.dispose();
    });

    test('guest receives authoritative snapshots from the host', () async {
      const config = BattleConfig(asteroidCount: 3);
      final (linkA, linkB) = LocalBattleLink.createPair();

      final host = BattleController.host(
        link: linkA,
        localRole: BattleRole.attacker,
        seed: 1,
        config: config,
      );
      final guest = BattleController.guest(
        link: linkB,
        localRole: BattleRole.defender,
        seed: 1,
        config: config,
      );

      expect(guest.latestSnapshot, isNull);

      for (int i = 0; i < 10; i++) {
        host.localInput = const BattleInput(thrust: true);
        host.tick();
        guest.tick();
        await _flush();
      }

      expect(guest.latestSnapshot, isNotNull);
      expect(guest.latestSnapshot!.asteroids.length, 3);

      host.dispose();
      guest.dispose();
    });

    test('onResolved fires exactly once for the host', () async {
      const config = BattleConfig(shipMaxHp: 12, asteroidCount: 0);
      final (linkA, linkB) = LocalBattleLink.createPair();

      final host = BattleController.host(
        link: linkA,
        localRole: BattleRole.attacker,
        seed: 2,
        config: config,
      );
      final guest = BattleController.guest(
        link: linkB,
        localRole: BattleRole.defender,
        seed: 2,
        config: config,
      );

      var resolvedCount = 0;
      host.onResolved.listen((_) => resolvedCount++);

      host.localInput = const BattleInput(thrust: true, fire: true);
      for (int i = 0; i < config.maxTicks && !host.finished; i++) {
        host.tick();
        guest.tick();
        if (i % 8 == 0) await _flush();
      }
      await _flush();

      expect(resolvedCount, 1);

      host.dispose();
      guest.dispose();
    });
  });
}
