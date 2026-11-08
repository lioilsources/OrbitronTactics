import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/telemetry/telemetry.dart';
import '../../../battle/data/battle_music.dart';
import '../../../battle/data/fleet_skin.dart';
import '../../../progress/presentation/providers/fleet_progress_provider.dart';
import '../../../telemetry/presentation/telemetry_provider.dart';
import '../../data/entitlements.dart';
import '../../data/entitlements_store.dart';
import '../../data/music_choice_store.dart';
import '../../data/purchase_service.dart';
import '../../data/store_catalog.dart';

/// The platform store. `main()` picks RevenueCat, the free debug store or
/// none; tests and previews have none.
final purchaseServiceProvider =
    Provider<PurchaseService>((ref) => const UnavailablePurchaseService());

/// Where entitlements are cached. `main()` keeps them on the device.
final entitlementsStoreProvider =
    Provider<EntitlementsStore>((ref) => MemoryEntitlementsStore());

/// Localized prices by product id; empty while the store is out of reach.
final storePricesProvider = FutureProvider<Map<String, String>>((ref) async {
  try {
    return await ref.watch(purchaseServiceProvider).prices(StoreCatalog.ids);
  } catch (_) {
    return const {};
  }
});

/// What this install owns from the store.
///
/// Starts from the cache, then [sync] asks the store. On the very first
/// launch with a store, a premium fleet the player already flies is kept
/// for good. Owned maneuver packs are handed to the player's fleet, and a
/// premium fleet that is no longer owned (a refund) is swapped for the
/// default.
class EntitlementsNotifier extends StateNotifier<Entitlements> {
  EntitlementsNotifier({
    required EntitlementsStore store,
    required PurchaseService service,
    required Telemetry telemetry,
    required String? Function() playerSkin,
    required void Function(String slug) setPlayerSkin,
    required void Function(String pack) grantPack,
    void Function(BattleMusic music)? selectMusic,
  })  : _store = store,
        _selectMusic = selectMusic,
        _service = service,
        _telemetry = telemetry,
        _playerSkin = playerSkin,
        _setPlayerSkin = setPlayerSkin,
        _grantPack = grantPack,
        super(store.load() ?? _firstLaunch(playerSkin())) {
    if (store.load() == null) _store.save(state);
  }

  final EntitlementsStore _store;
  final PurchaseService _service;
  final Telemetry _telemetry;
  final String? Function() _playerSkin;
  final void Function(String slug) _setPlayerSkin;
  final void Function(String pack) _grantPack;
  final void Function(BattleMusic music)? _selectMusic;

  static Entitlements _firstLaunch(String? skin) {
    final flown = FleetSkin.fromSlug(skin);
    return Entitlements(legacyFleets: {if (flown.premium) flown.slug});
  }

  /// Asks the store what this install owns. Offline, the cache stands.
  Future<void> sync() async {
    try {
      _apply(await _service.owned());
    } catch (_) {
      // Store out of reach: keep what was owned last time.
    }
  }

  Future<PurchaseOutcome> buy(StoreItem item) async {
    _telemetry.event('purchase_started', {'product': item.id});
    final outcome = await _service.buy(item.id);
    if (outcome case Purchased(:final owned)) {
      _apply(owned);
      if (item.fleet case final fleet? when state.ownsFleet(fleet)) {
        _setPlayerSkin(fleet.slug);
      }
      if (item.music case final music? when state.ownsMusic(music)) {
        _selectMusic?.call(music);
      }
    }
    _telemetry.event('purchase', {'product': item.id, 'outcome': outcome.name});
    return outcome;
  }

  /// Restores earlier purchases; the number of products owned, or null
  /// when the store could not be reached.
  Future<int?> restore() async {
    try {
      final owned = await _service.restore();
      _apply(owned);
      _telemetry.event('restore', {'owned': state.products.length});
      return state.products.length;
    } catch (_) {
      _telemetry.event('restore', {'failed': true});
      return null;
    }
  }

  void _apply(Set<String> owned) {
    final known = {
      for (final id in owned)
        if (StoreCatalog.byId(id) != null) id,
    };
    state = state.copyWith(products: known);
    _store.save(state);
    for (final pack in state.ownedPacks) {
      _grantPack(pack);
    }
    final flown = FleetSkin.fromSlug(_playerSkin());
    if (!state.ownsFleet(flown)) _setPlayerSkin(FleetSkin.fallback.slug);
  }
}

final entitlementsProvider =
    StateNotifierProvider<EntitlementsNotifier, Entitlements>((ref) {
  FleetProgressNotifier player() =>
      ref.read(fleetProgressProvider(playerFleetIdentity).notifier);
  return EntitlementsNotifier(
    store: ref.watch(entitlementsStoreProvider),
    service: ref.watch(purchaseServiceProvider),
    telemetry: ref.read(telemetryProvider),
    playerSkin: () =>
        ref.read(fleetProgressProvider(playerFleetIdentity)).skin,
    setPlayerSkin: (slug) => player().setSkin(slug),
    grantPack: (pack) => player().grantPack(pack),
    selectMusic: (music) =>
        ref.read(chosenBattleMusicProvider.notifier).choose(music),
  );
});

/// Where the battle music choice is kept. `main()` keeps it on the device.
final musicChoiceStoreProvider =
    Provider<MusicChoiceStore>((ref) => MemoryMusicChoiceStore());

/// The battle music the player picked, owned or not.
class BattleMusicChoice extends StateNotifier<BattleMusic> {
  BattleMusicChoice(this._store) : super(BattleMusic.fromSlug(_store.load()));

  final MusicChoiceStore _store;

  void choose(BattleMusic music) {
    state = music;
    _store.save(music.slug);
  }
}

final chosenBattleMusicProvider =
    StateNotifierProvider<BattleMusicChoice, BattleMusic>(
        (ref) => BattleMusicChoice(ref.watch(musicChoiceStoreProvider)));

/// The music battles play: the player's pick while it is owned, else the
/// standard themes.
final battleMusicProvider = Provider<BattleMusic>((ref) {
  final chosen = ref.watch(chosenBattleMusicProvider);
  return ref.watch(entitlementsProvider).ownsMusic(chosen)
      ? chosen
      : BattleMusic.standard;
});
