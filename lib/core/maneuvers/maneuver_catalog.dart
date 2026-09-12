import '../game_logic/models/piece.dart';
import 'maneuver.dart';

/// Every maneuver each ship can fly.
///
/// The families are shared, so a gesture learned on one ship works on the
/// next; each ship flies them in its own variant (a rook is slow and heavy,
/// a pawn quick and light) and adds one signature maneuver of its own.
class ManeuverCatalog {
  const ManeuverCatalog._();

  /// Packs sold as a whole; their maneuvers cannot be earned by playing.
  static const packs = [
    ManeuverPack(
      id: 'ace',
      name: 'Ace pack',
      description: 'The corkscrew, for every ship that can fly it.',
    ),
  ];

  static final Map<PieceType, List<Maneuver>> _byShip = {
    for (final ship in PieceType.values) ship: _buildShip(ship),
  };

  static final Map<String, Maneuver> _byId = {
    for (final maneuvers in _byShip.values)
      for (final maneuver in maneuvers) maneuver.id: maneuver,
  };

  /// Everything [ship] can fly, easiest to come by first.
  static List<Maneuver> forShip(PieceType ship) => _byShip[ship]!;

  static Maneuver? byId(String id) => _byId[id];

  /// What a ship flies from the start.
  static List<String> starterIds(PieceType ship) => [
        for (final maneuver in forShip(ship))
          if (maneuver.tier == ManeuverTier.starter) maneuver.id,
      ];

  static List<Maneuver> inPack(String packId) => [
        for (final maneuver in _byId.values)
          if (maneuver.unlock case PackUnlock(packId: final id) when id == packId)
            maneuver,
      ];

  /// Credits that take a maneuver to [toLevel] (2 or 3).
  static int upgradePrice(Maneuver maneuver, int toLevel) {
    final base = switch (maneuver.tier) {
      ManeuverTier.starter => 150,
      ManeuverTier.basic => 200,
      ManeuverTier.advanced => 300,
      ManeuverTier.signature || ManeuverTier.pack => 450,
    };
    return base * (toLevel - 1);
  }

  static List<Maneuver> _buildShip(PieceType ship) {
    final style = _styles[ship]!;
    final builders = <ManeuverFamily, Maneuver Function(PieceType, _Style)>{
      ManeuverFamily.sidestep: _sidestep,
      ManeuverFamily.strike: _strike,
      ManeuverFamily.retreat: _retreat,
      ManeuverFamily.roll: _roll,
      ManeuverFamily.feint: _feint,
      ManeuverFamily.volley: _volley,
      ManeuverFamily.slalom: _slalom,
      ManeuverFamily.dash: _dash,
      ManeuverFamily.shadow: _shadow,
      ManeuverFamily.overdrive: _overdrive,
      ManeuverFamily.loop: _loop,
      ManeuverFamily.spiral: _spiral,
      ManeuverFamily.signature: _signature,
    };
    return [
      for (final entry in builders.entries)
        if (!style.without.contains(entry.key)) entry.value(ship, style),
    ];
  }
}

/// How one ship flies the shared families.
class _Style {
  final double duration;
  final int energy;
  final double damage;
  final int extraShots;

  /// Added to every untouchable window.
  final int untouchableMs;
  final Set<ManeuverFamily> without;

  const _Style({
    this.duration = 1,
    this.energy = 0,
    this.damage = 1,
    this.extraShots = 0,
    this.untouchableMs = 0,
    this.without = const {},
  });
}

const _heavy = {ManeuverFamily.loop, ManeuverFamily.spiral};

const _styles = {
  // Quick and light: shorter moves, weaker but wider bursts.
  PieceType.pawn: _Style(duration: 0.8, energy: -5, damage: 0.8, extraShots: 1),
  // The acrobat: its escapes last longest.
  PieceType.knight: _Style(untouchableMs: 100),
  PieceType.bishop: _Style(duration: 1.2),
  // Too heavy to loop or corkscrew.
  PieceType.rook: _Style(duration: 1.3, without: _heavy),
  PieceType.queen: _Style(),
  PieceType.king: _Style(duration: 1.3, energy: 5, without: _heavy),
};

