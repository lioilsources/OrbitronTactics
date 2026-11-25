import 'package:flutter/material.dart';
import '../../../../core/game_logic/engine/upgrade_engine.dart';
import '../../../../core/game_logic/models/piece.dart';
import '../../../../core/worlds/world_balance.dart';
import '../../../../l10n/l10n.dart';

const Map<PieceType, String> _symbols = {
  PieceType.pawn: '♙',
  PieceType.rook: '♖',
  PieceType.knight: '♘',
  PieceType.bishop: '♗',
  PieceType.queen: '♕',
  PieceType.king: '♔',
};

class UpgradeCard extends StatelessWidget {
  final PieceType pieceType;
  final int level;
  final int credits;
  final VoidCallback? onUpgrade;

  /// The unit as it fights in the chosen world; without one the card
  /// shows its chess symbol.
  final String? artAsset;

  /// The numbers the unit fights by in the chosen world. Where some units
  /// fight up close, the card says how this one fights.
  final WorldBalance balance;

  const UpgradeCard({
    super.key,
    required this.pieceType,
    required this.level,
    required this.credits,
    required this.onUpgrade,
    this.artAsset,
    this.balance = WorldBalance.space,
  });

  Widget get _symbol => Text(
        _symbols[pieceType] ?? '',
        style: const TextStyle(fontSize: 32, color: Colors.white),
      );

  @override
  Widget build(BuildContext context) {
    final cost = UpgradeEngine.upgradeCost(level);
    final canUpgrade = level < 3 && credits >= cost && onUpgrade != null;
    final base = balance.statsOf(pieceType);
    final showsStyle = balance.units.values.any((stats) => stats.isMelee);
    final upgraded = UpgradeEngine.applyUpgrades(base, level);
    final l10n = context.l10n;

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
        // The card is drawn at its natural size and scaled into whatever the
        // grid gives it, so a larger text scale shrinks it instead of
        // overflowing.
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: SizedBox(
            width: 110,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
            // The unit, or its symbol
            if (artAsset case final asset?)
              Image.asset(
                asset,
                width: 40,
                height: 40,
                errorBuilder: (_, _, _) => _symbol,
              )
            else
              _symbol,
            const SizedBox(height: 4),
            // Name
            Text(
              l10n.pieceTypeName(pieceType),
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (showsStyle)
              Text(
                base.isMelee ? l10n.statMelee : l10n.statRanged,
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 9,
                  letterSpacing: 1.2,
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
            _StatRow(l10n.statHp, base.maxHp, upgraded.maxHp),
            _StatRow(l10n.statDamage, base.damage, upgraded.damage),
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
                    cost < 0 ? l10n.upgradeMax : l10n.creditsAmount(cost),
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
                child: Text(
                  l10n.upgradeMaxLevel,
                  style: const TextStyle(
                    color: Colors.amber,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
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
