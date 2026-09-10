import 'piece.dart';

class UpgradeProfile {
  final Map<PieceType, int> levels;

  const UpgradeProfile({this.levels = const {}});

  factory UpgradeProfile.empty() => const UpgradeProfile();

  /// Levels keyed by unit type name, e.g. `{"pawn": 1}` — the shape of the
  /// `user_upgrades.upgrades` column. Unknown keys are ignored.
  factory UpgradeProfile.fromJson(Map<String, dynamic> json) {
    return UpgradeProfile(levels: {
      for (final type in PieceType.values)
        if (json[type.name] case final num level) type: level.toInt(),
    });
  }

  int levelFor(PieceType type) => levels[type] ?? 0;

  UpgradeProfile copyWith({Map<PieceType, int>? levels}) {
    return UpgradeProfile(levels: levels ?? this.levels);
  }

  Map<String, int> toJson() => {
        for (final entry in levels.entries) entry.key.name: entry.value,
      };

  @override
  bool operator ==(Object other) =>
      other is UpgradeProfile &&
      PieceType.values.every((type) => other.levelFor(type) == levelFor(type));

  @override
  int get hashCode => Object.hashAll(PieceType.values.map(levelFor));
}
