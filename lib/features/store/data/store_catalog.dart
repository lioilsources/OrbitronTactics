import '../../../core/maneuvers/maneuver.dart';
import '../../../core/maneuvers/maneuver_catalog.dart';
import '../../battle/data/battle_music.dart';
import '../../battle/data/fleet_skin.dart';
import '../../game/data/piece_skin.dart';
import '../../../l10n/app_localizations_en.dart';

/// What a store item hands over.
enum StoreItemKind { commander, fleet, world, maneuverPack, music }

/// One product in the store. [id] is the product id in Google Play and App
/// Store Connect, the same on both.
class StoreItem {
  const StoreItem._({
    required this.id,
    required this.kind,
    required this.title,
    required this.description,
    this.fleet,
    this.world,
    this.pack,
    this.music,
  });

  final String id;
  final StoreItemKind kind;
  final String title;
  final String description;

  /// The fleet a [StoreItemKind.fleet] item sells.
  final FleetSkin? fleet;

  /// The world a [StoreItemKind.world] item sells.
  final PieceSkin? world;

  /// The maneuver pack a [StoreItemKind.maneuverPack] item sells.
  final ManeuverPack? pack;

  /// The battle music a [StoreItemKind.music] item sells.
  final BattleMusic? music;
}

/// Every product the game sells: one-time purchases of extra content, none
/// of which makes a fleet stronger.
class StoreCatalog {
  const StoreCatalog._();

  /// Every product id is `com.ol1n.<app>.pack.<packId>` (lowercase: Google
  /// Play takes no capitals in product ids).
  static const _prefix = 'com.ol1n.orbitrontactics.pack.';

  static const commanderId = '${_prefix}commander';

  static String fleetId(FleetSkin skin) => '${_prefix}fleet_${skin.slug}';
  static String worldId(PieceSkin world) => '${_prefix}world_${world.slug}';
  static String packId(String pack) => '$_prefix$pack';
  static String musicId(BattleMusic music) => '${_prefix}music_${music.slug}';

  static final premiumFleets = [
    for (final skin in FleetSkin.values)
      if (skin.premium) skin,
  ];

  static final premiumWorlds = [
    for (final world in PieceSkin.values)
      if (world.premium) world,
  ];

  /// Biggest first, as the store lists them.
  static final List<StoreItem> items = [
    const StoreItem._(
      id: commanderId,
      kind: StoreItemKind.commander,
      title: 'Commander Edition',
      description: 'Every premium world, fleet, maneuver pack and music '
          'pack, and everything added to the store later.',
    ),
    for (final world in premiumWorlds)
      StoreItem._(
        id: worldId(world),
        kind: StoreItemKind.world,
        title: world.displayName(AppLocalizationsEn()),
        description: 'Both armies of this world, on the board and in the '
            'arena. Looks only: they fight like any other world.',
        world: world,
      ),
    for (final skin in premiumFleets)
      StoreItem._(
        id: fleetId(skin),
        kind: StoreItemKind.fleet,
        title: skin.displayName,
        description: 'Ship art for all six units, white and black, flown in '
            'the Space world. Looks only: it flies like any other fleet.',
        fleet: skin,
      ),
    for (final pack in ManeuverCatalog.packs)
      StoreItem._(
        id: packId(pack.id),
        kind: StoreItemKind.maneuverPack,
        title: pack.name,
        description: pack.description,
        pack: pack,
      ),
    for (final music in BattleMusic.values)
      if (music.premium)
        StoreItem._(
          id: musicId(music),
          kind: StoreItemKind.music,
          title: '${music.displayName} music',
          description: 'Every battle theme again as 8-bit chiptune, from the '
              "pawn's quick synth line to the king's march.",
          music: music,
        ),
  ];

  static final Map<String, StoreItem> _byId = {
    for (final item in items) item.id: item,
  };

  static List<String> get ids => [for (final item in items) item.id];

  static StoreItem? byId(String id) => _byId[id];

  static StoreItem forFleet(FleetSkin skin) => _byId[fleetId(skin)]!;

  static StoreItem forWorld(PieceSkin world) => _byId[worldId(world)]!;

  static StoreItem forPack(String pack) => _byId[packId(pack)]!;

  static StoreItem forMusic(BattleMusic music) => _byId[musicId(music)]!;
}
