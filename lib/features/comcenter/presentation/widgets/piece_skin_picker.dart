import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/game_logic/models/piece.dart';
import '../../../../l10n/l10n.dart';
import '../../../game/data/piece_skin.dart';
import '../../../game/presentation/providers/piece_skin_provider.dart';
import '../../../game/presentation/widgets/board/piece_renderer.dart';

/// Picks the board's piece skin and the classic marks toggle. Each pack is
/// previewed with both armies on its own squares.
class PieceSkinPicker extends ConsumerWidget {
  const PieceSkinPicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final look = ref.watch(pieceSkinProvider);
    final notifier = ref.read(pieceSkinProvider.notifier);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          l10n.pieceSkinTitle,
          style: const TextStyle(
              color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.pieceSkinHint,
          style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
        ),
        const SizedBox(height: 8),
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
        const SizedBox(height: 8),
        for (final skin in PieceSkin.values)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: PieceSkinCard(
              skin: skin,
              selected: skin == look.skin,
              classicMarks: look.classicMarks,
              onTap: () => notifier.select(skin),
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
  });

  final PieceSkin skin;
  final bool selected;
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
                if (selected)
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
                return Row(
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
              }),
              const SizedBox(height: 6),
            ],
          ],
        ),
      ),
    );
  }
}