const _tiers = {
  ManeuverFamily.sidestep: ManeuverTier.starter,
  ManeuverFamily.strike: ManeuverTier.starter,
  ManeuverFamily.retreat: ManeuverTier.basic,
  ManeuverFamily.roll: ManeuverTier.basic,
  ManeuverFamily.feint: ManeuverTier.basic,
  ManeuverFamily.volley: ManeuverTier.basic,
  ManeuverFamily.slalom: ManeuverTier.advanced,
  ManeuverFamily.dash: ManeuverTier.advanced,
  ManeuverFamily.shadow: ManeuverTier.advanced,
  ManeuverFamily.overdrive: ManeuverTier.advanced,
  ManeuverFamily.loop: ManeuverTier.signature,
  ManeuverFamily.signature: ManeuverTier.signature,
  ManeuverFamily.spiral: ManeuverTier.pack,
};

const _unlocks = {
  ManeuverFamily.sidestep: StarterUnlock(),
  ManeuverFamily.strike: StarterUnlock(),
  ManeuverFamily.retreat: WinsUnlock(2),
  ManeuverFamily.roll: WinsUnlock(3),
  ManeuverFamily.feint: WinsUnlock(4),
  ManeuverFamily.volley: WinsUnlock(5),
  ManeuverFamily.slalom: WinsUnlock(7),
  ManeuverFamily.dash: WinsUnlock(9),
  ManeuverFamily.shadow: WinsUnlock(11),
  ManeuverFamily.overdrive: WinsUnlock(13),
  ManeuverFamily.loop: WinsUnlock(16),
  ManeuverFamily.signature: WinsUnlock(20),
  ManeuverFamily.spiral: PackUnlock('ace'),
};

/// Credits that buy a maneuver before it is earned.
const _prices = {
  ManeuverTier.starter: null,
  ManeuverTier.basic: 150,
  ManeuverTier.advanced: 400,
  ManeuverTier.signature: 900,
  ManeuverTier.pack: null,
};

/// Shared gestures. A ship's signature has its own, below.
const _patterns = {
  ManeuverFamily.sidestep: [3, 4, 5],
  ManeuverFamily.strike: [7, 4, 1],
  ManeuverFamily.retreat: [1, 4, 7],
  ManeuverFamily.roll: [1, 5, 7, 3],
  ManeuverFamily.feint: [0, 7, 2],
  ManeuverFamily.volley: [0, 1, 2, 4, 7],
  ManeuverFamily.slalom: [0, 1, 2, 4, 6, 7, 8],
  ManeuverFamily.dash: [0, 4, 8],
  ManeuverFamily.shadow: [0, 1, 2, 4, 6],
  ManeuverFamily.overdrive: [2, 3, 4, 5, 6],
  ManeuverFamily.loop: [1, 2, 5, 8, 7, 6, 3, 0],
  ManeuverFamily.spiral: [4, 1, 2, 5, 8, 7, 6, 3],
};

const _signaturePatterns = {
  PieceType.pawn: [8, 5, 2, 1],
  PieceType.knight: [0, 3, 6, 7],
  PieceType.bishop: [0, 4, 8, 5, 2],
  PieceType.rook: [0, 3, 6, 7, 8, 5, 2],
  PieceType.queen: [6, 3, 0, 1, 2, 5, 8],
  PieceType.king: [6, 3, 0, 4, 2, 5, 8],
};

