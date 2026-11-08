import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbitron_tactics/features/battle/data/battle_music.dart';
import 'package:orbitron_tactics/features/comcenter/presentation/screens/comcenter_screen.dart';
import 'package:orbitron_tactics/features/comcenter/presentation/widgets/maneuver_card.dart';
import 'package:orbitron_tactics/features/progress/data/fleet_progress_store.dart';
import 'package:orbitron_tactics/features/progress/presentation/providers/fleet_progress_provider.dart';
import 'package:orbitron_tactics/features/store/data/purchase_service.dart';
import 'package:orbitron_tactics/features/store/data/store_catalog.dart';
import 'package:orbitron_tactics/features/store/presentation/providers/store_providers.dart';
import 'package:orbitron_tactics/features/store/presentation/widgets/store_item_sheet.dart';
import 'package:orbitron_tactics/features/store/presentation/widgets/store_tab.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late ProviderContainer container;

  Future<void> open(WidgetTester tester, {PurchaseService? service}) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    container = ProviderContainer(overrides: [
      fleetProgressStoreProvider.overrideWithValue(FleetProgressStore(prefs)),
      purchaseServiceProvider
          .overrideWithValue(service ?? DebugPurchaseService(prefs)),
    ]);
    addTearDown(container.dispose);
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: ComcenterScreen()),
    ));
    await tester.pumpAndSettle();
  }

  String skin() =>
      container.read(fleetProgressProvider(playerFleetIdentity)).skin ??
      'vanguard';

  testWidgets('a locked fleet opens its store page and flies once bought',
      (tester) async {
    await open(tester);

    await tester.tap(find.text('Solar Crusade'));
    await tester.pumpAndSettle();

    expect(find.byType(StoreItemSheet), findsOneWidget);
    expect(skin(), 'vanguard');

    await tester.tap(find.text('BUY FREE (debug)'));
    await tester.pumpAndSettle();

    expect(find.byType(StoreItemSheet), findsNothing);
    expect(find.text('Solar Crusade is yours'), findsOneWidget);
    expect(skin(), 'solar_crusade');
  });

  testWidgets('a free fleet is picked without the store', (tester) async {
    await open(tester);

    await tester.tap(find.text('Void Hive'));
    await tester.pumpAndSettle();

    expect(find.byType(StoreItemSheet), findsNothing);
    expect(skin(), 'void_hive');
  });

  testWidgets('the store tab lists every item and restores', (tester) async {
    await open(tester);

    await tester.tap(find.text('STORE'));
    await tester.pumpAndSettle();

    expect(find.text(StoreCatalog.items.first.title), findsOneWidget);
    await tester.scrollUntilVisible(find.text('RESTORE PURCHASES'), 200,
        scrollable: find
            .descendant(
                of: find.byType(StoreTab), matching: find.byType(Scrollable))
            .first);
    await tester.tap(find.text('RESTORE PURCHASES'));
    await tester.pumpAndSettle();

    expect(find.text('No earlier purchases on this account'), findsOneWidget);
  });

  testWidgets('locked music leads to its page, owned music is picked',
      (tester) async {
    await open(tester);
    await tester.tap(find.text('STORE'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Retro Arcade'));
    await tester.pumpAndSettle();
    expect(find.byType(StoreItemSheet), findsOneWidget);
    expect(find.text('LISTEN'), findsOneWidget);

    await tester.tap(find.text('BUY FREE (debug)'));
    await tester.pumpAndSettle();
    expect(container.read(battleMusicProvider), BattleMusic.retro);

    await tester.tap(find.text('Standard'));
    await tester.pumpAndSettle();
    expect(container.read(battleMusicProvider), BattleMusic.standard);
  });

  testWidgets('without a store the page says so and sells nothing',
      (tester) async {
    await open(tester, service: const UnavailablePurchaseService());

    await tester.tap(find.text('Neon Runners'));
    await tester.pumpAndSettle();

    final buy = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'STORE NOT AVAILABLE'));
    expect(buy.onPressed, isNull);
  });

  testWidgets('a pack maneuver leads to the pack', (tester) async {
    await open(tester);

    await tester.tap(find.text('MANEUVERS'));
    await tester.pumpAndSettle();
    final corkscrew = find.ancestor(
        of: find.text('Corkscrew'), matching: find.byType(ManeuverCard));
    await tester.scrollUntilVisible(find.text('Corkscrew'), 200,
        scrollable: find
            .ancestor(
                of: find.byType(ManeuverCard).first,
                matching: find.byType(Scrollable))
            .first);
    final getPack =
        find.descendant(of: corkscrew, matching: find.text('GET PACK'));
    await tester.ensureVisible(getPack);
    await tester.pumpAndSettle();
    await tester.tap(getPack);
    await tester.pumpAndSettle();

    expect(find.text(StoreCatalog.forPack('ace').title), findsWidgets);
    expect(find.byType(StoreItemSheet), findsOneWidget);
  });
}
