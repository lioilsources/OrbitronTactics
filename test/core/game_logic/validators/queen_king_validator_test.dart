import 'package:flutter_test/flutter_test.dart';
import 'package:orbitron_tactics/core/game_logic/models/piece.dart';
import 'package:orbitron_tactics/core/game_logic/validators/queen_validator.dart';
import 'package:orbitron_tactics/core/game_logic/validators/king_validator.dart';
import '../test_helpers.dart';

void main() {
  group('QueenValidator', () {
    const validator = QueenValidator();

    test('can move up to 4 squares diagonally', () {
      final board = boardWith({pos(3, 3): whiteQueen});
      final moves = validator.getLegalMoves(board, pos(3, 3), PlayerColor.white);

      // 1-4 squares diagonal (forward-right)
      expect(moves, contains(pos(4, 4)));
      expect(moves, contains(pos(5, 5)));
      expect(moves, contains(pos(6, 6)));
      expect(moves, contains(pos(7, 7))); // 4 squares
    });

    test('CANNOT move more than 4 squares diagonally', () {
      // From (0,0), can go to (4,4) but NOT (5,5) — wait, that's 5 squares
      // Actually from (0,0): (1,1)=1, (2,2)=2, (3,3)=3, (4,4)=4
      final board = boardWith({pos(0, 0): whiteQueen});
      final moves = validator.getLegalMoves(board, pos(0, 0), PlayerColor.white);

      expect(moves, contains(pos(4, 4))); // 4 squares
      expect(moves, isNot(contains(pos(5, 5)))); // 5 squares
    });

    test('can move up to 2 squares in straight lines', () {
      final board = boardWith({pos(4, 4): whiteQueen});
      final moves = validator.getLegalMoves(board, pos(4, 4), PlayerColor.white);

      // Straight: 1-2 squares
      expect(moves, contains(pos(4, 5))); // right 1
      expect(moves, contains(pos(4, 6))); // right 2
      expect(moves, contains(pos(5, 4))); // down 1
      expect(moves, contains(pos(6, 4))); // down 2
    });

    test('CANNOT move more than 2 squares straight', () {
      final board = boardWith({pos(4, 4): whiteQueen});
      final moves = validator.getLegalMoves(board, pos(4, 4), PlayerColor.white);

      expect(moves, isNot(contains(pos(4, 7)))); // right 3
      expect(moves, isNot(contains(pos(7, 4)))); // down 3
    });

    test('diagonal blocked by piece', () {
      final board = boardWith({
        pos(3, 3): whiteQueen,
        pos(5, 5): whitePawn,
      });
      final moves = validator.getLegalMoves(board, pos(3, 3), PlayerColor.white);

      expect(moves, contains(pos(4, 4)));
      expect(moves, isNot(contains(pos(5, 5))));
      expect(moves, isNot(contains(pos(6, 6))));
    });
  });

  group('KingValidator', () {
    const validator = KingValidator();

    test('can move up to 4 squares in straight lines', () {
      final board = boardWith({pos(3, 3): whiteKing});
      final moves = validator.getLegalMoves(board, pos(3, 3), PlayerColor.white);

      // Straight: 1-4 squares
      expect(moves, contains(pos(3, 4))); // right 1
      expect(moves, contains(pos(3, 5))); // right 2
      expect(moves, contains(pos(3, 6))); // right 3
      expect(moves, contains(pos(3, 7))); // right 4
      expect(moves, contains(pos(4, 3))); // down 1
      expect(moves, contains(pos(7, 3))); // down 4
    });

    test('can move up to 2 squares diagonally', () {
      final board = boardWith({pos(4, 4): whiteKing});
      final moves = validator.getLegalMoves(board, pos(4, 4), PlayerColor.white);

      // Diagonal: 1-2 squares
      expect(moves, contains(pos(5, 5))); // 1 diagonal
      expect(moves, contains(pos(6, 6))); // 2 diagonal
    });

    test('CANNOT move more than 2 squares diagonally', () {
      final board = boardWith({pos(4, 4): whiteKing});
      final moves = validator.getLegalMoves(board, pos(4, 4), PlayerColor.white);

      expect(moves, isNot(contains(pos(7, 7)))); // 3 diagonal
    });

    test('CANNOT move more than 4 squares straight', () {
      final board = boardWith({pos(0, 0): whiteKing});
      final moves = validator.getLegalMoves(board, pos(0, 0), PlayerColor.white);

      expect(moves, contains(pos(4, 0))); // down 4
      expect(moves, isNot(contains(pos(5, 0)))); // down 5
    });

    test('King is stronger in straight lines, Queen in diagonals', () {
      // This test documents the unique design: King and Queen have swapped emphasis
      final boardK = boardWith({pos(3, 3): whiteKing});
      final kingMoves = validator.getLegalMoves(boardK, pos(3, 3), PlayerColor.white);

      const queenValidator = QueenValidator();
      final boardQ = boardWith({pos(3, 3): whiteQueen});
      final queenMoves = queenValidator.getLegalMoves(boardQ, pos(3, 3), PlayerColor.white);

      // King: 4 straight, so can reach (3,7) — 4 right
      expect(kingMoves, contains(pos(3, 7)));
      // Queen: 2 straight, so CANNOT reach (3,7)
      expect(queenMoves, isNot(contains(pos(3, 7))));

      // Queen: 4 diagonal, so can reach (7,7) — 4 diagonal
      expect(queenMoves, contains(pos(7, 7)));
      // King: 2 diagonal, so CANNOT reach (7,7)
      expect(kingMoves, isNot(contains(pos(7, 7))));
    });
  });
}
