import 'package:flutter/material.dart';
import '../../../../core/game_logic/engine/unit_base_stats.dart';
import '../../../../core/game_logic/engine/upgrade_engine.dart';
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
  PieceType.pawn: 'Pawn',
  PieceType.rook: 'Rook',
  PieceType.knight: 'Knight',
  PieceType.bishop: 'Bishop',
  PieceType.queen: 'Queen',
  PieceType.king: 'King',
};

class UpgradeCard extends StatelessWidget {
  final PieceType pieceType;
  final int level;
  final int credits;
  final VoidCallback? onUpgrade;

  const UpgradeCard({
    super.key,
    required this.pieceType,
    required this.level,
    required this.credits,
    required this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    final cost = UpgradeEngine.upgradeCost(level);
    final canUpgrade = level < 3 && credits >= cost && onUpgrade != null;
    final base = unitBaseStats[pieceType]!;
    final upgraded = UpgradeEngine.applyUpgrades(base, level);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: level == 3
              ? Colors.amber.shade700
              : Colors.blueGrey.shade800,
          width: level == 3 ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Symbol
            Text(
              _symbols[pieceType] ?? '',
              style: const TextStyle(fontSize: 32, color: Colors.white),
            ),
            const SizedBox(height: 4),
            // Name
            Text(
              _names[pieceType] ?? '',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            // Stars
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) {
                return Icon(
                  i < level ? Icons.star : Icons.star_border,
                  size: 14,
                  color: i < level ? Colors.amber : Colors.grey.shade700,
                );
              }),
            ),
            const SizedBox(height: 8),
            // Stats
            _StatRow('HP', base.maxHp, upgraded.maxHp),
            _StatRow('DMG', base.damage, upgraded.damage),
            const SizedBox(height: 8),
            // Upgrade button
            if (level < 3)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: canUpgrade ? onUpgrade : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canUpgrade
                        ? Colors.amber.shade800
                        : Colors.grey.shade800,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: Text(
                    cost < 0 ? 'MAX' : '${cost}cr',
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
              )
            else
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'MAX LEVEL',
                  style: TextStyle(
                    color: Colors.amber,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final int base;
  final int current;

  const _StatRow(this.label, this.base, this.current);

  @override
  Widget build(BuildContext context) {
    final boosted = current > base;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 10)),
        Text(
          boosted ? '$current (+${current - base})' : '$current',
          style: TextStyle(
            color: boosted ? Colors.greenAccent : Colors.grey.shade400,
            fontSize: 10,
            fontWeight: boosted ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
