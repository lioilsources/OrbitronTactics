import '../../../core/maneuvers/maneuver_catalog.dart';
import '../../battle/data/fleet_skin.dart';
import 'store_catalog.dart';

/// What this install may use from the store: the products bought, and the
/// premium fleet a player flew before fleets were sold.
class Entitlements {
  const Entitlements({this.products = const {}, this.legacyFleets = const {}});

  /// Store product ids owned, as the store reports them.
  final Set<String> products;

  /// Slugs of premium fleets kept from before the store existed.
  final Set<String> legacyFleets;

  bool get commander => products.contains(StoreCatalog.commanderId);

  bool get allFleets =>
      commander || products.contains(StoreCatalog.fleetBundleId);

  bool ownsFleet(FleetSkin skin) =>
      !skin.premium ||
      allFleets ||
      products.contains(StoreCatalog.fleetId(skin)) ||
      legacyFleets.contains(skin.slug);

  bool ownsPack(String pack) =>
      commander || products.contains(StoreCatalog.packId(pack));

  /// Whether everything [item] hands over is already here.
  bool owns(StoreItem item) => switch (item.kind) {
        StoreItemKind.commander => commander,
        StoreItemKind.fleetBundle => allFleets,
        StoreItemKind.fleet => ownsFleet(item.fleet!),
        StoreItemKind.maneuverPack => ownsPack(item.pack!.id),
      };

  /// Ids of the maneuver packs owned, to grant to the player's fleet.
  List<String> get ownedPacks => [
        for (final pack in ManeuverCatalog.packs)
          if (ownsPack(pack.id)) pack.id,
      ];

  Entitlements copyWith({Set<String>? products, Set<String>? legacyFleets}) =>
      Entitlements(
        products: products ?? this.products,
        legacyFleets: legacyFleets ?? this.legacyFleets,
      );

  factory Entitlements.fromJson(Map<String, dynamic> json) {
    Set<String> strings(String key) => switch (json[key]) {
          final List<dynamic> list => {...list.whereType<String>()},
          _ => const {},
        };
    return Entitlements(
      products: strings('products'),
      legacyFleets: strings('legacyFleets'),
    );
  }

  Map<String, dynamic> toJson() => {
        'products': products.toList()..sort(),
        'legacyFleets': legacyFleets.toList()..sort(),
      };

  @override
  bool operator ==(Object other) =>
      other is Entitlements &&
      _sameSet(other.products, products) &&
      _sameSet(other.legacyFleets, legacyFleets);

  @override
  int get hashCode => Object.hash(
      Object.hashAllUnordered(products), Object.hashAllUnordered(legacyFleets));

  static bool _sameSet(Set<String> a, Set<String> b) =>
      a.length == b.length && a.containsAll(b);
}
