import 'package:flutter_test/flutter_test.dart';
import 'package:orbitron_tactics/core/maneuvers/maneuver_catalog.dart';
import 'package:orbitron_tactics/features/battle/data/battle_music.dart';
import 'package:orbitron_tactics/features/battle/data/fleet_skin.dart';
import 'package:orbitron_tactics/features/store/data/entitlements.dart';
import 'package:orbitron_tactics/features/store/data/store_catalog.dart';

void main() {
  group('StoreCatalog', () {
    test('sells every premium music set', () {
      for (final music in BattleMusic.values.where((m) => m.premium)) {
        expect(StoreCatalog.forMusic(music).music, music);
      }
    });

    test('sells every premium fleet and every maneuver pack', () {
      for (final skin in FleetSkin.values.where((skin) => skin.premium)) {
        expect(StoreCatalog.forFleet(skin).fleet, skin);
      }
      for (final pack in ManeuverCatalog.packs) {
        expect(StoreCatalog.forPack(pack.id).pack, pack);
      }
    });

    test('product ids are unique and valid on both stores', () {
      final ids = StoreCatalog.ids;
      expect(ids.toSet(), hasLength(ids.length));
      for (final id in ids) {
        // Google Play: lowercase letters, digits, _ and .; App Store: no -.
        expect(RegExp(r'^[a-z0-9][a-z0-9_.]{0,39}$').hasMatch(id), isTrue,
            reason: id);
      }
    });

    test('lists the commander edition first', () {
      expect(StoreCatalog.items.first.id, StoreCatalog.commanderId);
    });
  });

  group('Entitlements', () {
    const solar = FleetSkin.solarCrusade;
    const neon = FleetSkin.neonRunners;

    test('free fleets need nothing', () {
      const none = Entitlements();
      for (final skin in FleetSkin.values) {
        expect(none.ownsFleet(skin), !skin.premium, reason: skin.slug);
      }
    });

    test('a fleet bought alone unlocks only that fleet', () {
      final one = Entitlements(products: {StoreCatalog.fleetId(solar)});
      expect(one.ownsFleet(solar), isTrue);
      expect(one.ownsFleet(neon), isFalse);
      expect(one.owns(StoreCatalog.forFleet(solar)), isTrue);
      expect(one.owns(StoreCatalog.byId(StoreCatalog.fleetBundleId)!),
          isFalse);
    });

    test('the fleet collection unlocks every fleet, not the packs', () {
      const bundle = Entitlements(products: {StoreCatalog.fleetBundleId});
      expect(StoreCatalog.premiumFleets.every(bundle.ownsFleet), isTrue);
      expect(bundle.ownsPack('ace'), isFalse);
      expect(bundle.ownedPacks, isEmpty);
    });

    test('the commander edition unlocks everything', () {
      const commander = Entitlements(products: {StoreCatalog.commanderId});
      expect(StoreCatalog.items.every(commander.owns), isTrue);
      expect(commander.ownedPacks, ['ace', 'phantom', 'striker']);
    });

    test('the standard music is free, the retro pack is bought', () {
      const none = Entitlements();
      expect(none.ownsMusic(BattleMusic.standard), isTrue);
      expect(none.ownsMusic(BattleMusic.retro), isFalse);
      expect(
          Entitlements(products: {StoreCatalog.musicId(BattleMusic.retro)})
              .ownsMusic(BattleMusic.retro),
          isTrue);
      expect(
          const Entitlements(products: {StoreCatalog.commanderId})
              .ownsMusic(BattleMusic.retro),
          isTrue);
      expect(
          const Entitlements(products: {StoreCatalog.fleetBundleId})
              .ownsMusic(BattleMusic.retro),
          isFalse);
    });

    test('a legacy fleet stays owned', () {
      final legacy = Entitlements(legacyFleets: {solar.slug});
      expect(legacy.ownsFleet(solar), isTrue);
      expect(legacy.ownsFleet(neon), isFalse);
    });

    test('survives a round trip through JSON', () {
      final entitlements = Entitlements(
        products: {StoreCatalog.packId('ace'), StoreCatalog.fleetId(neon)},
        legacyFleets: {solar.slug},
      );
      expect(Entitlements.fromJson(entitlements.toJson()), entitlements);
    });

    test('reads garbage as nothing owned', () {
      expect(Entitlements.fromJson({'products': 'x', 'legacyFleets': [1]}),
          const Entitlements());
    });
  });
}
