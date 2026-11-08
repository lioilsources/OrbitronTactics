import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../telemetry/presentation/telemetry_provider.dart';
import '../../data/store_catalog.dart';
import '../providers/store_providers.dart';
import 'store_item_preview.dart';
import 'store_item_sheet.dart';

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
    final owned = await ref.read(entitlementsProvider.notifier).restore();
    if (!mounted) return;
    setState(() => _restoring = false);
    messenger.showSnackBar(SnackBar(
      content: Text(switch (owned) {
        null => 'The store could not be reached',
        0 => 'No earlier purchases on this account',
        1 => 'Restored 1 purchase',
        final count => 'Restored $count purchases',
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
          'The whole game is free. These change how it looks, not who wins.',
          style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
        ),
        if (!available) ...[
          const SizedBox(height: 8),
          Text(
            'The store is not available on this build.',
            style: TextStyle(color: Colors.orange.shade300, fontSize: 13),
          ),
        ],
        const SizedBox(height: 12),
        for (final item in StoreCatalog.items)
          _StoreTile(
            item: item,
            label: priceLabel(item, prices, entitlements.owns(item)),
            owned: entitlements.owns(item),
            onTap: () => showStoreItemSheet(context, ref, item, from: 'store'),
          ),
        const SizedBox(height: 8),
        Center(
          child: TextButton(
            onPressed: available && !_restoring ? _restore : null,
            child: Text(_restoring ? 'RESTORING…' : 'RESTORE PURCHASES'),
          ),
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
                    item.title,
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
              item.description,
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
