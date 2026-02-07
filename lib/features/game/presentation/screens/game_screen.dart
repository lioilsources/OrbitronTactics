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
        child: Column(
          children: [
            // Opponent info bar (Black)
            _PlayerInfoBar(
              name: gameState.playerBlack.displayName,
              color: PlayerColor.black,
              isCurrentTurn: gameState.currentTurn == PlayerColor.black,
              hasKing: gameState.playerBlack.hasKing,
              hasQueen: gameState.playerBlack.hasQueen,
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
                        child: const GameBoard(),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 4),

            // Your info bar (White)
            _PlayerInfoBar(
              name: gameState.playerWhite.displayName,
              color: PlayerColor.white,
              isCurrentTurn: gameState.currentTurn == PlayerColor.white,
              hasKing: gameState.playerWhite.hasKing,
              hasQueen: gameState.playerWhite.hasQueen,
            ),

            const SizedBox(height: 8),

            // Game status message
            if (gameState.phase == GamePhase.finished)
              _GameOverBanner(
                winner: gameState.winner!,
                victoryCondition: gameState.victoryCondition!,
                onNewGame: () {
                  ref.read(gameStateProvider.notifier).startNewGame();
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _PlayerInfoBar extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final isWhite = color == PlayerColor.white;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isCurrentTurn
            ? (isWhite ? Colors.white12 : Colors.white10)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isCurrentTurn
            ? Border.all(color: Colors.green.shade400, width: 1.5)
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
            name,
            style: TextStyle(
              color: Colors.white,
              fontWeight: isCurrentTurn ? FontWeight.bold : FontWeight.normal,
              fontSize: 16,
            ),
          ),

          const Spacer(),

          // Royal status indicators
          if (!hasKing)
            const Padding(
              padding: EdgeInsets.only(right: 4),
              child: Text('\u2654', style: TextStyle(fontSize: 18, color: Colors.red)),
            ),
          if (!hasQueen)
            const Padding(
              padding: EdgeInsets.only(right: 4),
              child: Text('\u2655', style: TextStyle(fontSize: 18, color: Colors.red)),
            ),

          // Turn indicator
          if (isCurrentTurn)
            Container(
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

class _GameOverBanner extends StatelessWidget {
  final PlayerColor winner;
  final VictoryCondition victoryCondition;
  final VoidCallback onNewGame;

  const _GameOverBanner({
    required this.winner,
    required this.victoryCondition,
    required this.onNewGame,
  });

  String get _victoryText {
    return victoryCondition.when(
      powerFieldDomination: () => 'Power Field Domination!',
      royalElimination: () => 'Royal Elimination!',
      infiltration: (pos) => 'Infiltration!',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.indigo.shade900,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber, width: 2),
      ),
      child: Column(
        children: [
          Text(
            '${winner == PlayerColor.white ? "White" : "Black"} Wins!',
            style: const TextStyle(
              color: Colors.amber,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _victoryText,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: onNewGame,
            icon: const Icon(Icons.refresh),
            label: const Text('New Game'),
          ),
        ],
      ),
    );
  }
}
