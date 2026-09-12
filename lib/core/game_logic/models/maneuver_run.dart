import '../../maneuvers/maneuver.dart';
import '../../maneuvers/maneuver_catalog.dart';
import 'spot.dart';

/// A maneuver a ship is flying right now.
///
/// It holds what the maneuver's path is measured against — where the ship
/// started and where the enemy was — so the same run yields the same flight
/// whoever ticks it: the engine, the painter or the opponent's device.
class ManeuverRun {
  final String id;
  final int level;

  /// Whether the mirrored gesture started it.
  final bool mirrored;

  /// Battle time the maneuver started at.
  final int startedMs;

  final Spot origin;
  final Spot enemyAtStart;

  /// Indexes of [Maneuver.fire] already fired.
  final Set<int> firedCues;

  const ManeuverRun({
    required this.id,
    required this.startedMs,
    required this.origin,
    required this.enemyAtStart,
    this.level = 1,
    this.mirrored = false,
    this.firedCues = const {},
  });

  Maneuver get maneuver => ManeuverCatalog.byId(id)!;

  int get durationMs => maneuver.durationAt(level);

  /// How far through the maneuver is at battle time [elapsedMs], 0–1.
  double progressAt(int elapsedMs) => durationMs <= 0
      ? 1
      : ((elapsedMs - startedMs) / durationMs).clamp(0.0, 1.0);

  /// Where the ship is and how it is held, with the enemy at [enemyLive].
  ManeuverPose poseAt(int elapsedMs, Spot enemyLive) => maneuver.poseAt(
        progressAt(elapsedMs),
        context: ManeuverContext(
          origin: origin,
          enemyAtStart: enemyAtStart,
          enemyLive: enemyLive,
        ),
        mirrored: mirrored,
      );

  /// Whether shots pass through the ship at [elapsedMs].
  bool untouchableAt(int elapsedMs) {
    final window = maneuver.untouchableAt(level);
    if (window == null) return false;
    final progress = progressAt(elapsedMs);
    return progress >= window.$1 && progress <= window.$2;
  }

  ManeuverRun withFired(Set<int> cues) => ManeuverRun(
        id: id,
        level: level,
        mirrored: mirrored,
        startedMs: startedMs,
        origin: origin,
        enemyAtStart: enemyAtStart,
        firedCues: cues,
      );
}
