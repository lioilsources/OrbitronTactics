import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbitron_tactics/core/game_logic/models/piece.dart';
import 'package:orbitron_tactics/features/battle/data/fleet_skin.dart';
import 'package:orbitron_tactics/features/battle/data/unit_art.dart';
import 'package:orbitron_tactics/features/battle/presentation/providers/unit_art_provider.dart';
import 'package:orbitron_tactics/features/game/data/piece_skin.dart';
import 'package:orbitron_tactics/features/game/presentation/providers/piece_skin_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('every world has a picture for every unit of both armies', () {
    for (final world in PieceSkin.values) {
      for (final fleet in world.isSpace ? FleetSkin.values : [FleetSkin.fallback]) {
        for (final type in PieceType.values) {
          for (final color in PlayerColor.values) {
            final art = unitArt(world, fleet, type, color);
            expect(File(art.asset).existsSync(), isTrue, reason: art.asset);
          }
        }
      }
    }
  });

  test('Space flies the fleet from above, unmirrored', () {
    const fleet = FleetSkin.voidHive;
    for (final color in PlayerColor.values) {
      final art = unitArt(PieceSkin.classic, fleet, PieceType.rook, color);
      expect(art.asset, fleet.assetFor(PieceType.rook, color));
      expect(art.pose, UnitPose.topDown);
      expect(art.mirrored, isFalse);
    }
  });

  test('a figure world sends its board figures, the black army mirrored', () {
    const world = PieceSkin.romeCarthage;
    final white = unitArt(
        world, FleetSkin.solarCrusade, PieceType.king, PlayerColor.white);
    final black = unitArt(
        world, FleetSkin.solarCrusade, PieceType.king, PlayerColor.black);

    expect(white.asset, world.assetFor(PieceType.king, PlayerColor.white));
    expect(black.asset, world.assetFor(PieceType.king, PlayerColor.black));
    expect(white.pose, UnitPose.standing);
    expect(black.pose, UnitPose.standing);
    expect(white.mirrored, isFalse);
    expect(black.mirrored, isTrue);
  });

  test('every world but Space stands its units up', () {
    for (final world in PieceSkin.values) {
      expect(world.pose, world.isSpace ? UnitPose.topDown : UnitPose.standing,
          reason: world.slug);
    }
  });

  test('free worlds are listed in one place, Space among them', () {
    expect(PieceSkin.free, contains(PieceSkin.classic));
    for (final world in PieceSkin.values) {
      expect(world.premium, !PieceSkin.free.contains(world));
    }
  });

  test('a stored classic skin is the Space world', () async {
    SharedPreferences.setMockInitialValues({PieceSkinStore.skinKey: 'classic'});
    final prefs = await SharedPreferences.getInstance();

    final world = PieceSkinStore(prefs).load().skin;

    expect(world, PieceSkin.classic);
    expect(world.isSpace, isTrue);
  });

  test('outside single player both sides fly the default fleet, and the '
      'chosen world decides what fights', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    const key = (PieceType.pawn, PlayerColor.black);

    for (final color in PlayerColor.values) {
      expect(container.read(sideFleetProvider(color)), FleetSkin.fallback);
    }
    expect(container.read(sideUnitArtProvider(key)),
        unitArt(PieceSkin.classic, FleetSkin.fallback, key.$1, key.$2));

    container.read(pieceSkinProvider.notifier).select(PieceSkin.knightsOrcs);
    final art = container.read(sideUnitArtProvider(key));
    expect(art.pose, UnitPose.standing);
    expect(art.asset, 'assets/pieces/knights_orcs/pawn_black.png');
  });
}
