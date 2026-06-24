import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../model/battle_simulation.dart';
import '../net/battle_controller.dart';
import 'battle_game.dart';

/// Full-screen real-time battle arena.
///
/// Reusable and transport-agnostic: the caller builds a [BattleController]
/// (host or guest, over any [BattleLink]) and is notified via [onResolved]
/// with the winning role. The caller is responsible for turning that role into
/// a board result (e.g. `GameSession.submitBattleResult` on the host).
class BattleScreen extends StatefulWidget {
  final BattleController controller;
  final BattleRole localRole;
  final BattleConfig config;
  final void Function(BattleRole winner) onResolved;

  const BattleScreen({
    super.key,
    required this.controller,
    required this.localRole,
    this.config = const BattleConfig(),
    required this.onResolved,
  });

  @override
  State<BattleScreen> createState() => _BattleScreenState();
}

class _BattleScreenState extends State<BattleScreen> {
  late final BattleInputState _input = BattleInputState();
  late final BattleGame _game;
  bool _resolved = false;

  @override
  void initState() {
    super.initState();
    _game = BattleGame(
      controller: widget.controller,
      config: widget.config,
      localRole: widget.localRole,
      input: _input,
      onFinished: _handleFinished,
    );
  }

  void _handleFinished(BattleRole winner) {
    if (_resolved) return;
    _resolved = true;
    widget.onResolved(winner);
    if (mounted) setState(() {});
    // Show the result briefly, then return to the board.
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (mounted) Navigator.of(context).maybePop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final won = _resolved && widget.controller.winner == widget.localRole;

    return Scaffold(
      backgroundColor: const Color(0xFF0B0B1A),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(child: GameWidget(game: _game)),

            // Role banner.
            Positioned(
              top: 8,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  widget.localRole == BattleRole.attacker
                      ? 'ATTACKER'
                      : 'DEFENDER',
                  style: TextStyle(
                    color: widget.localRole == BattleRole.attacker
                        ? const Color(0xFF5BC0FF)
                        : const Color(0xFFFF6B6B),
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),

            if (!_resolved) ..._buildControls(),

            if (_resolved)
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 32, vertical: 20),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    won ? 'VICTORY' : 'DEFEAT',
                    style: TextStyle(
                      color: won ? const Color(0xFF7CFF7C) : Colors.redAccent,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildControls() {
    return [
      // Steering + thrust on the left.
      Positioned(
        left: 16,
        bottom: 24,
        child: Row(
          children: [
            _HoldButton(
              icon: Icons.rotate_left,
              onChanged: (held) => _input.turn = held ? -1 : 0,
            ),
            const SizedBox(width: 12),
            _HoldButton(
              icon: Icons.keyboard_double_arrow_up,
              onChanged: (held) => _input.thrust = held,
            ),
            const SizedBox(width: 12),
            _HoldButton(
              icon: Icons.rotate_right,
              onChanged: (held) => _input.turn = held ? 1 : 0,
            ),
          ],
        ),
      ),
      // Fire on the right.
      Positioned(
        right: 24,
        bottom: 24,
        child: _HoldButton(
          icon: Icons.whatshot,
          big: true,
          onChanged: (held) => _input.fire = held,
        ),
      ),
    ];
  }
}

/// A button that reports press-and-hold state (down = true, up = false).
class _HoldButton extends StatefulWidget {
  final IconData icon;
  final bool big;
  final void Function(bool held) onChanged;

  const _HoldButton({
    required this.icon,
    required this.onChanged,
    this.big = false,
  });

  @override
  State<_HoldButton> createState() => _HoldButtonState();
}

class _HoldButtonState extends State<_HoldButton> {
  bool _held = false;

  void _set(bool held) {
    if (_held == held) return;
    setState(() => _held = held);
    widget.onChanged(held);
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.big ? 88.0 : 64.0;
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: Container(
        width: d,
        height: d,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _held
              ? Colors.white.withValues(alpha: 0.35)
              : Colors.white.withValues(alpha: 0.12),
          border: Border.all(color: Colors.white24),
        ),
        child: Icon(widget.icon, color: Colors.white, size: widget.big ? 40 : 28),
      ),
    );
  }
}
