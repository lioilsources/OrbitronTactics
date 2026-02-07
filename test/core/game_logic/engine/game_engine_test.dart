import 'package:flutter_test/flutter_test.dart';
import 'package:orbitron_tactics/core/game_logic/engine/game_engine.dart';
import 'package:orbitron_tactics/core/game_logic/models/game_phase.dart';
import 'package:orbitron_tactics/core/game_logic/models/move.dart';
import 'package:orbitron_tactics/core/game_logic/models/piece.dart';
import 'package:orbitron_tactics/core/game_logic/models/player.dart';
import 'package:orbitron_tactics/core/game_logic/models/power_field.dart';
import 'package:orbitron_tactics/core/game_logic/models/victory_condition.dart';
import '../test_helpers.dart';

void main() {
  group('GameEngine', () {
    test('creates a game in formation phase', () {
      final state = GameEngine.createGame(
        gameId: 'test',
        playerWhite: const Player(
          userId: 'w',
          displayName: 'White',
          color: PlayerColor.white,
        ),
        playerBlack: const Player(
          userId: 'b',
          displayName: 'Black',
          color: PlayerColor.black,
        ),
      );

      expect(state.phase, GamePhase.formation);
      expect(state.currentTurn, PlayerColor.white);
    });

    test('transitions to playing after both formations applied', () {
      final state = defaultGameState();
      expect(state.phase, GamePhase.playing);
    });

    test('applyMove switches turn', () {
      final state = gameStateWith(
        board: boardWith({
          pos(1, 4): whitePawn,
          pos(0, 4): whiteKing,
          pos(0, 3): whiteQueen,
          pos(7, 4): blackKing,
          pos(7, 3): blackQueen,
        }),
      );

      final move = Move(
        from: pos(1, 4),
        to: pos(2, 3),
        piece: whitePawn,
      );

      final newState = GameEngine.applyMove(state, move);
      expect(newState.currentTurn, PlayerColor.black);
    });

    test('applyMove updates the board', () {
      final state = gameStateWith(
        board: boardWith({
          pos(1, 4): whitePawn,
          pos(0, 4): whiteKing,
          pos(0, 3): whiteQueen,
          pos(7, 4): blackKing,
          pos(7, 3): blackQueen,
        }),
      );

      final move = Move(
        from: pos(1, 4),
        to: pos(2, 3),
        piece: whitePawn,
      );

      final newState = GameEngine.applyMove(state, move);
      expect(newState.board.pieceAt(pos(1, 4)), isNull);
      expect(newState.board.pieceAt(pos(2, 3)), whitePawn);
    });

    test('applyMove handles capture', () {
      final state = gameStateWith(
        board: boardWith({
          pos(3, 4): whitePawn,
          pos(4, 5): blackPawn,
          pos(0, 4): whiteKing,
          pos(0, 3): whiteQueen,
          pos(7, 4): blackKing,
          pos(7, 3): blackQueen,
        }),
      );

      final move = Move(
        from: pos(3, 4),
        to: pos(4, 5),
        piece: whitePawn,
        capturedPiece: blackPawn,
      );

      final newState = GameEngine.applyMove(state, move);
      expect(newState.board.pieceAt(pos(4, 5)), whitePawn);
      expect(
          newState.board.findPieces(
              type: PieceType.pawn, color: PlayerColor.black),
          isEmpty);
    });

    test('applyMove records move in history', () {
      final state = gameStateWith(
        board: boardWith({
          pos(1, 4): whitePawn,
          pos(0, 4): whiteKing,
          pos(0, 3): whiteQueen,
          pos(7, 4): blackKing,
          pos(7, 3): blackQueen,
        }),
      );

      final move = Move(
        from: pos(1, 4),
        to: pos(2, 3),
        piece: whitePawn,
      );

      final newState = GameEngine.applyMove(state, move);
      expect(newState.moveHistory.length, 1);
      expect(newState.moveHistory.first, move);
      expect(newState.moveCount, 1);
    });

    test('tryMove returns null for illegal move', () {
      final state = gameStateWith(
        board: boardWith({
          pos(1, 4): whitePawn,
          pos(0, 4): whiteKing,
          pos(0, 3): whiteQueen,
          pos(7, 4): blackKing,
          pos(7, 3): blackQueen,
        }),
      );

      // Pawn can't move straight forward
      final result = GameEngine.tryMove(state, pos(1, 4), pos(2, 4));
      expect(result, isNull);
    });

    test('tryMove returns new state for legal move', () {
      final state = gameStateWith(
        board: boardWith({
          pos(1, 4): whitePawn,
          pos(0, 4): whiteKing,
          pos(0, 3): whiteQueen,
          pos(7, 4): blackKing,
          pos(7, 3): blackQueen,
        }),
      );

      final result = GameEngine.tryMove(state, pos(1, 4), pos(2, 3));
      expect(result, isNotNull);
      expect(result!.board.pieceAt(pos(2, 3)), whitePawn);
    });
  });

  group('GameEngine - Last Warrior', () {
    test('capturing king transforms queen into last warrior', () {
      final state = gameStateWith(
        board: boardWith({
          pos(3, 4): whitePawn,
          pos(4, 5): blackKing,
          pos(6, 2): blackQueen,
          pos(0, 4): whiteKing,
          pos(0, 3): whiteQueen,
        }),
      );

      final move = Move(
        from: pos(3, 4),
        to: pos(4, 5),
        piece: whitePawn,
        capturedPiece: blackKing,
      );

      final newState = GameEngine.applyMove(state, move);
      final queenPos = newState.board.findPieces(
          type: PieceType.queen, color: PlayerColor.black);
      expect(queenPos, isNotEmpty);
      expect(newState.board.pieceAt(queenPos.first)!.isLastWarrior, isTrue);
      expect(newState.playerBlack.hasKing, isFalse);
    });

    test('capturing queen transforms king into last warrior', () {
      final state = gameStateWith(
        board: boardWith({
          pos(3, 4): whitePawn,
          pos(4, 5): blackQueen,
          pos(6, 2): blackKing,
          pos(0, 4): whiteKing,
          pos(0, 3): whiteQueen,
        }),
      );

      final move = Move(
        from: pos(3, 4),
        to: pos(4, 5),
        piece: whitePawn,
        capturedPiece: blackQueen,
      );

      final newState = GameEngine.applyMove(state, move);
      final kingPos = newState.board.findPieces(
          type: PieceType.king, color: PlayerColor.black);
      expect(kingPos, isNotEmpty);
      expect(newState.board.pieceAt(kingPos.first)!.isLastWarrior, isTrue);
      expect(newState.playerBlack.hasQueen, isFalse);
    });

    test('capturing both royals ends the game', () {
      final state = gameStateWith(
        board: boardWith({
          pos(3, 4): whitePawn,
          pos(4, 5): blackKing,
          pos(0, 4): whiteKing,
          pos(0, 3): whiteQueen,
        }),
        blackHasQueen: false,
      );

      final move = Move(
        from: pos(3, 4),
        to: pos(4, 5),
        piece: whitePawn,
        capturedPiece: blackKing,
      );

      final newState = GameEngine.applyMove(state, move);
      expect(newState.phase, GamePhase.finished);
      expect(newState.winner, PlayerColor.white);
      expect(newState.victoryCondition, isA<RoyalElimination>());
    });
  });

  group('GameEngine - Victory Conditions', () {
    test('infiltration wins when pawn reaches back rank', () {
      final state = gameStateWith(
        board: boardWith({
          pos(6, 4): whitePawn,
          pos(0, 4): whiteKing,
          pos(0, 3): whiteQueen,
          pos(7, 0): blackKing,
          pos(7, 7): blackQueen,
        }),
      );

      final move = Move(
        from: pos(6, 4),
        to: pos(7, 3),
        piece: whitePawn,
      );

      final newState = GameEngine.applyMove(state, move);
      expect(newState.phase, GamePhase.finished);
      expect(newState.winner, PlayerColor.white);
      expect(newState.victoryCondition, isA<Infiltration>());
    });

    test('power field domination wins when all 5 controlled', () {
      final powerFields = [
        PowerField(position: pos(2, 2)),
        PowerField(position: pos(2, 5)),
        PowerField(position: pos(5, 2)),
        PowerField(position: pos(5, 5)),
        PowerField(position: pos(3, 4)),
      ];

      final state = gameStateWith(
        board: boardWith(
          {
            pos(2, 2): whitePawn,
            pos(2, 5): whiteRook,
            pos(5, 2): whiteBishop,
            pos(5, 5): whiteKnight,
            pos(1, 4): whiteRook, // will move to (3,4)
            pos(0, 4): whiteKing,
            pos(0, 3): whiteQueen,
            pos(7, 4): blackKing,
            pos(7, 3): blackQueen,
          },
          powerFields: powerFields,
        ),
      );

      final move = Move(
        from: pos(1, 4),
        to: pos(3, 4),
        piece: whiteRook,
      );

      final newState = GameEngine.applyMove(state, move);
      expect(newState.phase, GamePhase.finished);
      expect(newState.winner, PlayerColor.white);
      expect(newState.victoryCondition, isA<PowerFieldDomination>());
    });

    test('power field control lost when piece captured', () {
      final powerFields = [
        PowerField(position: pos(3, 3)),
        PowerField(position: pos(3, 4)),
        PowerField(position: pos(4, 3)),
        PowerField(position: pos(4, 4)),
        PowerField(position: pos(3, 5)),
      ];

      final board = boardWith(
        {
          pos(3, 3): whitePawn,
          pos(3, 4): whitePawn,
          pos(4, 3): whitePawn,
          pos(4, 4): whitePawn,
          pos(3, 5): whitePawn,
          pos(2, 2): blackPawn,
          pos(0, 4): whiteKing,
          pos(0, 3): whiteQueen,
          pos(7, 4): blackKing,
          pos(7, 3): blackQueen,
        },
        powerFields: powerFields,
      );

      expect(board.powerFieldCount(PlayerColor.white), 5);

      final state = gameStateWith(
        board: board,
        currentTurn: PlayerColor.black,
      );
      final move = Move(
        from: pos(2, 2),
        to: pos(3, 3),
        piece: blackPawn,
        capturedPiece: whitePawn,
      );

      final newState = GameEngine.applyMove(state, move);
      expect(newState.board.powerFieldCount(PlayerColor.white), 4);
      expect(newState.board.powerFieldCount(PlayerColor.black), 1);
    });
  });
}
