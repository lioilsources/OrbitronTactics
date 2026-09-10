import 'package:flutter_test/flutter_test.dart';
import 'package:orbitron_tactics/core/ai/move_generator.dart';
import 'package:orbitron_tactics/core/game_logic/models/game_phase.dart';
import 'package:orbitron_tactics/core/game_logic/models/game_state.dart';
import 'package:orbitron_tactics/core/game_logic/models/move.dart';
import 'package:orbitron_tactics/core/game_logic/models/piece.dart';
import 'package:orbitron_tactics/core/game_logic/validators/move_validator.dart';

import '../game_logic/test_helpers.dart';

void main() {
  /// A crowded middle game: captures, a snipe, a Last Warrior.
  GameState middleGame({PlayerColor currentTurn = PlayerColor.white}) {
    return gameStateWith(
      currentTurn: currentTurn,
      whiteHasKing: false,
      board: boardWith({
        // White — the queen survives its king as a Last Warrior.
        pos(2, 3): whiteQueen.copyWith(isLastWarrior: true),
        pos(3, 0): whiteRook,
        pos(2, 5): whiteKnight,
        pos(1, 2): whiteBishop,
        pos(1, 0): whitePawn,
        pos(3, 4): whitePawn,
        // Black
        pos(7, 4): blackKing,
        pos(5, 3): blackQueen,
        pos(4, 4): blackRook,
        pos(4, 2): blackBishop,
        pos(5, 6): blackKnight,
        pos(6, 1): blackPawn,
        pos(4, 5): blackPawn,
      }),
    );
  }

  Set<Move> validatorMoves(GameState state) => {
        for (final from in state.board.findPieces(color: state.currentTurn))
          for (final to in MoveValidator.getLegalMoves(state, from))
            MoveValidator.createMove(state, from, to)!,
      };

  group('MoveGenerator', () {
    test('matches MoveValidator for the side to move', () {
      for (final state in [
        defaultGameState(),
        middleGame(),
        middleGame(currentTurn: PlayerColor.black),
      ]) {
        final generated = MoveGenerator.generate(state, state.currentTurn);

        expect(generated.toSet(), validatorMoves(state));
        expect(generated.length, generated.toSet().length,
            reason: 'no duplicate moves');
      }
    });

    test('generates for the side not on turn', () {
      final state = middleGame(currentTurn: PlayerColor.white);

      final generated = MoveGenerator.generate(state, PlayerColor.black);

      expect(generated, isNotEmpty);
      expect(generated.toSet(),
          validatorMoves(state.copyWith(currentTurn: PlayerColor.black)));
    });

    test('lists captures before quiet moves', () {
      final generated = MoveGenerator.generate(middleGame(), PlayerColor.white);
      final firstQuiet = generated.indexWhere((m) => m.capturedPiece == null);

      expect(generated.where((m) => m.capturedPiece != null), isNotEmpty);
      expect(
        generated.skip(firstQuiet).where((m) => m.capturedPiece != null),
        isEmpty,
      );
    });

    test('fills in the captured piece and the snipe flag', () {
      final generated = MoveGenerator.generate(middleGame(), PlayerColor.white);

      // Bishop snipes three squares straight ahead onto the black bishop.
      expect(
        generated,
        contains(Move(
          from: pos(1, 2),
          to: pos(4, 2),
          piece: whiteBishop,
          capturedPiece: blackBishop,
          isSnipe: true,
        )),
      );
      // Pawn captures diagonally forward.
      expect(
        generated,
        contains(Move(
          from: pos(3, 4),
          to: pos(4, 5),
          piece: whitePawn,
          capturedPiece: blackPawn,
        )),
      );
      expect(generated.where((m) => m.isSnipe).length, 1);
    });

    test('moves a Last Warrior only one square', () {
      final generated = MoveGenerator.generate(middleGame(), PlayerColor.white);
      final queenMoves = generated.where((m) => m.from == pos(2, 3));

      expect(queenMoves, isNotEmpty);
      for (final move in queenMoves) {
        expect((move.to.row - 2).abs(), lessThanOrEqualTo(1));
        expect((move.to.col - 3).abs(), lessThanOrEqualTo(1));
      }
    });

    test('is empty once the game is finished', () {
      final state = middleGame().copyWith(
        phase: GamePhase.finished,
        winner: PlayerColor.black,
      );

      expect(MoveGenerator.generate(state, PlayerColor.white), isEmpty);
      expect(MoveGenerator.generate(state, PlayerColor.black), isEmpty);
    });
  });
}
