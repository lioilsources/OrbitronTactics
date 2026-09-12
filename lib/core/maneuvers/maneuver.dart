import '../game_logic/models/piece.dart';
import '../game_logic/models/spot.dart';

/// The move a maneuver belongs to. Ships share the families, each in its own
/// variant, so a gesture learned on one ship works on the next.
enum ManeuverFamily {
  sidestep,
  strike,
  retreat,
  slalom,
  loop,
  roll,
  feint,
  shadow,
  volley,
  dash,
  spiral,
  overdrive,
  signature,
}

/// How hard a maneuver is to come by.
enum ManeuverTier { starter, basic, advanced, signature, pack }

/// What a keyframe's offsets are measured from.
enum Anchor {
  /// Where the ship was when the maneuver started.
  origin,

  /// Where the enemy was when it started.
  enemyAtStart,

  /// Where the enemy is at this moment.
  enemyLive,

  /// The arena itself — the offset is the absolute position.
  arena,
}

enum Ease { linear, easeIn, easeOut, easeInOut }

/// How a maneuver is come by.
sealed class Unlock {
  const Unlock();
}

class StarterUnlock extends Unlock {
  const StarterUnlock();
}

/// Won by [wins] battles fought with this ship.
class WinsUnlock extends Unlock {
  final int wins;
  const WinsUnlock(this.wins);
}

class PackUnlock extends Unlock {
  final String packId;
  const PackUnlock(this.packId);
}

/// How the ship is drawn along the maneuver; the painter interpolates.
class Attitude {
  /// Turns around the ship's long axis: 1 is a full barrel roll.
  final double roll;

  /// -1 nose down, 1 nose up.
  final double pitch;

  /// Turns through the vertical: 1 is upside down, 2 a whole loop.
  final double flip;

  /// Engine flame, 0–1.
  final double boost;

  const Attitude({
    this.roll = 0,
    this.pitch = 0,
    this.flip = 0,
    this.boost = 0,
  });

  static const level = Attitude();

  Attitude get mirrored =>
      Attitude(roll: -roll, pitch: pitch, flip: flip, boost: boost);

  static Attitude lerp(Attitude from, Attitude to, double t) => Attitude(
        roll: from.roll + (to.roll - from.roll) * t,
        pitch: from.pitch + (to.pitch - from.pitch) * t,
        flip: from.flip + (to.flip - from.flip) * t,
        boost: from.boost + (to.boost - from.boost) * t,
      );
}

/// One point of a maneuver's path, [t] of the way through (0–1).
class Keyframe {
  final double t;
  final Anchor xAnchor;
  final double dx;
  final Anchor altitudeAnchor;
  final double dAltitude;

  /// Shape of the movement from the previous keyframe to this one.
  final Ease ease;
  final Attitude attitude;

  const Keyframe(
    this.t, {
    this.xAnchor = Anchor.origin,
    this.dx = 0,
    this.altitudeAnchor = Anchor.origin,
    this.dAltitude = 0,
    this.ease = Ease.easeInOut,
    this.attitude = Attitude.level,
  });
}

/// A burst of shots [t] of the way through the maneuver.
class FireCue {
  final double t;

  /// Shots fired at once, spread over as many lanes.
  final int shots;

  /// Distance between neighbouring lanes of one burst.
  final double spread;

  /// Multiplier on the unit's damage.
  final double damage;

  const FireCue(this.t, {this.shots = 1, this.spread = 0, this.damage = 1});
}

/// What one upgrade level adds. `levels[0]` is level 2, `levels[1]` level 3.
class LevelBonus {
  final int energySaved;
  final double durationScale;
  final int extraShots;
  final int extraUntouchableMs;

  const LevelBonus({
    this.energySaved = 0,
    this.durationScale = 1,
    this.extraShots = 0,
    this.extraUntouchableMs = 0,
  });
}

/// Where the ship is and how it is held at one moment of a maneuver.
class ManeuverPose {
  final double x;
  final double altitude;
  final Attitude attitude;

  const ManeuverPose({
    required this.x,
    required this.altitude,
    required this.attitude,
  });
}

/// What a running maneuver is measured against.
class ManeuverContext {
  final Spot origin;
  final Spot enemyAtStart;
  final Spot enemyLive;

  const ManeuverContext({
    required this.origin,
    required this.enemyAtStart,
    required this.enemyLive,
  });
}

/// A scripted move a ship flies on its own: it follows [path], fires at
/// [fire] and, while it runs, ignores steering.
class Maneuver {
  /// `<ship>.<family>`, e.g. `knight.loop`.
  final String id;
  final PieceType ship;
  final ManeuverFamily family;
  final ManeuverTier tier;
  final String name;
  final String description;

  /// The gesture that starts it, as dots of the 3×3 grid.
  final List<int> pattern;

  /// Whether the mirrored gesture flies the mirrored maneuver.
  final bool mirrorable;

