import 'package:flutter_test/flutter_test.dart';
import 'package:orbitron_tactics/core/game_logic/models/piece.dart';
import 'package:orbitron_tactics/features/game/data/game_session.dart';
import 'package:orbitron_tactics/features/game/data/game_transport.dart';
import '../../../core/game_logic/test_helpers.dart';

/// Pump the event queue so paired-transport messages are delivered.
Future<void> _flush() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

/// Two battle-enabled sessions sharing a paired transport, set up with a
/// white pawn able to capture a black pawn diagonally.
Future<(GameSession, GameSession)> _pair() async {
  final (tA, tB) = LocalGameTransport.createPair();
  final state = gameStateWith(
    board: boardWith({
      pos(3, 4): whitePawn,
      pos(4, 5): blackPawn,
      pos(0, 4): whiteKing,
      pos(0, 3): whiteQueen,
      pos(7, 4): blackKing,
      pos(7, 3): blackQueen,
    }),
  );

  final white = GameSession(
    localColor: PlayerColor.white,
    transport: tA,
    initialState: state,
    battleOnCapture: true,
  );
  final black = GameSession(
    localColor: PlayerColor.black,
    transport: tB,
    initialState: state,
    battleOnCapture: true,
  );
  await white.start();
  await black.start();
  return (white, black);
}

void main() {
  group('GameSession battle-on-capture', () {
    test('a capture opens the arena on both sides without mutating the board',
        () async {
      final (white, black) = await _pair();
      BattleStartRequest? whiteReq;
      BattleStartRequest? blackReq;
      white.onBattleRequested.listen((r) => whiteReq = r);
      black.onBattleRequested.listen((r) => blackReq = r);

      final accepted = white.tryMove(pos(3, 4), pos(4, 5));
      await _flush();

      expect(accepted, isTrue);
      expect(white.battlePending, isTrue);
      expect(black.battlePending, isTrue);

      // Roles: white is the attacker and the host; black is neither.
      expect(whiteReq, isNotNull);
      expect(whiteReq!.localIsAttacker, isTrue);
      expect(whiteReq!.localIsHost, isTrue);
      expect(blackReq, isNotNull);
      expect(blackReq!.localIsAttacker, isFalse);
      expect(blackReq!.localIsHost, isFalse);

      // Same deterministic seed on both devices.
      expect(whiteReq!.seed, blackReq!.seed);

      // Board untouched until the battle resolves.
      expect(white.state.board.pieceAt(pos(4, 5)), blackPawn);
      expect(white.state.board.pieceAt(pos(3, 4)), whitePawn);

      white.dispose();
      black.dispose();
    });

    test('attacker victory resolves as a normal capture on both sides',
        () async {
      final (white, black) = await _pair();
      white.tryMove(pos(3, 4), pos(4, 5));
      await _flush();

      // Host reports the attacker (white) won.
      white.submitBattleResult(PlayerColor.white);
      await _flush();

      for (final s in [white, black]) {
        expect(s.battlePending, isFalse);
        expect(s.state.board.pieceAt(pos(4, 5)), whitePawn);
        expect(s.state.board.pieceAt(pos(3, 4)), isNull);
        expect(s.state.currentTurn, PlayerColor.black);
      }

      white.dispose();
      black.dispose();
    });

    test('defender victory destroys the attacker on both sides', () async {
      final (white, black) = await _pair();
      white.tryMove(pos(3, 4), pos(4, 5));
      await _flush();

      // Host reports the defender (black) won.
      white.submitBattleResult(PlayerColor.black);
      await _flush();

      for (final s in [white, black]) {
        expect(s.battlePending, isFalse);
        // Attacker destroyed, defender stays.
        expect(s.state.board.pieceAt(pos(3, 4)), isNull);
        expect(s.state.board.pieceAt(pos(4, 5)), blackPawn);
        expect(s.state.currentTurn, PlayerColor.black);
      }

      white.dispose();
      black.dispose();
    });

    test('non-capture moves never trigger a battle', () async {
      final (white, black) = await _pair();
      var battleRequested = false;
      white.onBattleRequested.listen((_) => battleRequested = true);

      // Pawn advances diagonally to an empty square (legal, non-capturing).
      final accepted = white.tryMove(pos(3, 4), pos(4, 3));
      await _flush();

      expect(accepted, isTrue);
      expect(battleRequested, isFalse);
      expect(white.battlePending, isFalse);
      expect(white.state.board.pieceAt(pos(4, 3)), whitePawn);

      white.dispose();
      black.dispose();
    });
  });
}
