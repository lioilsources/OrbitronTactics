import 'package:flutter_test/flutter_test.dart';
import 'package:orbitron_tactics/core/ai/battle_odds.dart';
import 'package:orbitron_tactics/core/game_logic/engine/battle_engine.dart';
import 'package:orbitron_tactics/core/game_logic/engine/game_engine.dart';
import 'package:orbitron_tactics/core/game_logic/models/battle_state.dart';
import 'package:orbitron_tactics/core/game_logic/models/game_phase.dart';
import 'package:orbitron_tactics/core/game_logic/models/move.dart';
import 'package:orbitron_tactics/core/game_logic/models/piece.dart';
import 'package:orbitron_tactics/core/game_logic/models/player.dart';
import 'package:orbitron_tactics/core/game_logic/models/position.dart';
import 'package:orbitron_tactics/core/game_logic/models/upgrade_profile.dart';
import 'package:orbitron_tactics/core/maneuvers/maneuver.dart';
import 'package:orbitron_tactics/core/maneuvers/maneuver_catalog.dart';
import 'package:orbitron_tactics/core/worlds/world_balance.dart';

/// Melee combat as the game plays it (plan 14, step 5): mutual destruction,
/// the reach in sudden death, contact maneuvers and the board's side.
void main() {
  const tickMs = 16;
  const ground = WorldBalance.ground;

  BattleState battle(
    PieceType attacker,
    PieceType defender, {
    WorldBalance balance = ground,
  }) =>
      BattleEngine.createBattle(
        attacker: Piece(type: attacker, color: PlayerColor.white),
        defender: Piece(type: defender, color: PlayerColor.black),
        attackerUpgrades: const UpgradeProfile(),
        defenderUpgrades: const UpgradeProfile(),
        balance: balance,
      );

  BattleState run(BattleState state, int ms) {
    for (var t = 0; t < ms && !state.isFinished; t += tickMs) {
      state = BattleEngine.tick(state, tickMs);
    }
    return state;
  }

  group('mutual destruction', () {
    test('two strikes landing in one tick leave no winner', () {
      // Two pawns face to face, one blow from death, both ready to strike.
      var state = battle(PieceType.pawn, PieceType.pawn);
      state = state.copyWith(
        attacker: state.attacker.copyWith(currentHp: 1, nextAttackMs: 0),
        defender: state.defender.copyWith(currentHp: 1, nextAttackMs: 0),
      );
      state = run(state, 2000);

      expect(state.isFinished, isTrue);
      expect(state.winner, isNull);
      expect(state.isMutualDestruction, isTrue);
      expect(state.attacker.isAlive, isFalse);
      expect(state.defender.isAlive, isFalse);
    });

    test('a battle keeps the balance it was made with', () {
      expect(battle(PieceType.pawn, PieceType.king).balance, ground);
      expect(
          BattleEngine.tick(battle(PieceType.pawn, PieceType.king), tickMs)
              .balance,
          ground);
    });
  });

  group('sudden death', () {
    test('grows a strike\'s reach like the hit zone of shots', () {
      final start = battle(PieceType.knight, PieceType.knight);
      final striker = start.attacker;
      final target = start.defender.copyWith(xFraction: 0.85, altitude: 0.1);
      final rules = ground.arena;

      expect(BattleEngine.inReach(striker, target, rules: rules), isFalse);
      expect(
          BattleEngine.inReach(striker, target,
              elapsedMs: rules.suddenDeathAfterMs! - 1, rules: rules),
          isFalse);
      final late =
          rules.suddenDeathAfterMs! + rules.suddenDeathRampMs;
      expect(BattleEngine.inReach(striker, target, elapsedMs: late, rules: rules),
          isTrue);
      expect(
          BattleEngine.reachHalfWidthAt(striker.stats.melee!, late, rules) /
              striker.stats.melee!.arcHalfWidth,
          closeTo(
              BattleEngine.hitHalfWidthAt(late, rules) /
                  BattleEngine.hitHalfWidth,
              1e-9));
    });

    test('two melee units that keep apart still fight it out', () {
      // Opposite corners at their own edges: out of reach until sudden
      // death has grown it.
      var state = battle(PieceType.king, PieceType.king);
      state = BattleEngine.moveShip(state, true, 0.06, altitude: 0);
      state = BattleEngine.moveShip(state, false, 0.94, altitude: 0);
      final early = run(state, 30000);
      expect(early.impacts, isEmpty);
      expect(early.attacker.currentHp, early.attacker.stats.maxHp);

      final late = run(state, 120000);
      expect(late.isFinished, isTrue);
    });
  });

  group('contact maneuvers', () {
    test('a melee unit\'s bursts strike in contact; ids and gestures stay', () {
      for (final ship in PieceType.values) {
        final space = ManeuverCatalog.forShip(ship);
        final there = ManeuverCatalog.forShip(ship, balance: ground);
        expect([for (final m in there) m.id], [for (final m in space) m.id]);
        expect([for (final m in there) m.pattern],
            [for (final m in space) m.pattern]);
        final melee = ground.statsOf(ship).isMelee;
        for (final maneuver in there) {
          for (final cue in maneuver.fire) {
            expect(cue.contact, melee, reason: maneuver.id);
          }
        }
        for (final maneuver in space) {
          expect(maneuver.fire.any((cue) => cue.contact), isFalse);
        }
      }
    });

    test('a melee volley is a series of three strikes', () {
      final volley = ManeuverCatalog.byId('pawn.volley', balance: ground)!;
      expect(volley.fire, hasLength(3));
      expect(volley.strikesInContact, isTrue);
      expect(ManeuverCatalog.byId('bishop.volley', balance: ground)!
          .strikesInContact, isFalse);
    });

    Maneuver volleyOf(PieceType ship) =>
        ManeuverCatalog.forShip(ship, balance: ground)
            .firstWhere((m) => m.family == ManeuverFamily.volley);

    test('strikes without a shot\'s flight within range 1', () {
      var state = battle(PieceType.pawn, PieceType.bishop);
      // Face to face near the divider, the pawn's own strikes held back.
      state = BattleEngine.moveShip(state, true, 0.5, altitude: 0.8);
      state = BattleEngine.moveShip(state, false, 0.5, altitude: 0.8);
      state = state.copyWith(
          attacker: state.attacker.copyWith(nextAttackMs: 1 << 30, energy: 100),
          defender: state.defender.copyWith(nextAttackMs: 1 << 30));
      state = BattleEngine.startManeuver(state, true, volleyOf(PieceType.pawn));
      final after = run(state, 1200);

      expect(after.projectiles.where((p) => p.fromAttacker), isEmpty);
      expect(after.impacts.where((i) => i.melee && !i.onAttacker), isNotEmpty);
      expect(after.defender.currentHp, lessThan(after.defender.stats.maxHp));
    });

    test('miss beyond range 1', () {
      var state = battle(PieceType.pawn, PieceType.bishop);
      // Both at their own edges: range 2.
      state = BattleEngine.moveShip(state, true, 0.5, altitude: 0);
      state = BattleEngine.moveShip(state, false, 0.5, altitude: 0);
      state = state.copyWith(
          attacker: state.attacker.copyWith(nextAttackMs: 1 << 30, energy: 100),
          defender: state.defender.copyWith(nextAttackMs: 1 << 30));
      state = BattleEngine.startManeuver(state, true, volleyOf(PieceType.pawn));
      final after = run(state, 1200);

      expect(after.projectiles, isEmpty);
      expect(after.defender.currentHp, after.defender.stats.maxHp);
    });
  });

  group('the board after mutual destruction', () {
    test('both pieces leave, no credits, the turn passes', () {
      const attacker = Piece(type: PieceType.knight, color: PlayerColor.white);
      const defender = Piece(type: PieceType.pawn, color: PlayerColor.black);
      final from = const Position(row: 2, col: 2);
      final to = const Position(row: 4, col: 3);
      var game = GameEngine.createGame(
        gameId: 'mutual',
        playerWhite: const Player(
            userId: 'w', displayName: 'W', color: PlayerColor.white),
        playerBlack: const Player(
            userId: 'b', displayName: 'B', color: PlayerColor.black),
      );
      game = GameEngine.applyFormation(game, PlayerColor.white,
          GameEngine.defaultFormation(PlayerColor.white));
      game = GameEngine.applyFormation(game, PlayerColor.black,
          GameEngine.defaultFormation(PlayerColor.black));
      game = game.copyWith(
          board: game.board.setPiece(from, attacker).setPiece(to, defender));
      final move = Move(
          from: from, to: to, piece: attacker, capturedPiece: defender);

      final inBattle = GameEngine.applyMove(game, move, triggerBattle: true);
      final (after, credits) = GameEngine.resolveBattle(inBattle, move, null);

      expect(credits, 0);
      expect(after.board.pieceAt(from), isNull);
      expect(after.board.pieceAt(to), isNull);
      expect(after.phase, GamePhase.playing);
      expect(after.currentTurn, PlayerColor.black);
      expect(after.moveCount, game.moveCount + 1);
    });
  });

  group('BattleOdds', () {
    test('space odds and draws are unchanged: no draw reaches the search', () {
      final table = BattleOdds.table(const UpgradeProfile(), const UpgradeProfile());
      for (final a in PieceType.values) {
        for (final d in PieceType.values) {
          expect(table.drawOf(a, d), 0);
          expect(table.winOf(a, d), table.of(a, d));
        }
      }
    });

    test('a ground melee mirror can end with both pieces gone', () {
      final table = BattleOdds.table(const UpgradeProfile(), const UpgradeProfile(),
          balance: ground);
      final draw = table.drawOf(PieceType.pawn, PieceType.pawn);
      expect(draw, greaterThan(0.1));
      expect(table.winOf(PieceType.pawn, PieceType.pawn) + draw / 2,
          closeTo(table.of(PieceType.pawn, PieceType.pawn), 1e-9));
      expect(table.takesOf(PieceType.pawn, PieceType.pawn),
          greaterThan(table.of(PieceType.pawn, PieceType.pawn)));
      // A bishop shoots: no draw worth searching against it.
      expect(table.drawOf(PieceType.bishop, PieceType.pawn), 0);
    });
  });
}
