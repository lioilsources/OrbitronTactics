import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:orbitron_tactics/core/game_logic/models/piece.dart';
import 'package:orbitron_tactics/features/battle/data/battle_element.dart';
import 'package:orbitron_tactics/features/battle/data/battle_sounds.dart';

void main() {
  group('BattleSounds', () {
    test('ships a theme per attacker and a shot and explosion per element', () {
      final assets = [
        for (final type in PieceType.values) BattleSounds.music(type),
        for (final element in BattleElement.values) ...[
          BattleSounds.shot(element),
          BattleSounds.explosion(element),
        ],
      ];

      for (final asset in assets) {
        expect(File(asset).existsSync(), isTrue, reason: asset);
      }
    });

    test('pubspec bundles the audio folders', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();

      expect(pubspec, contains('- assets/audio/music/'));
      expect(pubspec, contains('- assets/audio/sfx/'));
    });
  });
}
