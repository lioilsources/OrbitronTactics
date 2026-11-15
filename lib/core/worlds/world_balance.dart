import '../game_logic/engine/unit_base_stats.dart';
import '../game_logic/models/piece.dart';
import '../game_logic/models/unit_stats.dart';
import '../game_logic/models/weapon_type.dart';

/// Arena rules a world may change. Space keeps today's arena.
///
/// Only the balance's unit stats are read by the engine so far; the arena
/// rules come with the melee track (plan 12, step 3).
class ArenaRules {
  /// 1.0: a shot crosses in its weapon's fixed time (space); below 1 shots
  /// between close units arrive sooner.
  final double rangeTravelScale;

  /// Battle time after which the hit zones start to grow; null = no limit.
  final int? suddenDeathAfterMs;

  /// Energy a melee hit wins back for maneuvers.
  final double energyPerHit;

  const ArenaRules({
    this.rangeTravelScale = 1.0,
    this.suddenDeathAfterMs,
    this.energyPerHit = 0,
  });
}

/// The tunable numbers of one world: unit stats per role and arena rules.
/// The single source for the arena, `BattleOdds` and the board AI.
class WorldBalance {
  /// Stable key, part of the odds cache.
  final String id;
  final Map<PieceType, UnitStats> units;
  final ArenaRules arena;

  const WorldBalance({
    required this.id,
    required this.units,
    this.arena = const ArenaRules(),
  });

  UnitStats statsOf(PieceType type) => units[type]!;

  /// Today's space arena, unchanged.
  static const WorldBalance space = WorldBalance(id: 'space', units: unitBaseStats);

  /// A ground world: pawns, knights, rooks and kings fight up close; bishops
  /// and queens keep their ranged weapons. Tuned with `tools/duel_lab.dart`
  /// to stay within 10 points of the same pairing in space.
  static const WorldBalance ground = WorldBalance(
    id: 'ground',
    units: {
      PieceType.pawn: UnitStats(
        maxHp: 45,
        damage: 13,
        attackIntervalMs: 700,
        defenseRating: 0.0,
        weaponType: WeaponType.rapidFire,
        attack: AttackStyle.melee,
        melee: MeleeProfile(
          windupMs: 180,
          dashMsPerRange: 220,
          recoverMs: 200,
          arcHalfWidth: 0.09,
        ),
      ),
      PieceType.knight: UnitStats(
        maxHp: 80,
        damage: 29,
        attackIntervalMs: 1000,
        defenseRating: 0.10,
        weaponType: WeaponType.standard,
        attack: AttackStyle.melee,
        melee: MeleeProfile(
          windupMs: 160,
          dashMsPerRange: 180,
          recoverMs: 250,
          arcHalfWidth: 0.09,
        ),
      ),
      PieceType.bishop: UnitStats(
        maxHp: 70,
        damage: 25,
        attackIntervalMs: 900,
        defenseRating: 0.05,
        weaponType: WeaponType.sniper,
      ),
      PieceType.rook: UnitStats(
        maxHp: 130,
        damage: 44,
        attackIntervalMs: 1500,
        defenseRating: 0.25,
        weaponType: WeaponType.heavyCannon,
        attack: AttackStyle.melee,
        melee: MeleeProfile(
          windupMs: 350,
          dashMsPerRange: 300,
          recoverMs: 400,
          arcHalfWidth: 0.12,
        ),
      ),
      PieceType.queen: UnitStats(
        maxHp: 150,
        damage: 40,
        attackIntervalMs: 1000,
        defenseRating: 0.20,
        weaponType: WeaponType.heavyCannon,
      ),
      PieceType.king: UnitStats(
        maxHp: 180,
        damage: 46,
        attackIntervalMs: 1500,
        defenseRating: 0.35,
        weaponType: WeaponType.heavyCannon,
        attack: AttackStyle.melee,
        melee: MeleeProfile(
          windupMs: 280,
          dashMsPerRange: 280,
          recoverMs: 400,
          arcHalfWidth: 0.12,
        ),
      ),
    },
  );

  static const List<WorldBalance> all = [space, ground];
}
