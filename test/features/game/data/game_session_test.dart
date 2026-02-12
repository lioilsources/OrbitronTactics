import 'package:flutter_test/flutter_test.dart';
import 'package:orbitron_tactics/core/game_logic/models/game_phase.dart';
import 'package:orbitron_tactics/core/game_logic/models/piece.dart';
import 'package:orbitron_tactics/core/game_logic/models/position.dart';
import 'package:orbitron_tactics/core/game_logic/models/victory_condition.dart';
import 'package:orbitron_tactics/features/game/data/game_event.dart';
import 'package:orbitron_tactics/features/game/data/game_session.dart';

void main() {
  group('GameSession - Local Multiplayer', () {
    late GameSession whiteSession;
    late GameSession blackSession;

    setUp(() async {
      final (w, b) = GameSession.createLocalGame();
      whiteSession = w;
      blackSession = b;
      await whiteSession.start();
      await blackSession.start();
    });

    tearDown(() {
      whiteSession.dispose();
      blackSession.dispose();
    });

    test('both sessions start in playing phase', () {
      expect(whiteSession.state.phase, GamePhase.playing);
      expect(blackSession.state.phase, GamePhase.playing);
    });

    test('white goes first', () {
      expect(whiteSession.isMyTurn, isTrue);
      expect(blackSession.isMyTurn, isFalse);
    });

    test('white can only move white pieces', () {
      // White pawn at (1, 4) — try to move it
      final moves = whiteSession.getLegalMoves(const Position(row: 1, col: 4));
      expect(moves, isNotEmpty);

      // Can't get moves for black pieces
      final blackMoves =
          whiteSession.getLegalMoves(const Position(row: 6, col: 4));
      expect(blackMoves, isEmpty);
    });

    test('white move is transmitted to black session', () async {
      // White pawn at (1, 4) moves diag forward to (2, 3)
      final success = whiteSession.tryMove(
        const Position(row: 1, col: 4),
        const Position(row: 2, col: 3),
      );
      expect(success, isTrue);

      // Allow event propagation
      await Future.delayed(Duration.zero);

      // White's state updated
      expect(
        whiteSession.state.board.pieceAt(const Position(row: 2, col: 3)),
        isNotNull,
      );
      expect(
        whiteSession.state.board
            .pieceAt(const Position(row: 2, col: 3))!
            .color,
        PlayerColor.white,
      );

      // Black received the move
      expect(
        blackSession.state.board.pieceAt(const Position(row: 2, col: 3)),
        isNotNull,
      );
      expect(blackSession.state.currentTurn, PlayerColor.black);
      expect(blackSession.isMyTurn, isTrue);
    });

    test('full turn cycle: white moves, then black moves', () async {
      // White pawn (1,4) → (2,3)
      whiteSession.tryMove(
        const Position(row: 1, col: 4),
        const Position(row: 2, col: 3),
      );
      await Future.delayed(Duration.zero);

      expect(blackSession.isMyTurn, isTrue);

      // Black pawn (6,4) → (5,3) (diagonal forward for black = row-1)
      final success = blackSession.tryMove(
        const Position(row: 6, col: 4),
        const Position(row: 5, col: 3),
      );
      expect(success, isTrue);
      await Future.delayed(Duration.zero);

      // Both sessions see black's move
      expect(
        whiteSession.state.board.pieceAt(const Position(row: 5, col: 3)),
        isNotNull,
      );
      expect(whiteSession.state.currentTurn, PlayerColor.white);
      expect(whiteSession.isMyTurn, isTrue);
    });

    test('black cannot move on white turn', () {
      final success = blackSession.tryMove(
        const Position(row: 6, col: 4),
        const Position(row: 5, col: 3),
      );
      expect(success, isFalse);
    });

    test('invalid move returns false', () {
      // White pawn can't move straight forward
      final success = whiteSession.tryMove(
        const Position(row: 1, col: 4),
        const Position(row: 2, col: 4),
      );
      expect(success, isFalse);
    });

    test('move history is synchronized', () async {
      whiteSession.tryMove(
        const Position(row: 1, col: 4),
        const Position(row: 2, col: 3),
      );
      await Future.delayed(Duration.zero);

      expect(whiteSession.state.moveHistory.length, 1);
      expect(blackSession.state.moveHistory.length, 1);
      expect(whiteSession.state.moveCount, 1);
      expect(blackSession.state.moveCount, 1);
    });

    test('stateStream emits on local move', () async {
      final states = <dynamic>[];
      whiteSession.stateStream.listen(states.add);

      whiteSession.tryMove(
        const Position(row: 1, col: 4),
        const Position(row: 2, col: 3),
      );

      await Future.delayed(Duration.zero);
      expect(states.length, 1);
    });

    test('stateStream emits on remote move', () async {
      final states = <dynamic>[];
      blackSession.stateStream.listen(states.add);

      whiteSession.tryMove(
        const Position(row: 1, col: 4),
        const Position(row: 2, col: 3),
      );

      await Future.delayed(Duration.zero);
      expect(states.length, 1);
    });
  });

  group('GameSession - Disconnect handling', () {
    late GameSession whiteSession;
    late GameSession blackSession;

    setUp(() async {
      final (w, b) = GameSession.createLocalGame();
      whiteSession = w;
      blackSession = b;
      await whiteSession.start();
      await blackSession.start();
    });

    tearDown(() {
      whiteSession.dispose();
      blackSession.dispose();
    });

    test('claimVictory sets finished state with abandonment', () {
      expect(whiteSession.state.isFinished, isFalse);

      whiteSession.claimVictory();

      expect(whiteSession.state.isFinished, isTrue);
      expect(whiteSession.state.phase, GamePhase.finished);
      expect(whiteSession.state.winner, PlayerColor.white);
      expect(
        whiteSession.state.victoryCondition,
        isA<Abandonment>(),
      );
    });

    test('claimVictory does nothing if already finished', () {
      whiteSession.claimVictory();
      final stateAfterFirst = whiteSession.state;

      // Claim again — should be a no-op
      whiteSession.claimVictory();
      expect(whiteSession.state, stateAfterFirst);
    });

    test('claimVictory emits updated state on stateStream', () async {
      final states = <dynamic>[];
      whiteSession.stateStream.listen(states.add);

      whiteSession.claimVictory();
      await Future.delayed(Duration.zero);

      expect(states.length, 1);
      expect(states.first.isFinished, isTrue);
    });

    test('PlayerLeftEvent triggers onOpponentDisconnect', () async {
      final disconnects = <void>[];
      whiteSession.onOpponentDisconnect.listen((_) => disconnects.add(null));

      // Black sends PlayerLeftEvent
      blackSession.transport.send(
        const PlayerLeftEvent(color: PlayerColor.black),
      );
      await Future.delayed(Duration.zero);

      expect(disconnects.length, 1);
    });

    test('PlayerLeftEvent does not trigger when game is finished', () async {
      // Finish the game first
      whiteSession.claimVictory();

      final disconnects = <void>[];
      whiteSession.onOpponentDisconnect.listen((_) => disconnects.add(null));

      blackSession.transport.send(
        const PlayerLeftEvent(color: PlayerColor.black),
      );
      await Future.delayed(Duration.zero);

      expect(disconnects, isEmpty);
    });

    test('isMyTurn is false after claimVictory', () {
      expect(whiteSession.isMyTurn, isTrue);
      whiteSession.claimVictory();
      expect(whiteSession.isMyTurn, isFalse);
    });
  });
}
