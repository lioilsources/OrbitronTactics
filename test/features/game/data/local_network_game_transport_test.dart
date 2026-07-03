import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:orbitron_tactics/core/game_logic/models/move.dart';
import 'package:orbitron_tactics/core/game_logic/models/piece.dart';
import 'package:orbitron_tactics/core/game_logic/models/position.dart';
import 'package:orbitron_tactics/features/battle/model/battle_simulation.dart';
import 'package:orbitron_tactics/features/game/data/game_event.dart';
import 'package:orbitron_tactics/features/game/data/game_transport.dart';
import 'package:orbitron_tactics/features/game/data/local_network/local_network_game_transport.dart';
import 'package:orbitron_tactics/features/game/data/local_network/local_network_peer.dart';

/// Minimal cross-wired peer pair for tests.
class _FakePeer implements LocalNetworkPeer {
  final StreamController<String> _messages = StreamController<String>.broadcast();
  _FakePeer? other;

  @override
  Stream<String> get messages => _messages.stream;
  @override
  Stream<List<DiscoveredPeer>> get discoveredPeers => const Stream.empty();
  @override
  Stream<ConnectionStatus> get connectionStatus => const Stream.empty();
  @override
  Future<void> startAdvertising(String displayName) async {}
  @override
  Future<void> startDiscovery(String displayName) async {}
  @override
  Future<void> connect(DiscoveredPeer peer) async {}
  @override
  void send(String message) => other?._messages.add(message);
  @override
  Future<void> stop() async {}
  @override
  void dispose() => _messages.close();

  static (_FakePeer, _FakePeer) pair() {
    final a = _FakePeer();
    final b = _FakePeer();
    a.other = b;
    b.other = a;
    return (a, b);
  }
}

Future<void> _flush() => Future<void>.delayed(Duration.zero);

void main() {
  group('LocalNetworkGameTransport', () {
    late LocalNetworkGameTransport txA;
    late LocalNetworkGameTransport txB;
    late List<GameEvent> received;

    setUp(() async {
      final (pa, pb) = _FakePeer.pair();
      txA = LocalNetworkGameTransport(pa);
      txB = LocalNetworkGameTransport(pb);
      await txA.connect();
      await txB.connect();
      received = [];
      txB.events.listen(received.add);
    });

    test('round-trips a move event through JSON over the peer', () async {
      const move = Move(
        from: Position(row: 1, col: 2),
        to: Position(row: 3, col: 4),
        piece: Piece(type: PieceType.knight, color: PlayerColor.white),
      );
      txA.send(const MoveMadeEvent(move: move));
      await _flush();

      expect(received.single, isA<MoveMadeEvent>());
      final got = received.single as MoveMadeEvent;
      expect(got.move.from, const Position(row: 1, col: 2));
      expect(got.move.piece.type, PieceType.knight);
    });

    test('round-trips battle events through JSON over the peer', () async {
      const move = Move(
        from: Position(row: 1, col: 2),
        to: Position(row: 2, col: 3),
        piece: Piece(type: PieceType.pawn, color: PlayerColor.black),
        capturedPiece: Piece(type: PieceType.pawn, color: PlayerColor.white),
      );
      final snapshot = BattleSimulation(seed: 1).snapshot();

      txA.send(const BattleStartedEvent(move: move, seed: 1234));
      txA.send(const BattleResolvedEvent(winner: PlayerColor.black));
      txA.send(const BattleInputEvent(
          input: BattleInput(turn: -1, thrust: true, fire: true)));
      txA.send(BattleSnapshotEvent(snapshot: snapshot));
      await _flush();

      expect(received.length, 4);
      expect((received[0] as BattleStartedEvent).seed, 1234);
      expect((received[1] as BattleResolvedEvent).winner, PlayerColor.black);
      expect((received[2] as BattleInputEvent).input.thrust, isTrue);
      expect((received[3] as BattleSnapshotEvent).snapshot.asteroids.length,
          snapshot.asteroids.length);
    });

    tearDown(() {
      txA.dispose();
      txB.dispose();
    });
  });
}
