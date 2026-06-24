import 'dart:async';

import 'package:flutter_nearby_connections/flutter_nearby_connections.dart';

import '../game_transport.dart';
import 'local_network_peer.dart';

/// [LocalNetworkPeer] backed by the `flutter_nearby_connections` package, which
/// wraps Android Nearby Connections and iOS MultipeerConnectivity behind one
/// API.
///
/// NOTE: this binding is written against the package's documented API but has
/// not been verified on a device in this environment. Validate the exact
/// `NearbyService` method/field names against the installed package version,
/// and test on two physical devices of the **same** platform (the two radios
/// do not interoperate across Android/iOS).
class NearbyLocalNetworkPeer implements LocalNetworkPeer {
  // Bonjour service type: lowercase letters/digits/hyphens, <= 15 chars.
  static const String _serviceType = 'orbitrontctic';

  final NearbyService _service = NearbyService();

  final StreamController<List<DiscoveredPeer>> _discovered =
      StreamController<List<DiscoveredPeer>>.broadcast();
  final StreamController<String> _messages =
      StreamController<String>.broadcast();
  final StreamController<ConnectionStatus> _status =
      StreamController<ConnectionStatus>.broadcast();

  StreamSubscription? _stateSub;
  StreamSubscription? _dataSub;
  String? _connectedDeviceId;
  bool _wasConnected = false;

  Future<void> _init(String displayName) async {
    await _service.init(
      serviceType: _serviceType,
      deviceName: displayName,
      strategy: Strategy.P2P_Cluster,
      callback: (isRunning) async {
        if (isRunning) {
          await _service.stopAdvertisingPeer();
          await _service.stopBrowsingForPeers();
          await _service.startAdvertisingPeer();
          await _service.startBrowsingForPeers();
        }
      },
    );

    _stateSub = _service.stateChangedSubscription(callback: (devices) {
      final discovered = <DiscoveredPeer>[];
      Device? connected;
      for (final d in devices) {
        switch (d.state) {
          case SessionState.notConnected:
            discovered.add(DiscoveredPeer(id: d.deviceId, name: d.deviceName));
          case SessionState.connecting:
            break;
          case SessionState.connected:
            connected = d;
        }
      }
      _discovered.add(discovered);

      if (connected != null) {
        _connectedDeviceId = connected.deviceId;
        if (!_wasConnected) {
          _wasConnected = true;
          _status.add(ConnectionStatus.connected);
        }
      } else if (_wasConnected) {
        _wasConnected = false;
        _connectedDeviceId = null;
        _status.add(ConnectionStatus.opponentLeft);
      }
    });

    _dataSub = _service.dataReceivedSubscription(callback: (data) {
      // data is a Map with 'deviceId' and 'message'.
      final message = data['message'];
      if (message is String) _messages.add(message);
    });
  }

  @override
  Stream<List<DiscoveredPeer>> get discoveredPeers => _discovered.stream;

  @override
  Stream<String> get messages => _messages.stream;

  @override
  Stream<ConnectionStatus> get connectionStatus => _status.stream;

  @override
  Future<void> startAdvertising(String displayName) => _init(displayName);

  @override
  Future<void> startDiscovery(String displayName) => _init(displayName);

  @override
  Future<void> connect(DiscoveredPeer peer) async {
    await _service.invitePeer(deviceID: peer.id, deviceName: peer.name);
  }

  @override
  void send(String message) {
    final id = _connectedDeviceId;
    if (id != null) {
      _service.sendMessage(id, message);
    }
  }

  @override
  Future<void> stop() async {
    await _service.stopAdvertisingPeer();
    await _service.stopBrowsingForPeers();
  }

  @override
  void dispose() {
    _stateSub?.cancel();
    _dataSub?.cancel();
    _discovered.close();
    _messages.close();
    _status.close();
  }
}
