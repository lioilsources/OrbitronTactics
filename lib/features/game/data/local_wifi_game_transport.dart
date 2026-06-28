import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'game_event.dart';
import 'game_transport.dart';

const _kPort = 42069;

/// WebSocket-based transport for local WiFi games.
/// One player acts as host (server), the other as guest (client).
abstract class LocalWifiGameTransport extends GameTransport {
  final _eventsController = StreamController<GameEvent>.broadcast();
  final _statusController = StreamController<ConnectionStatus>.broadcast();
  bool _connected = false;
  WebSocket? _socket;

  @override
  Stream<GameEvent> get events => _eventsController.stream;

  @override
  Stream<ConnectionStatus> get connectionStatus => _statusController.stream;

  @override
  bool get isConnected => _connected;

  @override
  void send(GameEvent event) {
    if (_connected && _socket != null) {
      _socket!.add(jsonEncode(event.toJson()));
    }
  }

  void _onMessage(dynamic data) {
    try {
      final json = jsonDecode(data as String) as Map<String, dynamic>;
      final event = GameEvent.fromJson(json);
      _eventsController.add(event);
    } catch (_) {}
  }

  void _onDone() {
    _connected = false;
    _statusController.add(ConnectionStatus.opponentLeft);
  }

  @override
  Future<void> disconnect() async {
    _connected = false;
    await _socket?.close();
  }

  @override
  void dispose() {
    _connected = false;
    _socket?.close();
    _eventsController.close();
    _statusController.close();
  }
}

/// Host transport: starts a WebSocket server and waits for one guest.
class HostWifiTransport extends LocalWifiGameTransport {
  HttpServer? _server;
  final void Function(String ip)? onReady;

  HostWifiTransport({this.onReady});

  @override
  Future<void> connect() async {
    _server = await HttpServer.bind(InternetAddress.anyIPv4, _kPort);
    final ip = await _localIp();
    onReady?.call('$ip:$_kPort');

    // Accept exactly one connection
    await for (final request in _server!) {
      if (WebSocketTransformer.isUpgradeRequest(request)) {
        final ws = await WebSocketTransformer.upgrade(request);
        _socket = ws;
        _connected = true;
        _statusController.add(ConnectionStatus.connected);
        ws.listen(_onMessage, onDone: _onDone, cancelOnError: false);
        await _server!.close();
        _server = null;
        break;
      }
    }
  }

  @override
  Future<void> disconnect() async {
    await _server?.close(force: true);
    _server = null;
    await super.disconnect();
  }

  @override
  void dispose() {
    _server?.close(force: true);
    super.dispose();
  }

  static Future<String> _localIp() async {
    final interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
      includeLinkLocal: false,
    );
    for (final iface in interfaces) {
      for (final addr in iface.addresses) {
        if (!addr.isLoopback) return addr.address;
      }
    }
    return '127.0.0.1';
  }
}

/// Guest transport: connects to the host's WebSocket server.
class GuestWifiTransport extends LocalWifiGameTransport {
  final String hostAddress;

  GuestWifiTransport({required this.hostAddress});

  @override
  Future<void> connect() async {
    final uri = hostAddress.startsWith('ws://')
        ? hostAddress
        : 'ws://$hostAddress';
    _socket = await WebSocket.connect(uri);
    _connected = true;
    _statusController.add(ConnectionStatus.connected);
    _socket!.listen(_onMessage, onDone: _onDone, cancelOnError: false);
  }
}
