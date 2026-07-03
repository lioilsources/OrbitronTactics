import 'weapon_type.dart';

class UnitStats {
  final int maxHp;
  final int damage;
  final int attackIntervalMs;
  final double defenseRating;
  final WeaponType weaponType;
  final int shieldDurationMs;
  final int shieldCooldownMs;

  const UnitStats({
    required this.maxHp,
    required this.damage,
    required this.attackIntervalMs,
    required this.defenseRating,
    required this.weaponType,
    this.shieldDurationMs = 1500,
    this.shieldCooldownMs = 5000,
  });

  UnitStats copyWith({
    int? maxHp,
    int? damage,
    int? attackIntervalMs,
    double? defenseRating,
    WeaponType? weaponType,
    int? shieldDurationMs,
    int? shieldCooldownMs,
  }) {
    return UnitStats(
      maxHp: maxHp ?? this.maxHp,
      damage: damage ?? this.damage,
      attackIntervalMs: attackIntervalMs ?? this.attackIntervalMs,
      defenseRating: defenseRating ?? this.defenseRating,
      weaponType: weaponType ?? this.weaponType,
      shieldDurationMs: shieldDurationMs ?? this.shieldDurationMs,
      shieldCooldownMs: shieldCooldownMs ?? this.shieldCooldownMs,
    );
  }
}
