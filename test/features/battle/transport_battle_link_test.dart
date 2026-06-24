import 'package:flutter_test/flutter_test.dart';
import 'package:orbitron_tactics/features/battle/model/battle_simulation.dart';
import 'package:orbitron_tactics/features/battle/net/battle_controller.dart';
import 'package:orbitron_tactics/features/battle/net/transport_battle_link.dart';
import 'package:orbitron_tactics/features/game/data/game_transport.dart';

Future<void> _flush() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

void main() {
  group('TransportBattleLink', () {
    test('runs a full battle over a paired game transport', () async {
      const config = BattleConfig(shipMaxHp: 24, asteroidCount: 0);
      final (tA, tB) = LocalGameTransport.createPair();
      await tA.connect();
      await tB.connect();

      final hostLink = TransportBattleLink(tA);
      final guestLink = TransportBattleLink(tB);

      final host = BattleController.host(
        link: hostLink,
        localRole: BattleRole.attacker,
        seed: 5,
        config: config,
      );
      final guest = BattleController.guest(
        link: guestLink,
        localRole: BattleRole.defender,
        seed: 5,
        config: config,
      );

      host.localInput = const BattleInput(thrust: true, fire: true);

      for (int i = 0; i < config.maxTicks && !host.finished; i++) {
        host.tick();
        guest.tick();
        if (i % 8 == 0) await _flush();
      }
      await _flush();
      await _flush();

      expect(host.finished, isTrue);
      expect(host.winner, BattleRole.attacker);
      // Guest learned the outcome from the authoritative finished snapshot.
      expect(guest.winner, BattleRole.attacker);

      host.dispose();
      guest.dispose();
      hostLink.dispose();
      guestLink.dispose();
    });
  });
}
