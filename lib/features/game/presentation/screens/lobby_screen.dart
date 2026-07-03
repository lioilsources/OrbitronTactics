import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/game_logic/models/piece.dart';
import '../../data/game_event.dart';
import '../../data/game_repository.dart';
import '../../data/game_session.dart';
import '../../../comcenter/presentation/screens/comcenter_screen.dart';
import '../providers/connectivity_providers.dart';
import '../providers/game_state_provider.dart';
import '../providers/lobby_providers.dart';
import 'game_screen.dart';
import 'local_coop_discovery_screen.dart';

class LobbyScreen extends ConsumerStatefulWidget {
  const LobbyScreen({super.key});

  @override
  ConsumerState<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends ConsumerState<LobbyScreen> {
  final _nameController = TextEditingController(text: 'Player');
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _createGame() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(gameRepositoryProvider);
      final playerName = _nameController.text.trim();
      if (playerName.isEmpty) return;

      final gameId = await repo.createGame(playerName: playerName);

      if (!mounted) return;

      // Navigate to waiting screen, then start game when opponent joins
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => _WaitingScreen(
            gameId: gameId,
            playerName: playerName,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating game: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _joinGame(GameLobbyEntry entry) async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(gameRepositoryProvider);
      final playerName = _nameController.text.trim();
      if (playerName.isEmpty) return;

      await repo.joinGame(gameId: entry.gameId, playerName: playerName);

      if (!mounted) return;

      // Create session as black (joiner is always black)
      final session = GameSession.createOnlineSession(
        gameId: entry.gameId,
        localColor: PlayerColor.black,
        localPlayerName: playerName,
        remotePlayerName: entry.hostName,
        client: Supabase.instance.client,
      );
      await session.start();

      // Notify the host that we've joined
      session.transport.send(PlayerJoinedEvent(
        color: PlayerColor.black,
        displayName: playerName,
      ));

      if (!mounted) {
        session.dispose();
        return;
      }

      ref.read(gameStateProvider.notifier).attachSession(session);

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const GameScreen()),
        (route) => false,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error joining game: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _startLocalGame() {
    ref.read(gameStateProvider.notifier).startNewGame();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const GameScreen()),
    );
  }

  void _startNearbyCoop() {
    final playerName = _nameController.text.trim();
    if (playerName.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LocalCoopDiscoveryScreen(playerName: playerName),
      ),
    );
  }

  /// The nearby plugin only supports Android/iOS.
  bool get _isMobilePlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  Widget build(BuildContext context) {
    final waitingGames = ref.watch(waitingGamesProvider);
    final localPlayAllowed = ref.watch(localPlayAllowedProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: const Text('OrbitronTactics'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'ComCenter — unit upgrades',
            icon: const Icon(Icons.rocket_launch, color: Colors.amber),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ComcenterScreen()),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Player name input
              TextField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Your name',
                  labelStyle: TextStyle(color: Colors.grey.shade400),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey.shade700),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.indigo),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _createGame,
                      icon: const Icon(Icons.add),
                      label: const Text('Create Game'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : _startLocalGame,
                      icon: const Icon(Icons.people),
                      label: const Text('Local Game'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: BorderSide(color: Colors.grey.shade700),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Local-network co-op (Archon-style real-time battles on
              // capture). Requires wifi — on cellular data the game is
              // turn-based cloud play only.
              if (_isMobilePlatform) ...[
                OutlinedButton.icon(
                  onPressed: (_isLoading || !localPlayAllowed)
                      ? null
                      : _startNearbyCoop,
                  icon: Icon(
                      localPlayAllowed ? Icons.wifi_tethering : Icons.wifi_off),
                  label: Text(localPlayAllowed
                      ? 'Local Co-op (nearby) — battles'
                      : 'Local Co-op — requires Wi-Fi'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: BorderSide(color: Colors.indigo.shade400),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
                const SizedBox(height: 24),
              ] else
                const SizedBox(height: 12),

              // Waiting games list
              Text(
                'Open Games',
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),

              Expanded(
                child: waitingGames.when(
                  data: (games) {
                    if (games.isEmpty) {
                      return Center(
                        child: Text(
                          'No open games.\nCreate one to start!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      );
                    }
                    return ListView.builder(
                      itemCount: games.length,
                      itemBuilder: (context, index) {
                        final game = games[index];
                        final age = DateTime.now().difference(game.createdAt);
                        final ageText = age.inMinutes < 1
                            ? 'just now'
                            : '${age.inMinutes}m ago';

                        return Card(
                          color: const Color(0xFF16213E),
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Colors.indigo,
                              child:
                                  Icon(Icons.person, color: Colors.white),
                            ),
                            title: Text(
                              game.hostName,
                              style: const TextStyle(color: Colors.white),
                            ),
                            subtitle: Text(
                              ageText,
                              style: TextStyle(color: Colors.grey.shade500),
                            ),
                            trailing: ElevatedButton(
                              onPressed: _isLoading
                                  ? null
                                  : () => _joinGame(game),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green.shade700,
                              ),
                              child: const Text('Join'),
                            ),
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  error: (err, _) => Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.cloud_off,
                            color: Colors.grey.shade600, size: 48),
                        const SizedBox(height: 8),
                        Text(
                          'Cannot connect to server',
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$err',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 11,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: LinearProgressIndicator(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Screen shown while waiting for an opponent to join.
class _WaitingScreen extends ConsumerStatefulWidget {
  final String gameId;
  final String playerName;

  const _WaitingScreen({
    required this.gameId,
    required this.playerName,
  });

  @override
  ConsumerState<_WaitingScreen> createState() => _WaitingScreenState();
}

class _WaitingScreenState extends ConsumerState<_WaitingScreen> {
  GameSession? _session;
  StreamSubscription<GameEvent>? _joinSub;

  @override
  void initState() {
    super.initState();
    _setupSession();
  }

  Future<void> _setupSession() async {
    // Host is always white
    final session = GameSession.createOnlineSession(
      gameId: widget.gameId,
      localColor: PlayerColor.white,
      localPlayerName: widget.playerName,
      remotePlayerName: 'Opponent',
      client: Supabase.instance.client,
    );

    await session.start();
    _session = session;

    // Listen for opponent joining via broadcast
    _joinSub = session.transport.events.listen((event) {
      if (event is PlayerJoinedEvent && mounted) {
        // Opponent joined — attach session and update their name
        final notifier = ref.read(gameStateProvider.notifier);
        notifier.attachSession(session);
        notifier.updateRemotePlayerName(event.displayName);

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const GameScreen()),
          (route) => false,
        );
      }
    });
  }

  @override
  void dispose() {
    _joinSub?.cancel();
    // Only dispose if we haven't handed the session to the provider
    if (ref.read(gameStateProvider.notifier).session != _session) {
      _session?.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: const Text('Waiting for opponent'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            Text(
              'Game ID:',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            ),
            const SizedBox(height: 4),
            SelectableText(
              widget.gameId,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Waiting for another player to join...',
              style: TextStyle(color: Colors.grey.shade400),
            ),
          ],
        ),
      ),
    );
  }
}
