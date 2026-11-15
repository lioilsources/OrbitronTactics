import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbitron_tactics/features/comcenter/presentation/screens/comcenter_screen.dart';
import 'package:orbitron_tactics/features/comcenter/presentation/widgets/piece_skin_picker.dart';
import 'package:orbitron_tactics/features/game/data/piece_skin.dart';
import 'package:orbitron_tactics/features/game/presentation/providers/piece_skin_provider.dart';
import 'package:orbitron_tactics/features/progress/data/fleet_progress_store.dart';
import 'package:orbitron_tactics/features/progress/presentation/providers/fleet_progress_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('the board tab picks a pack and the classic marks',
      (tester) async {
    tester.view.physicalSize = const Size(420, 1400);
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
    await tester.tap(find.text('BOARD'));
    await tester.pumpAndSettle();

    // Both armies of every pack: six white and six black pieces each.
    expect(find.byType(PieceSkinCard), findsNWidgets(PieceSkin.values.length));
    expect(find.byType(Image), findsNWidgets(12));

    await tester.tap(find.text('Heaven × Hell'));
    await tester.tap(find.text('Classic marks'));
    await tester.pumpAndSettle();

    expect(
      container.read(pieceSkinProvider),
      const PieceSkinSettings(skin: PieceSkin.heavenHell, classicMarks: true),
    );
    expect(prefs.getString(PieceSkinStore.skinKey), 'heaven_hell');
  });
}
