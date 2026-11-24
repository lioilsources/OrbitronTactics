/// A shot that arrived on target, or a melee strike that made contact: it
/// struck the unit, or the shield raised in its way. Kept briefly so the
/// arena can play the explosion.
class Impact {
  /// The projectile's id, or a strike's own.
  final String id;

  /// Whether the struck ship is the attacker.
  final bool onAttacker;

  /// Where the shot struck: its lane across the arena and its altitude.
  final double xFraction;
  final double altitude;

  /// The shot's damage before the target's defense.
  final int damage;

  /// Whether the target's shield absorbed the shot.
  final bool shielded;

  /// Battle time of the impact.
  final int atMs;

  /// Whether a melee strike made it (a blocked one is [shielded]).
  final bool melee;

  const Impact({
    required this.id,
    required this.onAttacker,
    required this.xFraction,
    required this.altitude,
    required this.damage,
    required this.shielded,
    required this.atMs,
    this.melee = false,
  });
}
