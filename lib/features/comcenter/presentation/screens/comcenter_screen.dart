import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/game_logic/models/fleet_progress.dart';
import '../../../../core/game_logic/models/piece.dart';
import '../../../../core/game_logic/models/ship_maneuvers.dart';
import '../../../../core/maneuvers/maneuver_catalog.dart';
import '../../../battle/data/battle_element.dart';
import '../../../battle/data/fleet_skin.dart';
import '../../../battle/data/unit_art.dart';
import '../../../game/presentation/providers/piece_skin_provider.dart';
import '../../../battle/presentation/widgets/pattern_glyph.dart';
import '../../../progress/presentation/providers/fleet_progress_provider.dart';
import '../../../store/data/store_catalog.dart';
import '../../../store/presentation/providers/store_providers.dart';
import '../../../store/presentation/widgets/store_item_sheet.dart';
import '../../../store/presentation/widgets/store_tab.dart';
import '../../../../l10n/l10n.dart';
import '../widgets/maneuver_card.dart';
import '../widgets/piece_skin_picker.dart';
import '../widgets/upgrade_card.dart';

class ComcenterScreen extends ConsumerWidget {
  const ComcenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // The player's saved fleet — the upgrades, ship art and maneuvers
    // single-player battles use.
    final fleet = ref.watch(fleetProgressProvider(playerFleetIdentity));
    final l10n = context.l10n;

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: const Color(0xFF0D0D1A),
        appBar: AppBar(
          title: Text(
            l10n.comcenterTitle,
            style: const TextStyle(letterSpacing: 3, fontWeight: FontWeight.bold),
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
                    l10n.creditsAmount(fleet.credits),
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
          bottom: TabBar(
            labelColor: Colors.amber,
            unselectedLabelColor: Colors.white54,
            indicatorColor: Colors.amber,
            tabs: [
              Tab(text: l10n.worldTab),
              Tab(text: l10n.unitsTab),
              Tab(text: l10n.maneuversTab),
              Tab(text: l10n.tabStore),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            const PieceSkinPicker(),
            _UnitsTab(fleet: fleet),
            _ManeuversTab(fleet: fleet),
            const StoreTab(),
          ],
        ),
      ),
    );
  }
}

/// Unit upgrades, each unit drawn as it fights in the chosen world.
class _UnitsTab extends ConsumerWidget {
  const _UnitsTab({required this.fleet});

  final FleetProgress fleet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final world = ref.watch(pieceSkinProvider).skin;
    final skin = FleetSkin.fromSlug(fleet.skin);
    final player =
        ref.read(fleetProgressProvider(playerFleetIdentity).notifier);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.upgradeHint,
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
                  level: fleet.profile.levelFor(type),
                  credits: fleet.credits,
                  onUpgrade: () => player.upgrade(type),
                  artAsset:
                      unitArt(world, skin, type, PlayerColor.white).asset,
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

/// What each ship can fly: the four armed gestures and the whole catalog.
class _ManeuversTab extends ConsumerStatefulWidget {
  const _ManeuversTab({required this.fleet});

  final FleetProgress fleet;

  @override
  ConsumerState<_ManeuversTab> createState() => _ManeuversTabState();
}

class _ManeuversTabState extends ConsumerState<_ManeuversTab> {
  PieceType _ship = PieceType.pawn;

  @override
  Widget build(BuildContext context) {
    final fleet = widget.fleet;
    final entitlements = ref.watch(entitlementsProvider);
    final learned = fleet.maneuversFor(_ship);
    final accent = BattleElement.of(_ship).color;
    final player =
        ref.read(fleetProgressProvider(playerFleetIdentity).notifier);

    void arm(String id) => player.armManeuvers(_ship, [...learned.active, id]);
    void unarm(String id) => player.armManeuvers(
        _ship, [for (final armed in learned.active) if (armed != id) armed]);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: PieceType.values.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final ship = PieceType.values[index];
                return ChoiceChip(
                  label: Text(context.l10n.pieceTypeName(ship).toUpperCase()),
                  labelStyle: TextStyle(
                    fontSize: 11,
                    color: ship == _ship ? Colors.black : Colors.white70,
                  ),
                  selectedColor: BattleElement.of(ship).color,
                  backgroundColor: const Color(0xFF1A1A2E),
                  selected: ship == _ship,
                  showCheckmark: false,
                  onSelected: (_) => setState(() => _ship = ship),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                context.l10n.armedCount(
                    learned.active.length, ShipManeuvers.slots),
                style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 11,
                    letterSpacing: 1.2),
              ),
              const SizedBox(width: 10),
              Text(
                context.l10n.battlesWon(fleet.battleWinsWith(_ship)),
                style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              for (var slot = 0; slot < ShipManeuvers.slots; slot++)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _Slot(
                    id: slot < learned.active.length
                        ? learned.active[slot]
                        : null,
                    accent: accent,
                    onTap: unarm,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView(
              children: [
                for (final maneuver in ManeuverCatalog.forShip(_ship))
                  ManeuverCard(
                    maneuver: maneuver,
                    accent: accent,
                    // A refunded pack's maneuvers show locked again.
                    owned: learned.owned.contains(maneuver.id) &&
                        entitlements.allowsManeuver(maneuver),
                    armed: learned.active.contains(maneuver.id) &&
                        entitlements.allowsManeuver(maneuver),
                    level: learned.levelOf(maneuver.id),
                    credits: fleet.credits,
                    battleWins: fleet.battleWinsWith(_ship),
                    hasFreeSlot: learned.hasFreeSlot,
                    onArm: () => arm(maneuver.id),
                    onUnarm: () => unarm(maneuver.id),
                    onBuy: () => player.buyManeuver(_ship, maneuver.id),
                    onTrain: () => player.upgradeManeuver(_ship, maneuver.id),
                    onGetPack: (pack) => showStoreItemSheet(
                        context, ref, StoreCatalog.forPack(pack),
                        from: 'maneuver'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One of the four gestures a ship takes into battle.
class _Slot extends StatelessWidget {
  const _Slot({required this.id, required this.accent, required this.onTap});

  final String? id;
  final Color accent;
  final void Function(String id) onTap;

  @override
  Widget build(BuildContext context) {
    final maneuver = id == null ? null : ManeuverCatalog.byId(id!);
    return GestureDetector(
      onTap: maneuver == null ? null : () => onTap(maneuver.id),
      child: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          color: const Color(0xFF15152B),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: maneuver == null
                ? Colors.blueGrey.shade800
                : accent.withValues(alpha: 0.6),
          ),
        ),
        child: maneuver == null
            ? Icon(Icons.add, size: 18, color: Colors.blueGrey.shade700)
            : Padding(
                padding: const EdgeInsets.all(5),
                child: PatternGlyph(
                    pattern: maneuver.pattern, color: accent, size: 46),
              ),
      ),
    );
  }
}
