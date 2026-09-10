import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbitron_tactics/core/ai/ai_difficulty.dart';
import 'package:orbitron_tactics/core/game_logic/models/game_phase.dart';
import 'package:orbitron_tactics/core/game_logic/models/piece.dart';
import 'package:orbitron_tactics/core/game_logic/models/victory_condition.dart';
import 'package:orbitron_tactics/features/game/presentation/providers/game_state_provider.dart';
import 'package:orbitron_tactics/features/game/presentation/screens/game_screen.dart';
import 'package:orbitron_tactics/features/progress/data/fleet_progress_store.dart';
import 'package:orbitron_tactics/features/progress/presentation/providers/fleet_progress_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const profile = AiProfile.easy;
  late ProviderContainer container;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final store = FleetProgressStore(await SharedPreferences.getInstance());
    container = ProviderContainer(
      overrides: [fleetProgressStoreProvider.overrideWithValue(store)],
    );
  });

  tearDown(() => container.dispose());

  Future<void> showGame(WidgetTester tester, PlayerColor humanColor) async {
    container.read(gameStateProvider.notifier).startSinglePlayerGame(
          profile: profile,
          humanColor: humanColor,
          humanName: 'Ada',
        );
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: GameScreen()),
    ));
  }

  testWidgets('the AI thinks, then plays its move', (tester) async {
    await showGame(tester, PlayerColor.black);

    expect(find.text(profile.displayName), findsOneWidget);
    expect(find.text('Ada'), findsOneWidget);
    expect(find.text('THINKING…'), findsOneWidget);

    await tester.pump(Duration(milliseconds: profile.thinkDelayMs + 1));
    // Let the board finish animating the AI's move.
    await tester.pump(const Duration(milliseconds: 300));

    expect(container.read(gameStateProvider).moveCount, 1);
    expect(find.text('THINKING…'), findsNothing);
    expect(find.text('TURN'), findsOneWidget);
  });

  testWidgets('game over shows the credits the player earned',
      (tester) async {
    await showGame(tester, PlayerColor.white);
    final game = container.read(gameStateProvider.notifier);

    game.onBattleReward!(PlayerColor.white, 60);
    game.state = game.state.copyWith(
      phase: GamePhase.finished,
      winner: PlayerColor.white,
      victoryCondition: const VictoryCondition.royalElimination(),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('+60 cr'), findsOneWidget);
  });
}
