import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/game_logic/engine/upgrade_engine.dart';
import '../../../../core/game_logic/models/piece.dart';
import '../../../../core/game_logic/models/upgrade_profile.dart';
import '../widgets/upgrade_card.dart';

// Simple in-memory provider for current session upgrades.
// In production, load from UpgradeRepository on screen open.
final _upgradeProfileProvider =
    StateProvider<UpgradeProfile>((ref) => UpgradeProfile.empty());
final _creditsProvider = StateProvider<int>((ref) => 0);

class ComcenterScreen extends ConsumerWidget {
  const ComcenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(_upgradeProfileProvider);
    final credits = ref.watch(_creditsProvider);

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
                    onUpgrade: () => _upgrade(ref, type, level, credits),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _upgrade(
      WidgetRef ref, PieceType type, int currentLevel, int credits) {
    final cost = UpgradeEngine.upgradeCost(currentLevel);
    if (cost < 0 || credits < cost) return;

    final profile = ref.read(_upgradeProfileProvider);
    final newLevels = Map<PieceType, int>.from(profile.levels)
      ..[type] = currentLevel + 1;
    ref.read(_upgradeProfileProvider.notifier).state =
        profile.copyWith(levels: newLevels);
    ref.read(_creditsProvider.notifier).state = credits - cost;
  }
}
