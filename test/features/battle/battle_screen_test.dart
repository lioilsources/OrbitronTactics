import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbitron_tactics/core/game_logic/engine/battle_engine.dart';
import 'package:orbitron_tactics/core/game_logic/models/piece.dart';
import 'package:orbitron_tactics/core/game_logic/models/upgrade_profile.dart';
import 'package:orbitron_tactics/features/battle/data/fleet_skin.dart';
import 'package:orbitron_tactics/features/battle/data/unit_art.dart';
import 'package:orbitron_tactics/features/battle/presentation/providers/battle_state_provider.dart';
import 'package:orbitron_tactics/features/battle/presentation/screens/battle_screen.dart';
import 'package:orbitron_tactics/features/battle/presentation/widgets/maneuver_pad.dart';
import 'package:orbitron_tactics/features/battle/presentation/widgets/battle_arena_painter.dart';
import 'package:orbitron_tactics/features/battle/presentation/widgets/shield_button.dart';
import 'package:orbitron_tactics/features/battle/presentation/widgets/unit_combat_panel.dart';
import 'package:orbitron_tactics/features/game/data/piece_skin.dart';
import 'package:orbitron_tactics/features/onboarding/data/onboarding_store.dart';
import 'package:orbitron_tactics/features/onboarding/presentation/onboarding_provider.dart';
import 'package:orbitron_tactics/features/progress/data/fleet_progress_store.dart';
import 'package:orbitron_tactics/features/progress/presentation/providers/fleet_progress_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  /// Pumps a hot-seat battle — both players get controls, the tightest
  /// layout there is — on a small phone.
  Future<ProviderContainer> pumpBattle(WidgetTester tester, Size size,
      {OnboardingStore? onboarding, PieceSkin? world}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(overrides: [
      fleetProgressStoreProvider.overrideWithValue(FleetProgressStore(prefs)),
      if (onboarding != null)
        onboardingStoreProvider.overrideWithValue(onboarding),
    ]);
    addTearDown(container.dispose);
    container.read(battleStateProvider.notifier).startBattle(
          initial: BattleEngine.createBattle(
            attacker:
                const Piece(type: PieceType.knight, color: PlayerColor.white),
            defender:
                const Piece(type: PieceType.queen, color: PlayerColor.black),
            attackerUpgrades: const UpgradeProfile(),
            defenderUpgrades: const UpgradeProfile(),
          ),
          attackerColor: PlayerColor.white,
        );
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: BattleScreen(
          attackerColor: PlayerColor.white,
          attackerArt: world == null
              ? null
              : unitArt(world, FleetSkin.fallback, PieceType.knight,
                  PlayerColor.white),
          defenderArt: world == null
              ? null
              : unitArt(world, FleetSkin.fallback, PieceType.queen,
                  PlayerColor.black),
        ),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 50));
    return container;
  }

  testWidgets('both players get a pad, a panel and a shield', (tester) async {
    final container = await pumpBattle(tester, const Size(360, 640));

    expect(find.byType(ManeuverPad), findsNWidgets(2));
    expect(find.byType(ShieldButton), findsNWidgets(2));
    expect(tester.takeException(), isNull);

    // The battle's ticker outlives the widget tree otherwise.
    container.read(battleStateProvider.notifier).stopBattle();
    await tester.pump();
  });

  testWidgets('a figure world fights with its standing figures',
      (tester) async {
    final container = await pumpBattle(tester, const Size(360, 640),
        world: PieceSkin.romeCarthage);
    await tester.pump(const Duration(milliseconds: 100));

    final painter = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((paint) => paint.painter)
        .whereType<BattleArenaPainter>()
        .single;
    expect(painter.attackerPose, UnitPose.standing);
    expect(painter.defenderPose, UnitPose.standing);
    expect(painter.defenderMirrored, isTrue);
    // Hot-seat: the top player sits across the device.
    expect(painter.topPlayerAcross, isTrue);
    final panels = tester
        .widgetList<UnitCombatPanel>(find.byType(UnitCombatPanel))
        .map((panel) => panel.spriteAsset);
    expect(panels, contains('assets/pieces/rome_carthage/knight_white.png'));
    expect(panels, contains('assets/pieces/rome_carthage/queen_black.png'));
    expect(tester.takeException(), isNull);

    container.read(battleStateProvider.notifier).stopBattle();
    await tester.pump();
  });

  testWidgets('the arena still fits a short screen', (tester) async {
    final container = await pumpBattle(tester, const Size(320, 568));

    expect(tester.takeException(), isNull);

    container.read(battleStateProvider.notifier).stopBattle();
    await tester.pump();
  });

  testWidgets('a first battle spells out the controls until the arena is '
      'touched', (tester) async {
    final onboarding = MemoryOnboardingStore(seen: false);
    final container = await pumpBattle(tester, const Size(360, 640),
        onboarding: onboarding);
    final hint = find.textContaining('Drag across your half');

    expect(hint, findsOneWidget);

    await tester.tapAt(tester.getCenter(hint));
    await tester.pump();

    expect(hint, findsNothing);
    expect(onboarding.battleHintSeen, isTrue);

    container.read(battleStateProvider.notifier).stopBattle();
    await tester.pump();
  });

  testWidgets('a seasoned player gets no hint', (tester) async {
    final container = await pumpBattle(tester, const Size(360, 640));

    expect(find.textContaining('Drag across your half'), findsNothing);

    container.read(battleStateProvider.notifier).stopBattle();
    await tester.pump();
  });
}
