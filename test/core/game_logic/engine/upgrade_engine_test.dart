import 'package:flutter_test/flutter_test.dart';
import 'package:orbitron_tactics/core/game_logic/engine/unit_base_stats.dart';
import 'package:orbitron_tactics/core/game_logic/engine/upgrade_engine.dart';
import 'package:orbitron_tactics/core/game_logic/models/piece.dart';
import 'package:orbitron_tactics/core/game_logic/models/upgrade_profile.dart';

void main() {
  group('UpgradeEngine.applyUpgrades', () {
    final base = unitBaseStats[PieceType.knight]!;

    test('level 0 returns the base stats unchanged', () {
      expect(UpgradeEngine.applyUpgrades(base, 0), same(base));
    });

    test('each level boosts hp and damage and speeds up attacks', () {
      final l1 = UpgradeEngine.applyUpgrades(base, 1);
      expect(l1.maxHp, (base.maxHp * 1.20).round());
      expect(l1.damage, (base.damage * 1.20).round());
      expect(l1.attackIntervalMs, lessThan(base.attackIntervalMs));
      expect(l1.shieldDurationMs, greaterThan(base.shieldDurationMs));

      final l3 = UpgradeEngine.applyUpgrades(base, 3);
      expect(l3.maxHp, (base.maxHp * 1.60).round());
      expect(l3.damage, greaterThan(l1.damage));
    });

    test('levels are clamped to the 1..3 range', () {
      final over = UpgradeEngine.applyUpgrades(base, 99);
      final l3 = UpgradeEngine.applyUpgrades(base, 3);
      expect(over.maxHp, l3.maxHp);
      expect(over.damage, l3.damage);
    });
  });

  group('UpgradeEngine.statsFor', () {
    test('applies the profile level for the given piece type', () {
      const profile = UpgradeProfile(levels: {PieceType.pawn: 2});
      final pawn =
          UpgradeEngine.statsFor(PieceType.pawn, profile, unitBaseStats);
      final rook =
          UpgradeEngine.statsFor(PieceType.rook, profile, unitBaseStats);

      expect(pawn.maxHp, (unitBaseStats[PieceType.pawn]!.maxHp * 1.40).round());
      expect(rook.maxHp, unitBaseStats[PieceType.rook]!.maxHp); // unleveled
    });
  });

  group('UpgradeEngine costs and rewards', () {
    test('upgrade costs rise per level and cap at level 3', () {
      expect(UpgradeEngine.upgradeCost(0), 100);
      expect(UpgradeEngine.upgradeCost(1), 250);
      expect(UpgradeEngine.upgradeCost(2), 500);
      expect(UpgradeEngine.upgradeCost(3), -1); // maxed
    });

    test('stronger pieces pay out more credits', () {
      expect(UpgradeEngine.resourcesFor(PieceType.king),
          greaterThan(UpgradeEngine.resourcesFor(PieceType.pawn)));
    });
  });

  group('UpgradeProfile JSON', () {
    test('round-trips through JSON', () {
      const profile = UpgradeProfile(
          levels: {PieceType.pawn: 2, PieceType.queen: 3});
      final restored = UpgradeProfile.fromJson(profile.toJson());
      expect(restored.levelFor(PieceType.pawn), 2);
      expect(restored.levelFor(PieceType.queen), 3);
      expect(restored.levelFor(PieceType.rook), 0);
    });
  });
}