/// Builds one maneuver, applying the ship's style to the family's numbers.
Maneuver _make(
  PieceType ship,
  _Style style, {
  required ManeuverFamily family,
  required String name,
  required String description,
  required int durationMs,
  required int energyCost,
  List<int>? pattern,
  bool mirrorable = false,
  List<Keyframe> path = const [],
  List<FireCue> fire = const [],
  (double, double)? untouchable,
  bool shield = false,
  bool ignoresShieldCooldown = false,
  bool keepsControl = false,
  double fireRateScale = 1,
}) {
  final tier = _tiers[family]!;
  final duration = (durationMs * style.duration).round();
  final shaped = [
    for (final cue in fire)
      FireCue(
        cue.t,
        shots: cue.shots + (cue.shots > 0 ? style.extraShots : 0),
        spread: cue.shots + style.extraShots > 1 && cue.spread == 0
            ? 0.05
            : cue.spread,
        damage: cue.damage * style.damage,
      ),
  ];
  final window = untouchable == null || style.untouchableMs == 0
      ? untouchable
      : (
          untouchable.$1,
          (untouchable.$2 + style.untouchableMs / duration).clamp(0.0, 1.0),
        );
  return Maneuver(
    id: '${ship.name}.${family.name}',
    ship: ship,
    family: family,
    tier: tier,
    name: name,
    description: description,
    pattern: pattern ?? _patterns[family]!,
    mirrorable: mirrorable,
    durationMs: duration,
    energyCost: (energyCost + style.energy).clamp(5, 100),
    path: path,
    fire: shaped,
    untouchable: window,
    shield: shield,
    ignoresShieldCooldown: ignoresShieldCooldown,
    keepsControl: keepsControl,
    fireRateScale: fireRateScale,
    unlock: _unlocks[family]!,
    price: _prices[tier],
    levels: [
      const LevelBonus(energySaved: 5, durationScale: 0.92),
      LevelBonus(
        energySaved: 5,
        durationScale: 0.92,
        extraShots: shaped.isEmpty ? 0 : 1,
        extraUntouchableMs: shaped.isEmpty ? 100 : 0,
      ),
    ],
  );
}

Maneuver _sidestep(PieceType ship, _Style style) {
  final wide = ship == PieceType.rook;
  final step = wide ? 0.4 : 0.22;
  return _make(
    ship,
    style,
    family: ManeuverFamily.sidestep,
    name: wide ? 'Castle' : 'Sidestep',
    description: wide
        ? 'A long slide across the arena onto the enemy\'s altitude.'
        : 'A quick step aside, matching the enemy\'s altitude.',
    durationMs: 500,
    energyCost: 25,
    mirrorable: true,
    path: [
      Keyframe(0.5,
          dx: step * 0.6,
          altitudeAnchor: Anchor.enemyAtStart,
          ease: Ease.easeOut,
          attitude: const Attitude(roll: 0.35, boost: 0.6)),
      Keyframe(1,
          dx: step,
          altitudeAnchor: Anchor.enemyAtStart,
          ease: Ease.easeOut,
          attitude: const Attitude(roll: 0.1)),
    ],
  );
}

Maneuver _strike(PieceType ship, _Style style) {
  if (ship == PieceType.rook) {
    return _make(
      ship,
      style,
      family: ManeuverFamily.strike,
      name: 'Steamroller',
      description: 'Grinds forward, firing all the way.',
      durationMs: 1400,
      energyCost: 40,
      path: const [
        Keyframe(1,
            dAltitude: 0.35,
            ease: Ease.linear,
            attitude: Attitude(pitch: 0.5, boost: 0.8)),
      ],
      fire: const [
        FireCue(0.15, damage: 1.2),
        FireCue(0.4, damage: 1.2),
        FireCue(0.65, damage: 1.2),
        FireCue(0.9, damage: 1.2),
      ],
    );
  }
  return _make(
    ship,
    style,
    family: ManeuverFamily.strike,
    name: 'Strike',
    description: 'Climbs onto the enemy, fires twice and drops back.',
    durationMs: 900,
    energyCost: 35,
    path: const [
      Keyframe(0.4,
          altitudeAnchor: Anchor.enemyLive,
          ease: Ease.easeOut,
          attitude: Attitude(pitch: 1, boost: 1)),
      Keyframe(0.7,
          altitudeAnchor: Anchor.enemyLive,
          attitude: Attitude(pitch: 0.2, boost: 0.4)),
      Keyframe(1, ease: Ease.easeInOut, attitude: Attitude(pitch: -1, boost: 0.6)),
    ],
    fire: const [FireCue(0.4), FireCue(0.65)],
  );
}

