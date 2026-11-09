import 'package:flutter/material.dart';

import '../../../../core/maneuvers/maneuver.dart';
import '../../../../core/maneuvers/maneuver_catalog.dart';
import '../../../battle/presentation/widgets/pattern_glyph.dart';
import '../../../../l10n/l10n.dart';

/// One maneuver in the Comcenter: its gesture, what it does, and the way in
/// — arm it, buy it, train it, or go and win battles for it.
class ManeuverCard extends StatelessWidget {
  const ManeuverCard({
    super.key,
    required this.maneuver,
    required this.accent,
    required this.owned,
    required this.armed,
    required this.level,
    required this.credits,
    required this.battleWins,
    required this.hasFreeSlot,
    required this.onArm,
    required this.onUnarm,
    required this.onBuy,
    required this.onTrain,
    required this.onGetPack,
  });

  final Maneuver maneuver;
  final Color accent;
  final bool owned;
  final bool armed;
  final int level;
  final int credits;
  final int battleWins;
  final bool hasFreeSlot;
  final VoidCallback onArm;
  final VoidCallback onUnarm;
  final VoidCallback onBuy;
  final VoidCallback onTrain;

  /// Opens the store page of the pack this maneuver comes in.
  final void Function(String pack) onGetPack;

  @override
  Widget build(BuildContext context) {
    final trainPrice =
        level < Maneuver.maxLevel ? ManeuverCatalog.upgradePrice(maneuver, level + 1) : null;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: armed ? accent : Colors.blueGrey.shade800,
          width: armed ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PatternGlyph(
                pattern: maneuver.pattern,
                color: accent,
                size: 46,
                dimmed: !owned,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            context.l10n.maneuverName(maneuver),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: owned ? Colors.white : Colors.white70,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        _Badge(text: _tierName(context), color: accent),
                        if (owned && level > 1) ...[
                          const SizedBox(width: 4),
                          _Badge(text: 'L$level', color: Colors.amber),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.l10n.maneuverDescription(maneuver),
                      style: TextStyle(
                          color: Colors.grey.shade400, fontSize: 11, height: 1.3),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.l10n.maneuverStats(
                            maneuver.costAt(level),
                            (maneuver.durationAt(level) / 1000)
                                .toStringAsFixed(1),
                          ) +
                          (maneuver.mirrorable
                              ? context.l10n.maneuverMirrors
                              : ''),
                      style: TextStyle(color: accent, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _wayIn(context)),
              if (owned && trainPrice != null) ...[
                const SizedBox(width: 8),
                TextButton(
                  onPressed: credits >= trainPrice ? onTrain : null,
                  child: Text(context.l10n.trainPrice(trainPrice)),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  static String _packName(BuildContext context, String packId) =>
      context.l10n.packName(ManeuverCatalog.packs.firstWhere(
          (pack) => pack.id == packId,
          orElse: () =>
              ManeuverPack(id: packId, name: 'pack', description: '')));

  String _tierName(BuildContext context) => switch (maneuver.tier) {
        ManeuverTier.starter => context.l10n.tierStarter,
        ManeuverTier.basic => context.l10n.tierBasic,
        ManeuverTier.advanced => context.l10n.tierAdvanced,
        ManeuverTier.signature => context.l10n.tierSignature,
        ManeuverTier.pack => context.l10n.tierPack,
      };

  Widget _wayIn(BuildContext context) {
    if (armed) {
      return OutlinedButton(onPressed: onUnarm, child: Text(context.l10n.maneuverArmed));
    }
    if (owned) {
      return FilledButton(
        onPressed: hasFreeSlot ? onArm : null,
        child: Text(hasFreeSlot
            ? context.l10n.maneuverArm
            : context.l10n.maneuverPadFull),
      );
    }
    final price = maneuver.price;
    return Row(
      children: [
        Expanded(
          child: Text(
            switch (maneuver.unlock) {
              WinsUnlock(:final wins) =>
                context.l10n.unlockWins(battleWins, wins),
              PackUnlock(:final packId) =>
                context.l10n.unlockPack(_packName(context, packId)),
              StarterUnlock() => context.l10n.unlockStarter,
            },
            style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
          ),
        ),
        if (price != null)
          FilledButton.tonal(
            onPressed: credits >= price ? onBuy : null,
            child: Text(context.l10n.buyCredits(price)),
          )
        else if (maneuver.unlock case PackUnlock(:final packId))
          FilledButton.tonal(
            onPressed: () => onGetPack(packId),
            child: Text(context.l10n.getPack),
          ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Text(
          text,
          style: TextStyle(
              color: color, fontSize: 9, fontWeight: FontWeight.bold),
        ),
      );
}
