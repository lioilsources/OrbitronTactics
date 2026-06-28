import 'piece.dart';

class UpgradeProfile {
  final Map<PieceType, int> levels;

  const UpgradeProfile({this.levels = const {}});

  factory UpgradeProfile.empty() => const UpgradeProfile();

  int levelFor(PieceType type) => levels[type] ?? 0;

  UpgradeProfile copyWith({Map<PieceType, int>? levels}) {
    return UpgradeProfile(levels: levels ?? this.levels);
  }
}
