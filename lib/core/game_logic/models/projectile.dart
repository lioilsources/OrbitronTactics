class Projectile {
  final String id;
  final double positionFraction;
  final int damage;
  final bool fromAttacker;

  /// Horizontal firing position, 0.0 (left) to 1.0 (right).
  /// The projectile travels straight; the target dodges by moving away.
  final double xFraction;

  const Projectile({
    required this.id,
    required this.positionFraction,
    required this.damage,
    required this.fromAttacker,
    this.xFraction = 0.5,
  });

  Projectile copyWith({
    String? id,
    double? positionFraction,
    int? damage,
    bool? fromAttacker,
    double? xFraction,
  }) {
    return Projectile(
      id: id ?? this.id,
      positionFraction: positionFraction ?? this.positionFraction,
      damage: damage ?? this.damage,
      fromAttacker: fromAttacker ?? this.fromAttacker,
      xFraction: xFraction ?? this.xFraction,
    );
  }
}