Maneuver _retreat(PieceType ship, _Style style) => _make(
      ship,
      style,
      family: ManeuverFamily.retreat,
      name: 'Retreat',
      description: 'Falls back to its own edge behind a shield.',
      durationMs: ship == PieceType.king ? 1000 : 700,
      energyCost: 20,
      shield: true,
      path: const [
        Keyframe(1,
            altitudeAnchor: Anchor.arena,
            dAltitude: 0.08,
            ease: Ease.easeOut,
            attitude: Attitude(pitch: -1, boost: 0.8)),
      ],
    );

Maneuver _roll(PieceType ship, _Style style) => _make(
      ship,
      style,
      family: ManeuverFamily.roll,
      name: 'Barrel Roll',
      description: 'Rolls out of the way; shots pass through.',
      durationMs: 700,
      energyCost: 30,
      mirrorable: true,
      untouchable: (0.15, 0.65),
      path: const [
        Keyframe(0.5, dx: 0.1, attitude: Attitude(roll: 0.5, boost: 0.6)),
        Keyframe(1,
            dx: 0.18, ease: Ease.easeOut, attitude: Attitude(roll: 1, boost: 0.3)),
      ],
    );

Maneuver _feint(PieceType ship, _Style style) => _make(
      ship,
      style,
      family: ManeuverFamily.feint,
      name: 'Feint',
      description: 'Leans one way, cuts back the other and fires.',
      durationMs: 800,
      energyCost: 30,
      mirrorable: true,
      path: const [
        Keyframe(0.3, dx: -0.08, ease: Ease.easeOut, attitude: Attitude(roll: -0.3)),
        Keyframe(0.55,
            dx: -0.04,
            altitudeAnchor: Anchor.enemyAtStart,
            attitude: Attitude(roll: 0.2)),
        Keyframe(1,
            dx: 0.22,
            altitudeAnchor: Anchor.enemyAtStart,
            ease: Ease.easeOut,
            attitude: Attitude(roll: 0.4, boost: 0.7)),
      ],
      fire: const [FireCue(0.9)],
    );

Maneuver _volley(PieceType ship, _Style style) {
  if (ship == PieceType.bishop) {
    return _make(
      ship,
      style,
      family: ManeuverFamily.volley,
      name: 'Charged Shot',
      description: 'Holds still, charges, and lands one heavy round.',
      durationMs: 1200,
      energyCost: 45,
      path: const [
        Keyframe(0.85, attitude: Attitude(pitch: 0.4, boost: 0.1)),
        Keyframe(1, attitude: Attitude(pitch: -0.2, boost: 0.4)),
      ],
      fire: const [FireCue(0.85, damage: 3)],
    );
  }
  final heavy = ship == PieceType.rook;
  return _make(
    ship,
    style,
    family: ManeuverFamily.volley,
    name: 'Volley',
    description: heavy
        ? 'Two heavy rounds from a standing ship.'
        : 'Four rounds in a row from a standing ship.',
    durationMs: heavy ? 1000 : 900,
    energyCost: 40,
    path: const [
      Keyframe(0.5, attitude: Attitude(pitch: -0.2)),
      Keyframe(1, attitude: Attitude.level),
    ],
    fire: heavy
        ? const [FireCue(0.35, damage: 1.5), FireCue(0.75, damage: 1.5)]
        : const [
            FireCue(0.2),
            FireCue(0.4),
            FireCue(0.6),
            FireCue(0.8),
          ],
  );
}

