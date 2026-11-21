import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbitron_tactics/core/ai/ai_difficulty.dart';
import 'package:orbitron_tactics/core/game_logic/models/piece.dart';
import 'package:orbitron_tactics/core/game_logic/models/position.dart';
import 'package:orbitron_tactics/features/game/presentation/providers/board_interaction_provider.dart';
import 'package:orbitron_tactics/features/game/presentation/providers/game_state_provider.dart';
import 'package:orbitron_tactics/features/game/presentation/screens/game_screen.dart';
import 'package:orbitron_tactics/features/game/presentation/widgets/board/game_board.dart';
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
  });

  tearDown(() => container.dispose());

  testWidgets('playing white, the white king sits in the bottom half',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(500, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    container.read(gameStateProvider.notifier).startSinglePlayerGame(
          profile: AiProfile.easy,
          humanColor: PlayerColor.white,
          humanName: 'Ada',
        );
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: GameScreen()),
    ));

    final board = container.read(gameStateProvider).board;
    late Position king;
    for (var row = 0; row < 8; row++) {
      for (var col = 0; col < 8; col++) {
        final piece = board.grid[row][col];
        if (piece?.type == PieceType.king &&
            piece?.color == PlayerColor.white) {
          king = Position(row: row, col: col);
        }
      }
    }

    // White's back row is drawn at the bottom, column 0 on the left.
    final rect = tester.getRect(find.byType(GameBoard));
    final square = rect.width / 8;
    final visualRow = 7 - king.row;
    expect(visualRow, greaterThanOrEqualTo(4));
    await tester.tapAt(Offset(
      rect.left + (king.col + 0.5) * square,
      rect.top + (visualRow + 0.5) * square,
    ));
    await tester.pump();

    expect(container.read(boardInteractionProvider).selectedPosition, king);
  });
}
