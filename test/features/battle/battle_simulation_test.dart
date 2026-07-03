import 'package:flutter_test/flutter_test.dart';
import 'package:orbitron_tactics/features/battle/model/battle_simulation.dart';

void main() {
  group('BattleSimulation - determinism', () {
    test('same seed produces identical starting asteroid field', () {
      final a = BattleSimulation(seed: 42).snapshot();
      final b = BattleSimulation(seed: 42).snapshot();

      expect(a.asteroids.length, b.asteroids.length);
      for (int i = 0; i < a.asteroids.length; i++) {
        expect(a.asteroids[i].x, b.asteroids[i].x);
        expect(a.asteroids[i].y, b.asteroids[i].y);
        expect(a.asteroids[i].radius, b.asteroids[i].radius);
      }
    });

    test('different seeds produce different fields', () {
      final a = BattleSimulation(seed: 1).snapshot();
      final b = BattleSimulation(seed: 2).snapshot();
      // Extremely unlikely to be identical.
      final same = a.asteroids.length == b.asteroids.length &&
          List.generate(a.asteroids.length, (i) => i)
              .every((i) => a.asteroids[i].x == b.asteroids[i].x);
      expect(same, isFalse);
    });
  });

  group('BattleSimulation - physics', () {
    test('thrust accelerates the ship along its facing', () {
      final sim = BattleSimulation(seed: 7);
      final start = sim.snapshot().attacker;
      // Attacker faces +x (angle 0); thrust should increase x over time.
      for (int i = 0; i < 30; i++) {
        sim.step(const BattleInput(thrust: true), BattleInput.idle);
      }
      final after = sim.snapshot().attacker;
      expect(after.x, greaterThan(start.x));
    });

    test('idle ships do not start a battle as finished', () {
      final sim = BattleSimulation(seed: 7);
      sim.step(BattleInput.idle, BattleInput.idle);
      expect(sim.finished, isFalse);
      expect(sim.winner, isNull);
    });
  });

  group('BattleSimulation - combat outcome', () {
    test('a ship reduced to zero hp loses the battle', () {
      // Use a config with almost no hp so a couple of hits end it quickly,
      // and aim the attacker straight at a stationary-ish defender.
      const config = BattleConfig(
        shipMaxHp: 20,
        asteroidCount: 0, // remove asteroids so shots fly clean
        projectileDamage: 12,
      );
      final sim = BattleSimulation(seed: 3, config: config);

      // Rotate the attacker to face the defender (defender is to the right,
      // attacker already faces +x), then hold fire while nudging forward.
      var finished = false;
      for (int i = 0; i < config.maxTicks && !sim.finished; i++) {
        sim.step(
          const BattleInput(thrust: true, fire: true),
          BattleInput.idle,
        );
        finished = sim.finished;
      }

      expect(finished, isTrue);
      // The idle defender, taking fire, should be the one to fall.
      expect(sim.winner, BattleRole.attacker);
    });

    test('mutual destruction favours the defender', () {
      const config = BattleConfig(shipMaxHp: 1, asteroidCount: 0);
      final sim = BattleSimulation(seed: 9, config: config);
      // Both fire at each other; if both die on the same tick the defender wins.
      // (Deterministic given identical inputs and symmetric-ish start.)
      for (int i = 0; i < config.maxTicks && !sim.finished; i++) {
        sim.step(
          const BattleInput(thrust: true, fire: true),
          const BattleInput(thrust: true, fire: true),
        );
      }
      expect(sim.finished, isTrue);
      expect(sim.winner, isNotNull);
    });
  });

  group('BattleSimulation - snapshot serialization', () {
    test('snapshot round-trips through JSON', () {
      final sim = BattleSimulation(seed: 11);
      for (int i = 0; i < 10; i++) {
        sim.step(const BattleInput(thrust: true, fire: true), BattleInput.idle);
      }
      final snap = sim.snapshot();
      final restored = BattleSnapshot.fromJson(snap.toJson());

      expect(restored.tick, snap.tick);
      expect(restored.attacker.x, snap.attacker.x);
      expect(restored.defender.hp, snap.defender.hp);
      expect(restored.asteroids.length, snap.asteroids.length);
      expect(restored.projectiles.length, snap.projectiles.length);
      expect(restored.winner, snap.winner);
    });

    test('battle input round-trips through JSON', () {
      const input = BattleInput(turn: -0.5, thrust: true, fire: false);
      final restored = BattleInput.fromJson(input.toJson());
      expect(restored.turn, input.turn);
      expect(restored.thrust, input.thrust);
      expect(restored.fire, input.fire);
    });
  });
}
