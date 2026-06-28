import '../models/piece.dart';
import '../models/unit_stats.dart';
import '../models/weapon_type.dart';

const Map<PieceType, UnitStats> unitBaseStats = {
  PieceType.pawn: UnitStats(
    maxHp: 40,
    damage: 8,
    attackIntervalMs: 400,
    defenseRating: 0.0,
    weaponType: WeaponType.rapidFire,
  ),
  PieceType.knight: UnitStats(
    maxHp: 80,
    damage: 20,
    attackIntervalMs: 800,
    defenseRating: 0.10,
    weaponType: WeaponType.standard,
  ),
  PieceType.bishop: UnitStats(
    maxHp: 70,
    damage: 25,
    attackIntervalMs: 900,
    defenseRating: 0.05,
    weaponType: WeaponType.sniper,
  ),
  PieceType.rook: UnitStats(
    maxHp: 120,
    damage: 30,
    attackIntervalMs: 1200,
    defenseRating: 0.25,
    weaponType: WeaponType.heavyCannon,
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
    damage: 35,
    attackIntervalMs: 1400,
    defenseRating: 0.35,
    weaponType: WeaponType.heavyCannon,
  ),
};
