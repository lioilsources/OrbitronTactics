import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/game_logic/models/piece.dart';
import '../../../progress/presentation/providers/fleet_progress_provider.dart';
import '../widgets/upgrade_card.dart';

class ComcenterScreen extends ConsumerWidget {
  const ComcenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // The player's saved fleet — the upgrades single-player battles use.
    final fleet = ref.watch(fleetProgressProvider(playerFleetIdentity));
    final profile = fleet.profile;
    final credits = fleet.credits;

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
                  return UpgradeCard(
                    pieceType: type,
                    level: profile.levelFor(type),
                    credits: credits,
                    onUpgrade: () => ref
                        .read(fleetProgressProvider(playerFleetIdentity)
                            .notifier)
                        .upgrade(type),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
