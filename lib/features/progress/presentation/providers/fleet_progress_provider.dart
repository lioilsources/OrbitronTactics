import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/game_logic/models/fleet_progress.dart';
import '../../../../core/game_logic/models/piece.dart';
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

  void replace(FleetProgress progress) => state = progress;
}

/// Progress of the fleet with the given identity: [playerFleetIdentity] or
/// an [AiProfile.identity].
final fleetProgressProvider = StateNotifierProvider.family<
    FleetProgressNotifier, FleetProgress, String>(
  (ref, identity) =>
      FleetProgressNotifier(ref.watch(fleetProgressStoreProvider), identity),
);
