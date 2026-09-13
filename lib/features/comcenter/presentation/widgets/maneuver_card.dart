import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/maneuvers/maneuver.dart';
import '../../../../core/maneuvers/maneuver_catalog.dart';
import '../../../battle/presentation/widgets/pattern_glyph.dart';

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
    required this.onGrantPack,
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
  final VoidCallback onGrantPack;

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
                            maneuver.name,
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
                        _Badge(text: _tierName, color: accent),
                        if (owned && level > 1) ...[
                          const SizedBox(width: 4),
                          _Badge(text: 'L$level', color: Colors.amber),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      maneuver.description,
                      style: TextStyle(
                          color: Colors.grey.shade400, fontSize: 11, height: 1.3),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${maneuver.costAt(level)} energy · '
                      '${(maneuver.durationAt(level) / 1000).toStringAsFixed(1)} s'
                      '${maneuver.mirrorable ? ' · mirrors' : ''}',
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
                  child: Text('TRAIN $trainPrice'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String get _tierName => switch (maneuver.tier) {
        ManeuverTier.starter => 'START',
        ManeuverTier.basic => 'BASIC',
        ManeuverTier.advanced => 'ADVANCED',
        ManeuverTier.signature => 'SIGNATURE',
        ManeuverTier.pack => 'PACK',
      };

  Widget _wayIn(BuildContext context) {
    if (armed) {
      return OutlinedButton(onPressed: onUnarm, child: const Text('ARMED'));
    }
    if (owned) {
      return FilledButton(
        onPressed: hasFreeSlot ? onArm : null,
        child: Text(hasFreeSlot ? 'ARM' : 'PAD FULL'),
      );
    }
    final price = maneuver.price;
    return Row(
      children: [
        Expanded(
          child: Text(
            switch (maneuver.unlock) {
              WinsUnlock(:final wins) => 'Win $battleWins/$wins battles',
              PackUnlock() => 'In the Ace pack',
              StarterUnlock() => 'From the start',
            },
            style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
          ),
        ),
        if (price != null)
          FilledButton.tonal(
            onPressed: credits >= price ? onBuy : null,
            child: Text('BUY $price'),
          )
        else if (maneuver.unlock is PackUnlock && kDebugMode)
          TextButton(onPressed: onGrantPack, child: const Text('UNLOCK PACK')),
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
