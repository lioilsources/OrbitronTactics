import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbitron_tactics/core/ai/ai_difficulty.dart';
import 'package:orbitron_tactics/core/game_logic/board/board_spec.dart';
import 'package:orbitron_tactics/core/game_logic/models/piece.dart';
import 'package:orbitron_tactics/core/game_logic/models/position.dart';
import 'package:orbitron_tactics/core/game_logic/validators/move_validator.dart';
import 'package:orbitron_tactics/features/game/presentation/providers/board_interaction_provider.dart';
import 'package:orbitron_tactics/features/game/presentation/providers/game_state_provider.dart';
import 'package:orbitron_tactics/features/game/presentation/screens/game_screen.dart';
import 'package:orbitron_tactics/features/game/presentation/widgets/board/board_layout.dart';
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

  testWidgets('on the hex board a tap on a white pawn selects it',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(500, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    container.read(gameStateProvider.notifier).startSinglePlayerGame(
          profile: AiProfile.easy,
          humanColor: PlayerColor.white,
          humanName: 'Ada',
          spec: BoardSpec.hex6,
        );
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: GameScreen()),
    ));

    final board = container.read(gameStateProvider).board;
    const pawn = Position(row: 2, col: 4);
    expect(board.pieceAt(pawn)?.type, PieceType.pawn);

    final rect = tester.getRect(find.byType(GameBoard));
    final layout = BoardLayout.within(board.geometry, rect.size);
    await tester.tapAt(rect.topLeft + layout.centreOf(pawn));
    await tester.pump();

    final interaction = container.read(boardInteractionProvider);
    expect(interaction.selectedPosition, pawn);
    expect(interaction.validMoves, isNotEmpty);
  });

  testWidgets('on the hex board a tap just beside a target moves there',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(500, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    container.read(gameStateProvider.notifier).startSinglePlayerGame(
          profile: AiProfile.easy,
          humanColor: PlayerColor.white,
          humanName: 'Ada',
          spec: BoardSpec.hex6,
        );
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: GameScreen()),
    ));

    final state = container.read(gameStateProvider);
    final board = state.board;
    const pawn = Position(row: 2, col: 4);
    final rect = tester.getRect(find.byType(GameBoard));
    final layout = BoardLayout.within(board.geometry, rect.size);
    // GameBoard centres the board in the space it gets.
    final origin = rect.center -
        Offset(layout.size.width / 2, layout.size.height / 2);

    await tester.tapAt(origin + layout.centreOf(pawn));
    await tester.pump();
    final targets = container.read(boardInteractionProvider).validMoves;

    // Cells where a tap does something; the finger must land off them.
    final preferred = <Position>{pawn, ...targets};
    for (final cell in board.geometry.cells) {
      final piece = board.pieceAt(cell);
      if (piece?.color == PlayerColor.white &&
          MoveValidator.getLegalMoves(state, cell).isNotEmpty) {
        preferred.add(cell);
      }
    }

    // A target an empty tap point 78 % of a cell from its centre reaches,
    // with no other preferred cell as near.
    Position? target;
    Offset? point;
    for (final t in targets.where((t) => board.pieceAt(t) == null)) {
      for (var i = 0; i < 6 && point == null; i++) {
        final angle = i * pi / 3 + pi / 6;
        final p = layout.centreOf(t) +
            Offset(cos(angle), sin(angle)) * (0.78 * layout.cellSize);
        final under = layout.positionAt(p);
        final rival = preferred.any((q) =>
            q != t &&
            (layout.centreOf(q) - p).distance < 0.8 * layout.cellSize);
        if (under != null && !preferred.contains(under) && !rival) {
          target = t;
          point = p;
        }
      }
      if (point != null) break;
    }
    expect(point, isNotNull, reason: 'no free side next to any target');

    await tester.tapAt(origin + point!);
    await tester.pump();

    final first = container.read(gameStateProvider).moveHistory.first;
    expect(first.from, pawn);
    expect(first.to, target);
    await tester.pump(const Duration(seconds: 2));
  });
}
