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
    if (action.targetX != null) {
      next = BattleEngine.moveShip(next, isAttacker, action.targetX!);
    }
    if (action.activateShield) {
      next = BattleEngine.activateShield(next, isAttacker);
    }
    return next;
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

  /// Two knights that never fire; one attacker shot flies up the defender's
  /// lane, [position] of the way across.
  BattleState incomingShot(double position) {
    final stats = unitBaseStats[PieceType.knight]!;
    BattleUnit knight(PlayerColor color) => BattleUnit(
          piece: Piece(type: PieceType.knight, color: color),
          stats: stats,
          currentHp: stats.maxHp,
          shieldState: const ShieldState(),
          nextAttackMs: 1 << 30,
        );
    return BattleState(
      attacker: knight(white),
      defender: knight(black),
      projectiles: [
        Projectile(
          id: 'shot',
          positionFraction: position,
          damage: stats.damage,
          fromAttacker: true,
          xFraction: 0.5,
        ),
      ],
    );
  }

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
