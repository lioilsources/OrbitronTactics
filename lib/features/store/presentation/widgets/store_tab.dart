import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../battle/data/battle_music.dart';

import '../../../telemetry/presentation/telemetry_provider.dart';
import '../../data/store_catalog.dart';
import '../providers/store_providers.dart';
import 'store_item_preview.dart';
import 'store_item_sheet.dart';
import '../../../../l10n/l10n.dart';

/// The Comcenter's store: every item with its price, and a way to get
/// earlier purchases back.
class StoreTab extends ConsumerStatefulWidget {
  const StoreTab({super.key});

  @override
  ConsumerState<StoreTab> createState() => _StoreTabState();
}

class _StoreTabState extends ConsumerState<StoreTab> {
  bool _restoring = false;

  @override
  void initState() {
    super.initState();
    ref.read(telemetryProvider).event('store_opened');
  }

  Future<void> _restore() async {
    setState(() => _restoring = true);
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    final owned = await ref.read(entitlementsProvider.notifier).restore();
    if (!mounted) return;
    setState(() => _restoring = false);
    messenger.showSnackBar(SnackBar(
      content: Text(switch (owned) {
        null => l10n.restoreFailed,
        0 => l10n.restoreNone,
        final count => l10n.restoredCount(count),
      }),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final entitlements = ref.watch(entitlementsProvider);
    final available = ref.watch(purchaseServiceProvider).available;
    final prices = ref.watch(storePricesProvider).valueOrNull ?? const {};

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          context.l10n.storeIntro,
          style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
        ),
        if (!available) ...[
          const SizedBox(height: 8),
          Text(
            context.l10n.storeUnavailable,
            style: TextStyle(color: Colors.orange.shade300, fontSize: 13),
          ),
        ],
        const SizedBox(height: 12),
        const _MusicChoice(),
        const SizedBox(height: 12),
        for (final item in StoreCatalog.items)
          _StoreTile(
            item: item,
            label: priceLabel(context, item, prices, entitlements.owns(item)),
            owned: entitlements.owns(item),
            onTap: () => showStoreItemSheet(context, ref, item, from: 'store'),
          ),
        const SizedBox(height: 8),
        Center(
          child: TextButton(
            onPressed: available && !_restoring ? _restore : null,
            child: Text(_restoring
                ? context.l10n.restoring
                : context.l10n.restorePurchases),
          ),
        ),
      ],
    );
  }
}

/// Which battle music plays: one chip per set, a locked one leading to
/// its store page.
class _MusicChoice extends ConsumerWidget {
  const _MusicChoice();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playing = ref.watch(battleMusicProvider);
    final entitlements = ref.watch(entitlementsProvider);
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          context.l10n.battleMusic,
          style: TextStyle(
              color: Colors.grey.shade400, fontSize: 11, letterSpacing: 1.2),
        ),
        for (final music in BattleMusic.values)
          ChoiceChip(
              avatar: entitlements.ownsMusic(music)
                  ? null
                  : const Icon(Icons.lock, size: 14, color: Colors.amber),
              label: Text(context.l10n.musicName(music)),
              selected: music == playing,
              showCheckmark: false,
              selectedColor: Colors.amber,
              labelStyle: TextStyle(
                fontSize: 12,
                color: music == playing ? Colors.black : Colors.white70,
              ),
              backgroundColor: const Color(0xFF1A1A2E),
              onSelected: (_) => entitlements.ownsMusic(music)
                  ? ref.read(chosenBattleMusicProvider.notifier).choose(music)
                  : showStoreItemSheet(
                      context, ref, StoreCatalog.forMusic(music),
                      from: 'music'),
          ),
      ],
    );
  }
}

class _StoreTile extends StatelessWidget {
  const _StoreTile({
    required this.item,
    required this.label,
    required this.owned,
    required this.onTap,
  });

  final StoreItem item;
  final String label;
  final bool owned;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final highlight = item.kind == StoreItemKind.commander;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: highlight ? Colors.amber.shade700 : Colors.blueGrey.shade800,
            width: highlight ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    context.l10n.storeTitle(item),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    color: owned ? Colors.greenAccent : Colors.amber,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              context.l10n.storeDescription(item),
              style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
            ),
            const SizedBox(height: 8),
            StoreItemPreview(item: item, size: 32),
          ],
        ),
      ),
    );
  }
}
