class Projectile {
  final String id;
  final double positionFraction;
  final int damage;
  final bool fromAttacker;

  const Projectile({
    required this.id,
    required this.positionFraction,
    required this.damage,
    required this.fromAttacker,
  });

  Projectile copyWith({
    String? id,
    double? positionFraction,
    int? damage,
    bool? fromAttacker,
  }) {
    return Projectile(
      id: id ?? this.id,
      positionFraction: positionFraction ?? this.positionFraction,
      damage: damage ?? this.damage,
      fromAttacker: fromAttacker ?? this.fromAttacker,
    );
  }
}
