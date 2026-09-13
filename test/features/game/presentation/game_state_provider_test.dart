import 'package:flutter_test/flutter_test.dart';
import 'package:orbitron_tactics/core/ai/ai_difficulty.dart';
import 'package:orbitron_tactics/core/game_logic/engine/upgrade_engine.dart';
import 'package:orbitron_tactics/core/game_logic/models/game_phase.dart';
import 'package:orbitron_tactics/core/game_logic/models/move.dart';
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

    test('battle resolution reports the winner, its ship and its credits',
        () {
      final notifier = notifierWithCaptureSetup();
      final rewards = <(PlayerColor, PieceType, int)>[];
      notifier.onBattleReward =
          (winner, ship, credits) => rewards.add((winner, ship, credits));
      notifier.tryMove(pos(3, 3), pos(4, 3));

      notifier.resolveBattle(PlayerColor.white);

      // White's rook won the battle; the credits are the pawn it took.
      expect(rewards, [
        (
          PlayerColor.white,
          PieceType.rook,
          UpgradeEngine.resourcesFor(PieceType.pawn),
        ),
      ]);
    });

    test('restartCurrentMode starts a hot-seat game', () {
      final notifier = notifierWithCaptureSetup();

      notifier.restartCurrentMode();

      expect(notifier.mode, GameMode.hotSeat);
      expect(notifier.state.moveCount, 0);
      expect(notifier.state.board.findPieces().length, 32);
    });
  });

  group('GameStateNotifier - single player', () {
    GameStateNotifier singlePlayer(PlayerColor humanColor) {
      return GameStateNotifier(defaultGameState())
        ..startSinglePlayerGame(
          profile: AiProfile.medium,
          humanColor: humanColor,
          humanName: 'Ada',
        );
    }

    test('sets up colors and players', () {
      final notifier = singlePlayer(PlayerColor.black);

      expect(notifier.mode, GameMode.singlePlayer);
      expect(notifier.localColor, PlayerColor.black);
      expect(notifier.aiColor, PlayerColor.white);
      expect(notifier.aiProfile, AiProfile.medium);
      expect(notifier.state.phase, GamePhase.playing);
      expect(notifier.state.currentTurn, PlayerColor.white);
      expect(notifier.state.playerBlack.displayName, 'Ada');
      expect(notifier.state.playerWhite.userId, AiProfile.medium.identity);
      expect(notifier.state.playerWhite.displayName,
          AiProfile.medium.displayName);
    });

    test('the player cannot move AI pieces', () {
      final notifier = singlePlayer(PlayerColor.black);

      expect(notifier.tryMove(pos(1, 0), pos(2, 1)), isFalse);
      expect(notifier.state.moveCount, 0);
    });

    test('applyAiMove plays only on the AI turn', () {
      final notifier = singlePlayer(PlayerColor.white);
      final aiMove = Move(from: pos(6, 0), to: pos(5, 1), piece: blackPawn);

      expect(notifier.applyAiMove(aiMove), isFalse);
      expect(notifier.tryMove(pos(1, 0), pos(2, 1)), isTrue);
      expect(notifier.applyAiMove(aiMove), isTrue);
      expect(notifier.state.currentTurn, PlayerColor.white);
      expect(notifier.state.moveCount, 2);
    });

    test('applyAiMove rejects illegal moves', () {
      final notifier = singlePlayer(PlayerColor.black);
      final illegal = Move(from: pos(1, 0), to: pos(4, 0), piece: whitePawn);

      expect(notifier.applyAiMove(illegal), isFalse);
      expect(notifier.state.moveCount, 0);
    });

    test('restartCurrentMode starts a new single player game', () {
      final notifier = singlePlayer(PlayerColor.black);
      notifier.applyAiMove(
          Move(from: pos(1, 0), to: pos(2, 1), piece: whitePawn));
      final firstGameId = notifier.state.gameId;

      notifier.restartCurrentMode();

      expect(notifier.mode, GameMode.singlePlayer);
      expect(notifier.aiColor, PlayerColor.white);
      expect(notifier.aiProfile, AiProfile.medium);
      expect(notifier.state.gameId, isNot(firstGameId));
      expect(notifier.state.moveCount, 0);
      expect(notifier.state.playerBlack.displayName, 'Ada');
    });

    test('startNewGame leaves single player', () {
      final notifier = singlePlayer(PlayerColor.white);

      notifier.startNewGame();

      expect(notifier.mode, GameMode.hotSeat);
      expect(notifier.localColor, isNull);
      expect(notifier.aiColor, isNull);
      expect(notifier.aiProfile, isNull);
    });
  });
}
