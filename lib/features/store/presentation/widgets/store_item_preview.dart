import 'package:flutter/material.dart';

import '../../../../core/game_logic/models/piece.dart';
import '../../../../core/maneuvers/maneuver_catalog.dart';
import '../../../battle/data/battle_element.dart';
import '../../../battle/presentation/widgets/pattern_glyph.dart';
import '../../data/store_catalog.dart';

/// What a store item looks like: a fleet's ships, a pack's gesture, or a
/// knight from each fleet a bundle holds.
class StoreItemPreview extends StatelessWidget {
  const StoreItemPreview({super.key, required this.item, this.size = 40});

  final StoreItem item;

  /// Height of one ship.
  final double size;

  @override
  Widget build(BuildContext context) {
    switch (item.kind) {
      case StoreItemKind.fleet:
        return _Ships(
          assets: [
            for (final type in PieceType.values)
              item.fleet!.assetFor(type, PlayerColor.white),
          ],
          size: size,
        );
      case StoreItemKind.fleetBundle:
      case StoreItemKind.commander:
        return _Ships(
          assets: [
            for (final skin in StoreCatalog.premiumFleets)
              skin.assetFor(PieceType.knight, PlayerColor.white),
          ],
          size: size,
        );
      case StoreItemKind.maneuverPack:
        final maneuvers = ManeuverCatalog.inPack(item.pack!.id);
        if (maneuvers.isEmpty) return SizedBox(height: size);
        return Row(
          children: [
            for (final maneuver in maneuvers.take(6))
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: PatternGlyph(
                  pattern: maneuver.pattern,
                  color: BattleElement.of(maneuver.ship).color,
                  size: size,
                ),
              ),
          ],
        );
    }
  }
}

class _Ships extends StatelessWidget {
  const _Ships({required this.assets, required this.size});

  final List<String> assets;
  final double size;

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 4,
        runSpacing: 4,
        children: [
          for (final asset in assets)
            Image.asset(asset, width: size, height: size),
        ],
      );
}

/// The badge a store item carries in a list: its price, OWNED, or a dash
/// while the store is out of reach.
String priceLabel(StoreItem item, Map<String, String> prices, bool owned) =>
    owned ? 'OWNED' : prices[item.id] ?? '—';
