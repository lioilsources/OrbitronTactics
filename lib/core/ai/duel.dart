import 'dart:math';

import '../game_logic/engine/battle_engine.dart';
import '../game_logic/models/battle_state.dart';
import '../game_logic/models/piece.dart';
import '../game_logic/models/upgrade_profile.dart';
import '../worlds/world_balance.dart';
import 'ai_difficulty.dart';
import 'battle_ai.dart';

/// Arena duels between two AI pilots, headless and seeded: the shared base
/// of the balance tests and `tools/duel_lab.dart`.
class Duel {
  const Duel._();

  /// The arena's tick, as `BattleStateNotifier` runs it.
  static const int tickMs = 16;

  /// [attacker] against [defender] until one is destroyed or [limitMs]
  /// passes. A null profile leaves that ship motionless. The attacker's
  /// pilot decides first each tick unless [defenderDecidesFirst].
  static BattleState fight(
    PieceType attacker,
    PieceType defender, {
    AiProfile? attackerPilot,
    AiProfile? defenderPilot,
    int seed = 0,
    int limitMs = 120000,
    UpgradeProfile attackerUpgrades = const UpgradeProfile(),
    UpgradeProfile defenderUpgrades = const UpgradeProfile(),
    WorldBalance balance = WorldBalance.space,
    bool defenderDecidesFirst = false,
  }) {
    var state = BattleEngine.createBattle(
      attacker: Piece(type: attacker, color: PlayerColor.white),
      defender: Piece(type: defender, color: PlayerColor.black),
      attackerUpgrades: attackerUpgrades,
      defenderUpgrades: defenderUpgrades,
      balance: balance,
    );
    final a = attackerPilot == null
        ? null
        : BattleAi(profile: attackerPilot, random: Random(seed));
    final d = defenderPilot == null
        ? null
        : BattleAi(profile: defenderPilot, random: Random(seed + 7919));
    while (!state.isFinished && state.elapsedMs < limitMs) {
      state = BattleEngine.tick(state, tickMs);
      // The pilot deciding second sees the first one's move: alternate to
      // keep that edge out of balance measurements.
      if (defenderDecidesFirst && d != null) {
        state = apply(
            state, d.decide(state, isAttacker: false, deltaMs: tickMs),
            isAttacker: false);
      }
      if (a != null) {
        state = apply(state, a.decide(state, isAttacker: true, deltaMs: tickMs),
            isAttacker: true);
      }
      if (!defenderDecidesFirst && d != null) {
        state = apply(
            state, d.decide(state, isAttacker: false, deltaMs: tickMs),
            isAttacker: false);
      }
    }
    return state;
  }

  /// Applies a pilot's [action] through the same engine calls as a player's
  /// input.
  static BattleState apply(
    BattleState state,
    BattleAiAction action, {
    required bool isAttacker,
  }) {
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
}
