import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:orbitron_tactics/core/ai/ai_difficulty.dart';
import 'package:orbitron_tactics/core/ai/board_ai.dart';
import 'package:orbitron_tactics/core/game_logic/engine/game_engine.dart';
import 'package:orbitron_tactics/core/game_logic/models/game_phase.dart';
import 'package:orbitron_tactics/core/game_logic/models/game_state.dart';
import 'package:orbitron_tactics/core/game_logic/models/move.dart';
import 'package:orbitron_tactics/core/game_logic/models/piece.dart';
import 'package:orbitron_tactics/core/game_logic/models/power_field.dart';
import 'package:orbitron_tactics/core/game_logic/models/upgrade_profile.dart';
import 'package:orbitron_tactics/core/game_logic/models/victory_condition.dart';
import 'package:orbitron_tactics/core/game_logic/validators/move_validator.dart';

import '../game_logic/test_helpers.dart';
import 'self_play.dart';

void main() {
  const white = PlayerColor.white;
  const noUpgrades = UpgradeProfile();

  GreedyAi greedy(AiProfile profile, int seed) => GreedyAi(
        profile: profile,
        random: Random(seed),
        ownUpgrades: noUpgrades,
        oppUpgrades: noUpgrades,
      );

  /// The position after [move], with its battle (if any) won by the mover.
  GameState afterWinning(GameState state, Move move) {
    if (move.capturedPiece == null) return GameEngine.applyMove(state, move);
    final battle = GameEngine.applyMove(state, move, triggerBattle: true);
    return GameEngine.resolveBattle(battle, move, move.piece.color).$1;
  }

  /// Easy and Medium, over several seeds, play a move winning [state].
  void expectGreedyWins(GameState state, Matcher victory) {
    for (final profile in [AiProfile.easy, AiProfile.medium]) {
      for (var seed = 0; seed < 5; seed++) {
        final move = greedy(profile, seed).chooseMove(state, white)!;
        final after = afterWinning(state, move);
        final reason = '${profile.displayName}, seed $seed, $move';
        expect(after.winner, white, reason: reason);
        expect(after.victoryCondition, victory, reason: reason);
      }
    }
  }

  group('RandomAi', () {
    test('plays only legal moves', () {
      final state = defaultGameState();
      final ai = RandomAi(Random(7));

      for (var i = 0; i < 50; i++) {
        final move = ai.chooseMove(state, PlayerColor.white)!;
        expect(MoveValidator.createMove(state, move.from, move.to), move);
      }
    });

    test('returns null once the game is over', () {
      final state = defaultGameState().copyWith(
        phase: GamePhase.finished,
        winner: PlayerColor.black,
      );

      expect(RandomAi(Random(7)).chooseMove(state, PlayerColor.white), isNull);
    });
  });

  group('GreedyAi', () {
    test('takes a win by infiltration', () {
      expectGreedyWins(
        gameStateWith(
          board: boardWith({
            pos(0, 0): whiteKing,
            pos(0, 7): whiteQueen,
            pos(2, 2): whiteKnight,
            pos(6, 3): whitePawn,
            pos(7, 0): blackKing,
            pos(7, 7): blackQueen,
            pos(5, 6): blackPawn,
          }),
        ),
        isA<Infiltration>(),
      );
    });

    test('takes a win by power field domination', () {
      final fields = [pos(3, 3), pos(3, 4), pos(4, 3), pos(4, 4), pos(3, 5)]
          .map((p) => PowerField(position: p))
          .toList();

      expectGreedyWins(
        gameStateWith(
          board: boardWith(
            {
              pos(0, 0): whiteKing,
              pos(0, 7): whiteQueen,
              pos(0, 5): whiteRook,
              pos(3, 3): whitePawn,
              pos(3, 4): whitePawn,
              pos(4, 3): whitePawn,
              pos(4, 4): whitePawn,
              pos(7, 0): blackKing,
              pos(7, 7): blackQueen,
            },
            powerFields: fields,
          ),
        ),
        isA<PowerFieldDomination>(),
      );
    });

    test('takes a win by royal elimination', () {
      expectGreedyWins(
        gameStateWith(
          blackHasQueen: false,
          board: boardWith({
            pos(0, 7): whiteKing,
            pos(0, 6): whiteQueen,
            pos(3, 0): whiteRook,
            pos(7, 0): blackKing.copyWith(isLastWarrior: true),
            pos(6, 5): blackPawn,
          }),
        ),
        isA<RoyalElimination>(),
      );
    });

    test('Medium does not throw a pawn at a king when it can move quietly',
        () {
      final fields = [pos(3, 3), pos(3, 4), pos(4, 3), pos(4, 4), pos(3, 5)]
          .map((p) => PowerField(position: p))
          .toList();
      final opening = defaultGameState();
      final cases = [
        (
          'mid-board',
          gameStateWith(
            board: boardWith(
              {
                pos(0, 0): whiteKing,
                pos(0, 7): whiteQueen,
                pos(1, 1): whiteRook,
                pos(1, 6): whiteKnight,
                pos(2, 5): whitePawn,
                pos(3, 3): whitePawn,
                pos(4, 4): blackKing,
                pos(6, 4): blackQueen,
                pos(7, 0): blackRook,
                pos(6, 6): blackKnight,
                pos(5, 2): blackPawn,
                pos(5, 6): blackPawn,
              },
              powerFields: fields,
            ),
          ),
          pos(3, 3),
          pos(4, 4),
        ),
        (
          'king guarded by its queen',
          gameStateWith(
            board: boardWith(
              {
                pos(0, 4): whiteKing,
                pos(1, 3): whiteQueen,
                pos(0, 0): whiteRook,
                pos(5, 3): whitePawn,
                pos(6, 4): blackKing,
                pos(7, 3): blackQueen,
                pos(7, 7): blackRook,
                pos(6, 6): blackPawn,
              },
              powerFields: fields,
            ),
          ),
          pos(5, 3),
          pos(6, 4),
        ),
        (
          'king raid in the opening',
          opening.copyWith(
            board: opening.board
                .movePiece(pos(7, 4), pos(2, 4))
                .movePiece(pos(6, 4), pos(4, 4)),
          ),
          pos(1, 3),
          pos(2, 4),
        ),
      ];

      for (final (name, state, pawn, king) in cases) {
        expect(MoveValidator.createMove(state, pawn, king)?.capturedPiece,
            blackKing,
            reason: '$name must offer the sacrifice');
        for (var seed = 0; seed < 20; seed++) {
          final move = greedy(AiProfile.medium, seed).chooseMove(state, white)!;
          expect(move.capturedPiece, isNull, reason: '$name, seed $seed: $move');
        }
      }
    });
  });

  group('self-play', () {
    test('200 random games stay legal and end', () {
      final random = Random(1);

      for (var game = 0; game < 200; game++) {
        final result = playGame(RandomAi(random), RandomAi(random), random);
        expect(result.plies, lessThanOrEqualTo(300));
      }
    });

    test('50 Medium games stay legal and end', () {
      final random = Random(2);

      for (var game = 0; game < 50; game++) {
        final result = playGame(
          greedy(AiProfile.medium, game),
          greedy(AiProfile.medium, 1000 + game),
          random,
        );
        expect(result.plies, lessThanOrEqualTo(300));
      }
    });
  });
}
