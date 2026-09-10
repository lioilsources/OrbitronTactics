import '../engine/upgrade_engine.dart';
import 'piece.dart';
import 'upgrade_profile.dart';

/// A fleet's lasting progress: unspent credits, unit upgrades and record.
class FleetProgress {
  final int credits;
  final UpgradeProfile profile;
  final int gamesPlayed;
  final int wins;

  const FleetProgress({
    this.credits = 0,
    this.profile = const UpgradeProfile(),
    this.gamesPlayed = 0,
    this.wins = 0,
  });

  /// Reads [toJson]'s shape; missing or malformed fields fall back to zero.
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
    );
  }

  int get losses => gamesPlayed - wins;

  /// Sum of the upgrade levels of every unit type.
  int get totalLevels =>
      profile.levels.values.fold(0, (sum, level) => sum + level);

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
  }) {
    return FleetProgress(
      credits: credits ?? this.credits,
      profile: profile ?? this.profile,
      gamesPlayed: gamesPlayed ?? this.gamesPlayed,
      wins: wins ?? this.wins,
    );
  }

  Map<String, dynamic> toJson() => {
        'credits': credits,
        'upgrades': profile.toJson(),
        'gamesPlayed': gamesPlayed,
        'wins': wins,
      };

  @override
  bool operator ==(Object other) =>
      other is FleetProgress &&
      other.credits == credits &&
      other.profile == profile &&
      other.gamesPlayed == gamesPlayed &&
      other.wins == wins;

  @override
  int get hashCode => Object.hash(credits, profile, gamesPlayed, wins);
}
