import 'piece.dart';

class UpgradeProfile {
  final Map<PieceType, int> levels;

  const UpgradeProfile({this.levels = const {}});

  factory UpgradeProfile.empty() => const UpgradeProfile();

  int levelFor(PieceType type) => levels[type] ?? 0;

  UpgradeProfile copyWith({Map<PieceType, int>? levels}) {
    return UpgradeProfile(levels: levels ?? this.levels);
  }

  Map<String, dynamic> toJson() =>
      {for (final e in levels.entries) e.key.name: e.value};

  factory UpgradeProfile.fromJson(Map<String, dynamic> json) => UpgradeProfile(
        levels: {
          for (final e in json.entries)
            PieceType.values.byName(e.key): (e.value as num).toInt(),
        },
      );
}