Maneuver _slalom(PieceType ship, _Style style) => _make(
      ship,
      style,
      family: ManeuverFamily.slalom,
      name: 'Slalom',
      description: 'Weaves across the enemy\'s altitude, firing throughout.',
      durationMs: ship == PieceType.knight ? 1440 : 1600,
      energyCost: 45,
      mirrorable: true,
      path: const [
        Keyframe(0.25,
            dx: -0.2,
            altitudeAnchor: Anchor.enemyAtStart,
            attitude: Attitude(roll: -0.35, boost: 0.5)),
        Keyframe(0.5,
            dx: 0.2,
            altitudeAnchor: Anchor.enemyAtStart,
            attitude: Attitude(roll: 0.35, boost: 0.5)),
        Keyframe(0.75,
            dx: -0.2,
            altitudeAnchor: Anchor.enemyAtStart,
            attitude: Attitude(roll: -0.35, boost: 0.5)),
        Keyframe(1,
            altitudeAnchor: Anchor.enemyAtStart,
            attitude: Attitude(boost: 0.3)),
      ],
      fire: [for (var i = 1; i <= 8; i++) FireCue(i / 8, damage: 0.8)],
    );

Maneuver _dash(PieceType ship, _Style style) {
  final damage = ship == PieceType.queen ? 1.2 : 1.0;
  return _make(
    ship,
    style,
    family: ManeuverFamily.dash,
    name: 'Dash',
    description: 'Crosses the arena at the enemy\'s altitude, firing.',
    durationMs: 1000,
    energyCost: 40,
    mirrorable: true,
    untouchable: (0.2, 0.5),
    path: const [
      Keyframe(0.5,
          dx: 0.25,
          altitudeAnchor: Anchor.enemyLive,
          ease: Ease.easeIn,
          attitude: Attitude(roll: 0.4, boost: 1)),
      Keyframe(1,
          dx: 0.45,
          altitudeAnchor: Anchor.enemyLive,
          ease: Ease.easeOut,
          attitude: Attitude(roll: 0.15, boost: 0.6)),
    ],
    fire: [
      FireCue(0.3, damage: damage),
      FireCue(0.5, damage: damage),
      FireCue(0.7, damage: damage),
    ],
  );
}

Maneuver _shadow(PieceType ship, _Style style) {
  final damage = ship == PieceType.queen ? 1.2 : 1.0;
  return _make(
    ship,
    style,
    family: ManeuverFamily.shadow,
    name: 'Shadow',
    description: 'Sticks to the enemy wherever it goes, firing steadily.',
    durationMs: 2000,
    energyCost: 45,
    path: const [
      Keyframe(0.3,
          xAnchor: Anchor.enemyLive,
          altitudeAnchor: Anchor.enemyLive,
          ease: Ease.easeOut,
          attitude: Attitude(boost: 0.5)),
      Keyframe(1,
          xAnchor: Anchor.enemyLive,
          altitudeAnchor: Anchor.enemyLive,
          ease: Ease.linear,
          attitude: Attitude(boost: 0.3)),
    ],
    fire: [
      for (var i = 1; i <= 6; i++) FireCue(0.25 + i * 0.12, damage: damage),
    ],
  );
}

Maneuver _overdrive(PieceType ship, _Style style) => _make(
      ship,
      style,
      family: ManeuverFamily.overdrive,
      name: 'Overdrive',
      description: 'Keeps the helm, but the guns run hot for three seconds.',
      durationMs: 3000,
      energyCost: 35,
      keepsControl: true,
      fireRateScale: 0.6,
      path: const [
        Keyframe(0.1, attitude: Attitude(boost: 1)),
        Keyframe(1, attitude: Attitude(boost: 1)),
      ],
    );

