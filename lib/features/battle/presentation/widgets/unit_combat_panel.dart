import 'package:flutter/material.dart';
import '../../../../core/game_logic/models/battle_unit.dart';
import '../../../../core/game_logic/models/piece.dart';

const Map<PieceType, String> _symbols = {
  PieceType.pawn: '♙',
  PieceType.rook: '♖',
  PieceType.knight: '♘',
  PieceType.bishop: '♗',
  PieceType.queen: '♕',
  PieceType.king: '♔',
};

const Map<PieceType, String> _names = {
  PieceType.pawn: 'PAWN',
  PieceType.rook: 'ROOK',
  PieceType.knight: 'KNIGHT',
  PieceType.bishop: 'BISHOP',
  PieceType.queen: 'QUEEN',
  PieceType.king: 'KING',
};

class UnitCombatPanel extends StatelessWidget {
  final BattleUnit unit;
  final bool isLeft;

  const UnitCombatPanel({
    super.key,
    required this.unit,
    required this.isLeft,
  });

  @override
  Widget build(BuildContext context) {
    final isWhite = unit.piece.color == PlayerColor.white;
    final shieldActive = unit.shieldState.isActive;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment:
          isLeft ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      children: [
        // Unit name
        Text(
          _names[unit.piece.type] ?? '',
          style: TextStyle(
            color: isWhite ? Colors.white : Colors.grey.shade400,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        // Unit avatar with shield glow
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isWhite
                ? Colors.white.withValues(alpha: 0.12)
                : Colors.grey.withValues(alpha: 0.12),
            border: Border.all(
              color: shieldActive
                  ? Colors.cyanAccent
                  : isWhite
                      ? Colors.white54
                      : Colors.grey.shade600,
              width: shieldActive ? 3 : 2,
            ),
            boxShadow: shieldActive
                ? [
                    BoxShadow(
                      color: Colors.cyanAccent.withValues(alpha: 0.6),
                      blurRadius: 20,
                      spreadRadius: 4,
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              _symbols[unit.piece.type] ?? '?',
              style: TextStyle(
                fontSize: 34,
                color: isWhite ? Colors.white : Colors.grey.shade300,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        // HP bar
        SizedBox(
          width: 80,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${unit.currentHp}/${unit.stats.maxHp}',
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 2),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: unit.hpFraction.clamp(0.0, 1.0),
                  minHeight: 8,
                  backgroundColor: Colors.grey.shade800,
                  valueColor: AlwaysStoppedAnimation(
                    unit.hpFraction > 0.5
                        ? Colors.greenAccent
                        : unit.hpFraction > 0.25
                            ? Colors.orange
                            : Colors.red,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
