import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/game_logic/models/game_phase.dart';
import '../../../../core/game_logic/models/piece.dart';
import '../../../../core/game_logic/models/victory_condition.dart';
import '../providers/game_state_provider.dart';
import '../widgets/board/game_board.dart';

class GameScreen extends ConsumerWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameStateProvider);
    final notifier = ref.read(gameStateProvider.notifier);
    final localColor = notifier.localColor;
    final flipBoard = localColor == PlayerColor.black;

    // In multiplayer, local player is always at the bottom.
    // In hot-seat, white is at the bottom.
    final bottomColor = flipBoard ? PlayerColor.black : PlayerColor.white;
    final topColor = bottomColor.opposite;

    final topPlayer = topColor == PlayerColor.white
        ? gameState.playerWhite
        : gameState.playerBlack;
    final bottomPlayer = bottomColor == PlayerColor.white
        ? gameState.playerWhite
        : gameState.playerBlack;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: const Text('OrbitronTactics'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(gameStateProvider.notifier).startNewGame();
            },
            tooltip: 'New Game',
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // Main game UI
            Column(
              children: [
                // Opponent info bar (top)
                _PlayerInfoBar(
                  name: topPlayer.displayName,
                  color: topColor,
                  isCurrentTurn: gameState.currentTurn == topColor,
                  hasKing: topPlayer.hasKing,
                  hasQueen: topPlayer.hasQueen,
                ),

                const SizedBox(height: 4),

                // Power field status
                _PowerFieldStatusBar(
                  whitePowerFields: gameState.board.powerFieldCount(PlayerColor.white),
                  blackPowerFields: gameState.board.powerFieldCount(PlayerColor.black),
                  total: gameState.board.powerFields.length,
                ),

                const SizedBox(height: 4),

                // Game board
                Expanded(
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.brown.shade800,
                              width: 3,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: GameBoard(flipBoard: flipBoard),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 4),

                // Your info bar (bottom)
                _PlayerInfoBar(
                  name: bottomPlayer.displayName,
                  color: bottomColor,
                  isCurrentTurn: gameState.currentTurn == bottomColor,
                  hasKing: bottomPlayer.hasKing,
                  hasQueen: bottomPlayer.hasQueen,
                ),

                const SizedBox(height: 8),
              ],
            ),

            // Game over overlay (on top of everything)
            if (gameState.phase == GamePhase.finished)
              _GameOverOverlay(
                winner: gameState.winner!,
                victoryCondition: gameState.victoryCondition!,
                onNewGame: () {
                  ref.read(gameStateProvider.notifier).startNewGame();
                },
                onBackToLobby: () {
                  Navigator.of(context).maybePop();
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _PlayerInfoBar extends StatefulWidget {
  final String name;
  final PlayerColor color;
  final bool isCurrentTurn;
  final bool hasKing;
  final bool hasQueen;

  const _PlayerInfoBar({
    required this.name,
    required this.color,
    required this.isCurrentTurn,
    required this.hasKing,
    required this.hasQueen,
  });

  @override
  State<_PlayerInfoBar> createState() => _PlayerInfoBarState();
}

class _PlayerInfoBarState extends State<_PlayerInfoBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseScale;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _pulseScale = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    if (widget.isCurrentTurn) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _PlayerInfoBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isCurrentTurn && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.isCurrentTurn && _pulseController.isAnimating) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWhite = widget.color == PlayerColor.white;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: widget.isCurrentTurn
            ? Colors.green.withValues(alpha: 0.15)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: widget.isCurrentTurn
              ? Colors.green.shade400
              : Colors.transparent,
          width: 2,
        ),
        boxShadow: widget.isCurrentTurn
            ? [
                BoxShadow(
                  color: Colors.green.withValues(alpha: 0.3),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          // Player color indicator
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: isWhite ? Colors.white : Colors.grey.shade800,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey),
            ),
          ),
          const SizedBox(width: 8),

          // Player name
          Text(
            widget.name,
            style: TextStyle(
              color: Colors.white,
              fontWeight: widget.isCurrentTurn ? FontWeight.bold : FontWeight.normal,
              fontSize: 16,
            ),
          ),

          const Spacer(),

          // Royal status indicators
          if (!widget.hasKing)
            const Padding(
              padding: EdgeInsets.only(right: 4),
              child: Text('\u2654', style: TextStyle(fontSize: 18, color: Colors.red)),
            ),
          if (!widget.hasQueen)
            const Padding(
              padding: EdgeInsets.only(right: 4),
              child: Text('\u2655', style: TextStyle(fontSize: 18, color: Colors.red)),
            ),

          // Turn indicator with pulse animation
          if (widget.isCurrentTurn)
            ScaleTransition(
              scale: _pulseScale,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.shade700,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'TURN',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PowerFieldStatusBar extends StatelessWidget {
  final int whitePowerFields;
  final int blackPowerFields;
  final int total;

  const _PowerFieldStatusBar({
    required this.whitePowerFields,
    required this.blackPowerFields,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final neutral = total - whitePowerFields - blackPowerFields;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.diamond_outlined, size: 16, color: Colors.cyan),
          const SizedBox(width: 4),
          Text(
            'Power Fields: ',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
          ),
          Text(
            '$whitePowerFields',
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
          ),
          Text(
            ' / $neutral / ',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
          ),
          Text(
            '$blackPowerFields',
            style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold),
          ),
          Text(
            '  (need $total)',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

/// Full-screen animated overlay shown when the game ends.
class _GameOverOverlay extends StatefulWidget {
  final PlayerColor winner;
  final VictoryCondition victoryCondition;
  final VoidCallback onNewGame;
  final VoidCallback onBackToLobby;

  const _GameOverOverlay({
    required this.winner,
    required this.victoryCondition,
    required this.onNewGame,
    required this.onBackToLobby,
  });

  @override
  State<_GameOverOverlay> createState() => _GameOverOverlayState();
}

class _GameOverOverlayState extends State<_GameOverOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  IconData get _victoryIcon {
    return widget.victoryCondition.when(
      powerFieldDomination: () => Icons.diamond,
      royalElimination: () => Icons.dangerous,
      infiltration: (_) => Icons.flag,
    );
  }

  String get _victoryText {
    return widget.victoryCondition.when(
      powerFieldDomination: () => 'Power Field Domination!',
      royalElimination: () => 'Royal Elimination!',
      infiltration: (_) => 'Pawn Infiltration!',
    );
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        color: Colors.black54,
        child: Center(
          child: SlideTransition(
            position: _slideAnimation,
            child: Container(
              margin: const EdgeInsets.all(32),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.amber, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _victoryIcon,
                    size: 48,
                    color: Colors.amber,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${widget.winner == PlayerColor.white ? "White" : "Black"} Wins!',
                    style: const TextStyle(
                      color: Colors.amber,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _victoryText,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton.icon(
                        onPressed: widget.onNewGame,
                        icon: const Icon(Icons.refresh),
                        label: const Text('New Game'),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: widget.onBackToLobby,
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Back'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white70,
                          side: const BorderSide(color: Colors.white30),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
