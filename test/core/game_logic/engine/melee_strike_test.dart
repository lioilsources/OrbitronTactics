import 'package:flutter_test/flutter_test.dart';
import 'package:orbitron_tactics/core/game_logic/engine/battle_engine.dart';
import 'package:orbitron_tactics/core/game_logic/models/battle_state.dart';
import 'package:orbitron_tactics/core/game_logic/models/battle_unit.dart';
import 'package:orbitron_tactics/core/game_logic/models/piece.dart';
import 'package:orbitron_tactics/core/game_logic/models/projectile.dart';
import 'package:orbitron_tactics/core/game_logic/models/shield_state.dart';
import 'package:orbitron_tactics/core/game_logic/models/strike_run.dart';
import 'package:orbitron_tactics/core/game_logic/models/unit_stats.dart';
import 'package:orbitron_tactics/core/worlds/world_balance.dart';

void main() {
  const tickMs = 16;
  final knight = WorldBalance.ground.statsOf(PieceType.knight);
  final melee = knight.melee!;

  /// A melee knight ready to strike, against an idle knight that never
  /// strikes back.
  BattleState duel({double defenderX = 0.5, double altitude = 0.5}) =>
      BattleState(
        attacker: BattleUnit(
          piece: const Piece(type: PieceType.knight, color: PlayerColor.white),
          stats: knight,
          currentHp: knight.maxHp,
          shieldState: const ShieldState(),
          altitude: altitude,
        ),
        defender: BattleUnit(
          piece: const Piece(type: PieceType.knight, color: PlayerColor.black),
          stats: knight,
          currentHp: knight.maxHp,
          shieldState: const ShieldState(),
          nextAttackMs: 1 << 30,
          xFraction: defenderX,
          altitude: altitude,
        ),
      );

  BattleState run(BattleState state, int ms) {
    for (var t = 0; t < ms; t += tickMs) {
      state = BattleEngine.tick(state, tickMs);
    }
    return state;
  }

  group('melee strike', () {
    test('starts when the enemy is in reach and lands after the lunge', () {
      var state = BattleEngine.tick(duel(), tickMs);
      final strike = state.attacker.strike!;
      expect(strike.phaseAt(state.elapsedMs), StrikePhase.windup);
      expect(strike.dashMs, melee.dashMsAt(1));

      state = run(state, strike.contactMs - state.elapsedMs - tickMs);
      expect(state.defender.currentHp, knight.maxHp, reason: 'not yet');

      state = run(state, 2 * tickMs);
      expect(state.defender.currentHp, lessThan(knight.maxHp));
      expect(state.impacts.single.onAttacker, isFalse);
    });

    test('does not start with the enemy out of reach', () {
      final state = run(duel(defenderX: 0.5 + melee.arcHalfWidth + 0.05), 2000);
      expect(state.attacker.strike, isNull);
      expect(state.defender.currentHp, knight.maxHp);
    });

    test('the lunge is longer the farther apart the units stand', () {
      final near = BattleEngine.tick(duel(altitude: 0.9), tickMs);
      final far = BattleEngine.tick(duel(altitude: 0.1), tickMs);
      expect(far.attacker.strike!.dashMs, greaterThan(near.attacker.strike!.dashMs));
      expect(near.attacker.strike!.dashMs, MeleeProfile.minDashMs);
    });

    test('stepping out of reach in the wind-up cancels it: a feint', () {
      var state = BattleEngine.tick(duel(), tickMs);
      expect(state.attacker.strike, isNotNull);
      state = BattleEngine.moveShip(state, false, 0.8);
      state = run(state, 600);
      expect(state.defender.currentHp, knight.maxHp);
      expect(state.impacts, isEmpty);
    });

    test('a raised shield blocks the strike and staggers the striker', () {
      var state = BattleEngine.activateShield(duel(), false);
      state = BattleEngine.tick(state, tickMs);
      final strike = state.attacker.strike!;
      state = run(state, strike.contactMs - state.elapsedMs + tickMs);

      expect(state.defender.currentHp, knight.maxHp);
      expect(state.impacts.single.shielded, isTrue);
      expect(state.attacker.strike!.recoverMs,
          melee.recoverMs + melee.staggerMs);
    });

    test('the helm is free in the wind-up and locked from the lunge', () {
      var state = BattleEngine.tick(duel(), tickMs);
      expect(BattleEngine.moveShip(state, true, 0.52).attacker.xFraction, 0.52);

      final strike = state.attacker.strike!;
      state = run(state, strike.windupMs);
      expect(state.attacker.strike!.phaseAt(state.elapsedMs), StrikePhase.dash);
      expect(BattleEngine.moveShip(state, true, 0.3).attacker.xFraction, 0.5);
    });

    test('shots pass through a lunging unit', () {
      var state = BattleEngine.tick(duel(), tickMs);
      state = run(state, state.attacker.strike!.windupMs);
      expect(state.attacker.strike!.untouchableAt(state.elapsedMs), isTrue);

      final shot = Projectile(
        id: 'shot',
        positionFraction: 0.999,
        damage: 50,
        fromAttacker: false,
        xFraction: state.attacker.xFraction,
        altitude: state.attacker.altitude,
      );
      state = BattleEngine.tick(state.copyWith(projectiles: [shot]), tickMs);
      expect(state.attacker.currentHp, knight.maxHp);
    });

    test('space units never strike', () {
      for (final stats in WorldBalance.space.units.values) {
        expect(stats.isMelee, isFalse);
      }
    });
  });
}
