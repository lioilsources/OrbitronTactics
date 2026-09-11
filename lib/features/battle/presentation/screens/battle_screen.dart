import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/game_logic/models/battle_state.dart';
import '../../../../core/game_logic/models/battle_unit.dart';
import '../../../../core/game_logic/models/piece.dart';
import '../../../game/presentation/providers/game_state_provider.dart';
import '../../data/battle_element.dart';
import '../../data/fleet_skin.dart';
import '../audio/battle_audio.dart';
import '../audio/battle_sound_cues.dart';
import '../providers/battle_state_provider.dart';
import '../providers/ship_sprite_provider.dart';
import '../widgets/battle_arena_painter.dart';
import '../widgets/shield_button.dart';
import '../widgets/ship_bank.dart';
import '../widgets/unit_combat_panel.dart';

class BattleScreen extends ConsumerStatefulWidget {
  final PlayerColor? attackerColor;

  /// The fleets whose ship art each side flies.
  final FleetSkin attackerSkin;
  final FleetSkin defenderSkin;

  const BattleScreen({
    super.key,
    this.attackerColor,
    this.attackerSkin = FleetSkin.fallback,
    this.defenderSkin = FleetSkin.fallback,
  });

  @override
  ConsumerState<BattleScreen> createState() => _BattleScreenState();
}

class _BattleScreenState extends ConsumerState<BattleScreen>
    with SingleTickerProviderStateMixin {
  /// Dragging this fraction of the arena's height forward climbs from the
  /// lowest altitude to the highest; dragging back dives.
  static const double _altitudeDragFraction = 0.3;

  /// Active arena pointers: pointer id -> started in the top half.
  /// Each finger steers the ship of the half it first touched, so two
  /// players can drag simultaneously without interfering.
  final Map<int, bool> _pointerInTopHalf = {};

  final _attackerBank = ShipBank();
  final _defenderBank = ShipBank();

  /// Plays the losing ship's explosion once the battle is over; the result
  /// shows when it has finished.
  late final AnimationController _destruction;

  @override
  void initState() {
    super.initState();
    _destruction = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: BattleArenaPainter.destructionMs),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) setState(() {});
      });
    // The battle is set up before this screen opens.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final battle = ref.read(battleStateProvider);
      if (mounted && battle != null) _startAudio(battle);
    });
  }

  @override
  void dispose() {
    BattleAudio.instance.stop();
    _destruction.dispose();
    super.dispose();
  }

  void _startAudio(BattleState battle) {
    final started = BattleAudio.instance.start(
      attacker: battle.attacker.piece.type,
      elements: {
        BattleElement.of(battle.attacker.piece.type),
        BattleElement.of(battle.defender.piece.type),
      },
    );
    // The saved mute setting is only known once audio is up.
    started.then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<BattleState?>(battleStateProvider, (previous, next) {
      if (next == null) return;
      if (previous == null) {
        _startAudio(next);
      } else {
        BattleAudio.instance.play(BattleSoundCues.between(previous, next));
      }
    });
    final battleState = ref.watch(battleStateProvider);
    final localColor = ref.read(gameStateProvider.notifier).localColor;
    final attackerColor = widget.attackerColor;

    if (battleState == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF0D0D1A),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Portrait arena: the local player fights from the bottom.
    // In hot-seat mode the attacker takes the bottom end and the other
    // player plays upside-down from the top end of the device.
    final isHotSeat = localColor == null;
    final attackerAtBottom = isHotSeat || localColor == attackerColor;
    final topUnit =
        attackerAtBottom ? battleState.defender : battleState.attacker;
    final bottomUnit =
        attackerAtBottom ? battleState.attacker : battleState.defender;

    // Until a sprite has loaded the arena draws the plain vector hull.
    final attackerAsset = widget.attackerSkin.assetFor(
        battleState.attacker.piece.type, battleState.attacker.piece.color);
    final defenderAsset = widget.defenderSkin.assetFor(
        battleState.defender.piece.type, battleState.defender.piece.color);
    final attackerSprite =
        ref.watch(shipSpriteProvider(attackerAsset)).valueOrNull;
    final defenderSprite =
        ref.watch(shipSpriteProvider(defenderAsset)).valueOrNull;
    final topAsset = attackerAtBottom ? defenderAsset : attackerAsset;
    final bottomAsset = attackerAtBottom ? attackerAsset : defenderAsset;

    final attackerBank = _attackerBank.update(
        battleState.attacker.xFraction, battleState.elapsedMs);
    final defenderBank = _defenderBank.update(
        battleState.defender.xFraction, battleState.elapsedMs);
    if (battleState.isFinished && _destruction.isDismissed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _destruction.isDismissed) _destruction.forward();
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _BattleHeader(
                  battleState: battleState,
                  muted: BattleAudio.instance.muted,
                  onToggleMute: () async {
                    await BattleAudio.instance.toggleMute();
                    if (mounted) setState(() {});
                  },
                ),
                const SizedBox(height: 8),
                // Top player: opponent (wifi) or the player sitting across
                // the device (hot-seat, rotated to face them).
                if (isHotSeat)
                  RotatedBox(
                    quarterTurns: 2,
                    child: _PlayerBattleControls(
                      unit: topUnit,
                      spriteAsset: topAsset,
                      label: _shieldLabel(topUnit.piece.color),
                      onShield: () => ref
                          .read(battleStateProvider.notifier)
                          .activateLocalShield(isAttacker: !attackerAtBottom),
                    ),
                  )
                else
                  UnitCombatPanel(
                    unit: topUnit,
                    isLeft: true,
                    spriteAsset: topAsset,
                  ),
                const SizedBox(height: 8),
                // Arena — in your half, drag across to dodge, forward to
                // climb and back to dive
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: LayoutBuilder(
                        builder: (context, constraints) => Listener(
                          behavior: HitTestBehavior.opaque,
                          onPointerDown: (e) => _onArenaPointerDown(
                              e, constraints, isHotSeat, attackerAtBottom),
                          onPointerMove: (e) => _onArenaPointerMove(
                              e, constraints, attackerAtBottom),
                          onPointerUp: (e) =>
                              _pointerInTopHalf.remove(e.pointer),
                          onPointerCancel: (e) =>
                              _pointerInTopHalf.remove(e.pointer),
                          child: AnimatedBuilder(
                            animation: _destruction,
                            builder: (context, child) => CustomPaint(
                              painter: BattleArenaPainter(
                                battleState,
                                attackerAtBottom: attackerAtBottom,
                                attackerSprite: attackerSprite,
                                defenderSprite: defenderSprite,
                                attackerBank: attackerBank,
                                defenderBank: defenderBank,
                                nowMs: battleState.elapsedMs +
                                    (_destruction.value *
                                            BattleArenaPainter.destructionMs)
                                        .round(),
                              ),
                              child: child,
                            ),
                            child: Container(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Bottom player: the local / acting player's controls.
                _PlayerBattleControls(
                  unit: bottomUnit,
                  spriteAsset: bottomAsset,
                  label: isHotSeat
                      ? _shieldLabel(bottomUnit.piece.color)
                      : 'YOUR SHIELD',
                  onShield: () => ref
                      .read(battleStateProvider.notifier)
                      .activateLocalShield(isAttacker: attackerAtBottom),
                ),
                const SizedBox(height: 12),
              ],
            ),
            // Battle result overlay, once the loser has exploded
            if (battleState.isFinished && _destruction.isCompleted)
              _BattleResultOverlay(
                winner: battleState.winner!,
                localColor: localColor,
                onContinue: () => Navigator.of(context).pop(),
              ),
          ],
        ),
      ),
    );
  }

  void _onArenaPointerDown(
    PointerDownEvent e,
    BoxConstraints constraints,
    bool isHotSeat,
    bool attackerAtBottom,
  ) {
    final inTopHalf = e.localPosition.dy < constraints.maxHeight / 2;
    // In network mode only the bottom (local) half is steerable —
    // the opponent's ship position arrives over the transport.
    if (!isHotSeat && inTopHalf) return;
    _pointerInTopHalf[e.pointer] = inTopHalf;
    _steerShip(
        e.localPosition.dx, 0, constraints, inTopHalf, attackerAtBottom);
  }

  void _onArenaPointerMove(
    PointerMoveEvent e,
    BoxConstraints constraints,
    bool attackerAtBottom,
  ) {
    final inTopHalf = _pointerInTopHalf[e.pointer];
    if (inTopHalf == null) return;
    _steerShip(e.localPosition.dx, e.delta.dy, constraints, inTopHalf,
        attackerAtBottom);
  }

  /// Steers the ship of the half a finger started in: across to the finger,
  /// and up or down by how far the finger moved [dy] forward — toward the
  /// enemy, which is up the screen for the bottom ship and down for the top.
  void _steerShip(
    double dx,
    double dy,
    BoxConstraints constraints,
    bool inTopHalf,
    bool attackerAtBottom,
  ) {
    // The top ship is the attacker exactly when the attacker is not at
    // the bottom.
    final isAttacker = inTopHalf ? !attackerAtBottom : attackerAtBottom;
    final forward = inTopHalf ? dy : -dy;
    ref.read(battleStateProvider.notifier).moveLocalShip(
          isAttacker: isAttacker,
          xFraction: (dx / constraints.maxWidth).clamp(0.0, 1.0),
          altitudeDelta:
              forward / (constraints.maxHeight * _altitudeDragFraction),
        );
  }

  String _shieldLabel(PlayerColor color) =>
      color == PlayerColor.white ? 'WHITE SHIELD' : 'BLACK SHIELD';
}

