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
class SupabaseGameTransport extends GameTransport {
  final String gameId;
  final SupabaseClient _client;
  final _controller = StreamController<GameEvent>.broadcast();

  RealtimeChannel? _channel;
  bool _connected = false;

  SupabaseGameTransport({
    required this.gameId,
    required SupabaseClient client,
  }) : _client = client;

  @override
  Stream<GameEvent> get events => _controller.stream;

  @override
  bool get isConnected => _connected;

  @override
  Future<void> connect() async {
    _channel = _client.channel(
      'game:$gameId',
      opts: const RealtimeChannelConfig(self: false),
    );

    _channel!.onBroadcast(
      event: 'game_event',
      callback: (payload) {
        try {
          // Payload from broadcast comes as Map<String, dynamic>
          // The actual event data is nested under our structure
          final eventData = payload['data'];
          if (eventData == null) return;

          // Round-trip through JSON to ensure proper Map types
          final jsonStr = jsonEncode(eventData);
          final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
          final event = GameEvent.fromJson(decoded);
          _controller.add(event);
        } catch (e) {
          _controller.addError(e);
        }
      },
    );

    final completer = Completer<void>();

    _channel!.subscribe((status, error) {
      if (status == RealtimeSubscribeStatus.subscribed) {
        _connected = true;
        if (!completer.isCompleted) completer.complete();
      } else if (status == RealtimeSubscribeStatus.channelError ||
          status == RealtimeSubscribeStatus.timedOut) {
        _connected = false;
        if (!completer.isCompleted) {
          completer.completeError(
            error ?? Exception('Failed to subscribe: $status'),
          );
        }
      } else if (status == RealtimeSubscribeStatus.closed) {
        _connected = false;
      }
    });

    return completer.future;
  }

  @override
  void send(GameEvent event) {
    if (_channel == null || !_connected) return;

    // jsonEncode → jsonDecode to ensure clean Map<String, dynamic>
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
      await _channel!.unsubscribe();
      _channel = null;
    }
  }

  @override
  void dispose() {
    _connected = false;
    _channel?.unsubscribe();
    _channel = null;
    _controller.close();
  }
}
