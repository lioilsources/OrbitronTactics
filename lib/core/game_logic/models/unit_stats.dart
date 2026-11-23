import 'weapon_type.dart';

/// How a unit attacks: by firing shots across the arena or by lunging at the
/// enemy.
enum AttackStyle { ranged, melee }

/// Timing of a melee unit's strike: a wind-up the enemy can see and step out
/// of, an untouchable lunge whose length grows with the distance between the
/// two units, and a vulnerable recovery.
class MeleeProfile {
  final int windupMs;

  /// Lunge time per unit of range; range is 0 with both units at the divider
  /// and 2 with both at their own edges.
  final int dashMsPerRange;
  final int recoverMs;

  /// Extra recovery when the enemy's shield blocks the strike.
  final int staggerMs;

  /// How far across the target may be from the striker and still be hit.
  final double arcHalfWidth;

  /// A lunge never takes less than this.
  static const int minDashMs = 80;

  const MeleeProfile({
    required this.windupMs,
    required this.dashMsPerRange,
    required this.recoverMs,
    required this.arcHalfWidth,
    this.staggerMs = 400,
  });

  /// Lunge time at [range].
  int dashMsAt(double range) {
    final ms = (dashMsPerRange * range).round();
    return ms < minDashMs ? minDashMs : ms;
  }
}

class UnitStats {
  final int maxHp;
  final int damage;
  final int attackIntervalMs;
  final double defenseRating;
  final WeaponType weaponType;
  final int shieldDurationMs;
  final int shieldCooldownMs;
  final AttackStyle attack;

  /// Strike timing; set exactly when [attack] is [AttackStyle.melee].
  final MeleeProfile? melee;

  const UnitStats({
    required this.maxHp,
    required this.damage,
    required this.attackIntervalMs,
    required this.defenseRating,
    required this.weaponType,
    this.shieldDurationMs = 1500,
    this.shieldCooldownMs = 5000,
    this.attack = AttackStyle.ranged,
    this.melee,
  }) : assert((attack == AttackStyle.melee) == (melee != null));

  bool get isMelee => attack == AttackStyle.melee;

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
      attack: attack,
      melee: melee,
    );
  }
}
