import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/game_logic/engine/upgrade_engine.dart';
import '../../../../core/game_logic/models/piece.dart';
import '../providers/upgrade_providers.dart';
import '../widgets/upgrade_card.dart';

/// Between-game screen where battle credits are spent on unit upgrades.
/// Progress persists via Supabase for signed-in users and stays session-only
/// otherwise.
class ComcenterScreen extends ConsumerStatefulWidget {
  const ComcenterScreen({super.key});

  @override
  ConsumerState<ComcenterScreen> createState() => _ComcenterScreenState();
}

class _ComcenterScreenState extends ConsumerState<ComcenterScreen> {
  @override
  void initState() {
    super.initState();
    loadUpgrades(ref);
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(upgradeProfileProvider);
    final credits = ref.watch(playerCreditsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        title: const Text(
          'COMCENTER',
          style: TextStyle(letterSpacing: 3, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                const Icon(Icons.monetization_on,
                    color: Colors.amber, size: 18),
                const SizedBox(width: 4),
                Text(
                  '$credits cr',
                  style: const TextStyle(
                    color: Colors.amber,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Upgrade your units to gain advantage in battle',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.count(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.72,
                children: PieceType.values.map((type) {
                  final level = profile.levelFor(type);
                  return UpgradeCard(
                    pieceType: type,
                    level: level,
                    credits: credits,
                    onUpgrade: () => _upgrade(type, level, credits),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _upgrade(PieceType type, int currentLevel, int credits) {
    final cost = UpgradeEngine.upgradeCost(currentLevel);
    if (cost < 0 || credits < cost) return;

    final profile = ref.read(upgradeProfileProvider);
    final newLevels = Map<PieceType, int>.from(profile.levels)
      ..[type] = currentLevel + 1;
    ref.read(upgradeProfileProvider.notifier).state =
        profile.copyWith(levels: newLevels);
    ref.read(playerCreditsProvider.notifier).state = credits - cost;
    persistUpgrades(ref);
  }
}
