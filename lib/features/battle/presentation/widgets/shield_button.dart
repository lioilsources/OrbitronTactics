import 'package:flutter/material.dart';
import '../../../../core/game_logic/models/shield_state.dart';

class ShieldButton extends StatelessWidget {
  final ShieldState shieldState;
  final VoidCallback? onPressed;

  const ShieldButton({
    super.key,
    required this.shieldState,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final canActivate = shieldState.canActivate;
    final isActive = shieldState.isActive;
    final cooldownFraction = shieldState.isOnCooldown
        ? shieldState.cooldownRemainingMs / 5000.0
        : 0.0;

    return GestureDetector(
      onTap: canActivate ? onPressed : null,
      child: SizedBox(
        width: 80,
        height: 80,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Cooldown ring
            if (shieldState.isOnCooldown)
              CircularProgressIndicator(
                value: cooldownFraction,
                strokeWidth: 4,
                color: Colors.grey.shade600,
                backgroundColor: Colors.transparent,
              ),
            // Active ring
            if (isActive)
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.5, end: 1.0),
                duration: const Duration(milliseconds: 600),
                builder: (_, v, __) => CircularProgressIndicator(
                  value: v,
                  strokeWidth: 4,
                  color: Colors.cyanAccent,
                ),
              ),
            // Button
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive
                    ? Colors.cyan.withValues(alpha: 0.3)
                    : canActivate
                        ? Colors.blueGrey.shade800
                        : Colors.grey.shade900,
                border: Border.all(
                  color: isActive
                      ? Colors.cyanAccent
                      : canActivate
                          ? Colors.blueGrey.shade400
                          : Colors.grey.shade700,
                  width: 2,
                ),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: Colors.cyanAccent.withValues(alpha: 0.5),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                Icons.shield,
                color: isActive
                    ? Colors.cyanAccent
                    : canActivate
                        ? Colors.blueGrey.shade300
                        : Colors.grey.shade700,
                size: 28,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
