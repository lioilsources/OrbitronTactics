import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbitron_tactics/core/game_logic/models/fleet_progress.dart';
import 'package:orbitron_tactics/core/game_logic/models/piece.dart';
import 'package:orbitron_tactics/core/maneuvers/maneuver_catalog.dart';
import 'package:orbitron_tactics/features/comcenter/presentation/screens/comcenter_screen.dart';
import 'package:orbitron_tactics/features/comcenter/presentation/widgets/maneuver_card.dart';
import 'package:orbitron_tactics/features/progress/data/fleet_progress_store.dart';
import 'package:orbitron_tactics/features/progress/presentation/providers/fleet_progress_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late ProviderContainer container;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final store = FleetProgressStore(await SharedPreferences.getInstance());
    container = ProviderContainer(
      overrides: [fleetProgressStoreProvider.overrideWithValue(store)],
    );
    addTearDown(container.dispose);
  });

  FleetProgress progress() =>
      container.read(fleetProgressProvider(playerFleetIdentity));

  Future<void> openManeuvers(WidgetTester tester) async {
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: ComcenterScreen()),
    ));
    await tester.tap(find.text('MANEUVERS'));
    await tester.pumpAndSettle();
  }

  testWidgets('the tab lists what a ship can fly', (tester) async {
    await openManeuvers(tester);

    // The list builds lazily; what matters is that it is the pawn's.
    expect(find.byType(ManeuverCard), findsWidgets);
    expect(find.text(ManeuverCatalog.forShip(PieceType.pawn).first.name),
        findsOneWidget);
    expect(find.text('ARMED 2/4'), findsOneWidget);
  });

  testWidgets('a starter can be taken off the pad and put back',
      (tester) async {
    await openManeuvers(tester);
    final starter = ManeuverCatalog.starterIds(PieceType.pawn).first;

    await tester.tap(find.text('ARMED').first);
    await tester.pumpAndSettle();

    expect(progress().maneuversFor(PieceType.pawn).active,
        isNot(contains(starter)));
    expect(find.text('ARMED 1/4'), findsOneWidget);

    await tester.tap(find.text('ARM').first);
    await tester.pumpAndSettle();

    expect(
        progress().maneuversFor(PieceType.pawn).active, contains(starter));
  });

  testWidgets('another ship shows its own maneuvers', (tester) async {
    await openManeuvers(tester);

    await tester.tap(find.text('ROOK'));
    await tester.pumpAndSettle();

    expect(find.text(ManeuverCatalog.forShip(PieceType.rook).first.name),
        findsOneWidget);
    expect(find.text(ManeuverCatalog.forShip(PieceType.pawn).first.name),
        findsNothing);
  });
}
