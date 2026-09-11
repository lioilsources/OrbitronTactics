import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbitron_tactics/core/game_logic/engine/battle_engine.dart';
import 'package:orbitron_tactics/core/game_logic/models/battle_state.dart';
import 'package:orbitron_tactics/core/game_logic/models/impact.dart';
import 'package:orbitron_tactics/core/game_logic/models/piece.dart';
import 'package:orbitron_tactics/core/game_logic/models/projectile.dart';
import 'package:orbitron_tactics/core/game_logic/models/upgrade_profile.dart';
import 'package:orbitron_tactics/features/battle/presentation/widgets/battle_arena_painter.dart';

void main() {
  BattleState battleOf(PieceType attacker, PieceType defender) =>
      BattleEngine.createBattle(
        attacker: Piece(type: attacker, color: PlayerColor.white),
        defender: Piece(type: defender, color: PlayerColor.black),
        attackerUpgrades: const UpgradeProfile(),
        defenderUpgrades: const UpgradeProfile(),
      );

  // A shielded king flying high against a low pawn, with a shot on and a
  // shot off its target's altitude, so every drawing path runs.
  var start = battleOf(PieceType.king, PieceType.pawn);
  start = BattleEngine.moveShip(start, true, 0.3, altitude: 0.9);
  start = BattleEngine.moveShip(start, false, 0.7, altitude: 0.1);
  final battle = BattleEngine.activateShield(start, true).copyWith(
    projectiles: const [
      Projectile(
        id: 'off target',
        positionFraction: 0.4,
        damage: 35,
        fromAttacker: true,
        xFraction: 0.3,
        altitude: 0.9,
      ),
      Projectile(
        id: 'on target',
        positionFraction: 0.6,
        damage: 8,
        fromAttacker: false,
        xFraction: 0.7,
        altitude: 0.85,
      ),
    ],
  );

  void paint(BattleArenaPainter painter) {
    final recorder = ui.PictureRecorder();
    painter.paint(Canvas(recorder), const Size(360, 640));
    recorder.endRecording().dispose();
  }

  testWidgets('paints fleet sprites at any bank, either side at the bottom',
      (tester) async {
    final sprite = (await tester.runAsync(
        () => createTestImage(width: 256, height: 256, cache: false)))!;
    addTearDown(sprite.dispose);

    for (final attackerAtBottom in [true, false]) {
      for (final bank in [-1.0, 0.0, 0.6]) {
        expect(
          () => paint(BattleArenaPainter(
            battle,
            attackerAtBottom: attackerAtBottom,
            attackerSprite: sprite,
            defenderSprite: sprite,
            attackerBank: bank,
            defenderBank: -bank,
          )),
          returnsNormally,
        );
      }
    }
  });

  test('falls back to the vector hull without sprites', () {
    expect(
      () => paint(BattleArenaPainter(battle, attackerAtBottom: true,
          attackerBank: 0.5)),
      returnsNormally,
    );
  });

  test('plays impacts and the losing ship explosion of every unit type', () {
    for (final type in PieceType.values) {
      final finished = battleOf(type, type).copyWith(
        impacts: [
          Impact(
            id: '${type.name} hit',
            onAttacker: false,
            xFraction: 0.5,
            altitude: 0.5,
            damage: 30,
            shielded: false,
            atMs: 1000,
          ),
          Impact(
            id: '${type.name} blocked',
            onAttacker: true,
            xFraction: 0.5,
            altitude: 0.2,
            damage: 30,
            shielded: true,
            atMs: 1100,
          ),
        ],
        elapsedMs: 1200,
        isFinished: true,
        winner: PlayerColor.white,
      );

      for (var ms = 1200;
          ms <= 1200 + BattleArenaPainter.destructionMs;
          ms += 100) {
        expect(
          () => paint(BattleArenaPainter(finished,
              attackerAtBottom: true, nowMs: ms)),
          returnsNormally,
          reason: '${type.name} at $ms ms',
        );
      }
    }
  });
}
