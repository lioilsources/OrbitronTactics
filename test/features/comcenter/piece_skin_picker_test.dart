import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbitron_tactics/features/battle/data/fleet_skin.dart';
import 'package:orbitron_tactics/features/comcenter/presentation/screens/comcenter_screen.dart';
import 'package:orbitron_tactics/features/comcenter/presentation/widgets/upgrade_card.dart';
import 'package:orbitron_tactics/features/comcenter/presentation/widgets/piece_skin_picker.dart';
import 'package:orbitron_tactics/features/game/data/piece_skin.dart';
import 'package:orbitron_tactics/features/game/presentation/providers/piece_skin_provider.dart';
import 'package:orbitron_tactics/features/progress/data/fleet_progress_store.dart';
import 'package:orbitron_tactics/features/progress/presentation/providers/fleet_progress_provider.dart';
import 'package:orbitron_tactics/features/store/presentation/widgets/store_item_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<(ProviderContainer, SharedPreferences)> pumpComcenter(
      WidgetTester tester) async {
    // Tall enough for every world card, so the lazy list builds them all.
    tester.view.physicalSize = Size(420, 600.0 + 300 * PieceSkin.values.length);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(overrides: [
      fleetProgressStoreProvider.overrideWithValue(FleetProgressStore(prefs)),
      pieceSkinStoreProvider.overrideWithValue(PieceSkinStore(prefs)),
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: ComcenterScreen()),
    ));
    await tester.pumpAndSettle();
    return (container, prefs);
  }

  testWidgets('the Comcenter opens on the world, then units, maneuvers and '
      'the store', (tester) async {
    await pumpComcenter(tester);

    final tabs = tester.widgetList<Tab>(find.byType(Tab)).map((tab) => tab.text);
    expect(tabs, ['WORLD', 'UNITS', 'MANEUVERS', 'STORE']);
    expect(find.byType(PieceSkinPicker), findsOneWidget);
    // One look picker: no fleet picker on the units tab.
    await tester.tap(find.text('UNITS'));
    await tester.pumpAndSettle();
    expect(find.byType(FleetPicker), findsNothing);
    expect(find.byType(UpgradeCard), findsNWidgets(6));
  });

  testWidgets('the world tab picks a world and the classic marks',
      (tester) async {
    final (container, prefs) = await pumpComcenter(tester);

    // Space is the stored default: its fleets are on offer, not the marks.
    expect(container.read(pieceSkinProvider).skin.isSpace, isTrue);
    expect(find.text('Space'), findsOneWidget);
    expect(find.byType(FleetPicker), findsOneWidget);
    expect(find.text('Classic marks'), findsNothing);

    // Both armies of every image world.
    expect(find.byType(PieceSkinCard), findsNWidgets(PieceSkin.values.length));
    final imagePacks = PieceSkin.values.where((skin) => skin.isImagePack).length;
    expect(
        find.descendant(
            of: find.byType(PieceSkinCard), matching: find.byType(Image)),
        findsNWidgets(12 * imagePacks));
    expect(find.text(FleetSkin.fallback.displayName), findsWidgets);

    await tester.tap(find.text('Heaven × Hell'));
    await tester.pumpAndSettle();
    expect(find.byType(FleetPicker), findsNothing);
    await tester.tap(find.text('Classic marks'));
    await tester.pumpAndSettle();

    expect(
      container.read(pieceSkinProvider),
      const PieceSkinSettings(skin: PieceSkin.heavenHell, classicMarks: true),
    );
    expect(prefs.getString(PieceSkinStore.skinKey), 'heaven_hell');
  });

  testWidgets('a locked world opens its store page instead of being chosen',
      (tester) async {
    final (container, _) = await pumpComcenter(tester);
    const locked = PieceSkin.samuraiYokai;
    expect(locked.premium, isTrue);

    await tester.tap(find.text('Samurai × Yōkai'));
    await tester.pumpAndSettle();

    expect(container.read(pieceSkinProvider).skin, PieceSkin.classic);
    expect(find.byType(StoreItemSheet), findsOneWidget);
  });
}
