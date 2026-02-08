import 'package:flutter_test/flutter_test.dart';
import 'package:orbitron_tactics/core/game_logic/models/piece.dart';
import 'package:orbitron_tactics/core/game_logic/services/threat_analyzer.dart';
import '../test_helpers.dart';

void main() {
  group('ThreatAnalyzer', () {
    test('pawn threatens diagonally forward', () {
      // Black pawn at (5,3) threatens white pieces at (4,2) and (4,4)
      // (black forward = toward lower rows)
      final board = boardWith({
        pos(5, 3): blackPawn,
        pos(4, 2): whitePawn,   // threatened
        pos(4, 4): whiteRook,   // threatened
        pos(4, 3): whiteKnight, // NOT threatened (straight forward is impossible for pawn)
      });

      final threatened = ThreatAnalyzer.getThreatenedPositions(
        board, PlayerColor.white,
      );

      expect(threatened, contains(pos(4, 2)));
      expect(threatened, contains(pos(4, 4)));
      expect(threatened, isNot(contains(pos(4, 3))));
    });

    test('rook threatens along file and rank', () {
      // Black rook at (4,4) threatens white piece at (4,0) along rank
      // and at (0,4) along file
      final board = boardWith({
        pos(4, 4): blackRook,
        pos(4, 0): whitePawn,   // threatened (4 squares away — within range)
        pos(0, 4): whiteKing,   // threatened (4 squares away — within range)
        pos(7, 4): whiteBishop, // NOT threatened (3 squares, but within range — actually IS threatened)
      });

      final threatened = ThreatAnalyzer.getThreatenedPositions(
        board, PlayerColor.white,
      );

      expect(threatened, contains(pos(4, 0)));
      expect(threatened, contains(pos(0, 4)));
      expect(threatened, contains(pos(7, 4))); // 3 squares, within rook's max 4
    });

    test('no threats when opponent cannot capture anything', () {
      // White pieces far from any black attack
      final board = boardWith({
        pos(0, 0): whitePawn,
        pos(7, 7): blackPawn,
      });

      final threatened = ThreatAnalyzer.getThreatenedPositions(
        board, PlayerColor.white,
      );

      expect(threatened, isEmpty);
    });

    test('multiple opponent pieces threatening same piece', () {
      // Two black bishops can both threaten a white pawn
      final board = boardWith({
        pos(4, 4): whitePawn,
        pos(3, 3): blackBishop, // threatens (4,4) diagonally
        pos(3, 5): blackBishop, // threatens (4,4) diagonally
      });

      final threatened = ThreatAnalyzer.getThreatenedPositions(
        board, PlayerColor.white,
      );

      // Should contain it once (it's a Set)
      expect(threatened, contains(pos(4, 4)));
      expect(threatened.length, 1);
    });

    test('does not include opponent pieces in result', () {
      // Black rook threatens the square where another black piece sits,
      // but that should not appear in white's threatened set
      final board = boardWith({
        pos(4, 4): blackRook,
        pos(4, 6): blackPawn, // same color — not a capture target
        pos(4, 2): whitePawn, // threatened
      });

      final threatened = ThreatAnalyzer.getThreatenedPositions(
        board, PlayerColor.white,
      );

      expect(threatened, contains(pos(4, 2)));
      expect(threatened, hasLength(1));
    });

    test('last warrior threatens all 8 adjacent squares', () {
      // Last warrior moves 1 square in all 8 directions (like standard king)
      final board = boardWith({
        pos(4, 4): blackLastWarrior,
        pos(3, 4): whitePawn, // 1 square up — threatened
        pos(5, 5): whiteRook, // 1 square diagonal — threatened
        pos(4, 7): whiteBishop, // 3 squares away — NOT threatened
      });

      final threatened = ThreatAnalyzer.getThreatenedPositions(
        board, PlayerColor.white,
      );

      expect(threatened, contains(pos(3, 4)));
      expect(threatened, contains(pos(5, 5)));
      expect(threatened, isNot(contains(pos(4, 7))));
    });

    test('knight threatens L-shaped positions', () {
      // Black knight at (4,4) can attack white piece at (2,3) (tall L forward)
      final board = boardWith({
        pos(4, 4): blackKnight,
        pos(2, 3): whitePawn, // 2 forward, 1 left — valid knight move
        pos(2, 5): whiteRook, // 2 forward, 1 right — valid knight move
      });

      final threatened = ThreatAnalyzer.getThreatenedPositions(
        board, PlayerColor.white,
      );

      expect(threatened, contains(pos(2, 3)));
      expect(threatened, contains(pos(2, 5)));
    });

    test('bishop snipe threatens 3 squares forward', () {
      // Black bishop at (5,3) can snipe to (2,3) — 3 forward, same column
      final board = boardWith({
        pos(5, 3): blackBishop,
        pos(2, 3): whitePawn, // snipe target (3 forward for black)
      });

      final threatened = ThreatAnalyzer.getThreatenedPositions(
        board, PlayerColor.white,
      );

      expect(threatened, contains(pos(2, 3)));
    });

    test('works for black player checking their own threats', () {
      // White rook threatens black pawn
      final board = boardWith({
        pos(4, 4): whiteRook,
        pos(4, 7): blackPawn, // threatened by white rook
      });

      final threatened = ThreatAnalyzer.getThreatenedPositions(
        board, PlayerColor.black,
      );

      expect(threatened, contains(pos(4, 7)));
    });

    test('blocked rook does not threaten piece behind blocker', () {
      // Black rook at (4,0), white pawn at (4,2), white bishop at (4,4)
      // Rook can reach (4,2) but NOT (4,4) — blocked by pawn
      final board = boardWith({
        pos(4, 0): blackRook,
        pos(4, 2): whitePawn,   // threatened
        pos(4, 4): whiteBishop, // NOT threatened — blocked
      });

      final threatened = ThreatAnalyzer.getThreatenedPositions(
        board, PlayerColor.white,
      );

      expect(threatened, contains(pos(4, 2)));
      expect(threatened, isNot(contains(pos(4, 4))));
    });
  });
}
