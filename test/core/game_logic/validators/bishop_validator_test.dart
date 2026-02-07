import 'package:flutter_test/flutter_test.dart';
import 'package:orbitron_tactics/core/game_logic/models/piece.dart';
import 'package:orbitron_tactics/core/game_logic/validators/bishop_validator.dart';
import '../test_helpers.dart';

void main() {
  const validator = BishopValidator();

  group('BishopValidator - Diagonal Movement', () {
    test('can move 1-3 squares diagonally', () {
      final board = boardWith({pos(4, 4): whiteBishop});
      final moves = validator.getLegalMoves(board, pos(4, 4), PlayerColor.white);

      // Should be able to reach up to 3 squares in each diagonal
      expect(moves, contains(pos(5, 5))); // 1 diagonal
      expect(moves, contains(pos(6, 6))); // 2 diagonal
      expect(moves, contains(pos(7, 7))); // 3 diagonal
      expect(moves, contains(pos(3, 3))); // 1 backward-left
      expect(moves, contains(pos(2, 2))); // 2 backward-left
      expect(moves, contains(pos(1, 1))); // 3 backward-left
    });

    test('CANNOT move more than 3 squares diagonally', () {
      final board = boardWith({pos(3, 3): whiteBishop});
      final moves = validator.getLegalMoves(board, pos(3, 3), PlayerColor.white);

      // 4 squares diagonal should NOT be reachable
      expect(moves, contains(pos(6, 6))); // 3 squares - OK
      expect(moves, isNot(contains(pos(7, 7)))); // 4 squares - too far
    });

    test('diagonal blocked by friendly piece', () {
      final board = boardWith({
        pos(4, 4): whiteBishop,
        pos(5, 5): whitePawn,
      });
      final moves = validator.getLegalMoves(board, pos(4, 4), PlayerColor.white);

      expect(moves, isNot(contains(pos(5, 5))));
      expect(moves, isNot(contains(pos(6, 6))));
    });

    test('diagonal can capture enemy but stops after', () {
      final board = boardWith({
        pos(4, 4): whiteBishop,
        pos(5, 5): blackPawn,
      });
      final moves = validator.getLegalMoves(board, pos(4, 4), PlayerColor.white);

      expect(moves, contains(pos(5, 5))); // capture
      expect(moves, isNot(contains(pos(6, 6)))); // blocked after capture
    });
  });

  group('BishopValidator - Snipe', () {
    test('can snipe exactly 3 squares forward (white)', () {
      final board = boardWith({pos(3, 4): whiteBishop});
      final moves = validator.getLegalMoves(board, pos(3, 4), PlayerColor.white);

      // Snipe: exactly +3 forward for white = row+3
      expect(moves, contains(pos(6, 4)));
    });

    test('can snipe exactly 3 squares forward (black)', () {
      final board = boardWith({pos(5, 4): blackBishop});
      final moves = validator.getLegalMoves(board, pos(5, 4), PlayerColor.black);

      // Snipe: exactly +3 forward for black = row-3
      expect(moves, contains(pos(2, 4)));
    });

    test('snipe jumps over pieces', () {
      final board = boardWith({
        pos(3, 4): whiteBishop,
        pos(4, 4): blackPawn, // piece in the way
        pos(5, 4): blackRook, // another piece in the way
      });
      final moves = validator.getLegalMoves(board, pos(3, 4), PlayerColor.white);

      // Should still be able to snipe to row 6
      expect(moves, contains(pos(6, 4)));
    });

    test('snipe can capture enemy at target', () {
      final board = boardWith({
        pos(3, 4): whiteBishop,
        pos(6, 4): blackPawn, // enemy at snipe target
      });
      final moves = validator.getLegalMoves(board, pos(3, 4), PlayerColor.white);
      expect(moves, contains(pos(6, 4)));
    });

    test('CANNOT snipe onto friendly piece', () {
      final board = boardWith({
        pos(3, 4): whiteBishop,
        pos(6, 4): whitePawn, // friendly at snipe target
      });
      final moves = validator.getLegalMoves(board, pos(3, 4), PlayerColor.white);
      expect(moves, isNot(contains(pos(6, 4))));
    });

    test('snipe does not work if target is off board', () {
      final board = boardWith({pos(6, 4): whiteBishop});
      final moves = validator.getLegalMoves(board, pos(6, 4), PlayerColor.white);

      // Row 6 + 3 = row 9, off the board
      // No snipe position should be added for off-board
      expect(moves.where((m) => m.col == 4 && m.row > 7), isEmpty);
    });
  });
}
