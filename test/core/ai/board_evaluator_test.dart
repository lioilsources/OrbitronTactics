import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:orbitron_tactics/core/ai/board_ai.dart';
import 'package:orbitron_tactics/core/ai/board_evaluator.dart';
import 'package:orbitron_tactics/core/game_logic/engine/game_engine.dart';
import 'package:orbitron_tactics/core/game_logic/models/board_state.dart';
import 'package:orbitron_tactics/core/game_logic/models/game_phase.dart';
import 'package:orbitron_tactics/core/game_logic/models/game_state.dart';
import 'package:orbitron_tactics/core/game_logic/models/piece.dart';
import 'package:orbitron_tactics/core/game_logic/models/position.dart';
import 'package:orbitron_tactics/core/game_logic/models/power_field.dart';
import 'package:orbitron_tactics/core/game_logic/models/upgrade_profile.dart';

import '../game_logic/test_helpers.dart';

void main() {
  const white = PlayerColor.white;
  const black = PlayerColor.black;

  double eval(GameState state, PlayerColor pov) =>
      BoardEvaluator.evaluate(state, pov);

  /// Mirrors [state] through the board center and swaps the colors, so each
  /// side takes over the other's position.
  GameState mirror(GameState state) {
    Piece? swap(Piece? piece) => piece?.copyWith(color: piece.color.opposite);
    return state.copyWith(
      board: BoardState(
        grid: [
          for (var row = 0; row < 8; row++)
            [
              for (var col = 0; col < 8; col++)
                swap(state.board.grid[7 - row][7 - col]),
            ],
        ],
        powerFields: [
          for (final field in state.board.powerFields)
            PowerField(position: field.position.mirrored),
        ],
      ),
      currentTurn: state.currentTurn.opposite,
      playerWhite: state.playerBlack.copyWith(color: white),
      playerBlack: state.playerWhite.copyWith(color: black),
    );
  }

  /// The position after [plies] random moves, battles decided by coin flip.
  GameState randomPosition(int seed, int plies) {
    final random = Random(seed);
    final ai = RandomAi(random);
    var state = defaultGameState();
    for (var i = 0; i < plies && !state.isFinished; i++) {
      final move = ai.chooseMove(state, state.currentTurn);
      if (move == null) break;
      final captured = move.capturedPiece;
      if (captured == null) {
        state = GameEngine.applyMove(state, move);
      } else {
        final battle = GameEngine.applyMove(state, move, triggerBattle: true);
        final winner = random.nextBool() ? move.piece.color : captured.color;
        state = GameEngine.resolveBattle(battle, move, winner).$1;
      }
    }
    return state;
  }

  /// Royals parked in the corners, far from the pieces under test.
  Map<Position, Piece> corners() => {
        pos(0, 0): whiteKing,
        pos(0, 7): whiteQueen,
        pos(7, 0): blackKing,
        pos(7, 7): blackQueen,
      };

  group('BoardEvaluator', () {
    final positions = [
      defaultGameState(),
      for (var seed = 1; seed <= 12; seed++) randomPosition(seed, 8 + seed * 5),
    ].where((s) => !s.isFinished).toList();

    test('a mirrored position scores the same for the swapped side', () {
      expect(positions.length, greaterThan(6));
      expect(positions.where((s) => eval(s, white).abs() > 1), isNotEmpty,
          reason: 'some positions must be unbalanced');

      for (final state in positions) {
        final mirrored = mirror(state);
        expect(eval(state, white), closeTo(eval(mirrored, black), 1e-9));
        expect(eval(state, white), closeTo(-eval(mirrored, white), 1e-9));
      }
    });

    test('is zero-sum', () {
      for (final state in positions) {
        expect(eval(state, white), -eval(state, black));
      }
    });

    test('holding 4 of 5 power fields beats holding 2', () {
      final fields = [pos(3, 3), pos(3, 4), pos(4, 3), pos(4, 4), pos(3, 5)]
          .map((p) => PowerField(position: p))
          .toList();
      GameState withPawns(List<Position> pawns) => gameStateWith(
            board: boardWith(
              {...corners(), for (final p in pawns) p: whitePawn},
              powerFields: fields,
            ),
          );

      final four = withPawns([pos(3, 3), pos(3, 4), pos(4, 3), pos(4, 4)]);
      final two = withPawns([pos(3, 3), pos(3, 4), pos(4, 0), pos(4, 7)]);

      expect(eval(four, white), greaterThan(eval(two, white)));
    });

    test('a pawn on row 6 is worth more than a pawn on row 1', () {
      GameState withPawnAt(Position p) =>
          gameStateWith(board: boardWith({...corners(), p: whitePawn}));

      expect(
        eval(withPawnAt(pos(6, 3)), white),
        greaterThan(eval(withPawnAt(pos(1, 3)), white)),
      );
    });

    test('losing the king is worse than losing a rook', () {
      final start = defaultGameState();
      final noKing = start.copyWith(
        board: start.board.setPiece(pos(0, 4), null),
        playerWhite: start.playerWhite.copyWith(hasKing: false),
      );
      final noRook = start.copyWith(board: start.board.setPiece(pos(0, 0), null));

      expect(eval(noKing, white), lessThan(eval(noRook, white)));
    });

    test('a finished game scores a win or a loss', () {
      final won = defaultGameState().copyWith(
        phase: GamePhase.finished,
        winner: white,
      );

      expect(eval(won, white), BoardEvaluator.win);
      expect(eval(won, black), -BoardEvaluator.win);
    });

    test('upgrades raise and a Last Warrior lowers piece value', () {
      const none = UpgradeProfile();
      const rookUpgraded = UpgradeProfile(levels: {PieceType.rook: 2});

      expect(BoardEvaluator.pieceValue(whiteRook, rookUpgraded),
          greaterThan(BoardEvaluator.pieceValue(whiteRook, none)));
      expect(
          BoardEvaluator.pieceValue(
              whiteQueen.copyWith(isLastWarrior: true), none),
          lessThan(BoardEvaluator.pieceValue(whiteQueen, none)));
    });
  });
}
