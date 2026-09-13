import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:orbitron_tactics/core/ai/ai_difficulty.dart';
import 'package:orbitron_tactics/core/ai/battle_ai.dart';
import 'package:orbitron_tactics/core/game_logic/engine/battle_engine.dart';
import 'package:orbitron_tactics/core/game_logic/engine/unit_base_stats.dart';
import 'package:orbitron_tactics/core/game_logic/models/battle_state.dart';
import 'package:orbitron_tactics/core/game_logic/models/battle_unit.dart';
import 'package:orbitron_tactics/core/game_logic/models/piece.dart';
import 'package:orbitron_tactics/core/game_logic/models/projectile.dart';
import 'package:orbitron_tactics/core/game_logic/models/shield_state.dart';
import 'package:orbitron_tactics/core/game_logic/models/upgrade_profile.dart';

void main() {
  const tickMs = 16;
  const white = PlayerColor.white;
  const black = PlayerColor.black;
  const noUpgrades = UpgradeProfile();

  BattleAi pilot(AiProfile profile, int seed) =>
      BattleAi(profile: profile, random: Random(seed));

  BattleState apply(BattleState state, BattleAiAction action,
      {required bool isAttacker}) {
    var next = state;
    if (action.targetX != null || action.targetAltitude != null) {
      final me = isAttacker ? next.attacker : next.defender;
      next = BattleEngine.moveShip(
          next, isAttacker, action.targetX ?? me.xFraction,
          altitude: action.targetAltitude);
    }
    if (action.activateShield) {
      next = BattleEngine.activateShield(next, isAttacker);
    }
    final maneuver = action.maneuver;
    if (maneuver != null) {
      next = BattleEngine.startManeuver(next, isAttacker, maneuver,
          mirrored: action.mirrored);
    }
    return next;
  }

  /// Fights [seeds] duels of knights and counts the ticks the attacker spent
  /// flying a maneuver.
  int maneuverTicks(AiProfile profile, {int seeds = 6}) {
    var ticks = 0;
    for (var seed = 0; seed < seeds && ticks == 0; seed++) {
      var state = BattleEngine.createBattle(
        attacker: const Piece(type: PieceType.knight, color: white),
        defender: const Piece(type: PieceType.knight, color: black),
        attackerUpgrades: noUpgrades,
        defenderUpgrades: noUpgrades,
      );
      final attacker = pilot(profile, seed);
      final defender = pilot(AiProfile.easy, 500 + seed);
      while (!state.isFinished && state.elapsedMs < 30000) {
        state = BattleEngine.tick(state, tickMs);
        state = apply(
            state, attacker.decide(state, isAttacker: true, deltaMs: tickMs),
            isAttacker: true);
        state = apply(
            state, defender.decide(state, isAttacker: false, deltaMs: tickMs),
            isAttacker: false);
        if (state.attacker.maneuver != null) ticks++;
      }
    }
    return ticks;
  }

  /// A battle between two ships of [type] at 16 ms ticks, as the arena runs
  /// it. A null pilot never moves.
  BattleState fight(PieceType type, BattleAi? attacker, BattleAi? defender) {
    var state = BattleEngine.createBattle(
      attacker: Piece(type: type, color: white),
      defender: Piece(type: type, color: black),
      attackerUpgrades: noUpgrades,
      defenderUpgrades: noUpgrades,
    );
    while (!state.isFinished && state.elapsedMs < 120000) {
      state = BattleEngine.tick(state, tickMs);
      if (attacker != null) {
        state = apply(
            state, attacker.decide(state, isAttacker: true, deltaMs: tickMs),
            isAttacker: true);
      }
      if (defender != null) {
        state = apply(
            state, defender.decide(state, isAttacker: false, deltaMs: tickMs),
            isAttacker: false);
      }
    }
    return state;
  }

  final knightStats = unitBaseStats[PieceType.knight]!;

  /// A knight at the middle of the arena that never fires.
  BattleUnit idleKnight(PlayerColor color) => BattleUnit(
        piece: Piece(type: PieceType.knight, color: color),
        stats: knightStats,
        currentHp: knightStats.maxHp,
        shieldState: const ShieldState(),
        nextAttackMs: 1 << 30,
      );

  /// An attacker shot in the lane at [x], [position] of the way across.
  Projectile shot(String id, double position, {double x = 0.5}) => Projectile(
        id: id,
        positionFraction: position,
        damage: knightStats.damage,
        fromAttacker: true,
        xFraction: x,
      );

  /// Two knights that never fire; one attacker shot flies up the defender's
  /// lane, [position] of the way across.
  BattleState incomingShot(double position) => BattleState(
        attacker: idleKnight(white),
        defender: idleKnight(black),
        projectiles: [shot('shot', position)],
      );

  /// Flies [state]'s shots home with [ai] piloting the defender. Returns the
  /// final state and whether the shield went up.
  (BattleState, bool) defend(BattleState state, BattleAi ai) {
    var shielded = false;
    while (state.projectiles.isNotEmpty) {
      final action = ai.decide(state, isAttacker: false, deltaMs: tickMs);
      shielded |= action.activateShield;
      state = BattleEngine.tick(apply(state, action, isAttacker: false), tickMs);
    }
    return (state, shielded);
  }

  group('BattleAi', () {
    test('Hard dodges a single shot from rest', () {
      final (state, shielded) =
          defend(incomingShot(0), pilot(AiProfile.hard, 1));

      expect(state.defender.currentHp, state.defender.stats.maxHp);
      expect(shielded, isFalse, reason: 'dodged, not blocked');
    });

    test('Hard climbs or dives out of a spread it cannot sidestep', () {
      final spread = BattleState(
        attacker: idleKnight(white),
        defender: idleKnight(black),
        projectiles: [
          shot('left', 0, x: 0.4),
          shot('middle', 0),
          shot('right', 0, x: 0.6),
        ],
      );

      final (state, shielded) = defend(spread, pilot(AiProfile.hard, 1));

      expect(state.defender.currentHp, state.defender.stats.maxHp);
      expect(shielded, isFalse, reason: 'dodged, not blocked');
      expect((state.defender.altitude - 0.5).abs(),
          greaterThan(BattleEngine.hitHalfAltitude));
    });

    test('Hard flies to the enemy altitude and hits it there', () {
      final knight = unitBaseStats[PieceType.knight]!;
      var state = BattleState(
        attacker: BattleUnit(
          piece: const Piece(type: PieceType.knight, color: white),
          stats: knight,
          currentHp: knight.maxHp,
          shieldState: const ShieldState(),
          nextAttackMs: knight.attackIntervalMs,
        ),
        defender: idleKnight(black).copyWith(altitude: 0.9),
      );
      final hard = pilot(AiProfile.hard, 1);

      while (state.elapsedMs < 3000) {
        state = BattleEngine.tick(state, tickMs);
        state = apply(state, hard.decide(state, isAttacker: true, deltaMs: tickMs),
            isAttacker: true);
      }

      expect(state.attacker.altitude,
          closeTo(0.9, BattleEngine.hitHalfAltitude / 2));
      expect(state.defender.currentHp, lessThan(knight.maxHp));
    });

    test('a ship too slow to dodge raises its shield', () {
      final slow = AiProfile.hard.copyWith(maxShipSpeed: 0.2, shieldSkill: 1.0);

      final first = pilot(slow, 1)
          .decide(incomingShot(0.9), isAttacker: false, deltaMs: tickMs);
      expect(first.activateShield, isTrue);

      final (state, _) = defend(incomingShot(0.9), pilot(slow, 1));
      expect(state.defender.currentHp, state.defender.stats.maxHp);
    });

    test('without shield skill the slow ship takes the hit', () {
      final clumsy = AiProfile.hard.copyWith(maxShipSpeed: 0.2, shieldSkill: 0);

      final (state, shielded) = defend(incomingShot(0.9), pilot(clumsy, 1));

      expect(shielded, isFalse);
      expect(state.defender.currentHp, lessThan(state.defender.stats.maxHp));
    });

    test('Hard beats a motionless ship of the same type', () {
      for (final type in PieceType.values) {
        expect(fight(type, pilot(AiProfile.hard, 1), null).winner, white,
            reason: 'Hard attacking with ${type.name}');
        expect(fight(type, null, pilot(AiProfile.hard, 2)).winner, black,
            reason: 'Hard defending with ${type.name}');
      }
    });

    test('Hard reaches for a maneuver in a duel', () {
      expect(maneuverTicks(AiProfile.hard), greaterThan(0));
    });

    test('a pilot taught none never flies one', () {
      expect(maneuverTicks(AiProfile.hard.copyWith(maneuverCount: 0)), 0);
    });

    test('Hard beats Easy in more than 80% of 50 seeded battles', () {
      var hardWins = 0;
      for (var i = 0; i < 50; i++) {
        final type = PieceType.values[i % PieceType.values.length];
        final hard = pilot(AiProfile.hard, i);
        final easy = pilot(AiProfile.easy, 1000 + i);
        final hardAttacks = i.isEven;

        final result =
            hardAttacks ? fight(type, hard, easy) : fight(type, easy, hard);

        if (result.winner == (hardAttacks ? white : black)) hardWins++;
      }

      expect(hardWins, greaterThan(40));
    });
  });
}
