import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbitron_tactics/core/game_logic/engine/battle_engine.dart';
import 'package:orbitron_tactics/core/game_logic/models/piece.dart';
import 'package:orbitron_tactics/core/game_logic/models/upgrade_profile.dart';
import 'package:orbitron_tactics/features/battle/presentation/widgets/battle_arena_painter.dart';

void main() {
  // A shielded king against a pawn, so both sprite and shield paths run.
  final battle = BattleEngine.activateShield(
    BattleEngine.createBattle(
      attacker: const Piece(type: PieceType.king, color: PlayerColor.white),
      defender: const Piece(type: PieceType.pawn, color: PlayerColor.black),
      attackerUpgrades: const UpgradeProfile(),
      defenderUpgrades: const UpgradeProfile(),
    ),
    true,
  );

  void paint(BattleArenaPainter painter) {
    final recorder = ui.PictureRecorder();
    painter.paint(Canvas(recorder), const Size(360, 640));
    recorder.endRecording().dispose();
  }

  testWidgets('paints fleet sprites with either side at the bottom',
      (tester) async {
    final sprite = (await tester.runAsync(
        () => createTestImage(width: 256, height: 256, cache: false)))!;
    addTearDown(sprite.dispose);

    for (final attackerAtBottom in [true, false]) {
      expect(
        () => paint(BattleArenaPainter(
          battle,
          attackerAtBottom: attackerAtBottom,
          attackerSprite: sprite,
          defenderSprite: sprite,
        )),
        returnsNormally,
      );
    }
  });

  test('falls back to the vector hull without sprites', () {
    expect(
      () => paint(BattleArenaPainter(battle, attackerAtBottom: true)),
      returnsNormally,
    );
  });
}
