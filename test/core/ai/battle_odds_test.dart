import 'package:flutter_test/flutter_test.dart';
import 'package:orbitron_tactics/core/ai/battle_odds.dart';
import 'package:orbitron_tactics/core/game_logic/engine/battle_engine.dart';
import 'package:orbitron_tactics/core/game_logic/engine/unit_base_stats.dart';
import 'package:orbitron_tactics/core/game_logic/models/battle_state.dart';
import 'package:orbitron_tactics/core/game_logic/models/battle_unit.dart';
import 'package:orbitron_tactics/core/game_logic/models/piece.dart';
import 'package:orbitron_tactics/core/game_logic/models/shield_state.dart';
import 'package:orbitron_tactics/core/game_logic/models/unit_stats.dart';
import 'package:orbitron_tactics/core/game_logic/models/upgrade_profile.dart';

void main() {
  const noUpgrades = UpgradeProfile();
  const tickMs = 16;

  Piece white(PieceType type) => Piece(type: type, color: PlayerColor.white);
  Piece black(PieceType type) => Piece(type: type, color: PlayerColor.black);

  double odds(
    PieceType attacker,
    PieceType defender, {
    UpgradeProfile attackerUpgrades = noUpgrades,
  }) =>
      BattleOdds.attackerWinProbability(
          white(attacker), black(defender), attackerUpgrades, noUpgrades);

  BattleUnit unit(Piece piece, UnitStats stats) => BattleUnit(
        piece: piece,
        stats: stats,
        currentHp: stats.maxHp,
        shieldState: const ShieldState(),
        nextAttackMs: stats.attackIntervalMs,
      );

  /// Runs a battle with both ships parked in the center until one dies.
  BattleState fight(BattleState battle) {
    while (!battle.isFinished) {
      battle = BattleEngine.tick(battle, tickMs);
    }
    return battle;
  }

  group('BattleOdds', () {
    test('a pawn attacking a king is hopeless', () {
      expect(odds(PieceType.pawn, PieceType.king), lessThan(0.2));
    });

    test('a king attacking a pawn is near certain', () {
      expect(odds(PieceType.king, PieceType.pawn), greaterThan(0.8));
    });

    test('identical units are an even fight', () {
      for (final type in PieceType.values) {
        expect(odds(type, type), 0.5, reason: type.name);
      }
    });

    test('every estimate stays within the bounds', () {
      for (final attacker in PieceType.values) {
        for (final defender in PieceType.values) {
          expect(
            odds(attacker, defender),
            inInclusiveRange(
                BattleOdds.minProbability, BattleOdds.maxProbability),
          );
        }
      }
    });

    test('upgrades improve the odds', () {
      const upgraded = UpgradeProfile(levels: {PieceType.knight: 3});

      expect(
        odds(PieceType.knight, PieceType.knight, attackerUpgrades: upgraded),
        greaterThan(0.5),
      );
    });

    test('timeToKillMs matches the arena against a target that never hits',
        () {
      for (final shooter in PieceType.values) {
        for (final target in PieceType.values) {
          final shooterStats = unitBaseStats[shooter]!;
          final targetStats = unitBaseStats[target]!;

          final battle = fight(BattleState(
            attacker: unit(white(shooter), shooterStats),
            defender: unit(black(target), targetStats.copyWith(damage: 0)),
          ));

          expect(
            battle.elapsedMs,
            closeTo(BattleOdds.timeToKillMs(shooterStats, targetStats), tickMs),
            reason: '${shooter.name} shooting ${target.name}',
          );
        }
      }
    });

    test('the favourite wins the arena in all 36 pairings', () {
      for (final attacker in PieceType.values) {
        for (final defender in PieceType.values) {
          final battle = fight(BattleEngine.createBattle(
            attacker: white(attacker),
            defender: black(defender),
            attackerUpgrades: noUpgrades,
            defenderUpgrades: noUpgrades,
          ));
          final p = odds(attacker, defender);

          if (p == 0.5) {
            // Only a mirror match is a dead heat: both ships die on the same
            // tick and the engine awards the attacker.
            expect(attacker, defender);
            continue;
          }
          expect(battle.winner == PlayerColor.white, p > 0.5,
              reason: '${attacker.name} attacking ${defender.name}, p=$p');
        }
      }
    });
  });
}
