@Tags(['slow'])
library;

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:orbitron_tactics/core/ai/ai_difficulty.dart';
import 'package:orbitron_tactics/core/ai/battle_ai.dart';
import 'package:orbitron_tactics/core/game_logic/engine/battle_engine.dart';
import 'package:orbitron_tactics/core/game_logic/models/battle_state.dart';
import 'package:orbitron_tactics/core/game_logic/models/piece.dart';
import 'package:orbitron_tactics/core/game_logic/models/upgrade_profile.dart';
import 'package:orbitron_tactics/core/maneuvers/maneuver.dart';
import 'package:orbitron_tactics/core/maneuvers/maneuver_catalog.dart';

/// Sold maneuvers must be sidegrades. Two pilots in the same ship fly the
/// same loadout, except that one has the pack maneuver where the other has
/// the earnable maneuver closest to it; the pack side must not win clearly
/// more often.
///
/// Medium pilots, keen on maneuvers like Hard ones: two Hard pilots dodge
/// each other for ever.
void main() {
  const battlesPerShip = 150;
  final pilot = AiProfile.medium
      .copyWith(maneuverSkill: AiProfile.hard.maneuverSkill);

  Maneuver of(PieceType ship, ManeuverFamily family) => ManeuverCatalog
      .forShip(ship)
      .firstWhere((maneuver) => maneuver.family == family);

  List<Maneuver> base(PieceType ship) => [
        for (final family in [
          ManeuverFamily.sidestep,
          ManeuverFamily.strike,
          ManeuverFamily.retreat,
          ManeuverFamily.roll,
          ManeuverFamily.volley,
          ManeuverFamily.signature,
        ])
          of(ship, family),
      ];

  /// Whether the first pilot wins a battle fought to the end.
  bool firstWins(PieceType ship, List<Maneuver> first, List<Maneuver> second,
      {required bool firstAttacks, required Random random}) {
    final aiFirst =
        BattleAi(profile: pilot, random: random, maneuvers: first);
    final aiSecond =
        BattleAi(profile: pilot, random: random, maneuvers: second);
    var state = BattleEngine.createBattle(
      attacker: Piece(type: ship, color: PlayerColor.white),
      defender: Piece(type: ship, color: PlayerColor.black),
      attackerUpgrades: const UpgradeProfile(),
      defenderUpgrades: const UpgradeProfile(),
    );
    const deltaMs = 16;
    for (var elapsed = 0; elapsed < 180000 && !state.isFinished;
        elapsed += deltaMs) {
      state = BattleEngine.tick(state, deltaMs);
      for (final (ai, isAttacker) in [
        (aiFirst, firstAttacks),
        (aiSecond, !firstAttacks),
      ]) {
        state = _apply(state, ai.decide(state,
            isAttacker: isAttacker, deltaMs: deltaMs), isAttacker);
      }
    }
    expect(state.isFinished, isTrue, reason: 'a battle must end');
    final firstColor = firstAttacks ? PlayerColor.white : PlayerColor.black;
    return state.winner == firstColor;
  }

  for (final (pack, earnable) in [
    (ManeuverFamily.phantom, ManeuverFamily.dash),
    (ManeuverFamily.strafe, ManeuverFamily.shadow),
  ]) {
    test('${pack.name} wins no more than ${earnable.name} does', () {
      final random = Random(7);
      var packWins = 0;
      var battles = 0;
      for (final ship in PieceType.values) {
        final withPack = [...base(ship), of(ship, pack)];
        final withEarnable = [...base(ship), of(ship, earnable)];
        for (var i = 0; i < battlesPerShip; i++) {
          if (firstWins(ship, withPack, withEarnable,
              firstAttacks: i.isEven, random: random)) {
            packWins++;
          }
          battles++;
        }
      }
      final rate = packWins / battles;
      // ignore: avoid_print
      print('${pack.name} vs ${earnable.name}: '
          '${(rate * 100).toStringAsFixed(1)} % of $battles');
      expect(rate, lessThanOrEqualTo(0.58));
    });
  }
}

BattleState _apply(BattleState state, BattleAiAction action, bool isAttacker) {
  var next = state;
  if (action.targetX != null || action.targetAltitude != null) {
    final me = isAttacker ? next.attacker : next.defender;
    next = BattleEngine.moveShip(next, isAttacker,
        action.targetX ?? me.xFraction,
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
