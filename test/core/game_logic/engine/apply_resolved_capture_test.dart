import 'package:flutter_test/flutter_test.dart';
import 'package:orbitron_tactics/core/game_logic/engine/game_engine.dart';
import 'package:orbitron_tactics/core/game_logic/models/game_phase.dart';
import 'package:orbitron_tactics/core/game_logic/models/move.dart';
import 'package:orbitron_tactics/core/game_logic/models/piece.dart';
import 'package:orbitron_tactics/core/game_logic/models/victory_condition.dart';
import '../test_helpers.dart';

/// Tests for the Archon-style battle resolution used in the local-network
/// co-op mode. A capturing move is resolved by [GameEngine.applyResolvedCapture]
/// according to who won the real-time arena.
void main() {
  group('GameEngine.applyResolvedCapture - attacker wins', () {
    test('resolves exactly like a normal capture', () {
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

      final result =
          GameEngine.applyResolvedCapture(state, move, attackerWon: true);
      final normal = GameEngine.applyMove(state, move);

      // Attacker took the square, defender is gone, turn passed.
      expect(result.board.pieceAt(pos(4, 5)), whitePawn);
      expect(result.board.pieceAt(pos(3, 4)), isNull);
      expect(result.currentTurn, PlayerColor.black);
      expect(result.board.grid, normal.board.grid);
    });
  });

  group('GameEngine.applyResolvedCapture - defender wins', () {
    test('attacker is destroyed and defender survives', () {
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

      final result =
          GameEngine.applyResolvedCapture(state, move, attackerWon: false);

      // Attacker removed from origin, never reaches the target square.
      expect(result.board.pieceAt(pos(3, 4)), isNull);
      // Defender stays put.
      expect(result.board.pieceAt(pos(4, 5)), blackPawn);
      // Turn still passes to the defender.
      expect(result.currentTurn, PlayerColor.black);
      // Move is recorded.
      expect(result.moveCount, 1);
      expect(result.moveHistory.single, move);
      // No premature victory.
      expect(result.phase, GamePhase.playing);
    });

    test('snipe loser is removed from its origin square', () {
      final state = gameStateWith(
        board: boardWith({
          pos(3, 4): whiteBishop,
          pos(6, 4): blackPawn,
          pos(0, 4): whiteKing,
          pos(0, 3): whiteQueen,
          pos(7, 4): blackKing,
          pos(7, 3): blackQueen,
        }),
      );

      final move = Move(
        from: pos(3, 4),
        to: pos(6, 4),
        piece: whiteBishop,
        capturedPiece: blackPawn,
        isSnipe: true,
      );

      final result =
          GameEngine.applyResolvedCapture(state, move, attackerWon: false);

      expect(result.board.pieceAt(pos(3, 4)), isNull);
      expect(result.board.pieceAt(pos(6, 4)), blackPawn);
    });

    test('losing the last royal hands victory to the defender', () {
      // White's only royal is the attacking queen (no white king on board).
      final state = gameStateWith(
        board: boardWith({
          pos(3, 4): whiteQueen,
          pos(4, 4): blackPawn,
          pos(7, 4): blackKing,
          pos(7, 3): blackQueen,
        }),
        whiteHasKing: false,
      );

      final move = Move(
        from: pos(3, 4),
        to: pos(4, 4),
        piece: whiteQueen,
        capturedPiece: blackPawn,
      );

      final result =
          GameEngine.applyResolvedCapture(state, move, attackerWon: false);

      expect(result.phase, GamePhase.finished);
      expect(result.winner, PlayerColor.black);
      expect(result.victoryCondition, isA<RoyalElimination>());
    });

    test('losing a royal transforms the surviving royal into a Last Warrior',
        () {
      // Attacking white king loses; white queen survives and becomes a
      // Last Warrior.
      final state = gameStateWith(
        board: boardWith({
          pos(3, 4): whiteKing,
          pos(4, 4): blackPawn,
          pos(0, 3): whiteQueen,
          pos(7, 4): blackKing,
          pos(7, 3): blackQueen,
        }),
      );

      final move = Move(
        from: pos(3, 4),
        to: pos(4, 4),
        piece: whiteKing,
        capturedPiece: blackPawn,
      );

      final result =
          GameEngine.applyResolvedCapture(state, move, attackerWon: false);

      expect(result.phase, GamePhase.playing);
      expect(result.playerWhite.hasKing, isFalse);
      final queenPositions =
          result.board.findPieces(type: PieceType.queen, color: PlayerColor.white);
      expect(queenPositions, isNotEmpty);
      expect(result.board.pieceAt(queenPositions.first)!.isLastWarrior, isTrue);
    });
  });
}
