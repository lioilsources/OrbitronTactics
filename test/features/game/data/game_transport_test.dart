import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbitron_tactics/features/game/data/game_event.dart';
import 'package:orbitron_tactics/features/game/data/game_transport.dart';
import 'package:orbitron_tactics/core/game_logic/models/piece.dart';
import 'package:orbitron_tactics/core/game_logic/models/position.dart';
import 'package:orbitron_tactics/core/game_logic/models/move.dart';

void main() {
  group('LocalGameTransport', () {
    test('createPair creates two connected transports', () {
      final (a, b) = LocalGameTransport.createPair();
      expect(a, isNotNull);
      expect(b, isNotNull);
      a.dispose();
      b.dispose();
    });

    test('sending from A is received by B', () async {
      final (a, b) = LocalGameTransport.createPair();
      await a.connect();
      await b.connect();

      final received = <GameEvent>[];
      b.events.listen(received.add);

      final event = MoveMadeEvent(
        move: Move(
          from: const Position(row: 1, col: 4),
          to: const Position(row: 2, col: 3),
          piece: const Piece(type: PieceType.pawn, color: PlayerColor.white),
        ),
      );

      a.send(event);
      await Future.delayed(Duration.zero);

      expect(received.length, 1);
      expect(received.first, isA<MoveMadeEvent>());

      a.dispose();
      b.dispose();
    });

    test('sending from B is received by A', () async {
      final (a, b) = LocalGameTransport.createPair();
      await a.connect();
      await b.connect();

      final received = <GameEvent>[];
      a.events.listen(received.add);

      const event = GameStartedEvent();
      b.send(event);
      await Future.delayed(Duration.zero);

      expect(received.length, 1);
      expect(received.first, isA<GameStartedEvent>());

      a.dispose();
      b.dispose();
    });

    test('not received when peer is disconnected', () async {
      final (a, b) = LocalGameTransport.createPair();
      await a.connect();
      // b is NOT connected

      final received = <GameEvent>[];
      b.events.listen(received.add);

      const event = GameStartedEvent();
      a.send(event);
      await Future.delayed(Duration.zero);

      expect(received, isEmpty);

      a.dispose();
      b.dispose();
    });

    test('isConnected reflects connection state', () async {
      final (a, b) = LocalGameTransport.createPair();
      expect(a.isConnected, isFalse);

      await a.connect();
      expect(a.isConnected, isTrue);

      await a.disconnect();
      expect(a.isConnected, isFalse);

      a.dispose();
      b.dispose();
    });

    test('connectionStatus returns empty stream', () async {
      final (a, b) = LocalGameTransport.createPair();

      final statuses = <ConnectionStatus>[];
      a.connectionStatus.listen(statuses.add);

      await a.connect();
      await Future.delayed(Duration.zero);

      expect(statuses, isEmpty);

      a.dispose();
      b.dispose();
    });
  });

  group('GameEvent serialization', () {
    test('MoveMadeEvent round-trips through JSON', () {
      final event = MoveMadeEvent(
        move: Move(
          from: const Position(row: 1, col: 4),
          to: const Position(row: 2, col: 3),
          piece: const Piece(type: PieceType.pawn, color: PlayerColor.white),
        ),
      );

      // Full round-trip: toJson → jsonEncode → jsonDecode → fromJson
      final jsonString = jsonEncode(event.toJson());
      final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
      final restored = GameEvent.fromJson(decoded);

      expect(restored, isA<MoveMadeEvent>());
      final moveMade = restored as MoveMadeEvent;
      expect(moveMade.move.from, event.move.from);
      expect(moveMade.move.to, event.move.to);
      expect(moveMade.move.piece.type, PieceType.pawn);
    });

    test('GameStartedEvent round-trips through JSON', () {
      const event = GameStartedEvent();
      final json = event.toJson();
      final restored = GameEvent.fromJson(json);
      expect(restored, isA<GameStartedEvent>());
    });

    test('GameOverEvent round-trips through JSON', () {
      const event = GameOverEvent(
        winner: PlayerColor.white,
        reason: 'Royal Elimination',
      );

      final json = event.toJson();
      final restored = GameEvent.fromJson(json);
      expect(restored, isA<GameOverEvent>());
      expect((restored as GameOverEvent).winner, PlayerColor.white);
      expect(restored.reason, 'Royal Elimination');
    });

    test('PlayerJoinedEvent round-trips through JSON', () {
      const event = PlayerJoinedEvent(
        color: PlayerColor.black,
        displayName: 'Bob',
      );

      final json = event.toJson();
      final restored = GameEvent.fromJson(json);
      expect(restored, isA<PlayerJoinedEvent>());
      expect((restored as PlayerJoinedEvent).color, PlayerColor.black);
      expect(restored.displayName, 'Bob');
    });

    test('PlayerLeftEvent round-trips through JSON', () {
      const event = PlayerLeftEvent(color: PlayerColor.white);

      final json = event.toJson();
      final restored = GameEvent.fromJson(json);
      expect(restored, isA<PlayerLeftEvent>());
      expect((restored as PlayerLeftEvent).color, PlayerColor.white);
    });
  });
}
