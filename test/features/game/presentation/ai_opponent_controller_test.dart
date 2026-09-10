import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbitron_tactics/core/ai/ai_difficulty.dart';
import 'package:orbitron_tactics/core/game_logic/models/piece.dart';
import 'package:orbitron_tactics/features/game/presentation/providers/ai_opponent_controller.dart';
import 'package:orbitron_tactics/features/game/presentation/providers/game_state_provider.dart';

import '../../../core/game_logic/test_helpers.dart';

void main() {
  const profile = AiProfile.easy;
  final thinkDelay = Duration(milliseconds: profile.thinkDelayMs);

  /// A single-player game with the AI controller attached.
  (ProviderContainer, AiOpponentController) startGame(PlayerColor humanColor) {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container
        .read(gameStateProvider.notifier)
        .startSinglePlayerGame(profile: profile, humanColor: humanColor);
    final sub = container.listen(aiOpponentProvider, (_, _) {});
    addTearDown(sub.close);
    return (container, container.read(aiOpponentProvider)!);
  }

  testWidgets('AI plays its move after the think delay', (tester) async {
    final (container, controller) = startGame(PlayerColor.black);
    expect(controller.isThinking.value, isTrue);

    await tester.pump(thinkDelay ~/ 2);
    expect(container.read(gameStateProvider).moveCount, 0);

    await tester.pump(thinkDelay);
    final state = container.read(gameStateProvider);
    expect(state.moveCount, 1);
    expect(state.currentTurn, PlayerColor.black);
    expect(controller.isThinking.value, isFalse);
  });

  testWidgets('AI stays idle on the player turn', (tester) async {
    final (container, controller) = startGame(PlayerColor.white);

    await tester.pump(thinkDelay * 3);

    expect(container.read(gameStateProvider).moveCount, 0);
    expect(controller.isThinking.value, isFalse);
  });

  testWidgets('AI answers the player move', (tester) async {
    final (container, _) = startGame(PlayerColor.white);

    container.read(gameStateProvider.notifier).tryMove(pos(1, 0), pos(2, 1));
    await tester.pump(thinkDelay + const Duration(milliseconds: 1));

    final state = container.read(gameStateProvider);
    expect(state.moveCount, 2);
    expect(state.currentTurn, PlayerColor.white);
  });

  testWidgets('AI holds its move while the battle screen is open',
      (tester) async {
    final (container, controller) = startGame(PlayerColor.white);
    controller.battleScreenOpen = true;

    container.read(gameStateProvider.notifier).tryMove(pos(1, 0), pos(2, 1));
    await tester.pump(thinkDelay * 3);
    expect(container.read(gameStateProvider).moveCount, 1);

    controller.battleScreenOpen = false;
    await tester.pump(thinkDelay + const Duration(milliseconds: 1));
    expect(container.read(gameStateProvider).moveCount, 2);
  });

  testWidgets('a restart discards the move planned for the previous game',
      (tester) async {
    final (container, _) = startGame(PlayerColor.black);
    await tester.pump(thinkDelay ~/ 2);

    container.read(gameStateProvider.notifier).restartCurrentMode();
    // The first game's move would have been due now.
    await tester.pump(thinkDelay ~/ 2 + const Duration(milliseconds: 1));
    expect(container.read(gameStateProvider).moveCount, 0);

    await tester.pump(thinkDelay);
    expect(container.read(gameStateProvider).moveCount, 1);
  });

  test('no controller outside single player', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(aiOpponentProvider), isNull);
  });
}
