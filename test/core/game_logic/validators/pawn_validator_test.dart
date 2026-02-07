import 'package:flutter_test/flutter_test.dart';
import 'package:orbitron_tactics/core/game_logic/models/piece.dart';
import 'package:orbitron_tactics/core/game_logic/validators/pawn_validator.dart';
import '../test_helpers.dart';

void main() {
  const validator = PawnValidator();

  group('PawnValidator - White', () {
    group('movement (non-capturing)', () {
      test('can move left to empty square', () {
        final board = boardWith({pos(3, 4): whitePawn});
        final moves = validator.getLegalMoves(board, pos(3, 4), PlayerColor.white);
        expect(moves, contains(pos(3, 3)));
      });

      test('can move right to empty square', () {
        final board = boardWith({pos(3, 4): whitePawn});
        final moves = validator.getLegalMoves(board, pos(3, 4), PlayerColor.white);
        expect(moves, contains(pos(3, 5)));
      });

      test('can move backward (down for white) to empty square', () {
        final board = boardWith({pos(3, 4): whitePawn});
        final moves = validator.getLegalMoves(board, pos(3, 4), PlayerColor.white);
        expect(moves, contains(pos(2, 4))); // backward = -dir = row-1 for white
      });

      test('CANNOT move straight forward', () {
        final board = boardWith({pos(3, 4): whitePawn});
        final moves = validator.getLegalMoves(board, pos(3, 4), PlayerColor.white);
        expect(moves, isNot(contains(pos(4, 4)))); // forward = +dir = row+1 for white
      });

      test('CANNOT move sideways to capture enemy', () {
        final board = boardWith({
          pos(3, 4): whitePawn,
          pos(3, 5): blackPawn, // enemy to the right
        });
        final moves = validator.getLegalMoves(board, pos(3, 4), PlayerColor.white);
        expect(moves, isNot(contains(pos(3, 5))));
      });

      test('CANNOT move backward to capture enemy', () {
        final board = boardWith({
          pos(3, 4): whitePawn,
          pos(2, 4): blackPawn, // enemy behind
        });
        final moves = validator.getLegalMoves(board, pos(3, 4), PlayerColor.white);
        expect(moves, isNot(contains(pos(2, 4))));
      });

      test('CANNOT move sideways onto friendly piece', () {
        final board = boardWith({
          pos(3, 4): whitePawn,
          pos(3, 3): whiteRook, // friendly to the left
        });
        final moves = validator.getLegalMoves(board, pos(3, 4), PlayerColor.white);
        expect(moves, isNot(contains(pos(3, 3))));
      });
    });

    group('capture', () {
      test('can capture diagonally forward-left', () {
        final board = boardWith({
          pos(3, 4): whitePawn,
          pos(4, 3): blackPawn,
        });
        final moves = validator.getLegalMoves(board, pos(3, 4), PlayerColor.white);
        expect(moves, contains(pos(4, 3)));
      });

      test('can capture diagonally forward-right', () {
        final board = boardWith({
          pos(3, 4): whitePawn,
          pos(4, 5): blackPawn,
        });
        final moves = validator.getLegalMoves(board, pos(3, 4), PlayerColor.white);
        expect(moves, contains(pos(4, 5)));
      });

      test('can move diagonally forward to empty square', () {
        final board = boardWith({pos(3, 4): whitePawn});
        final moves = validator.getLegalMoves(board, pos(3, 4), PlayerColor.white);
        expect(moves, contains(pos(4, 3)));
        expect(moves, contains(pos(4, 5)));
      });

      test('CANNOT capture friendly piece diagonally', () {
        final board = boardWith({
          pos(3, 4): whitePawn,
          pos(4, 5): whiteRook, // friendly
        });
        final moves = validator.getLegalMoves(board, pos(3, 4), PlayerColor.white);
        expect(moves, isNot(contains(pos(4, 5))));
      });
    });

    group('board edges', () {
      test('left edge: cannot move further left', () {
        final board = boardWith({pos(3, 0): whitePawn});
        final moves = validator.getLegalMoves(board, pos(3, 0), PlayerColor.white);
        expect(moves, isNot(contains(pos(3, -1))));
        // Should still have right, backward, diagonal forward-right
        expect(moves, contains(pos(3, 1))); // right
        expect(moves, contains(pos(2, 0))); // backward
        expect(moves, contains(pos(4, 1))); // diagonal forward-right
      });

      test('right edge: cannot move further right', () {
        final board = boardWith({pos(3, 7): whitePawn});
        final moves = validator.getLegalMoves(board, pos(3, 7), PlayerColor.white);
        expect(moves, isNot(contains(pos(3, 8))));
      });
    });
  });

  group('PawnValidator - Black', () {
    test('forward is toward lower rows for black', () {
      final board = boardWith({pos(5, 4): blackPawn});
      final moves = validator.getLegalMoves(board, pos(5, 4), PlayerColor.black);

      // Forward (toward opponent) for black = row-1
      // CANNOT move straight forward
      expect(moves, isNot(contains(pos(4, 4))));

      // Can move backward (row+1) for black
      expect(moves, contains(pos(6, 4)));

      // Can move diagonally forward (toward row 4)
      expect(moves, contains(pos(4, 3)));
      expect(moves, contains(pos(4, 5)));
    });

    test('black pawn backward movement does not capture', () {
      final board = boardWith({
        pos(5, 4): blackPawn,
        pos(6, 4): whitePawn, // enemy behind (backward for black = row+1)
      });
      final moves = validator.getLegalMoves(board, pos(5, 4), PlayerColor.black);
      expect(moves, isNot(contains(pos(6, 4))));
    });
  });
}
