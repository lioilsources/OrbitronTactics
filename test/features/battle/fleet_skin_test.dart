import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:orbitron_tactics/core/ai/ai_difficulty.dart';
import 'package:orbitron_tactics/core/game_logic/models/piece.dart';
import 'package:orbitron_tactics/features/battle/data/fleet_skin.dart';

void main() {
  group('FleetSkin', () {
    test('finds every fleet by its slug', () {
      for (final skin in FleetSkin.values) {
        expect(FleetSkin.fromSlug(skin.slug), skin);
      }
    });

    test('falls back without a slug or for an unknown one', () {
      expect(FleetSkin.fromSlug(null), FleetSkin.fallback);
      expect(FleetSkin.fromSlug('no_such_fleet'), FleetSkin.fallback);
    });

    test('every AI difficulty flies a real fleet', () {
      final slugs = FleetSkin.values.map((skin) => skin.slug);
      for (final difficulty in AiDifficulty.values) {
        expect(slugs, contains(AiProfile.of(difficulty).fleetSkin));
      }
    });

    test('ships a sprite for every unit and color of every fleet', () {
      for (final skin in FleetSkin.values) {
        for (final type in PieceType.values) {
          for (final color in PlayerColor.values) {
            final asset = skin.assetFor(type, color);
            expect(File(asset).existsSync(), isTrue, reason: asset);
          }
        }
      }
    });

    test('pubspec bundles every fleet folder', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      for (final skin in FleetSkin.values) {
        expect(pubspec, contains('- assets/fleets/${skin.slug}/'));
      }
    });
  });
}
