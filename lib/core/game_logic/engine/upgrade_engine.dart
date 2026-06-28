import '../models/piece.dart';
import '../models/unit_stats.dart';
import '../models/upgrade_profile.dart';

const List<int> _upgradeCosts = [100, 250, 500];

const Map<int, double> _hpMultiplier = {1: 1.20, 2: 1.40, 3: 1.60};
const Map<int, double> _damageMultiplier = {1: 1.20, 2: 1.40, 3: 1.60};
const Map<int, double> _attackSpeedMultiplier = {1: 0.90, 2: 0.85, 3: 0.80};
const Map<int, int> _shieldDurationBonus = {1: 500, 2: 750, 3: 1000};

class UpgradeEngine {
  const UpgradeEngine._();

  static UnitStats applyUpgrades(UnitStats base, int level) {
    if (level <= 0) return base;
    final l = level.clamp(1, 3);
    return base.copyWith(
      maxHp: (base.maxHp * _hpMultiplier[l]!).round(),
      damage: (base.damage * _damageMultiplier[l]!).round(),
      attackIntervalMs:
          (base.attackIntervalMs * _attackSpeedMultiplier[l]!).round(),
      shieldDurationMs: base.shieldDurationMs + _shieldDurationBonus[l]!,
    );
  }

  static UnitStats statsFor(PieceType type, UpgradeProfile profile,
      Map<PieceType, UnitStats> baseStats) {
    final base = baseStats[type]!;
    return applyUpgrades(base, profile.levelFor(type));
  }

  static int upgradeCost(int currentLevel) {
    if (currentLevel >= _upgradeCosts.length) return -1;
    return _upgradeCosts[currentLevel];
  }

  static int resourcesFor(PieceType type) {
    return switch (type) {
      PieceType.pawn => 20,
      PieceType.knight => 30,
      PieceType.bishop => 35,
      PieceType.rook => 40,
      PieceType.queen => 60,
      PieceType.king => 100,
    };
  }
}
