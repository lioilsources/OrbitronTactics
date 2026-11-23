import '../../../core/maneuvers/maneuver.dart';
import '../../../core/maneuvers/maneuver_catalog.dart';
import '../../battle/data/battle_music.dart';
import '../../battle/data/fleet_skin.dart';
import '../../game/data/piece_skin.dart';
import 'store_catalog.dart';

/// What this install may use from the store: the products bought, and the
/// premium fleet a player flew and the world a player played in before
/// they were sold.
class Entitlements {
  const Entitlements({
    this.products = const {},
    this.legacyFleets = const {},
    this.legacyWorlds = const {},
    this.worldsSettled = true,
  });

  /// Store product ids owned, as the store reports them.
  final Set<String> products;

  /// Slugs of premium fleets kept from before the store existed.
  final Set<String> legacyFleets;

  /// Slugs of premium worlds kept from before worlds were sold.
  final Set<String> legacyWorlds;

  /// Whether [legacyWorlds] has been settled. False only for a cache saved
  /// before worlds were sold, so the world chosen then can still be kept.
  final bool worldsSettled;

  bool get commander => products.contains(StoreCatalog.commanderId);

  bool ownsFleet(FleetSkin skin) =>
      !skin.premium ||
      commander ||
      products.contains(StoreCatalog.fleetId(skin)) ||
      legacyFleets.contains(skin.slug);

  bool ownsWorld(PieceSkin world) =>
      !world.premium ||
      commander ||
      products.contains(StoreCatalog.worldId(world)) ||
      legacyWorlds.contains(world.slug);

  bool ownsPack(String pack) =>
      commander || products.contains(StoreCatalog.packId(pack));

  bool ownsMusic(BattleMusic music) =>
      !music.premium ||
      commander ||
      products.contains(StoreCatalog.musicId(music));

  /// Whether everything [item] hands over is already here.
  bool owns(StoreItem item) => switch (item.kind) {
        StoreItemKind.commander => commander,
        StoreItemKind.fleet => ownsFleet(item.fleet!),
        StoreItemKind.world => ownsWorld(item.world!),
        StoreItemKind.maneuverPack => ownsPack(item.pack!.id),
        StoreItemKind.music => ownsMusic(item.music!),
      };

  /// Whether [maneuver] may fly: a pack maneuver only while its pack is
  /// owned. A refunded pack stays learned in the fleet's progress, so it
  /// comes back with a new purchase, but it no longer flies.
  bool allowsManeuver(Maneuver maneuver) => switch (maneuver.unlock) {
        PackUnlock(:final packId) => ownsPack(packId),
        _ => true,
      };

  /// Ids of the maneuver packs owned, to grant to the player's fleet.
  List<String> get ownedPacks => [
        for (final pack in ManeuverCatalog.packs)
          if (ownsPack(pack.id)) pack.id,
      ];

  Entitlements copyWith({
    Set<String>? products,
    Set<String>? legacyFleets,
    Set<String>? legacyWorlds,
    bool? worldsSettled,
  }) =>
      Entitlements(
        products: products ?? this.products,
        legacyFleets: legacyFleets ?? this.legacyFleets,
        legacyWorlds: legacyWorlds ?? this.legacyWorlds,
        worldsSettled: worldsSettled ?? this.worldsSettled,
      );

  factory Entitlements.fromJson(Map<String, dynamic> json) {
    Set<String> strings(String key) => switch (json[key]) {
          final List<dynamic> list => {...list.whereType<String>()},
          _ => const {},
        };
    return Entitlements(
      products: strings('products'),
      legacyFleets: strings('legacyFleets'),
      legacyWorlds: strings('legacyWorlds'),
      worldsSettled: json.containsKey('legacyWorlds'),
    );
  }

  Map<String, dynamic> toJson() => {
        'products': products.toList()..sort(),
        'legacyFleets': legacyFleets.toList()..sort(),
        'legacyWorlds': legacyWorlds.toList()..sort(),
      };

  @override
  bool operator ==(Object other) =>
      other is Entitlements &&
      _sameSet(other.products, products) &&
      _sameSet(other.legacyFleets, legacyFleets) &&
      _sameSet(other.legacyWorlds, legacyWorlds) &&
      other.worldsSettled == worldsSettled;

  @override
  int get hashCode => Object.hash(
      Object.hashAllUnordered(products),
      Object.hashAllUnordered(legacyFleets),
      Object.hashAllUnordered(legacyWorlds),
      worldsSettled);

  static bool _sameSet(Set<String> a, Set<String> b) =>
      a.length == b.length && a.containsAll(b);
}
