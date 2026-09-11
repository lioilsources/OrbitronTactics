import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbitron_tactics/core/game_logic/models/piece.dart';
import 'package:orbitron_tactics/features/battle/data/battle_element.dart';
import 'package:orbitron_tactics/features/battle/presentation/widgets/explosion_fx.dart';

void main() {
  test('each unit type fires its element', () {
    expect({for (final type in PieceType.values) type: BattleElement.of(type)}, {
      PieceType.pawn: BattleElement.kinetic,
      PieceType.knight: BattleElement.water,
      PieceType.bishop: BattleElement.fire,
      PieceType.rook: BattleElement.ice,
      PieceType.queen: BattleElement.electric,
      PieceType.king: BattleElement.electric,
    });
  });

  test('every element explodes from start to finish', () {
    for (final element in BattleElement.values) {
      for (final progress in [0.0, 0.01, 0.3, 0.5, 0.8, 0.99, 1.0]) {
        final recorder = ui.PictureRecorder();
        expect(
          () => ExplosionFx.paint(
            Canvas(recorder),
            const Offset(100, 100),
            element: element,
            radius: 40,
            progress: progress,
            seed: 7,
          ),
          returnsNormally,
          reason: '${element.name} at $progress',
        );
        recorder.endRecording().dispose();
      }
    }
  });
}
