import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:orbitron_tactics/core/ai/ai_difficulty.dart';
import 'package:orbitron_tactics/core/ai/battle_odds.dart';
import 'package:orbitron_tactics/core/ai/board_ai.dart';
import 'package:orbitron_tactics/core/ai/move_generator.dart';
import 'package:orbitron_tactics/core/game_logic/engine/game_engine.dart';
import 'package:orbitron_tactics/core/game_logic/models/game_phase.dart';
import 'package:orbitron_tactics/core/game_logic/models/game_state.dart';
import 'package:orbitron_tactics/core/game_logic/models/move.dart';
import 'package:orbitron_tactics/core/game_logic/models/piece.dart';
import 'package:orbitron_tactics/core/game_logic/models/power_field.dart';
import 'package:orbitron_tactics/core/game_logic/models/upgrade_profile.dart';
import 'package:orbitron_tactics/core/game_logic/validators/move_validator.dart';

import '../game_logic/test_helpers.dart';

void main() {
  const white = PlayerColor.white;
  const black = PlayerColor.black;
  const noUpgrades = UpgradeProfile();
  // Fixed depth without a clock, so results don't depend on machine speed.
  final hardProfile = AiProfile.hard.copyWith(timeBudgetMs: 0);

  SearchAi hard(int seed, {AiProfile? profile}) => SearchAi(
        profile: profile ?? hardProfile,
        random: Random(seed),
        ownUpgrades: noUpgrades,
        oppUpgrades: noUpgrades,
      );

  GreedyAi medium(int seed) => GreedyAi(
        profile: AiProfile.medium,
        random: Random(seed),
        ownUpgrades: noUpgrades,
        oppUpgrades: noUpgrades,
      );

  List<PowerField> fields(List<(int, int)> squares) => [
        for (final (row, col) in squares) PowerField(position: pos(row, col)),
      ];

  /// The position after a quiet [move], or both positions after its battle.
  List<GameState> outcomes(GameState state, Move move) {
    if (move.capturedPiece == null) return [GameEngine.applyMove(state, move)];
    final battle = GameEngine.applyMove(state, move, triggerBattle: true);
    return [
      GameEngine.resolveBattle(battle, move, move.piece.color).$1,
      GameEngine.resolveBattle(battle, move, move.piece.color.opposite).$1,
    ];
  }

  bool winsAtOnce(GameState state, PlayerColor color) =>
      MoveGenerator.generate(state, color).any((move) =>
          move.capturedPiece == null &&
          GameEngine.applyMove(state, move).winner == color);

  /// Whether [move] wins by force: whatever the opponent replies, and
  /// however its battles end, [color] then wins with a quiet move.
  bool forcesWin(GameState state, Move move, PlayerColor color) {
    return outcomes(state, move).every((after) {
      if (after.isFinished) return after.winner == color;
      return MoveGenerator.generate(after, color.opposite).every((reply) =>
          outcomes(after, reply).every((position) =>
              position.winner == color ||
              (!position.isFinished && winsAtOnce(position, color))));
    });
  }

  group('SearchAi', () {
    test('finds a win in two that Greedy misses', () {
      final state = gameStateWith(
        board: boardWith(
          {
            pos(0, 0): whiteKing,
            pos(0, 2): whiteQueen,
            // One step from black's back rank, but the pawn's own knight
            // and bishop block both of its diagonals.
            pos(6, 3): whitePawn,
            pos(7, 2): whiteKnight,
            pos(7, 4): whiteBishop,
            pos(3, 7): blackKing,
            pos(2, 6): blackQueen,
          },
          powerFields: fields([(1, 3), (2, 2), (3, 5), (4, 6), (5, 0)]),
        ),
      );
      expect(winsAtOnce(state, white), isFalse);

      for (var seed = 0; seed < 3; seed++) {
        final move = hard(seed).chooseMove(state, white)!;
        expect(forcesWin(state, move, white), isTrue,
            reason: 'Hard, seed $seed: $move');
      }
      for (var seed = 0; seed < 3; seed++) {
        final move = medium(seed).chooseMove(state, white)!;
        expect(forcesWin(state, move, white), isFalse,
            reason: 'Medium, seed $seed: $move');
      }
    });

    test('does not give away a piece without compensation', () {
      final state = gameStateWith(
        board: boardWith(
          {
            pos(0, 4): whiteKing,
            pos(0, 3): whiteQueen,
            pos(0, 0): whiteRook,
            pos(3, 3): whiteKnight,
            pos(1, 0): whitePawn,
            pos(1, 1): whitePawn,
            pos(1, 6): whitePawn,
            pos(1, 7): whitePawn,
            pos(7, 4): blackKing,
            pos(7, 3): blackQueen,
            pos(4, 5): blackRook,
            pos(7, 2): blackBishop,
            pos(6, 0): blackPawn,
            pos(6, 1): blackPawn,
            pos(6, 6): blackPawn,
            pos(6, 7): blackPawn,
          },
          powerFields: fields([(3, 3), (3, 4), (4, 3), (4, 4), (3, 5)]),
        ),
      );
      // The bait: a knight attacking a rook wins only one battle in five.
      expect(MoveValidator.createMove(state, pos(3, 3), pos(4, 5))?.capturedPiece,
          blackRook);
      final blackOdds = BattleOdds.table(noUpgrades, noUpgrades);

      for (var seed = 0; seed < 3; seed++) {
        final move = hard(seed).chooseMove(state, white)!;
        final reason = 'seed $seed: $move';
        expect(move.capturedPiece, isNull, reason: reason);

        // Nor does it park the moved piece where black would likely win it.
        final after = GameEngine.applyMove(state, move);
        for (final attack in MoveGenerator.generate(after, black)
            .where((reply) => reply.to == move.to)) {
          expect(blackOdds.of(attack.piece.type, move.piece.type),
              lessThan(0.5),
              reason: '$reason, attacked by ${attack.piece.type.name}');
        }
      }
    });

    test('stays within its time budget', () {
      final state = defaultGameState();
      final ai = hard(1, profile: AiProfile.hard.copyWith(timeBudgetMs: 50));

      final stopwatch = Stopwatch()..start();
      final move = ai.chooseMove(state, white)!;
      stopwatch.stop();

      expect(MoveValidator.createMove(state, move.from, move.to), move);
      // Generous slack: the first iteration always completes.
      expect(stopwatch.elapsedMilliseconds, lessThan(1000));
    });

    test('returns null once the game is over', () {
      final state = defaultGameState().copyWith(
        phase: GamePhase.finished,
        winner: black,
      );

      expect(hard(1).chooseMove(state, white), isNull);
    });
  });
}
