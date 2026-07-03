import '../game_transport.dart';

/// A peer discovered on the local network / nearby radios.
class DiscoveredPeer {
  final String id;
  final String name;

  const DiscoveredPeer({required this.id, required this.name});

  @override
  bool operator ==(Object other) =>
      other is DiscoveredPeer && other.id == id && other.name == name;

  @override
  int get hashCode => Object.hash(id, name);
}

/// Platform-agnostic local peer-to-peer link used for the local-network co-op
/// mode. Concrete implementations wrap Android Nearby Connections and iOS
/// MultipeerConnectivity (e.g. via the `flutter_nearby_connections` package).
///
/// The link carries opaque string payloads; [LocalNetworkGameTransport]
/// encodes [GameEvent]s as JSON on top of it.
///
/// Note: Nearby Connections and MultipeerConnectivity do not interoperate, so
/// a session is Android↔Android or iOS↔iOS only.
abstract class LocalNetworkPeer {
  /// Peers currently visible while discovering.
  Stream<List<DiscoveredPeer>> get discoveredPeers;

  /// Incoming raw string payloads from the connected peer.
  Stream<String> get messages;

  /// Connection lifecycle for the active peer.
  Stream<ConnectionStatus> get connectionStatus;

  /// Make this device visible to others under [displayName].
  Future<void> startAdvertising(String displayName);

  /// Begin scanning for advertising peers.
  Future<void> startDiscovery(String displayName);

  /// Request a connection to a discovered [peer].
  Future<void> connect(DiscoveredPeer peer);

  /// Send a raw payload to the connected peer.
  void send(String message);

  /// Stop advertising/discovery and tear down the active connection.
  Future<void> stop();

  /// Release all resources.
  void dispose();
}
