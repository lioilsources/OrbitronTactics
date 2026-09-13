import 'package:collection/collection.dart';

import '../engine/upgrade_engine.dart';
import 'piece.dart';
import 'ship_maneuvers.dart';
import 'upgrade_profile.dart';

/// A fleet's lasting progress: unspent credits, unit upgrades, record, the
/// ship art it flies and what each of its ships can fly.
class FleetProgress {
  final int credits;
  final UpgradeProfile profile;
  final int gamesPlayed;
  final int wins;

  /// Slug of the fleet skin the ships are drawn with; null until chosen.
  final String? skin;

  /// Maneuvers per ship; a ship not in here flies what it starts with.
  final Map<PieceType, ShipManeuvers> maneuvers;

  /// Battles won in the arena by each ship — what unlocks its maneuvers.
  final Map<PieceType, int> battleWins;

  const FleetProgress({
    this.credits = 0,
    this.profile = const UpgradeProfile(),
    this.gamesPlayed = 0,
    this.wins = 0,
    this.skin,
    this.maneuvers = const {},
    this.battleWins = const {},
  });

  /// Reads [toJson]'s shape; missing or malformed fields fall back to their
  /// defaults, so progress saved before a field existed still loads.
  factory FleetProgress.fromJson(Map<String, dynamic> json) {
    int count(String key) => switch (json[key]) {
          final num value => value.toInt(),
          _ => 0,
        };
    final upgrades = json['upgrades'];
    return FleetProgress(
      credits: count('credits'),
      profile: upgrades is Map<String, dynamic>
          ? UpgradeProfile.fromJson(upgrades)
          : const UpgradeProfile(),
      gamesPlayed: count('gamesPlayed'),
      wins: count('wins'),
      skin: switch (json['skin']) {
        final String slug => slug,
        _ => null,
      },
      maneuvers: switch (json['maneuvers']) {
        final Map<String, dynamic> saved => {
            for (final ship in PieceType.values)
              if (saved[ship.name] case final Map<String, dynamic> ships)
                ship: ShipManeuvers.fromJson(ships, ship),
          },
        _ => const {},
      },
      battleWins: switch (json['battleWins']) {
        final Map<String, dynamic> saved => {
            for (final ship in PieceType.values)
              if (saved[ship.name] case final num won) ship: won.toInt(),
          },
        _ => const {},
      },
    );
  }

  int get losses => gamesPlayed - wins;

  /// Sum of the upgrade levels of every unit type.
  int get totalLevels =>
      profile.levels.values.fold(0, (sum, level) => sum + level);

  /// What [ship] can fly; a ship that has learned nothing flies its
  /// starters.
  ShipManeuvers maneuversFor(PieceType ship) =>
      maneuvers[ship] ?? ShipManeuvers.starter(ship);

  /// Battles [ship] has won in the arena.
  int battleWinsWith(PieceType ship) => battleWins[ship] ?? 0;

  /// This fleet after buying [type]'s next level, or null when that unit is
  /// maxed out or the credits don't cover it.
  FleetProgress? upgraded(PieceType type) {
    final level = profile.levelFor(type);
    final cost = UpgradeEngine.upgradeCost(level);
    if (cost < 0 || credits < cost) return null;
    return copyWith(
      credits: credits - cost,
      profile: profile.copyWith(levels: {...profile.levels, type: level + 1}),
    );
  }

  FleetProgress copyWith({
    int? credits,
    UpgradeProfile? profile,
    int? gamesPlayed,
    int? wins,
    String? skin,
    Map<PieceType, ShipManeuvers>? maneuvers,
    Map<PieceType, int>? battleWins,
  }) {
    return FleetProgress(
      credits: credits ?? this.credits,
      profile: profile ?? this.profile,
      gamesPlayed: gamesPlayed ?? this.gamesPlayed,
      wins: wins ?? this.wins,
      skin: skin ?? this.skin,
      maneuvers: maneuvers ?? this.maneuvers,
      battleWins: battleWins ?? this.battleWins,
    );
  }

  Map<String, dynamic> toJson() => {
        'credits': credits,
        'upgrades': profile.toJson(),
        'gamesPlayed': gamesPlayed,
        'wins': wins,
        if (skin != null) 'skin': skin,
        if (maneuvers.isNotEmpty)
          'maneuvers': {
            for (final entry in maneuvers.entries)
              entry.key.name: entry.value.toJson(),
          },
        if (battleWins.isNotEmpty)
          'battleWins': {
            for (final entry in battleWins.entries) entry.key.name: entry.value,
          },
      };

  @override
  bool operator ==(Object other) =>
      other is FleetProgress &&
      other.credits == credits &&
      other.profile == profile &&
      other.gamesPlayed == gamesPlayed &&
      other.wins == wins &&
      other.skin == skin &&
      const MapEquality<PieceType, ShipManeuvers>()
          .equals(other.maneuvers, maneuvers) &&
      const MapEquality<PieceType, int>()
          .equals(other.battleWins, battleWins);

  @override
  int get hashCode => Object.hash(
        credits,
        profile,
        gamesPlayed,
        wins,
        skin,
        const MapEquality<PieceType, ShipManeuvers>().hash(maneuvers),
        const MapEquality<PieceType, int>().hash(battleWins),
      );
}
