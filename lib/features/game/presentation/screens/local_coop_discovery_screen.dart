import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/game_logic/models/piece.dart';
import '../../data/game_session.dart';
import '../../data/game_transport.dart';
import '../../data/local_network/local_network_game_transport.dart';
import '../../data/local_network/local_network_peer.dart';
import '../../data/local_network/nearby_local_network_peer.dart';
import '../providers/connectivity_providers.dart';
import '../providers/game_state_provider.dart';
import 'game_screen.dart';

/// Discovery + connection screen for the local-network co-op (nearby) mode.
///
/// Both devices advertise and browse. The device that taps a peer becomes the
/// host (white); the invited device becomes the guest (black). Both build a
/// [GameSession] over [LocalNetworkGameTransport] once connected.
///
/// A constant game id is used so both devices generate the same power-field
/// layout (there is no shared lobby id as in the online mode).
class LocalCoopDiscoveryScreen extends ConsumerStatefulWidget {
  final String playerName;

  const LocalCoopDiscoveryScreen({super.key, required this.playerName});

  @override
  ConsumerState<LocalCoopDiscoveryScreen> createState() =>
      _LocalCoopDiscoveryScreenState();
}

class _LocalCoopDiscoveryScreenState
    extends ConsumerState<LocalCoopDiscoveryScreen> {
  static const String _gameId = 'nearby-coop';

  final LocalNetworkPeer _peer = NearbyLocalNetworkPeer();
  StreamSubscription<List<DiscoveredPeer>>? _peerSub;
  StreamSubscription<ConnectionStatus>? _statusSub;

  List<DiscoveredPeer> _peers = const [];
  bool _invited = false;
  bool _launching = false;
  bool _permissionsDenied = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  /// Nearby Connections needs the Bluetooth/nearby-devices runtime permissions
  /// on Android 12+; on iOS the local-network prompt is driven by Info.plist.
  Future<bool> _requestPermissions() async {
    if (!Platform.isAndroid) return true;
    final statuses = await [
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.nearbyWifiDevices,
      Permission.location, // required instead of nearbyWifiDevices on API <= 32
    ].request();
    // Older/newer Android versions report the inapplicable permissions as
    // permanentlyDenied/restricted, so only require the ones actually granted
    // on this OS version: all requested permissions must not be denied by the
    // user (isDenied covers an explicit "don't allow").
    return statuses.values.every((s) => !s.isDenied);
  }

  Future<void> _start() async {
    if (!await _requestPermissions()) {
      if (mounted) setState(() => _permissionsDenied = true);
      return;
    }
    _peerSub = _peer.discoveredPeers.listen((peers) {
      if (mounted) setState(() => _peers = peers);
    });
    _statusSub = _peer.connectionStatus.listen((status) {
      if (status == ConnectionStatus.connected) _launch();
    });
    // Advertise and browse simultaneously.
    await _peer.startAdvertising(widget.playerName);
    await _peer.startDiscovery(widget.playerName);
  }

  Future<void> _invite(DiscoveredPeer peer) async {
    setState(() => _invited = true);
    await _peer.connect(peer);
  }

  Future<void> _launch() async {
    if (_launching || !mounted) return;
    _launching = true;

    // Inviter is white (host); the invited device is black (guest).
    final localColor = _invited ? PlayerColor.white : PlayerColor.black;
    final transport = LocalNetworkGameTransport(_peer);
    final session = GameSession.createLocalNetworkSession(
      gameId: _gameId,
      localColor: localColor,
      localPlayerName: widget.playerName,
      remotePlayerName: 'Opponent',
      transport: transport,
    );
    await session.start();

    if (!mounted) {
      session.dispose();
      return;
    }
    ref.read(gameStateProvider.notifier).attachSession(session);
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const GameScreen()),
      (route) => false,
    );
  }

  @override
  void dispose() {
    _peerSub?.cancel();
    _statusSub?.cancel();
    // The peer is handed to the transport on launch; only dispose it here if
    // we never connected.
    if (!_launching) _peer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If wifi drops while still browsing, back out — a game that has already
    // launched is handled by the transport's disconnect path instead.
    ref.listen(localPlayAllowedProvider, (previous, allowed) {
      if (!allowed && !_launching && mounted) {
        _peer.stop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Wi-Fi is required for local co-op.')),
        );
        Navigator.of(context).pop();
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: const Text('Local Co-op (nearby)'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _invited ? 'Connecting…' : 'Nearby players',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
              ),
              const SizedBox(height: 8),
              if (_permissionsDenied)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.block, size: 48, color: Colors.orange),
                        const SizedBox(height: 16),
                        Text(
                          'Nearby permissions are required\nto find local players.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade400),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: openAppSettings,
                          child: const Text('Open settings'),
                        ),
                      ],
                    ),
                  ),
                )
              else
              Expanded(
                child: _peers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(height: 16),
                            Text(
                              'Searching for nearby players…',
                              style: TextStyle(color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _peers.length,
                        itemBuilder: (context, index) {
                          final peer = _peers[index];
                          return Card(
                            color: const Color(0xFF16213E),
                            child: ListTile(
                              leading: const Icon(Icons.wifi_tethering,
                                  color: Colors.indigo),
                              title: Text(
                                peer.name,
                                style: const TextStyle(color: Colors.white),
                              ),
                              trailing: ElevatedButton(
                                onPressed:
                                    _invited ? null : () => _invite(peer),
                                child: const Text('Connect'),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
