import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../battle/presentation/audio/battle_audio.dart';

import '../../../telemetry/presentation/telemetry_provider.dart';
import '../../data/purchase_service.dart';
import '../../data/store_catalog.dart';
import '../providers/store_providers.dart';
import 'store_item_preview.dart';
import '../../../../l10n/l10n.dart';

/// Opens [item]'s page from anywhere in the game; [from] says where, for
/// telemetry.
Future<void> showStoreItemSheet(
  BuildContext context,
  WidgetRef ref,
  StoreItem item, {
  required String from,
}) {
  ref
      .read(telemetryProvider)
      .event('store_item_viewed', {'product': item.id, 'from': from});
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: const Color(0xFF15152B),
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => StoreItemSheet(item: item),
  );
}

/// One store item: what it holds, what it costs, and the button to buy it.
class StoreItemSheet extends ConsumerStatefulWidget {
  const StoreItemSheet({super.key, required this.item});

  final StoreItem item;

  @override
  ConsumerState<StoreItemSheet> createState() => _StoreItemSheetState();
}

class _StoreItemSheetState extends ConsumerState<StoreItemSheet> {
  bool _busy = false;

  Future<void> _buy() async {
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final outcome =
        await ref.read(entitlementsProvider.notifier).buy(widget.item);
    if (!mounted) return;
    setState(() => _busy = false);
    final l10n = context.l10n;
    final title = l10n.storeTitle(widget.item);
    final message = switch (outcome) {
      Purchased() => l10n.purchaseDone(title),
      PurchasePending() => l10n.purchasePending(title),
      PurchaseFailed(failure: PurchaseFailure.storeUnavailable) =>
        l10n.storeUnavailableShort,
      PurchaseFailed(failure: PurchaseFailure.notInStore) =>
        l10n.notInStoreYet,
      PurchaseFailed(:final message) => message,
      PurchaseCancelled() => null,
    };
    if (outcome is Purchased || outcome is PurchasePending) navigator.pop();
    if (message != null) {
      messenger.showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final owned = ref.watch(entitlementsProvider).owns(item);
    final available = ref.watch(purchaseServiceProvider).available;
    final prices = ref.watch(storePricesProvider).valueOrNull ?? const {};
    final price = prices[item.id];
    final canBuy = available && !owned && price != null && !_busy;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              context.l10n.storeTitle(item),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              context.l10n.storeDescription(item),
              style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            ),
            const SizedBox(height: 16),
            StoreItemPreview(item: item, size: 48),
            if (item.music case final music?) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () => BattleAudio.instance.preview(music),
                icon: const Icon(Icons.play_arrow),
                label: Text(context.l10n.listen),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: canBuy ? _buy : null,
                child: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(owned
                        ? context.l10n.owned
                        : !available
                            ? context.l10n.storeNotAvailableButton
                            : price == null
                                ? context.l10n.notInStoreYet
                                : context.l10n.buyPrice(price)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
