import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbitron_tactics/core/game_logic/engine/battle_engine.dart';
import 'package:orbitron_tactics/core/game_logic/models/piece.dart';
import 'package:orbitron_tactics/core/game_logic/models/upgrade_profile.dart';
import 'package:orbitron_tactics/features/battle/presentation/providers/battle_state_provider.dart';
import 'package:orbitron_tactics/features/battle/presentation/screens/battle_screen.dart';
import 'package:orbitron_tactics/features/battle/presentation/widgets/maneuver_pad.dart';
import 'package:orbitron_tactics/features/battle/presentation/widgets/shield_button.dart';

void main() {
  /// Pumps a hot-seat battle — both players get controls, the tightest
  /// layout there is — on a small phone.
  Future<ProviderContainer> pumpBattle(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final container = ProviderContainer();
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
      child: const MaterialApp(
        home: BattleScreen(attackerColor: PlayerColor.white),
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

  testWidgets('the arena still fits a short screen', (tester) async {
    final container = await pumpBattle(tester, const Size(320, 568));

    expect(tester.takeException(), isNull);

    container.read(battleStateProvider.notifier).stopBattle();
    await tester.pump();
  });
}
