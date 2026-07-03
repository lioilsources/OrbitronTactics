import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/game_logic/models/piece.dart';
import '../../data/game_session.dart';
import '../../data/game_transport.dart';
import '../../data/local_network/local_network_game_transport.dart';
import '../../data/local_network/local_network_peer.dart';
import '../../data/local_network/nearby_local_network_peer.dart';
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

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
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
