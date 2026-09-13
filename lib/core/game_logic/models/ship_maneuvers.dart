import 'package:collection/collection.dart';

import '../../maneuvers/maneuver_catalog.dart';
import 'piece.dart';

/// What one ship of a fleet has learned: the maneuvers it owns, the ones it
/// takes into battle and how far each is trained.
class ShipManeuvers {
  /// Ids of every maneuver this ship has earned, bought or been given.
  final Set<String> owned;

  /// The ones armed on the pad, at most [slots] of them, in order.
  final List<String> active;

  /// Trained levels, 2 or 3; a maneuver not in here is at level 1.
  final Map<String, int> levels;

  /// How many maneuvers a ship can take into a battle.
  static const int slots = 4;

  const ShipManeuvers({
    this.owned = const {},
    this.active = const [],
    this.levels = const {},
  });

  /// What a ship flies before it has won anything.
  factory ShipManeuvers.starter(PieceType ship) {
    final starters = ManeuverCatalog.starterIds(ship);
    return ShipManeuvers(owned: starters.toSet(), active: starters);
  }

  factory ShipManeuvers.fromJson(Map<String, dynamic> json, PieceType ship) {
    final owned = switch (json['owned']) {
      final List<dynamic> ids => ids.whereType<String>().toSet(),
      _ => ManeuverCatalog.starterIds(ship).toSet(),
    };
    final active = switch (json['active']) {
      final List<dynamic> ids => ids.whereType<String>().toList(),
      _ => <String>[],
    };
    final levels = switch (json['levels']) {
      final Map<String, dynamic> saved => {
          for (final entry in saved.entries)
            if (entry.value case final num level) entry.key: level.toInt(),
        },
      _ => <String, int>{},
    };
    return ShipManeuvers(
      owned: owned,
      // Only what is still owned can be armed.
      active: [
        for (final id in active.take(slots))
          if (owned.contains(id)) id,
      ],
      levels: levels,
    );
  }

  int levelOf(String id) => levels[id] ?? 1;

  bool get hasFreeSlot => active.length < slots;

  /// This ship having learned [ids], armed too when there is room.
  ShipManeuvers learn(Iterable<String> ids) {
    final armed = [...active];
    for (final id in ids) {
      if (!armed.contains(id) && armed.length < slots) armed.add(id);
    }
    return copyWith(owned: {...owned, ...ids}, active: armed);
  }

  ShipManeuvers copyWith({
    Set<String>? owned,
    List<String>? active,
    Map<String, int>? levels,
  }) =>
      ShipManeuvers(
        owned: owned ?? this.owned,
        active: active ?? this.active,
        levels: levels ?? this.levels,
      );

  Map<String, dynamic> toJson() => {
        'owned': owned.toList()..sort(),
        'active': active,
        if (levels.isNotEmpty) 'levels': levels,
      };

  @override
  bool operator ==(Object other) =>
      other is ShipManeuvers &&
      const SetEquality<String>().equals(other.owned, owned) &&
      const ListEquality<String>().equals(other.active, active) &&
      const MapEquality<String, int>().equals(other.levels, levels);

  @override
  int get hashCode => Object.hash(
        const SetEquality<String>().hash(owned),
        const ListEquality<String>().hash(active),
        const MapEquality<String, int>().hash(levels),
      );
}
