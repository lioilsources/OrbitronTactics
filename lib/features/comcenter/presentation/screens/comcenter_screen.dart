import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/game_logic/models/piece.dart';
import '../../../battle/data/fleet_skin.dart';
import '../../../progress/presentation/providers/fleet_progress_provider.dart';
import '../widgets/upgrade_card.dart';

class ComcenterScreen extends ConsumerWidget {
  const ComcenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // The player's saved fleet — the upgrades and ship art single-player
    // battles use.
    final fleet = ref.watch(fleetProgressProvider(playerFleetIdentity));
    final profile = fleet.profile;
    final credits = fleet.credits;
    final skin = FleetSkin.fromSlug(fleet.skin);

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
              'Your fleet: ${skin.displayName}',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 112,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: FleetSkin.values.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final option = FleetSkin.values[index];
                  return _FleetCard(
                    skin: option,
                    selected: option == skin,
                    onTap: () => ref
                        .read(fleetProgressProvider(playerFleetIdentity)
                            .notifier)
                        .setSkin(option.slug),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
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

/// One selectable fleet, previewed by its white knight.
class _FleetCard extends StatelessWidget {
  final FleetSkin skin;
  final bool selected;
  final VoidCallback onTap;

  const _FleetCard({
    required this.skin,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 92,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? Colors.amber.shade700 : Colors.blueGrey.shade800,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Image.asset(
              skin.assetFor(PieceType.knight, PlayerColor.white),
              width: 56,
              height: 56,
            ),
            const SizedBox(height: 6),
            Text(
              skin.displayName,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: TextStyle(
                color: selected ? Colors.white : Colors.white70,
                fontSize: 10,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
