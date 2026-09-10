import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbitron_tactics/core/game_logic/models/fleet_progress.dart';
import 'package:orbitron_tactics/core/game_logic/models/piece.dart';
import 'package:orbitron_tactics/core/game_logic/models/upgrade_profile.dart';
import 'package:orbitron_tactics/features/progress/data/fleet_progress_store.dart';
import 'package:orbitron_tactics/features/progress/presentation/providers/fleet_progress_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<FleetProgressStore> storeWith(Map<String, Object> values) async {
    SharedPreferences.setMockInitialValues(values);
    return FleetProgressStore(await SharedPreferences.getInstance());
  }

  group('FleetProgressStore', () {
    test('round-trips a fleet', () async {
      final store = await storeWith({});
      const progress = FleetProgress(
        credits: 340,
        profile: UpgradeProfile(levels: {PieceType.pawn: 2, PieceType.queen: 1}),
        gamesPlayed: 7,
        wins: 4,
      );

      await store.save('ai-hard', progress);

      expect(store.load('ai-hard'), progress);
    });

    test('a missing key loads a fresh fleet', () async {
      final store = await storeWith({});

      expect(store.load(playerFleetIdentity), const FleetProgress());
    });

    test('keeps each identity apart', () async {
      final store = await storeWith({});

      await store.save('ai-easy', const FleetProgress(credits: 10));

      expect(store.load('ai-easy').credits, 10);
      expect(store.load('ai-medium'), const FleetProgress());
    });

    test('stores upgrades in the upgrade repository shape', () async {
      final store = await storeWith({});

      await store.save(
        playerFleetIdentity,
        const FleetProgress(
          credits: 5,
          profile: UpgradeProfile(levels: {PieceType.rook: 3}),
        ),
      );

      final prefs = await SharedPreferences.getInstance();
      expect(jsonDecode(prefs.getString('fleet_progress.player')!), {
        'credits': 5,
        'upgrades': {'rook': 3},
        'gamesPlayed': 0,
        'wins': 0,
      });
    });

    test('a corrupt blob loads a fresh fleet', () async {
      final store = await storeWith({'fleet_progress.player': 'not json'});

      expect(store.load(playerFleetIdentity), const FleetProgress());
    });
  });

  group('fleetProgressProvider', () {
    test('saves every change', () async {
      final store = await storeWith({});
      final container = ProviderContainer(
        overrides: [fleetProgressStoreProvider.overrideWithValue(store)],
      );
      addTearDown(container.dispose);
      final fleet =
          container.read(fleetProgressProvider(playerFleetIdentity).notifier);

      fleet.addCredits(150);
      expect(fleet.upgrade(PieceType.knight), isTrue);
      expect(fleet.upgrade(PieceType.knight), isFalse,
          reason: '50 cr left, the next level costs 250');
      fleet.recordGame(won: true);

      const expected = FleetProgress(
        credits: 50,
        profile: UpgradeProfile(levels: {PieceType.knight: 1}),
        gamesPlayed: 1,
        wins: 1,
      );
      expect(container.read(fleetProgressProvider(playerFleetIdentity)),
          expected);
      expect(store.load(playerFleetIdentity), expected);
    });
  });
}