Maneuver _loop(PieceType ship, _Style style) => _make(
      ship,
      style,
      family: ManeuverFamily.loop,
      name: 'Loop',
      description: 'Over the top and down; shots pass under the ship.',
      durationMs: 1800,
      energyCost: 50,
      untouchable: (0.25, 0.55),
      path: const [
        Keyframe(0.2,
            altitudeAnchor: Anchor.arena,
            dAltitude: 0.75,
            ease: Ease.easeOut,
            attitude: Attitude(pitch: 1, flip: 0.5, boost: 1)),
        Keyframe(0.35,
            altitudeAnchor: Anchor.arena,
            dAltitude: 1,
            attitude: Attitude(pitch: 0.4, flip: 1, boost: 0.8)),
        Keyframe(0.55,
            altitudeAnchor: Anchor.arena,
            dAltitude: 0.5,
            attitude: Attitude(pitch: -0.6, flip: 1.5, boost: 0.6)),
        Keyframe(0.7,
            altitudeAnchor: Anchor.arena,
            dAltitude: 0.05,
            ease: Ease.easeIn,
            attitude: Attitude(pitch: -1, flip: 2, boost: 0.8)),
        Keyframe(1, ease: Ease.easeOut, attitude: Attitude(boost: 0.5)),
      ],
      fire: const [FireCue(0.75), FireCue(0.85)],
    );

Maneuver _spiral(PieceType ship, _Style style) => _make(
      ship,
      style,
      family: ManeuverFamily.spiral,
      name: 'Corkscrew',
      description: 'Climbs and dives through a rolling spiral.',
      durationMs: 1500,
      energyCost: 50,
      untouchable: (0.3, 0.7),
      path: const [
        Keyframe(0.2,
            dx: 0.15,
            altitudeAnchor: Anchor.arena,
            dAltitude: 0.55,
            attitude: Attitude(roll: 0.5, boost: 0.8)),
        Keyframe(0.4,
            dx: -0.15,
            altitudeAnchor: Anchor.arena,
            dAltitude: 0.9,
            attitude: Attitude(roll: 1, boost: 0.8)),
        Keyframe(0.6,
            dx: 0.15,
            altitudeAnchor: Anchor.arena,
            dAltitude: 0.9,
            attitude: Attitude(roll: 1.5, boost: 0.8)),
        Keyframe(0.8,
            dx: -0.15,
            altitudeAnchor: Anchor.arena,
            dAltitude: 0.5,
            attitude: Attitude(roll: 2, boost: 0.6)),
        Keyframe(1, ease: Ease.easeOut, attitude: Attitude(roll: 2, boost: 0.4)),
      ],
      fire: const [FireCue(0.5), FireCue(0.9)],
    );

