import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/game_logic/models/fleet_progress.dart';
import '../../../../core/game_logic/models/piece.dart';
import '../../../../core/game_logic/models/ship_maneuvers.dart';
import '../../../../core/maneuvers/maneuver.dart';
import '../../../../core/maneuvers/maneuver_catalog.dart';
import '../../data/fleet_progress_store.dart';

/// Fleet identity of the human player; the app has no accounts yet.
const playerFleetIdentity = 'player';

/// Device storage for fleets. `main()` overrides it once SharedPreferences
/// has loaded.
final fleetProgressStoreProvider = Provider<FleetProgressStore>(
  (ref) => throw UnimplementedError(
      'fleetProgressStoreProvider must be overridden in main()'),
);

/// One fleet's progress. Every change is saved right away.
class FleetProgressNotifier extends StateNotifier<FleetProgress> {
  FleetProgressNotifier(this._store, this._identity)
      : super(_store.load(_identity));

  final FleetProgressStore _store;
  final String _identity;

  @override
  set state(FleetProgress value) {
    super.state = value;
    unawaited(_store.save(_identity, value));
  }

  void addCredits(int credits) =>
      state = state.copyWith(credits: state.credits + credits);

  /// Buys [type]'s next level. False when it is maxed out or unaffordable.
  bool upgrade(PieceType type) {
    final upgraded = state.upgraded(type);
    if (upgraded == null) return false;
    state = upgraded;
    return true;
  }

  void recordGame({required bool won}) => state = state.copyWith(
        gamesPlayed: state.gamesPlayed + 1,
        wins: state.wins + (won ? 1 : 0),
      );

  /// Draws this fleet's ships with the fleet skin [slug] from now on.
  void setSkin(String slug) => state = state.copyWith(skin: slug);

  /// Records a battle [ship] won in the arena and returns what that win has
  /// just unlocked. Anything unlocked is armed if the pad has room.
  List<Maneuver> recordBattleWin(PieceType ship) {
    final won = state.battleWinsWith(ship) + 1;
    final learned = state.maneuversFor(ship);
    final unlocked = [
      for (final maneuver in ManeuverCatalog.forShip(ship))
        if (!learned.owned.contains(maneuver.id))
          if (maneuver.unlock case WinsUnlock(:final wins) when wins <= won)
            maneuver,
    ];
    state = state.copyWith(
      battleWins: {...state.battleWins, ship: won},
      maneuvers: unlocked.isEmpty
          ? state.maneuvers
          : {
              ...state.maneuvers,
              ship: learned.learn([for (final one in unlocked) one.id]),
            },
    );
    return unlocked;
  }

  /// Buys [id] for [ship]. False when it is not for sale, already owned or
  /// the credits don't cover it.
  bool buyManeuver(PieceType ship, String id) {
    final maneuver = ManeuverCatalog.byId(id);
    final price = maneuver?.price;
    if (maneuver == null || maneuver.ship != ship || price == null) return false;
    final learned = state.maneuversFor(ship);
    if (learned.owned.contains(id) || state.credits < price) return false;
    state = state.copyWith(
      credits: state.credits - price,
      maneuvers: {...state.maneuvers, ship: learned.learn([id])},
    );
    return true;
  }

  /// Trains an owned maneuver one level further.
  bool upgradeManeuver(PieceType ship, String id) {
    final maneuver = ManeuverCatalog.byId(id);
    final learned = state.maneuversFor(ship);
    if (maneuver == null || !learned.owned.contains(id)) return false;
    final level = learned.levelOf(id) + 1;
    if (level > Maneuver.maxLevel) return false;
    final price = ManeuverCatalog.upgradePrice(maneuver, level);
    if (state.credits < price) return false;
    state = state.copyWith(
      credits: state.credits - price,
      maneuvers: {
        ...state.maneuvers,
        ship: learned.copyWith(levels: {...learned.levels, id: level}),
      },
    );
    return true;
  }

  /// Arms [ids] on [ship]'s pad. False when one of them is not owned, or
  /// there are more than the pad holds.
  bool armManeuvers(PieceType ship, List<String> ids) {
    final learned = state.maneuversFor(ship);
    if (ids.length > ShipManeuvers.slots) return false;
    if (ids.any((id) => !learned.owned.contains(id))) return false;
    state = state.copyWith(
      maneuvers: {...state.maneuvers, ship: learned.copyWith(active: ids)},
    );
    return true;
  }

  /// Hands over everything in [packId] — what buying a pack grants.
  void grantPack(String packId) {
    final byShip = <PieceType, List<String>>{};
    for (final maneuver in ManeuverCatalog.inPack(packId)) {
      byShip.putIfAbsent(maneuver.ship, () => []).add(maneuver.id);
    }
    if (byShip.isEmpty) return;
    state = state.copyWith(maneuvers: {
      ...state.maneuvers,
      for (final entry in byShip.entries)
        entry.key: state.maneuversFor(entry.key).learn(entry.value),
    });
  }

  void replace(FleetProgress progress) => state = progress;
}

/// Progress of the fleet with the given identity: [playerFleetIdentity] or
/// an [AiProfile.identity].
final fleetProgressProvider = StateNotifierProvider.family<
    FleetProgressNotifier, FleetProgress, String>(
  (ref, identity) =>
      FleetProgressNotifier(ref.watch(fleetProgressStoreProvider), identity),
);
