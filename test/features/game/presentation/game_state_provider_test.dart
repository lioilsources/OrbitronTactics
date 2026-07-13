import 'package:flutter_test/flutter_test.dart';
import 'package:orbitron_tactics/core/game_logic/models/game_phase.dart';
import 'package:orbitron_tactics/core/game_logic/models/piece.dart';
import 'package:orbitron_tactics/features/game/presentation/providers/game_state_provider.dart';

import '../../../core/game_logic/test_helpers.dart';

void main() {
  group('GameStateNotifier - hot-seat battle arena', () {
    GameStateNotifier notifierWithCaptureSetup() {
      // White rook can capture the black pawn one square ahead.
      // Kings present so no victory condition fires.
      final board = boardWith({
        pos(0, 0): whiteKing,
        pos(7, 7): blackKing,
        pos(3, 3): whiteRook,
        pos(4, 3): blackPawn,
      });
      return GameStateNotifier(gameStateWith(board: board));
    }

    test('non-capture move does not enter battle phase', () {
      final notifier = notifierWithCaptureSetup();

      final ok = notifier.tryMove(pos(3, 3), pos(3, 5));

      expect(ok, isTrue);
      expect(notifier.state.phase, GamePhase.playing);
      expect(notifier.pendingBattleMove, isNull);
    });

    test('capture move enters battle phase and stores pending move', () {
      final notifier = notifierWithCaptureSetup();

      final ok = notifier.tryMove(pos(3, 3), pos(4, 3));

      expect(ok, isTrue);
      expect(notifier.state.phase, GamePhase.battle);
      final pending = notifier.pendingBattleMove;
      expect(pending, isNotNull);
      expect(pending!.piece.color, PlayerColor.white);
      expect(pending.capturedPiece, isNotNull);
      // Board is untouched until the battle resolves.
      expect(notifier.state.board.pieceAt(pos(3, 3)), whiteRook);
      expect(notifier.state.board.pieceAt(pos(4, 3)), blackPawn);
    });

    test('attacker win applies the capture', () {
      final notifier = notifierWithCaptureSetup();
      notifier.tryMove(pos(3, 3), pos(4, 3));

      notifier.resolveBattle(PlayerColor.white);

      expect(notifier.state.phase, GamePhase.playing);
      expect(notifier.state.board.pieceAt(pos(4, 3)), whiteRook);
      expect(notifier.state.board.pieceAt(pos(3, 3)), isNull);
      expect(notifier.state.currentTurn, PlayerColor.black);
      expect(notifier.pendingBattleMove, isNull);
    });

    test('defender win removes the attacker', () {
      final notifier = notifierWithCaptureSetup();
      notifier.tryMove(pos(3, 3), pos(4, 3));

      notifier.resolveBattle(PlayerColor.black);

      expect(notifier.state.phase, GamePhase.playing);
      expect(notifier.state.board.pieceAt(pos(3, 3)), isNull);
      expect(notifier.state.board.pieceAt(pos(4, 3)), blackPawn);
      expect(notifier.state.currentTurn, PlayerColor.black);
      expect(notifier.pendingBattleMove, isNull);
    });

    test('resolveBattle outside battle phase is a no-op', () {
      final notifier = notifierWithCaptureSetup();

      notifier.resolveBattle(PlayerColor.white);

      expect(notifier.state.phase, GamePhase.playing);
      expect(notifier.state.board.pieceAt(pos(3, 3)), whiteRook);
    });

    test('startNewGame clears a pending battle', () {
      final notifier = notifierWithCaptureSetup();
      notifier.tryMove(pos(3, 3), pos(4, 3));

      notifier.startNewGame();

      expect(notifier.pendingBattleMove, isNull);
      expect(notifier.state.phase, GamePhase.playing);
    });
  });
}
