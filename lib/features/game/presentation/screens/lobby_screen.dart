import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/ai/ai_difficulty.dart';
import '../../../../core/game_logic/models/piece.dart';
import '../../data/game_event.dart';
import '../../data/game_repository.dart';
import '../../data/game_session.dart';
import '../providers/game_state_provider.dart';
import '../providers/lobby_providers.dart';
import 'game_screen.dart';
import '../../../comcenter/presentation/screens/comcenter_screen.dart';
import '../../../progress/presentation/providers/fleet_progress_provider.dart';
import '../../../onboarding/presentation/how_to_play_screen.dart';
import '../../../onboarding/presentation/onboarding_provider.dart';
import '../../../telemetry/presentation/telemetry_provider.dart';
import '../../../../l10n/l10n.dart';

// Last single-player setup picked in the lobby, kept for the app session.
final _singlePlayerDifficultyProvider =
    StateProvider<AiDifficulty>((ref) => AiDifficulty.medium);
final _singlePlayerColorProvider =
    StateProvider<PlayerColor>((ref) => PlayerColor.white);

class LobbyScreen extends ConsumerStatefulWidget {
  const LobbyScreen({super.key});

  @override
  ConsumerState<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends ConsumerState<LobbyScreen> {
  final _nameController = TextEditingController();
  bool _isLoading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_nameController.text.isEmpty) {
      _nameController.text = context.l10n.defaultPlayerName;
    }
  }

  @override
  void initState() {
    super.initState();
    // The rules are unusual: a new player sees them before the first game.
    final onboarding = ref.read(onboardingStoreProvider);
    if (!onboarding.howToPlaySeen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        onboarding.markHowToPlaySeen();
        _showHowToPlay();
      });
    }
  }

  void _showHowToPlay() => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const HowToPlayScreen()),
      );

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _trackGameStarted(GameMode mode, [AiDifficulty? difficulty]) =>
      ref.read(telemetryProvider).event('game_started', {
        'mode': mode.name,
        if (difficulty != null) 'difficulty': difficulty.name,
      });

  Future<void> _startSinglePlayer() async {
    final setup =
        await showDialog<({AiDifficulty difficulty, PlayerColor color})>(
      context: context,
      builder: (_) => const _SinglePlayerDialog(),
    );
    if (setup == null || !mounted) return;

    final name = _nameController.text.trim();
    ref.read(gameStateProvider.notifier).startSinglePlayerGame(
          profile: AiProfile.of(setup.difficulty),
          humanColor: setup.color,
          humanName: name.isEmpty ? context.l10n.defaultPlayerName : name,
        );
    _trackGameStarted(GameMode.singlePlayer, setup.difficulty);
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const GameScreen()),
    );
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
          SnackBar(content: Text(context.l10n.errorCreatingGame('$e'))),
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
      _trackGameStarted(GameMode.multiplayer);

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const GameScreen()),
        (route) => false,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                e is GameNotOpen
                    ? context.l10n.gameNotOpen
                    : context.l10n.errorJoiningGame('$e')),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _startLocalGame() {
    ref.read(gameStateProvider.notifier).startNewGame();
    _trackGameStarted(GameMode.hotSeat);
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const GameScreen()),
    );
  }

  Future<void> _hostLocalWifi() async {
    setState(() => _isLoading = true);
    try {
      final playerName = _nameController.text.trim().isEmpty
          ? context.l10n.defaultHostName
          : _nameController.text.trim();

      final session = GameSession.createLocalWifiHostSession(
        localPlayerName: playerName,
        onReady: (addr) {
          if (mounted) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (_) => _WifiHostDialog(address: addr),
            );
          }
        },
      );

      await session.start(); // blocks until guest connects

      if (!mounted) {
        session.dispose();
        return;
      }
      Navigator.of(context).pop(); // close dialog
      ref.read(gameStateProvider.notifier).attachLocalWifiSession(session);
      _trackGameStarted(GameMode.localWifi);
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const GameScreen()),
        (route) => false,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.wifiHostError('$e'))),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _joinLocalWifi() async {
    final ip = await showDialog<String>(
      context: context,
      builder: (_) => const _WifiJoinDialog(),
    );
    if (ip == null || ip.isEmpty || !mounted) return;

    setState(() => _isLoading = true);
    try {
      final playerName = _nameController.text.trim().isEmpty
          ? context.l10n.defaultGuestName
          : _nameController.text.trim();

      final session = GameSession.createLocalWifiGuestSession(
        hostAddress: ip.contains(':') ? ip : '$ip:42069',
        localPlayerName: playerName,
      );
      await session.start();

      if (!mounted) {
        session.dispose();
        return;
      }
      ref.read(gameStateProvider.notifier).attachLocalWifiSession(session);
      _trackGameStarted(GameMode.localWifi);
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const GameScreen()),
        (route) => false,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.wifiJoinError('$e'))),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final waitingGames = ref.watch(waitingGamesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: Text(context.l10n.appTitle),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: context.l10n.howToPlayTooltip,
            onPressed: _showHowToPlay,
          ),
          IconButton(
            icon: const Icon(Icons.military_tech),
            tooltip: context.l10n.comcenterTooltip,
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
                  labelText: context.l10n.lobbyYourName,
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

              // Single player against the AI
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _startSinglePlayer,
                icon: const Icon(Icons.smart_toy),
                label: Text(context.l10n.lobbySinglePlayer),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
              const SizedBox(height: 12),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _createGame,
                      icon: const Icon(Icons.add),
                      label: Text(context.l10n.lobbyCreateGame),
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
                      label: Text(context.l10n.lobbyLocalGame),
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

              // Local WiFi buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : _hostLocalWifi,
                      icon: const Icon(Icons.wifi, size: 16),
                      label: Text(context.l10n.lobbyHostWifi),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.greenAccent,
                        side: const BorderSide(color: Colors.green),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : _joinLocalWifi,
                      icon: const Icon(Icons.wifi_find, size: 16),
                      label: Text(context.l10n.lobbyJoinWifi),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.greenAccent,
                        side: const BorderSide(color: Colors.green),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                context.l10n.lobbyWifiNote,
                style: TextStyle(color: Colors.green.shade700, fontSize: 11),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Waiting games list
              Text(
                context.l10n.lobbyOpenGames,
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
                          context.l10n.lobbyNoOpenGames,
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
                            ? context.l10n.lobbyJustNow
                            : context.l10n.lobbyMinutesAgo(age.inMinutes);

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
                              child: Text(context.l10n.join),
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
                          context.l10n.lobbyCannotConnect,
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

class _SinglePlayerDialog extends ConsumerWidget {
  const _SinglePlayerDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final difficulty = ref.watch(_singlePlayerDifficultyProvider);
    final color = ref.watch(_singlePlayerColorProvider);

    return AlertDialog(
      backgroundColor: const Color(0xFF1A1A2E),
      title: Row(
        children: [
          Icon(Icons.smart_toy, color: Colors.deepPurpleAccent),
          SizedBox(width: 8),
          Text(context.l10n.lobbySinglePlayer,
              style: const TextStyle(color: Colors.white)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _DialogLabel(context.l10n.dialogDifficulty),
          SegmentedButton<AiDifficulty>(
            segments: [
              ButtonSegment(
                  value: AiDifficulty.easy,
                  label: Text(context.l10n.difficultyEasy)),
              ButtonSegment(
                  value: AiDifficulty.medium,
                  label: Text(context.l10n.difficultyMedium)),
              ButtonSegment(
                  value: AiDifficulty.hard,
                  label: Text(context.l10n.difficultyHard)),
            ],
            selected: {difficulty},
            showSelectedIcon: false,
            onSelectionChanged: (selection) => ref
                .read(_singlePlayerDifficultyProvider.notifier)
                .state = selection.first,
          ),
          const SizedBox(height: 12),
          _DialogLabel(context.l10n.dialogAiFleets),
          for (final option in AiDifficulty.values)
            _FleetRow(difficulty: option, selected: option == difficulty),
          const SizedBox(height: 16),
          _DialogLabel(context.l10n.dialogYourColor),
          SegmentedButton<PlayerColor>(
            segments: [
              ButtonSegment(
                  value: PlayerColor.white,
                  label: Text(context.l10n.colorWhite)),
              ButtonSegment(
                  value: PlayerColor.black,
                  label: Text(context.l10n.colorBlack)),
            ],
            selected: {color},
            showSelectedIcon: false,
            onSelectionChanged: (selection) => ref
                .read(_singlePlayerColorProvider.notifier)
                .state = selection.first,
          ),
          const SizedBox(height: 8),
          Text(
            color == PlayerColor.white
                ? context.l10n.youMoveFirst
                : context.l10n.aiMovesFirst,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.l10n.cancel),
        ),
        ElevatedButton.icon(
          onPressed: () => Navigator.of(context)
              .pop((difficulty: difficulty, color: color)),
          icon: const Icon(Icons.play_arrow),
          label: Text(context.l10n.start),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}

/// One AI fleet's progress: upgrade levels, unspent credits and record.
class _FleetRow extends ConsumerWidget {
  final AiDifficulty difficulty;
  final bool selected;

  const _FleetRow({required this.difficulty, required this.selected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fleet =
        ref.watch(fleetProgressProvider(AiProfile.of(difficulty).identity));
    final style = TextStyle(
      color: selected ? Colors.white : Colors.grey.shade600,
      fontSize: 12,
      fontWeight: selected ? FontWeight.bold : FontWeight.normal,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 64,
            child: Text(
              switch (difficulty) {
                AiDifficulty.easy => context.l10n.difficultyEasy,
                AiDifficulty.medium => context.l10n.difficultyMedium,
                AiDifficulty.hard => context.l10n.difficultyHard,
              },
              style: style,
            ),
          ),
          Icon(
            Icons.star,
            size: 12,
            color: selected ? Colors.amber : Colors.grey.shade700,
          ),
          const SizedBox(width: 2),
          Text('${fleet.totalLevels}', style: style),
          const Spacer(),
          Text(context.l10n.credits(fleet.credits), style: style),
          const SizedBox(width: 12),
          Text(context.l10n.fleetRecord(fleet.wins, fleet.losses),
              style: style),
        ],
      ),
    );
  }
}

class _DialogLabel extends StatelessWidget {
  final String text;

  const _DialogLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
      ),
    );
  }
}

class _WifiHostDialog extends StatelessWidget {
  final String address;

  const _WifiHostDialog({required this.address});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1A1A2E),
      title: Row(
        children: [
          const Icon(Icons.wifi, color: Colors.greenAccent),
          const SizedBox(width: 8),
          Text(context.l10n.wifiHostTitle,
              style: const TextStyle(color: Colors.white)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            context.l10n.wifiShareAddress,
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 12),
          SelectableText(
            address,
            style: const TextStyle(
              color: Colors.greenAccent,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 16),
          const CircularProgressIndicator(color: Colors.greenAccent),
          const SizedBox(height: 8),
          Text(
            context.l10n.wifiWaitingGuest,
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _WifiJoinDialog extends StatefulWidget {
  const _WifiJoinDialog();

  @override
  State<_WifiJoinDialog> createState() => _WifiJoinDialogState();
}

class _WifiJoinDialogState extends State<_WifiJoinDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1A1A2E),
      title: Row(
        children: [
          const Icon(Icons.wifi_find, color: Colors.greenAccent),
          const SizedBox(width: 8),
          Text(context.l10n.wifiJoinTitle,
              style: const TextStyle(color: Colors.white)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            context.l10n.wifiEnterIp,
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            style: const TextStyle(color: Colors.white),
            keyboardType: TextInputType.url,
            decoration: InputDecoration(
              hintText: '192.168.1.x:42069',
              hintStyle: TextStyle(color: Colors.grey.shade600),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey.shade700),
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.greenAccent),
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.l10n.cancel),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          child: Text(context.l10n.connect),
        ),
      ],
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
      remotePlayerName: context.l10n.defaultOpponentName,
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
        title: Text(context.l10n.waitingForOpponent),
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
              context.l10n.gameIdLabel,
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
              context.l10n.waitingForPlayer,
              style: TextStyle(color: Colors.grey.shade400),
            ),
          ],
        ),
      ),
    );
  }
}
