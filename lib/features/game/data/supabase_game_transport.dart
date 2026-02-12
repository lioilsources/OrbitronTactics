import 'dart:async';
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'game_event.dart';
import 'game_transport.dart';

/// Supabase Broadcast transport for real-time multiplayer over the internet.
///
/// Uses Supabase Realtime Broadcast channels — ephemeral, low-latency
/// message passing between connected clients. No data is persisted
/// in the channel itself (game state is managed by [GameSession]).
///
/// Also uses Supabase Presence to detect opponent disconnects.
class SupabaseGameTransport extends GameTransport {
  final String gameId;
  final String localColorName;
  final SupabaseClient _client;
  final _controller = StreamController<GameEvent>.broadcast();
  final _connectionController = StreamController<ConnectionStatus>.broadcast();

  RealtimeChannel? _channel;
  bool _connected = false;

  SupabaseGameTransport({
    required this.gameId,
    required this.localColorName,
    required SupabaseClient client,
  }) : _client = client;

  @override
  Stream<GameEvent> get events => _controller.stream;

  @override
  Stream<ConnectionStatus> get connectionStatus =>
      _connectionController.stream;

  @override
  bool get isConnected => _connected;

  @override
  Future<void> connect() async {
    _channel = _client.channel(
      'game:$gameId',
      opts: RealtimeChannelConfig(self: false, key: localColorName),
    );

    _channel!.onBroadcast(
      event: 'game_event',
      callback: (payload) {
        try {
          final eventData = payload['data'];
          if (eventData == null) return;

          final jsonStr = jsonEncode(eventData);
          final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
          final event = GameEvent.fromJson(decoded);
          _controller.add(event);
        } catch (e) {
          _controller.addError(e);
        }
      },
    );

    // Presence: detect opponent disconnect
    _channel!.onPresenceLeave((payload) {
      for (final presence in payload.leftPresences) {
        final color = presence.payload['color'] as String?;
        if (color != null && color != localColorName) {
          _connectionController.add(ConnectionStatus.opponentLeft);
        }
      }
    });

    final completer = Completer<void>();

    _channel!.subscribe((status, error) {
      if (status == RealtimeSubscribeStatus.subscribed) {
        _connected = true;
        _connectionController.add(ConnectionStatus.connected);
        if (!completer.isCompleted) completer.complete();
      } else if (status == RealtimeSubscribeStatus.channelError ||
          status == RealtimeSubscribeStatus.timedOut) {
        _connected = false;
        _connectionController.add(ConnectionStatus.disconnected);
        if (!completer.isCompleted) {
          completer.completeError(
            error ?? Exception('Failed to subscribe: $status'),
          );
        }
      } else if (status == RealtimeSubscribeStatus.closed) {
        _connected = false;
        _connectionController.add(ConnectionStatus.disconnected);
      }
    });

    await completer.future;

    // Track presence after subscribing
    await _channel!.track({'color': localColorName});
  }

  @override
  void send(GameEvent event) {
    if (_channel == null || !_connected) return;

    final jsonStr = jsonEncode(event.toJson());
    final cleanMap = jsonDecode(jsonStr) as Map<String, dynamic>;

    _channel!.sendBroadcastMessage(
      event: 'game_event',
      payload: {'data': cleanMap},
    );
  }

  @override
  Future<void> disconnect() async {
    _connected = false;
    if (_channel != null) {
      await _channel!.untrack();
      await _channel!.unsubscribe();
      _channel = null;
    }
  }

  @override
  void dispose() {
    _connected = false;
    _channel?.untrack();
    _channel?.unsubscribe();
    _channel = null;
    _controller.close();
    _connectionController.close();
  }
}