/// One player's battle controls: unit panel and shield button side by side.
class _PlayerBattleControls extends StatelessWidget {
  final BattleUnit unit;
  final String spriteAsset;
  final String label;
  final VoidCallback onShield;

  const _PlayerBattleControls({
    required this.unit,
    required this.spriteAsset,
    required this.label,
    required this.onShield,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          UnitCombatPanel(unit: unit, isLeft: true, spriteAsset: spriteAsset),
          Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 10,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              ShieldButton(
                shieldState: unit.shieldState,
                onPressed: onShield,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BattleHeader extends StatelessWidget {
  final BattleState battleState;
  final bool muted;
  final VoidCallback onToggleMute;

  const _BattleHeader({
    required this.battleState,
    required this.muted,
    required this.onToggleMute,
  });

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
          IconButton(
            icon: Icon(muted ? Icons.volume_off : Icons.volume_up),
            color: Colors.grey.shade500,
            iconSize: 20,
            visualDensity: VisualDensity.compact,
            tooltip: muted ? 'Sound on' : 'Sound off',
            onPressed: onToggleMute,
          ),
        ],
      ),
    );
  }
}

class _BattleResultOverlay extends StatelessWidget {
  final PlayerColor winner;
  final PlayerColor? localColor;
  final VoidCallback onContinue;

  const _BattleResultOverlay({
    required this.winner,
    required this.localColor,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final isLocalWin = localColor == null || winner == localColor;
    return GestureDetector(
      onTap: onContinue,
      child: Container(
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
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                ),
                const SizedBox(height: 16),
                Text(
                  'Tap to continue',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 11,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
