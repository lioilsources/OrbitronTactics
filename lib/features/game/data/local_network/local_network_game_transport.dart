import 'dart:async';
import 'dart:convert';

import '../game_event.dart';
import '../game_transport.dart';
import 'local_network_peer.dart';

/// [GameTransport] backed by a [LocalNetworkPeer]. Encodes [GameEvent]s as JSON
/// strings over the peer link, so all of the turn-based and battle traffic
/// (including high-frequency input/snapshot events) travels the local-network
/// connection.
class LocalNetworkGameTransport extends GameTransport {
  final LocalNetworkPeer peer;

  final StreamController<GameEvent> _events =
      StreamController<GameEvent>.broadcast();
  StreamSubscription<String>? _messageSub;
  bool _connected = false;

  LocalNetworkGameTransport(this.peer);

  @override
  Stream<GameEvent> get events => _events.stream;

  @override
  Stream<ConnectionStatus> get connectionStatus => peer.connectionStatus;

  @override
  bool get isConnected => _connected;

  @override
  Future<void> connect() async {
    _connected = true;
    _messageSub = peer.messages.listen((raw) {
      try {
        final json = jsonDecode(raw) as Map<String, dynamic>;
        _events.add(GameEvent.fromJson(json));
      } catch (_) {
        // Ignore malformed payloads rather than tearing down the match.
      }
    });
  }

  @override
  void send(GameEvent event) {
    peer.send(jsonEncode(event.toJson()));
  }

  @override
  Future<void> disconnect() async {
    _connected = false;
    await peer.stop();
  }

  @override
  void dispose() {
    _messageSub?.cancel();
    _events.close();
    peer.dispose();
  }
}
