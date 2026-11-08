import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbitron_tactics/core/game_logic/models/fleet_progress.dart';
import 'package:orbitron_tactics/core/game_logic/models/piece.dart';
import 'package:orbitron_tactics/core/maneuvers/maneuver_catalog.dart';
import 'package:orbitron_tactics/core/telemetry/telemetry.dart';
import 'package:orbitron_tactics/features/battle/data/fleet_skin.dart';
import 'package:orbitron_tactics/features/progress/data/fleet_progress_store.dart';
import 'package:orbitron_tactics/features/progress/presentation/providers/fleet_progress_provider.dart';
import 'package:orbitron_tactics/features/store/data/entitlements.dart';
import 'package:orbitron_tactics/features/store/data/entitlements_store.dart';
import 'package:orbitron_tactics/features/store/data/purchase_service.dart';
import 'package:orbitron_tactics/features/store/data/store_catalog.dart';
import 'package:orbitron_tactics/features/store/presentation/providers/store_providers.dart';
import 'package:orbitron_tactics/features/telemetry/presentation/telemetry_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences prefs;
  late FleetProgressStore fleets;
  late RecordingTelemetry telemetry;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    fleets = FleetProgressStore(prefs);
    telemetry = RecordingTelemetry();
  });

  ProviderContainer container({
    PurchaseService? service,
    EntitlementsStore? store,
  }) {
    final container = ProviderContainer(overrides: [
      fleetProgressStoreProvider.overrideWithValue(fleets),
      telemetryProvider.overrideWithValue(telemetry),
      purchaseServiceProvider
          .overrideWithValue(service ?? DebugPurchaseService(prefs)),
      if (store != null) entitlementsStoreProvider.overrideWithValue(store),
    ]);
    addTearDown(container.dispose);
    return container;
  }

  FleetProgress player(ProviderContainer c) =>
      c.read(fleetProgressProvider(playerFleetIdentity));

  test('the first launch keeps the premium fleet the player flies', () async {
    await fleets.save(playerFleetIdentity,
        const FleetProgress(skin: 'crystal_choir'));
    final store = MemoryEntitlementsStore();
    final c = container(store: store);

    final entitlements = c.read(entitlementsProvider);

    expect(entitlements.legacyFleets, {'crystal_choir'});
    expect(store.load(), entitlements);
    await c.read(entitlementsProvider.notifier).sync();
    expect(player(c).skin, 'crystal_choir');
  });

  test('a premium fleet no longer owned is swapped for the default',
      () async {
    await fleets.save(playerFleetIdentity,
        const FleetProgress(skin: 'crystal_choir'));
    // Not the first launch: the cache says nothing is owned.
    final c = container(store: MemoryEntitlementsStore(const Entitlements()));

    await c.read(entitlementsProvider.notifier).sync();

    expect(player(c).skin, FleetSkin.fallback.slug);
  });

  test('buying a fleet owns it and flies it', () async {
    final c = container();
    final item = StoreCatalog.forFleet(FleetSkin.roninBlades);

    final outcome = await c.read(entitlementsProvider.notifier).buy(item);

    expect(outcome, isA<Purchased>());
    expect(c.read(entitlementsProvider).ownsFleet(FleetSkin.roninBlades),
        isTrue);
    expect(player(c).skin, 'ronin_blades');
    expect(telemetry.names, ['purchase_started', 'purchase']);
    expect(telemetry.events.last.props,
        {'product': item.id, 'outcome': 'purchased'});
  });

  test('buying the Ace pack teaches every ship its maneuvers', () async {
    final c = container();

    await c
        .read(entitlementsProvider.notifier)
        .buy(StoreCatalog.forPack('ace'));

    for (final maneuver in ManeuverCatalog.inPack('ace')) {
      expect(player(c).maneuversFor(maneuver.ship).owned,
          contains(maneuver.id));
    }
  });

  test('restore brings back purchases made before', () async {
    await DebugPurchaseService(prefs).buy(StoreCatalog.commanderId);
    final c = container(store: MemoryEntitlementsStore(const Entitlements()));

    final count = await c.read(entitlementsProvider.notifier).restore();

    expect(count, 1);
    expect(c.read(entitlementsProvider).commander, isTrue);
    expect(player(c).maneuversFor(PieceType.pawn).owned,
        contains(ManeuverCatalog.inPack('ace').first.id));
  });

  test('ids the game does not sell are ignored', () async {
    await prefs.setStringList(DebugPurchaseService.key, ['old.thing']);
    final c = container();

    await c.read(entitlementsProvider.notifier).sync();

    expect(c.read(entitlementsProvider).products, isEmpty);
  });

  test('without a store nothing is sold and the cache stands', () async {
    final cached =
        Entitlements(products: {StoreCatalog.fleetId(FleetSkin.atomicAge)});
    final c = container(
      service: const UnavailablePurchaseService(),
      store: MemoryEntitlementsStore(cached),
    );
    final notifier = c.read(entitlementsProvider.notifier);

    await notifier.sync();
    final outcome = await notifier.buy(StoreCatalog.forPack('ace'));

    expect(outcome, isA<PurchaseFailed>());
    expect(c.read(entitlementsProvider), cached);
    expect(await notifier.restore(), isNull);
  });
}