  final int durationMs;
  final int energyCost;
  final List<Keyframe> path;
  final List<FireCue> fire;

  /// Window (from, to) of the maneuver in which shots pass through.
  final (double, double)? untouchable;

  /// Raises the shield at the start.
  final bool shield;

  /// Raises it even on cooldown.
  final bool ignoresShieldCooldown;

  /// Leaves steering to the player; only the firing changes.
  final bool keepsControl;

  /// Multiplier on the attack interval while [keepsControl] runs.
  final double fireRateScale;

  final Unlock unlock;

  /// Credits that buy it before it is earned; null when it cannot be bought.
  final int? price;

  final List<LevelBonus> levels;

  const Maneuver({
    required this.id,
    required this.ship,
    required this.family,
    required this.tier,
    required this.name,
    required this.description,
    required this.pattern,
    required this.durationMs,
    required this.energyCost,
    required this.unlock,
    this.mirrorable = false,
    this.path = const [],
    this.fire = const [],
    this.untouchable,
    this.shield = false,
    this.ignoresShieldCooldown = false,
    this.keepsControl = false,
    this.fireRateScale = 1,
    this.price,
    this.levels = const [],
  });

  /// Levels this maneuver can still be upgraded to, 1 (as owned) to 3.
  static const int maxLevel = 3;

  Iterable<LevelBonus> _bonusesAt(int level) =>
      levels.take((level - 1).clamp(0, levels.length));

  int costAt(int level) {
    var cost = energyCost;
    for (final bonus in _bonusesAt(level)) {
      cost -= bonus.energySaved;
    }
    return cost.clamp(5, 100);
  }

  int durationAt(int level) {
    var duration = durationMs.toDouble();
    for (final bonus in _bonusesAt(level)) {
      duration *= bonus.durationScale;
    }
    return duration.round();
  }

  (double, double)? untouchableAt(int level) {
    final window = untouchable;
    if (window == null) return null;
    var extra = 0;
    for (final bonus in _bonusesAt(level)) {
      extra += bonus.extraUntouchableMs;
    }
    if (extra == 0) return window;
    final grown = extra / durationAt(level);
    return (window.$1, (window.$2 + grown).clamp(0.0, 1.0));
  }

  /// Shots in [cue] at this [level].
  int shotsAt(FireCue cue, int level) {
    var shots = cue.shots;
    for (final bonus in _bonusesAt(level)) {
      shots += bonus.extraShots;
    }
    return shots;
  }

  /// Where the ship is [progress] of the way through, and how it is held.
  ManeuverPose poseAt(
    double progress, {
    required ManeuverContext context,
    bool mirrored = false,
  }) {
    final t = progress.clamp(0.0, 1.0);
    const start = Keyframe(0);
    var before = start;
    Keyframe? after;
    for (final frame in path) {
      if (frame.t <= t) {
        before = frame;
      } else {
        after = frame;
        break;
      }
    }
    final from = _poseOf(before, context, mirrored);
    if (after == null) return from;
    final to = _poseOf(after, context, mirrored);
    final span = after.t - before.t;
    final local = span <= 0 ? 1.0 : ((t - before.t) / span).clamp(0.0, 1.0);
    final eased = _easeValue(after.ease, local);
    return ManeuverPose(
      x: from.x + (to.x - from.x) * eased,
      altitude: from.altitude + (to.altitude - from.altitude) * eased,
      attitude: Attitude.lerp(from.attitude, to.attitude, eased),
    );
  }

  ManeuverPose _poseOf(Keyframe frame, ManeuverContext context, bool mirrored) {
    final base = (
      x: _anchor(frame.xAnchor, context).x,
      altitude: _anchor(frame.altitudeAnchor, context).altitude,
    );
    return ManeuverPose(
      x: base.x + (mirrored ? -frame.dx : frame.dx),
      altitude: base.altitude + frame.dAltitude,
      attitude: mirrored ? frame.attitude.mirrored : frame.attitude,
    );
  }

  static Spot _anchor(Anchor anchor, ManeuverContext context) =>
      switch (anchor) {
        Anchor.origin => context.origin,
        Anchor.enemyAtStart => context.enemyAtStart,
        Anchor.enemyLive => context.enemyLive,
        Anchor.arena => (x: 0.0, altitude: 0.0),
      };

  static double _easeValue(Ease ease, double t) => switch (ease) {
        Ease.linear => t,
        Ease.easeIn => t * t,
        Ease.easeOut => 1 - (1 - t) * (1 - t),
        Ease.easeInOut => t < 0.5 ? 2 * t * t : 1 - 2 * (1 - t) * (1 - t),
      };
}

/// A set of maneuvers sold together.
class ManeuverPack {
  final String id;
  final String name;
  final String description;

  const ManeuverPack({
    required this.id,
    required this.name,
    required this.description,
  });
}