Maneuver _signature(PieceType ship, _Style style) => switch (ship) {
      PieceType.pawn => _make(
          ship,
          style,
          family: ManeuverFamily.signature,
          name: 'Double Step',
          description: 'Two hops forward, a burst after each.',
          durationMs: 1200,
          energyCost: 50,
          pattern: _signaturePatterns[ship],
          path: const [
            Keyframe(0.25,
                dAltitude: 0.25,
                ease: Ease.easeOut,
                attitude: Attitude(pitch: 1, boost: 1)),
            Keyframe(0.5, dAltitude: 0.25, attitude: Attitude(pitch: 0.2, boost: 0.3)),
            Keyframe(0.75,
                dAltitude: 0.5,
                ease: Ease.easeOut,
                attitude: Attitude(pitch: 1, boost: 1)),
            Keyframe(1, dAltitude: 0.5, attitude: Attitude(pitch: 0.2, boost: 0.3)),
          ],
          fire: const [
            FireCue(0.35, shots: 3, spread: 0.05, damage: 0.8),
            FireCue(0.85, shots: 3, spread: 0.05, damage: 0.8),
          ],
        ),
      PieceType.knight => _make(
          ship,
          style,
          family: ManeuverFamily.signature,
          name: 'Leap',
          description: 'Jumps clear and lands a lane over, on the enemy.',
          durationMs: 1000,
          energyCost: 45,
          mirrorable: true,
          pattern: _signaturePatterns[ship],
          untouchable: (0.1, 0.6),
          path: const [
            Keyframe(0.3,
                dx: 0.11,
                dAltitude: 0.5,
                ease: Ease.easeOut,
                attitude: Attitude(pitch: 1, roll: 0.3, boost: 1)),
            Keyframe(0.7,
                dx: 0.22,
                altitudeAnchor: Anchor.enemyLive,
                ease: Ease.easeIn,
                attitude: Attitude(pitch: -0.5, roll: 0.5, boost: 0.5)),
            Keyframe(1,
                dx: 0.22,
                altitudeAnchor: Anchor.enemyLive,
                attitude: Attitude(boost: 0.3)),
          ],
          fire: const [FireCue(0.75), FireCue(0.9)],
        ),
      PieceType.bishop => _make(
          ship,
          style,
          family: ManeuverFamily.signature,
          name: 'Sniper Shot',
          description: 'Stands still for a second, then one devastating round.',
          durationMs: 1200,
          energyCost: 55,
          pattern: _signaturePatterns[ship],
          path: const [
            Keyframe(0.85, attitude: Attitude(pitch: 0.4)),
            Keyframe(1, attitude: Attitude(pitch: -0.3, boost: 0.5)),
          ],
          fire: const [FireCue(0.85, damage: 3)],
        ),
      PieceType.rook => _make(
          ship,
          style,
          family: ManeuverFamily.signature,
          name: 'Bulwark',
          description: 'Shield up even on cooldown, three heavy rounds out.',
          durationMs: 1500,
          energyCost: 60,
          pattern: _signaturePatterns[ship],
          shield: true,
          ignoresShieldCooldown: true,
          path: const [Keyframe(1, attitude: Attitude(boost: 0.1))],
          fire: const [
            FireCue(0.25, damage: 1.5),
            FireCue(0.55, damage: 1.5),
            FireCue(0.85, damage: 1.5),
          ],
        ),
      PieceType.queen => _make(
          ship,
          style,
          family: ManeuverFamily.signature,
          name: 'Royal Waltz',
          description: 'Sweeps the whole arena on the enemy\'s altitude.',
          durationMs: 1800,
          energyCost: 60,
          mirrorable: true,
          pattern: _signaturePatterns[ship],
          untouchable: (0.15, 0.4),
          path: const [
            Keyframe(0.2,
                xAnchor: Anchor.arena,
                dx: 0.12,
                altitudeAnchor: Anchor.enemyLive,
                ease: Ease.easeOut,
                attitude: Attitude(roll: 0.4, boost: 1)),
            Keyframe(0.5,
                xAnchor: Anchor.arena,
                dx: 0.5,
                altitudeAnchor: Anchor.enemyLive,
                ease: Ease.linear,
                attitude: Attitude(roll: 0.2, boost: 0.6)),
            Keyframe(0.85,
                xAnchor: Anchor.arena,
                dx: 0.88,
                altitudeAnchor: Anchor.enemyLive,
                attitude: Attitude(roll: -0.4, boost: 1)),
            Keyframe(1,
                xAnchor: Anchor.arena,
                dx: 0.88,
                altitudeAnchor: Anchor.enemyLive,
                attitude: Attitude(boost: 0.3)),
          ],
          fire: const [
            FireCue(0.25),
            FireCue(0.4),
            FireCue(0.55),
            FireCue(0.7),
            FireCue(0.85),
            FireCue(0.95),
          ],
        ),
      PieceType.king => _make(
          ship,
          style,
          family: ManeuverFamily.signature,
          name: 'Crown',
          description: 'Holds the line behind a shield, every battery firing.',
          durationMs: 1600,
          energyCost: 60,
          pattern: _signaturePatterns[ship],
          shield: true,
          path: const [Keyframe(1, attitude: Attitude(boost: 0.2))],
          fire: const [
            FireCue(0.4, shots: 3, spread: 0.16),
            FireCue(0.8, shots: 3, spread: 0.16),
          ],
        ),
    };
