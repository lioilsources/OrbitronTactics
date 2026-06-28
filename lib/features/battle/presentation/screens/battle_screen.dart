import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/game_logic/models/battle_state.dart';
import '../../../../core/game_logic/models/piece.dart';
import '../../../game/presentation/providers/game_state_provider.dart';
import '../providers/battle_state_provider.dart';
import '../widgets/battle_arena_painter.dart';
import '../widgets/shield_button.dart';
import '../widgets/unit_combat_panel.dart';

class BattleScreen extends ConsumerStatefulWidget {
  final PlayerColor? attackerColor;

  const BattleScreen({super.key, this.attackerColor});

  @override
  ConsumerState<BattleScreen> createState() => _BattleScreenState();
}

class _BattleScreenState extends ConsumerState<BattleScreen> {
  @override
  Widget build(BuildContext context) {
    final battleState = ref.watch(battleStateProvider);
    final localColor = ref.read(gameStateProvider.notifier).localColor;
    final attackerColor = widget.attackerColor;

    if (battleState == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF0D0D1A),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Determine which side is local (always shown at bottom/left)
    final isLocalAttacker = localColor == attackerColor;
    final localUnit =
        isLocalAttacker ? battleState.attacker : battleState.defender;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _BattleHeader(battleState: battleState),
                const SizedBox(height: 8),
                // Combat units row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      UnitCombatPanel(unit: battleState.attacker, isLeft: true),
                      Column(
                        children: [
                          const SizedBox(height: 12),
                          Text(
                            'VS',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.3),
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      UnitCombatPanel(unit: battleState.defender, isLeft: false),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Arena
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CustomPaint(
                        painter: BattleArenaPainter(battleState),
                        child: Container(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Shield button for local player
                if (localColor != null)
                  Column(
                    children: [
                      Text(
                        'YOUR SHIELD',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 10,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ShieldButton(
                        shieldState: localUnit.shieldState,
                        onPressed: () {
                          ref
                              .read(battleStateProvider.notifier)
                              .activateLocalShield(
                                isAttacker: localColor == attackerColor,
                              );
                        },
                      ),
                    ],
                  ),
                const SizedBox(height: 24),
              ],
            ),
            // Battle result overlay
            if (battleState.isFinished)
              _BattleResultOverlay(
                winner: battleState.winner!,
                localColor: localColor,
              ),
          ],
        ),
      ),
    );
  }
}

class _BattleHeader extends StatelessWidget {
  final BattleState battleState;

  const _BattleHeader({required this.battleState});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.purple.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.bolt, color: Colors.amber, size: 20),
          const SizedBox(width: 8),
          const Text(
            'BATTLE',
            style: TextStyle(
              color: Colors.amber,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 3,
            ),
          ),
          const Spacer(),
          Text(
            '${(battleState.elapsedMs / 1000).toStringAsFixed(1)}s',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _BattleResultOverlay extends StatelessWidget {
  final PlayerColor winner;
  final PlayerColor? localColor;

  const _BattleResultOverlay({required this.winner, required this.localColor});

  @override
  Widget build(BuildContext context) {
    final isLocalWin = localColor == null || winner == localColor;
    return Container(
      color: Colors.black.withValues(alpha: 0.7),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isLocalWin ? Colors.amber : Colors.redAccent,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: (isLocalWin ? Colors.amber : Colors.redAccent)
                    .withValues(alpha: 0.3),
                blurRadius: 20,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isLocalWin ? Icons.emoji_events : Icons.close,
                color: isLocalWin ? Colors.amber : Colors.redAccent,
                size: 48,
              ),
              const SizedBox(height: 12),
              Text(
                isLocalWin ? 'VICTORY!' : 'DEFEATED',
                style: TextStyle(
                  color: isLocalWin ? Colors.amber : Colors.redAccent,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${winner == PlayerColor.white ? "White" : "Black"} unit survives',
                style:
                    TextStyle(color: Colors.grey.shade400, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
