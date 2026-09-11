import 'package:flutter_test/flutter_test.dart';
import 'package:orbitron_tactics/core/game_logic/engine/battle_engine.dart';
import 'package:orbitron_tactics/core/game_logic/models/battle_state.dart';
import 'package:orbitron_tactics/core/game_logic/models/piece.dart';
import 'package:orbitron_tactics/core/game_logic/models/upgrade_profile.dart';

void main() {
  BattleState createBattle() {
    return BattleEngine.createBattle(
      attacker: const Piece(type: PieceType.rook, color: PlayerColor.white),
      defender: const Piece(type: PieceType.pawn, color: PlayerColor.black),
      attackerUpgrades: UpgradeProfile.empty(),
      defenderUpgrades: UpgradeProfile.empty(),
    );
  }

  group('BattleEngine - ship movement', () {
    test('ships start centered', () {
      final battle = createBattle();
      expect(battle.attacker.xFraction, 0.5);
      expect(battle.defender.xFraction, 0.5);
    });

    test('moveShip moves the right unit', () {
      var battle = createBattle();
      battle = BattleEngine.moveShip(battle, true, 0.2);
      battle = BattleEngine.moveShip(battle, false, 0.8);
      expect(battle.attacker.xFraction, 0.2);
      expect(battle.defender.xFraction, 0.8);
    });

    test('moveShip clamps to arena margins', () {
      var battle = createBattle();
      battle = BattleEngine.moveShip(battle, true, -1.0);
      expect(battle.attacker.xFraction, BattleEngine.shipEdgeMargin);
      battle = BattleEngine.moveShip(battle, true, 2.0);
      expect(battle.attacker.xFraction, 1.0 - BattleEngine.shipEdgeMargin);
    });

    test('projectiles fire from the shooter position', () {
      var battle = createBattle();
      battle = BattleEngine.moveShip(battle, true, 0.2);
      // Tick until the attacker fires at least once
      while (battle.projectiles.isEmpty) {
        battle = BattleEngine.tick(battle, 100);
      }
      final attackerShot =
          battle.projectiles.where((p) => p.fromAttacker).toList();
      if (attackerShot.isNotEmpty) {
        expect(attackerShot.first.xFraction, 0.2);
      }
    });

    test('dodged projectile deals no damage', () {
      var battle = createBattle();
      // Defender moves far away from the attacker's firing lane
      battle = BattleEngine.moveShip(battle, false, 0.9);
      final startHp = battle.defender.currentHp;

      // Attacker keeps firing from 0.5; the defender stays parked at 0.9,
      // outside hitHalfWidth, so every shot must miss.
      for (var i = 0; i < 50 && !battle.isFinished; i++) {
        battle = BattleEngine.tick(battle, 100);
        battle = BattleEngine.moveShip(battle, false, 0.9);
      }

      expect(battle.defender.currentHp, startHp,
          reason: 'shots fired from 0.5 must miss a ship parked at 0.9');
    });

    test('aligned projectile hits', () {
      var battle = createBattle();
      final startHp = battle.defender.currentHp;

      for (var i = 0; i < 30 && !battle.isFinished; i++) {
        battle = BattleEngine.tick(battle, 100);
      }

      expect(battle.defender.currentHp, lessThan(startHp),
          reason: 'both ships centered — shots must connect');
    });
  });

  group('BattleEngine - altitude', () {
    /// Ticks [battle] until a rook shot has struck the pawn or its shield.
    /// The pawn fires faster, so the rook is struck first.
    BattleState untilDefenderStruck(BattleState battle) {
      while (!battle.impacts.any((impact) => !impact.onAttacker) &&
          !battle.isFinished) {
        battle = BattleEngine.tick(battle, 100);
      }
      return battle;
    }

    test('ships start at mid altitude', () {
      final battle = createBattle();
      expect(battle.attacker.altitude, 0.5);
      expect(battle.defender.altitude, 0.5);
    });

    test('moveShip sets and clamps the altitude, or keeps it', () {
      var battle = createBattle();
      battle = BattleEngine.moveShip(battle, true, 0.5, altitude: 0.8);
      expect(battle.attacker.altitude, 0.8);
      battle = BattleEngine.moveShip(battle, true, 0.3);
      expect(battle.attacker.altitude, 0.8);
      battle = BattleEngine.moveShip(battle, true, 0.3, altitude: 1.4);
      expect(battle.attacker.altitude, 1.0);
      battle = BattleEngine.moveShip(battle, true, 0.3, altitude: -0.2);
      expect(battle.attacker.altitude, 0.0);
    });

    test('projectiles hold the altitude they were fired at', () {
      var battle = BattleEngine.moveShip(createBattle(), true, 0.5,
          altitude: 0.8);
      while (!battle.projectiles.any((p) => p.fromAttacker)) {
        battle = BattleEngine.tick(battle, 100);
      }
      battle = BattleEngine.moveShip(battle, true, 0.5, altitude: 0.1);
      battle = BattleEngine.tick(battle, 100);

      expect(battle.projectiles.firstWhere((p) => p.fromAttacker).altitude, 0.8);
    });

    test('a shot at another altitude misses a ship in its lane', () {
      var battle = createBattle();
      final startHp = battle.defender.currentHp;

      for (var i = 0; i < 50 && !battle.isFinished; i++) {
        battle = BattleEngine.tick(battle, 100);
        battle = BattleEngine.moveShip(battle, false, 0.5,
            altitude: 0.5 + BattleEngine.hitHalfAltitude + 0.05);
      }

      expect(battle.defender.currentHp, startHp);
      expect(battle.impacts, isEmpty);
    });

    test('a shot within the altitude band hits', () {
      var battle = BattleEngine.moveShip(createBattle(), false, 0.5,
          altitude: 0.5 + BattleEngine.hitHalfAltitude - 0.02);
      final startHp = battle.defender.currentHp;

      battle = untilDefenderStruck(battle);

      expect(battle.defender.currentHp, lessThan(startHp));
      final impact = battle.impacts.firstWhere((impact) => !impact.onAttacker);
      expect(impact.shielded, isFalse);
      expect(impact.altitude, 0.5);
      expect(impact.damage, battle.attacker.stats.damage);
    });

    test('a shot into a raised shield is an impact without damage', () {
      var battle = createBattle();
      // The rook's first shot leaves at 1200 ms and lands 700 ms later.
      while (battle.elapsedMs < 1000) {
        battle = BattleEngine.tick(battle, 100);
      }
      battle = BattleEngine.activateShield(battle, false);
      final startHp = battle.defender.currentHp;

      battle = untilDefenderStruck(battle);

      expect(
        battle.impacts.firstWhere((impact) => !impact.onAttacker).shielded,
        isTrue,
      );
      expect(battle.defender.currentHp, startHp);
    });

    test('impacts are forgotten after impactMemoryMs', () {
      var battle = untilDefenderStruck(createBattle());
      // Out of the lane, so no new shot lands; the pawn's last shots may
      // still be in flight for up to 300 ms.
      for (var ms = 0; ms <= BattleEngine.impactMemoryMs + 500; ms += 100) {
        battle = BattleEngine.moveShip(battle, false, 0.9);
        battle = BattleEngine.tick(battle, 100);
      }

      expect(battle.impacts, isEmpty);
    });
  });
}
