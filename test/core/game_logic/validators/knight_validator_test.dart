import 'package:flutter_test/flutter_test.dart';
import 'package:orbitron_tactics/core/game_logic/models/piece.dart';
import 'package:orbitron_tactics/core/game_logic/validators/knight_validator.dart';
import '../test_helpers.dart';

void main() {
  const validator = KnightValidator();

  group('KnightValidator - White', () {
    group('forward L-shapes', () {
      test('can move 2 forward 1 sideways (tall L forward)', () {
        final board = boardWith({pos(3, 4): whiteKnight});
        final moves = validator.getLegalMoves(board, pos(3, 4), PlayerColor.white);

        // 2 forward (row+2), 1 sideways
        expect(moves, contains(pos(5, 3)));
        expect(moves, contains(pos(5, 5)));
      });

      test('can move 1 forward 2 sideways (wide L forward)', () {
        final board = boardWith({pos(3, 4): whiteKnight});
        final moves = validator.getLegalMoves(board, pos(3, 4), PlayerColor.white);

        // 1 forward (row+1), 2 sideways
        expect(moves, contains(pos(4, 2)));
        expect(moves, contains(pos(4, 6)));
      });
    });

    group('backward L-shapes', () {
      test('can move 1 backward 2 sideways (lower L backward)', () {
        final board = boardWith({pos(3, 4): whiteKnight});
        final moves = validator.getLegalMoves(board, pos(3, 4), PlayerColor.white);

        // 1 backward (row-1), 2 sideways = lower L — ALLOWED
        expect(moves, contains(pos(2, 2)));
        expect(moves, contains(pos(2, 6)));
      });

      test('CANNOT move 2 backward 1 sideways (tall L backward)', () {
        final board = boardWith({pos(4, 4): whiteKnight});
        final moves = validator.getLegalMoves(board, pos(4, 4), PlayerColor.white);

        // 2 backward (row-2), 1 sideways = tall L — NOT ALLOWED
        expect(moves, isNot(contains(pos(2, 3))));
        expect(moves, isNot(contains(pos(2, 5))));
      });
    });

    group('rook blocking', () {
      test('blocked by rook directly in front (tall forward L)', () {
        final board = boardWith({
          pos(3, 4): whiteKnight,
          pos(4, 4): blackRook, // rook directly in front
        });
        final moves = validator.getLegalMoves(board, pos(3, 4), PlayerColor.white);

        // Tall forward L (2 forward, 1 sideways) should be BLOCKED
        expect(moves, isNot(contains(pos(5, 3))));
        expect(moves, isNot(contains(pos(5, 5))));

        // Wide forward L (1 forward, 2 sideways) should still work
        expect(moves, contains(pos(4, 2)));
        expect(moves, contains(pos(4, 6)));
      });

      test('blocked by friendly rook in front too', () {
        final board = boardWith({
          pos(3, 4): whiteKnight,
          pos(4, 4): whiteRook, // friendly rook in front
        });
        final moves = validator.getLegalMoves(board, pos(3, 4), PlayerColor.white);

        // Tall forward L blocked
        expect(moves, isNot(contains(pos(5, 3))));
        expect(moves, isNot(contains(pos(5, 5))));
      });

      test('NOT blocked by non-rook piece in front', () {
        final board = boardWith({
          pos(3, 4): whiteKnight,
          pos(4, 4): blackPawn, // pawn, not a rook
        });
        final moves = validator.getLegalMoves(board, pos(3, 4), PlayerColor.white);

        // NOT blocked — pawns don't count
        expect(moves, contains(pos(5, 3)));
        expect(moves, contains(pos(5, 5)));
      });

      test('backward moves are not affected by rook blocking', () {
        final board = boardWith({
          pos(3, 4): whiteKnight,
          pos(4, 4): blackRook,
        });
        final moves = validator.getLegalMoves(board, pos(3, 4), PlayerColor.white);

        // Backward lower L should still work
        expect(moves, contains(pos(2, 2)));
        expect(moves, contains(pos(2, 6)));
      });
    });

    test('can capture enemy pieces', () {
      final board = boardWith({
        pos(3, 4): whiteKnight,
        pos(5, 3): blackPawn,
      });
      final moves = validator.getLegalMoves(board, pos(3, 4), PlayerColor.white);
      expect(moves, contains(pos(5, 3)));
    });

    test('CANNOT land on friendly piece', () {
      final board = boardWith({
        pos(3, 4): whiteKnight,
        pos(5, 3): whitePawn,
      });
      final moves = validator.getLegalMoves(board, pos(3, 4), PlayerColor.white);
      expect(moves, isNot(contains(pos(5, 3))));
    });
  });

  group('KnightValidator - Black', () {
    test('forward for black is toward lower rows', () {
      final board = boardWith({pos(5, 4): blackKnight});
      final moves = validator.getLegalMoves(board, pos(5, 4), PlayerColor.black);

      // Forward for black = row - dir = row-(-1) → we need to check:
      // Black's forward dir is -1, so 2 forward = row + 2*(-1) = row - 2
      // Tall forward L: (3, 3) and (3, 5)
      expect(moves, contains(pos(3, 3)));
      expect(moves, contains(pos(3, 5)));

      // Backward tall L (row + 2) should be blocked
      expect(moves, isNot(contains(pos(7, 3))));
      expect(moves, isNot(contains(pos(7, 5))));

      // Backward lower L (row + 1, col +/- 2) should work
      expect(moves, contains(pos(6, 2)));
      expect(moves, contains(pos(6, 6)));
    });
  });
}
