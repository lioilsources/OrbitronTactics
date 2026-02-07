import 'package:flutter_test/flutter_test.dart';
import 'package:orbitron_tactics/core/game_logic/models/piece.dart';
import 'package:orbitron_tactics/core/game_logic/validators/last_warrior_validator.dart';
import '../test_helpers.dart';

void main() {
  const validator = LastWarriorValidator();

  group('LastWarriorValidator', () {
    test('can move 1 square in all 8 directions', () {
      final board = boardWith({pos(4, 4): whiteLastWarrior});
      final moves =
          validator.getLegalMoves(board, pos(4, 4), PlayerColor.white);

      // All 8 adjacent squares
      expect(moves, contains(pos(3, 3)));
      expect(moves, contains(pos(3, 4)));
      expect(moves, contains(pos(3, 5)));
      expect(moves, contains(pos(4, 3)));
      expect(moves, contains(pos(4, 5)));
      expect(moves, contains(pos(5, 3)));
      expect(moves, contains(pos(5, 4)));
      expect(moves, contains(pos(5, 5)));

      expect(moves.length, 8);
    });

    test('CANNOT move more than 1 square', () {
      final board = boardWith({pos(4, 4): whiteLastWarrior});
      final moves =
          validator.getLegalMoves(board, pos(4, 4), PlayerColor.white);

      expect(moves, isNot(contains(pos(6, 6))));
      expect(moves, isNot(contains(pos(4, 6))));
      expect(moves, isNot(contains(pos(2, 4))));
    });

    test('can capture enemy piece', () {
      final board = boardWith({
        pos(4, 4): whiteLastWarrior,
        pos(5, 5): blackPawn,
      });
      final moves =
          validator.getLegalMoves(board, pos(4, 4), PlayerColor.white);
      expect(moves, contains(pos(5, 5)));
    });

    test('CANNOT land on friendly piece', () {
      final board = boardWith({
        pos(4, 4): whiteLastWarrior,
        pos(5, 5): whitePawn,
      });
      final moves =
          validator.getLegalMoves(board, pos(4, 4), PlayerColor.white);
      expect(moves, isNot(contains(pos(5, 5))));
    });

    test('limited moves at corner', () {
      final board = boardWith({pos(0, 0): whiteLastWarrior});
      final moves =
          validator.getLegalMoves(board, pos(0, 0), PlayerColor.white);

      expect(moves.length, 3); // Only 3 valid adjacent squares
      expect(moves, contains(pos(0, 1)));
      expect(moves, contains(pos(1, 0)));
      expect(moves, contains(pos(1, 1)));
    });
  });
}
