import 'package:flutter_test/flutter_test.dart';
import 'package:orbitron_tactics/core/game_logic/engine/battle_engine.dart';
import 'package:orbitron_tactics/core/game_logic/engine/unit_base_stats.dart';
import 'package:orbitron_tactics/core/game_logic/models/battle_state.dart';
import 'package:orbitron_tactics/core/game_logic/models/battle_unit.dart';
import 'package:orbitron_tactics/core/game_logic/models/piece.dart';
import 'package:orbitron_tactics/core/game_logic/models/projectile.dart';
import 'package:orbitron_tactics/core/game_logic/models/shield_state.dart';
import 'package:orbitron_tactics/core/game_logic/models/upgrade_profile.dart';
import 'package:orbitron_tactics/core/maneuvers/maneuver.dart';
import 'package:orbitron_tactics/core/maneuvers/maneuver_catalog.dart';

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

  group('BattleEngine - maneuvers', () {
    Maneuver maneuverOf(PieceType ship, ManeuverFamily family) =>
        ManeuverCatalog.forShip(ship)
            .firstWhere((maneuver) => maneuver.family == family);

    /// Two ships of [type] that only fire when a maneuver tells them to.
    BattleState idle(PieceType type) {
      final stats = unitBaseStats[type]!;
      BattleUnit ship(PlayerColor color) => BattleUnit(
            piece: Piece(type: type, color: color),
            stats: stats,
            currentHp: stats.maxHp,
            shieldState: const ShieldState(),
            nextAttackMs: 1 << 30,
          );
      return BattleState(
        attacker: ship(PlayerColor.white),
        defender: ship(PlayerColor.black),
      );
    }

    BattleState fly(BattleState battle, int ms, {int step = 16}) {
      for (var elapsed = 0; elapsed < ms; elapsed += step) {
        battle = BattleEngine.tick(battle, step);
      }
      return battle;
    }

    test('ships start half charged and win energy back over time', () {
      var battle = idle(PieceType.knight);
      expect(battle.attacker.energy, BattleUnit.startingEnergy);

      battle = fly(battle, 1000);
      expect(
        battle.attacker.energy,
        closeTo(BattleUnit.startingEnergy + BattleEngine.energyPerSecond, 0.5),
      );

      battle = fly(battle, 10000);
      expect(battle.attacker.energy, BattleUnit.maxEnergy);
    });

    test('a maneuver costs energy, and one too dear never starts', () {
      final sidestep = maneuverOf(PieceType.knight, ManeuverFamily.sidestep);
      final battle = idle(PieceType.knight);

      final flying = BattleEngine.startManeuver(battle, true, sidestep);
      expect(flying.attacker.maneuver!.id, sidestep.id);
      expect(flying.attacker.energy,
          BattleUnit.startingEnergy - sidestep.energyCost);

      final drained =
          battle.copyWith(attacker: battle.attacker.copyWith(energy: 10));
      expect(
        BattleEngine.startManeuver(drained, true, sidestep).attacker.maneuver,
        isNull,
      );
      // The opponent's device already flew it: price paid or not, it runs.
      final forced =
          BattleEngine.startManeuver(drained, true, sidestep, force: true);
      expect(forced.attacker.maneuver, isNotNull);
      expect(forced.attacker.energy, 0);
    });

    test('one maneuver at a time', () {
      final sidestep = maneuverOf(PieceType.knight, ManeuverFamily.sidestep);
      final strike = maneuverOf(PieceType.knight, ManeuverFamily.strike);
      final battle =
          BattleEngine.startManeuver(idle(PieceType.knight), true, sidestep);

      final second = BattleEngine.startManeuver(battle, true, strike);

      expect(second.attacker.maneuver!.id, sidestep.id);
    });

    test('a sidestep flies the ship aside, onto the enemy altitude', () {
      final sidestep = maneuverOf(PieceType.knight, ManeuverFamily.sidestep);
      var battle = idle(PieceType.knight);
      battle = BattleEngine.moveShip(battle, false, 0.5, altitude: 0.8);
      battle = BattleEngine.startManeuver(battle, true, sidestep);

      battle = fly(battle, sidestep.durationMs + 100);

      expect(battle.attacker.maneuver, isNull);
      expect(battle.attacker.xFraction, closeTo(0.72, 0.01));
      expect(battle.attacker.altitude, closeTo(0.8, 0.01));
    });

    test('steering waits until the maneuver is over', () {
      final sidestep = maneuverOf(PieceType.knight, ManeuverFamily.sidestep);
      var battle =
          BattleEngine.startManeuver(idle(PieceType.knight), true, sidestep);
      battle = fly(battle, 100);

      final flying = battle.attacker;
      battle = BattleEngine.moveShip(battle, true, 0.9, altitude: 0.1);
      expect(battle.attacker.xFraction, flying.xFraction);
      expect(battle.attacker.altitude, flying.altitude);

      battle = fly(battle, sidestep.durationMs);
      battle = BattleEngine.moveShip(battle, true, 0.9, altitude: 0.1);
      expect(battle.attacker.xFraction, closeTo(0.9, 0.001));
    });

    test('a volley fires exactly the bursts of its plan', () {
      final volley = maneuverOf(PieceType.knight, ManeuverFamily.volley);
      var battle =
          BattleEngine.startManeuver(idle(PieceType.knight), true, volley);

      final seen = <String>{};
      while (battle.attacker.maneuver != null &&
          battle.elapsedMs < volley.durationMs * 2) {
        battle = BattleEngine.tick(battle, 16);
        seen.addAll(battle.projectiles
            .where((shot) => shot.fromAttacker)
            .map((shot) => shot.id));
      }

      expect(seen.length, volley.fire.length);
    });

    test('the crown fires three lanes at once', () {
      final crown = maneuverOf(PieceType.king, ManeuverFamily.signature);
      // A signature costs more than a ship starts a battle with.
      final charged = idle(PieceType.king);
      var battle = BattleEngine.startManeuver(
        charged.copyWith(
            attacker: charged.attacker.copyWith(energy: BattleUnit.maxEnergy)),
        true,
        crown,
      );
      expect(battle.attacker.maneuver, isNotNull);

      while (battle.projectiles.isEmpty &&
          battle.elapsedMs < crown.durationMs) {
        battle = BattleEngine.tick(battle, 16);
      }
      final lanes = battle.projectiles.map((shot) => shot.xFraction).toList()
        ..sort();

      expect(lanes.length, 3);
      expect(lanes[1] - lanes[0], closeTo(0.16, 0.001));
      expect(lanes[2] - lanes[1], closeTo(0.16, 0.001));
    });

    test('shots pass through a ship in its untouchable window', () {
      final loop = maneuverOf(PieceType.knight, ManeuverFamily.loop);
      final window = loop.untouchableAt(1)!;

      /// Fires one shot at the defender where it is, [at] of the way through
      /// its loop, and returns the battle once the shot has arrived.
      BattleState shootAt(double at) {
        var battle =
            BattleEngine.startManeuver(idle(PieceType.knight), false, loop);
        battle = fly(battle, (loop.durationMs * at).round());
        battle = battle.copyWith(projectiles: [
          Projectile(
            id: 'shot',
            positionFraction: 0.9,
            damage: 20,
            fromAttacker: true,
            xFraction: battle.defender.xFraction,
            altitude: battle.defender.altitude,
          ),
        ]);
        return fly(battle, 100);
      }

      final through = shootAt((window.$1 + window.$2) / 2);
      expect(through.impacts, isEmpty);
      expect(through.defender.currentHp, through.defender.stats.maxHp);

      final hit = shootAt(window.$2 + 0.2);
      expect(hit.impacts, hasLength(1));
      expect(hit.defender.currentHp, lessThan(hit.defender.stats.maxHp));
    });

    test('overdrive leaves the helm and runs the guns hot', () {
      final overdrive = maneuverOf(PieceType.knight, ManeuverFamily.overdrive);
      final stats = unitBaseStats[PieceType.knight]!;
      BattleState firing() => idle(PieceType.knight).copyWith(
            attacker: idle(PieceType.knight)
                .attacker
                .copyWith(nextAttackMs: stats.attackIntervalMs),
          );

      int shotsIn(BattleState battle, int ms) {
        final seen = <String>{};
        for (var elapsed = 0; elapsed < ms; elapsed += 16) {
          battle = BattleEngine.tick(battle, 16);
          seen.addAll(battle.projectiles
              .where((shot) => shot.fromAttacker)
              .map((shot) => shot.id));
        }
        return seen.length;
      }

      final plain = shotsIn(firing(), overdrive.durationMs);
      final hot = shotsIn(
        BattleEngine.startManeuver(firing(), true, overdrive),
        overdrive.durationMs,
      );
      expect(hot, greaterThan(plain));

      // The helm stays with the player.
      final steered = BattleEngine.moveShip(
          BattleEngine.startManeuver(firing(), true, overdrive), true, 0.9);
      expect(steered.attacker.xFraction, closeTo(0.9, 0.001));
    });

    test('the guns come back soon after a maneuver ends', () {
      final sidestep = maneuverOf(PieceType.knight, ManeuverFamily.sidestep);
      final stats = unitBaseStats[PieceType.knight]!;
      var battle = idle(PieceType.knight);
      battle = battle.copyWith(
          attacker: battle.attacker.copyWith(nextAttackMs: stats.attackIntervalMs));
      battle = BattleEngine.startManeuver(battle, true, sidestep);

      battle = fly(battle, sidestep.durationMs + 32);

      expect(battle.attacker.maneuver, isNull);
      expect(battle.attacker.nextAttackMs, lessThanOrEqualTo(200));
    });
  });
}
