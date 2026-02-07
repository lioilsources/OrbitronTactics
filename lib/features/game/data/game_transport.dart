import 'dart:async';
import 'game_event.dart';

/// Abstract transport layer for game communication.
///
/// Implementations:
/// - [LocalGameTransport] — in-memory, same-process (hot-seat / testing)
/// - Future: SupabaseGameTransport, WebSocketGameTransport, etc.
abstract class GameTransport {
  /// Stream of incoming events from the other player.
  Stream<GameEvent> get events;

  /// Send an event to the other player.
  void send(GameEvent event);

  /// Whether the transport is currently connected.
  bool get isConnected;

  /// Connect to the game channel.
  Future<void> connect();

  /// Disconnect from the game channel.
  Future<void> disconnect();

  /// Dispose resources.
  void dispose();
}

/// In-memory transport for local play and testing.
/// Two instances are paired: what one sends, the other receives.
class LocalGameTransport extends GameTransport {
  final _controller = StreamController<GameEvent>.broadcast();
  LocalGameTransport? _peer;
  bool _connected = false;

  @override
  Stream<GameEvent> get events => _controller.stream;

  @override
  bool get isConnected => _connected;

  @override
  void send(GameEvent event) {
    if (_peer != null && _peer!._connected) {
      _peer!._controller.add(event);
    }
  }

  @override
  Future<void> connect() async {
    _connected = true;
  }

  @override
  Future<void> disconnect() async {
    _connected = false;
  }

  @override
  void dispose() {
    _connected = false;
    _controller.close();
  }

  /// Create a linked pair of local transports.
  static (LocalGameTransport, LocalGameTransport) createPair() {
    final a = LocalGameTransport();
    final b = LocalGameTransport();
    a._peer = b;
    b._peer = a;
    return (a, b);
  }
}
