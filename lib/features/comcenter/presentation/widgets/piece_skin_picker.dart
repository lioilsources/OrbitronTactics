import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/game_logic/models/piece.dart';
import '../../../../l10n/l10n.dart';
import '../../../battle/data/fleet_skin.dart';
import '../../../game/data/piece_skin.dart';
import '../../../game/presentation/providers/piece_skin_provider.dart';
import '../../../game/presentation/widgets/board/piece_renderer.dart';
import '../../../progress/presentation/providers/fleet_progress_provider.dart';
import '../../../store/data/store_catalog.dart';
import '../../../store/presentation/providers/store_providers.dart';
import '../../../store/presentation/widgets/store_item_sheet.dart';

/// Picks the world: the pieces on the board and the units in the arena.
/// Each world is previewed with both armies on its own squares; Space adds
/// the fleet picker, the figure worlds the classic marks toggle. A premium
/// world not owned yet shows a lock and opens its store page.
class PieceSkinPicker extends ConsumerWidget {
  const PieceSkinPicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final look = ref.watch(pieceSkinProvider);
    final notifier = ref.read(pieceSkinProvider.notifier);
    final entitlements = ref.watch(entitlementsProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          l10n.worldTitle,
          style: const TextStyle(
              color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.worldHint,
          style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
        ),
        const SizedBox(height: 12),
        if (look.skin.isSpace)
          const FleetPicker()
        else
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            activeThumbColor: Colors.amber,
            title: Text(l10n.classicMarks,
                style: const TextStyle(color: Colors.white)),
            subtitle: Text(l10n.classicMarksHint,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
            value: look.classicMarks,
            onChanged: notifier.setClassicMarks,
          ),
        const SizedBox(height: 12),
        for (final skin in PieceSkin.values)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: PieceSkinCard(
              skin: skin,
              selected: skin == look.skin,
              locked: !entitlements.ownsWorld(skin),
              classicMarks: look.classicMarks,
              onTap: entitlements.ownsWorld(skin)
                  ? () => notifier.select(skin)
                  : () => showStoreItemSheet(
                      context, ref, StoreCatalog.forWorld(skin),
                      from: 'world'),
            ),
          ),
      ],
    );
  }
}

/// One selectable skin: its name and both armies, white above black.
class PieceSkinCard extends StatelessWidget {
  const PieceSkinCard({
    super.key,
    required this.skin,
    required this.selected,
    required this.classicMarks,
    required this.onTap,
    this.locked = false,
  });

  final PieceSkin skin;
  final bool selected;

  /// A premium world not owned yet: dimmed, with a lock.
  final bool locked;
  final bool classicMarks;
  final VoidCallback onTap;

  static const _order = [
    PieceType.king,
    PieceType.queen,
    PieceType.rook,
    PieceType.bishop,
    PieceType.knight,
    PieceType.pawn,
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? Colors.amber.shade700 : Colors.blueGrey.shade800,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    skin.displayName(l10n),
                    style: TextStyle(
                      color: selected ? Colors.white : Colors.white70,
                      fontSize: 14,
                      fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
                if (locked)
                  const Icon(Icons.lock, color: Colors.amber, size: 18)
                else if (selected)
                  Icon(Icons.check_circle,
                      color: Colors.amber.shade700, size: 18),
              ],
            ),
            const SizedBox(height: 8),
            for (final color in PlayerColor.values) ...[
              Text(
                skin.sideName(l10n, color),
                style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
              ),
              const SizedBox(height: 4),
              LayoutBuilder(builder: (context, constraints) {
                final square = constraints.maxWidth / _order.length;
                final row = Row(
                  children: [
                    for (var i = 0; i < _order.length; i++)
                      Container(
                        width: square,
                        height: square,
                        color: (i + color.index) % 2 == 0
                            ? skin.lightSquare
                            : skin.darkSquare,
                        padding: EdgeInsets.all(square * 0.075),
                        child: PieceRenderer.build(
                          Piece(type: _order[i], color: color),
                          square,
                          skin: skin,
                          classicMarks: classicMarks,
                        ),
                      ),
                  ],
                );
                return locked ? Opacity(opacity: 0.55, child: row) : row;
              }),
              const SizedBox(height: 6),
            ],
          ],
        ),
      ),
    );
  }
}

/// The player's fleet: the ships that fight in the Space world. A premium
/// fleet not owned yet shows a lock and opens its store page.
class FleetPicker extends ConsumerWidget {
  const FleetPicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fleet = ref.watch(fleetProgressProvider(playerFleetIdentity));
    final skin = FleetSkin.fromSlug(fleet.skin);
    final player =
        ref.read(fleetProgressProvider(playerFleetIdentity).notifier);
    final entitlements = ref.watch(entitlementsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.worldFleetHint,
          style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          context.l10n.yourFleet(skin.localizedName(context.l10n)),
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
              final owned = entitlements.ownsFleet(option);
              return _FleetCard(
                skin: option,
                selected: option == skin,
                locked: !owned,
                onTap: owned
                    ? () => player.setSkin(option.slug)
                    : () => showStoreItemSheet(
                        context, ref, StoreCatalog.forFleet(option),
                        from: 'fleet'),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// One selectable fleet, previewed by its white knight.
class _FleetCard extends StatelessWidget {
  final FleetSkin skin;
  final bool selected;
  final bool locked;
  final VoidCallback onTap;

  const _FleetCard({
    required this.skin,
    required this.selected,
    required this.locked,
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
            Stack(
              children: [
                Opacity(
                  opacity: locked ? 0.45 : 1,
                  child: Image.asset(
                    skin.assetFor(PieceType.knight, PlayerColor.white),
                    width: 56,
                    height: 56,
                  ),
                ),
                if (locked)
                  const Positioned(
                    right: 0,
                    top: 0,
                    child: Icon(Icons.lock, size: 16, color: Colors.amber),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              skin.localizedName(context.l10n),
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
