import 'package:flutter_test/flutter_test.dart';
import 'package:orbitron_tactics/core/game_logic/models/piece.dart';
import 'package:orbitron_tactics/core/game_logic/validators/rook_validator.dart';
import '../test_helpers.dart';

void main() {
  const validator = RookValidator();

  group('RookValidator', () {
    test('can move up to 4 squares in all straight directions', () {
      final board = boardWith({pos(4, 4): whiteRook});
      final moves = validator.getLegalMoves(board, pos(4, 4), PlayerColor.white);

      // Right: 4,5 4,6 4,7 (only 3 because col 7 is max at distance 3)
      // Actually from col 4: 5,6,7 = 3 squares. Max 4 allowed so all 3 are ok.
      // Wait, distance 4 means col 4+4=8 which is off board.
      expect(moves, contains(pos(4, 5)));
      expect(moves, contains(pos(4, 6)));
      expect(moves, contains(pos(4, 7)));

      // Left: 4,3 4,2 4,1 4,0
      expect(moves, contains(pos(4, 3)));
      expect(moves, contains(pos(4, 2)));
      expect(moves, contains(pos(4, 1)));
      expect(moves, contains(pos(4, 0)));

      // Up (toward row 0): 3,4 2,4 1,4 0,4
      expect(moves, contains(pos(3, 4)));
      expect(moves, contains(pos(2, 4)));
      expect(moves, contains(pos(1, 4)));
      expect(moves, contains(pos(0, 4)));

      // Down (toward row 7): 5,4 6,4 7,4 but NOT 8,4
      expect(moves, contains(pos(5, 4)));
      expect(moves, contains(pos(6, 4)));
      expect(moves, contains(pos(7, 4)));
    });

    test('CANNOT move more than 4 squares', () {
      final board = boardWith({pos(4, 0): whiteRook});
      final moves = validator.getLegalMoves(board, pos(4, 0), PlayerColor.white);

      // Right: can reach col 1,2,3,4 (4 squares)
      expect(moves, contains(pos(4, 4)));
      // col 5 would be 5 squares — too far
      expect(moves, isNot(contains(pos(4, 5))));
    });

    test('blocked by friendly piece', () {
      final board = boardWith({
        pos(4, 4): whiteRook,
        pos(4, 6): whitePawn,
      });
      final moves = validator.getLegalMoves(board, pos(4, 4), PlayerColor.white);

      expect(moves, contains(pos(4, 5)));
      expect(moves, isNot(contains(pos(4, 6))));
      expect(moves, isNot(contains(pos(4, 7))));
    });

    test('can capture enemy but stops after', () {
      final board = boardWith({
        pos(4, 4): whiteRook,
        pos(4, 6): blackPawn,
      });
      final moves = validator.getLegalMoves(board, pos(4, 4), PlayerColor.white);

      expect(moves, contains(pos(4, 5)));
      expect(moves, contains(pos(4, 6))); // capture
      expect(moves, isNot(contains(pos(4, 7)))); // blocked
    });

    test('CANNOT move diagonally', () {
      final board = boardWith({pos(4, 4): whiteRook});
      final moves = validator.getLegalMoves(board, pos(4, 4), PlayerColor.white);

      expect(moves, isNot(contains(pos(5, 5))));
      expect(moves, isNot(contains(pos(3, 3))));
    });
  });
}
