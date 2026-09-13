/// Skill tiers of the single-player AI opponent.
///
/// Difficulty is skill only — search depth and arena reflexes. Unit strength
/// comes from the AI fleet's upgrades, which grow through play.
enum AiDifficulty { easy, medium, hard }

/// All tunables of one AI difficulty: board play, arena piloting and fleet
/// progression.
class AiProfile {
  final AiDifficulty difficulty;

  // Board
  /// Plies searched ahead; 0 = greedy one-ply evaluation.
  final int searchDepth;

  /// Uniform noise (±) added to every candidate move's score.
  final double evalNoise;

  /// Whether the evaluation counts pieces that can be captured next move.
  final bool useThreatTerm;

  /// Wall-clock budget for iterative deepening; 0 = no limit.
  final int timeBudgetMs;

  /// UX pause before the AI plays its move.
  final int thinkDelayMs;

  // Battle
  /// Minimum time between steering decisions.
  final int reactionMs;

  /// Ship speed in arena widths per second.
  final double maxShipSpeed;

  /// Max random aim offset, in arena widths.
  final double aimError;

  /// Chance (0–1) of raising the shield against a hit it cannot dodge.
  final double shieldSkill;

  /// Incoming shots arriving sooner than this are dodged.
  final int dodgeWindowMs;

  /// Lead the opponent's ship using its recent velocity.
  final bool predictOpponent;

  /// Chance (0–1) of reaching for a maneuver when one would help.
  final double maneuverSkill;

  /// How many of its ship's maneuvers the pilot knows; six include the
  /// ship's signature.
  final int maneuverCount;

  // Progression
  /// How many upgrade levels the AI fleet may lead the player's fleet by.
  final int rubberBandOffset;

  /// Fleet progress key, e.g. `ai-hard`.
  final String identity;

  final String displayName;

  /// Slug of the fleet skin this AI's ships are drawn with.
  final String fleetSkin;

  const AiProfile({
    required this.difficulty,
    required this.searchDepth,
    required this.evalNoise,
    required this.useThreatTerm,
    required this.timeBudgetMs,
    required this.thinkDelayMs,
    required this.reactionMs,
    required this.maxShipSpeed,
    required this.aimError,
    required this.shieldSkill,
    required this.dodgeWindowMs,
    required this.predictOpponent,
    required this.maneuverSkill,
    required this.maneuverCount,
    required this.rubberBandOffset,
    required this.identity,
    required this.displayName,
    required this.fleetSkin,
  });

  static const easy = AiProfile(
    difficulty: AiDifficulty.easy,
    searchDepth: 0,
    evalNoise: 40,
    useThreatTerm: false,
    timeBudgetMs: 0,
    thinkDelayMs: 500,
    reactionMs: 400,
    maxShipSpeed: 0.5,
    aimError: 0.10,
    shieldSkill: 0.4,
    dodgeWindowMs: 250,
    predictOpponent: false,
    maneuverSkill: 0.2,
    maneuverCount: 2,
    rubberBandOffset: 0,
    identity: 'ai-easy',
    displayName: 'Orbitron AI · Easy',
    fleetSkin: 'star_nomads',
  );

  static const medium = AiProfile(
    difficulty: AiDifficulty.medium,
    searchDepth: 0,
    evalNoise: 5,
    useThreatTerm: true,
    timeBudgetMs: 0,
    thinkDelayMs: 400,
    reactionMs: 220,
    maxShipSpeed: 0.9,
    aimError: 0.05,
    shieldSkill: 0.7,
    dodgeWindowMs: 400,
    predictOpponent: false,
    maneuverSkill: 0.5,
    maneuverCount: 4,
    rubberBandOffset: 1,
    identity: 'ai-medium',
    displayName: 'Orbitron AI · Medium',
    fleetSkin: 'iron_armada',
  );

  static const hard = AiProfile(
    difficulty: AiDifficulty.hard,
    searchDepth: 3,
    evalNoise: 0,
    useThreatTerm: true,
    timeBudgetMs: 800,
    thinkDelayMs: 300,
    reactionMs: 100,
    maxShipSpeed: 1.5,
    aimError: 0.015,
    shieldSkill: 0.95,
    dodgeWindowMs: 600,
    predictOpponent: true,
    maneuverSkill: 0.85,
    maneuverCount: 6,
    rubberBandOffset: 2,
    identity: 'ai-hard',
    displayName: 'Orbitron AI · Hard',
    fleetSkin: 'void_hive',
  );

  static AiProfile of(AiDifficulty difficulty) => switch (difficulty) {
        AiDifficulty.easy => easy,
        AiDifficulty.medium => medium,
        AiDifficulty.hard => hard,
      };

  AiProfile copyWith({
    int? searchDepth,
    double? evalNoise,
    bool? useThreatTerm,
    int? timeBudgetMs,
    int? thinkDelayMs,
    int? reactionMs,
    double? maxShipSpeed,
    double? aimError,
    double? shieldSkill,
    int? dodgeWindowMs,
    bool? predictOpponent,
    double? maneuverSkill,
    int? maneuverCount,
    int? rubberBandOffset,
  }) {
    return AiProfile(
      difficulty: difficulty,
      searchDepth: searchDepth ?? this.searchDepth,
      evalNoise: evalNoise ?? this.evalNoise,
      useThreatTerm: useThreatTerm ?? this.useThreatTerm,
      timeBudgetMs: timeBudgetMs ?? this.timeBudgetMs,
      thinkDelayMs: thinkDelayMs ?? this.thinkDelayMs,
      reactionMs: reactionMs ?? this.reactionMs,
      maxShipSpeed: maxShipSpeed ?? this.maxShipSpeed,
      aimError: aimError ?? this.aimError,
      shieldSkill: shieldSkill ?? this.shieldSkill,
      dodgeWindowMs: dodgeWindowMs ?? this.dodgeWindowMs,
      predictOpponent: predictOpponent ?? this.predictOpponent,
      maneuverSkill: maneuverSkill ?? this.maneuverSkill,
      maneuverCount: maneuverCount ?? this.maneuverCount,
      rubberBandOffset: rubberBandOffset ?? this.rubberBandOffset,
      identity: identity,
      displayName: displayName,
      fleetSkin: fleetSkin,
    );
  }
}
