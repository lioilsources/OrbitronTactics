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
}
