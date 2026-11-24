import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbitron_tactics/core/ai/ai_difficulty.dart';
import 'package:orbitron_tactics/core/game_logic/board/board_geometry.dart';
import 'package:orbitron_tactics/core/game_logic/board/board_spec.dart';
import 'package:orbitron_tactics/core/game_logic/models/board_state.dart';
import 'package:orbitron_tactics/core/game_logic/models/piece.dart';
import 'package:orbitron_tactics/core/game_logic/models/position.dart';
import 'package:orbitron_tactics/core/game_logic/validators/move_validator.dart';
import 'package:orbitron_tactics/features/game/data/piece_skin.dart';
import 'package:orbitron_tactics/features/game/presentation/providers/board_interaction_provider.dart';
import 'package:orbitron_tactics/features/game/presentation/providers/game_state_provider.dart';
import 'package:orbitron_tactics/features/game/presentation/providers/piece_skin_provider.dart';
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

  // The tilted board of a world of standing figures.

  BoardState startingBoard(BoardSpec spec) {
    container.read(gameStateProvider.notifier).startSinglePlayerGame(
          profile: AiProfile.easy,
          humanColor: PlayerColor.white,
          humanName: 'Ada',
          spec: spec,
        );
    return container.read(gameStateProvider).board;
  }

  /// The share of [p]'s figure that the figures painted after it cover,
  /// on their outlines ([BoardLayout.figureOutline]). The figure counts
  /// from its top down to its plinth's centre: the plinth itself lies on
  /// the cell, and the figure in front stands on the cell in front.
  double occlusion(BoardLayout layout, BoardState board, Position p,
      List<Position> inFront) {
    final outline = layout.figureOutline(p, board.pieceAt(p)!.type);
    final body = Rect.fromLTRB(
        outline.left, outline.top, outline.right, layout.centreOf(p).dy);
    final covers = [
      for (final q in inFront) layout.figureOutline(q, board.pieceAt(q)!.type),
    ];
    const n = 60;
    var covered = 0;
    for (var i = 0; i < n; i++) {
      for (var j = 0; j < n; j++) {
        final point = Offset(body.left + (i + 0.5) / n * body.width,
            body.top + (j + 0.5) / n * body.height);
        if (covers.any((r) => r.contains(point))) covered++;
      }
    }
    return covered / (n * n);
  }

  for (final spec in [BoardSpec.hex6, BoardSpec.classic8]) {
    test('${spec.id} at 360 dp: tall figures, none more than a third hidden',
        () {
      final board = startingBoard(spec);
      final tilt = boardTiltFor(spec, PieceSkin.romeCarthage)!;
      for (final flipped in [false, true]) {
        final layout = BoardLayout.fit(spec.geometry, 360,
            flipped: flipped, tilt: tilt);
        final order = layout.inDrawOrder(
            board.geometry.cells.where((c) => board.pieceAt(c) != null));
        expect(order, hasLength(2 * spec.armySize));

        // Measured with the P2 defaults: hex6 40.9 dp, at most 7.5 %
        // hidden; classic8 56.3 dp, at most 25 %.
        for (var i = 0; i < order.length; i++) {
          final share =
              occlusion(layout, board, order[i], order.sublist(i + 1));
          expect(share, lessThanOrEqualTo(1 / 3),
              reason: '${board.pieceAt(order[i])} on ${order[i]}');
        }
        if (spec.geometry is HexGeometry) {
          expect(layout.pieceBox(order.first).height,
              greaterThanOrEqualTo(40));
        }
      }
    });
  }

  test('Space and its symbols keep the board flat', () {
    expect(boardTiltFor(BoardSpec.hex6, PieceSkin.classic), isNull);
    expect(boardTiltFor(BoardSpec.classic8, PieceSkin.classic), isNull);
    for (final spec in BoardSpec.all) {
      expect(boardTiltFor(spec, PieceSkin.knightsOrcs), isNotNull,
          reason: spec.id);
      expect(standingTilts, contains(spec.id));
    }
  });

  Future<BoardLayout> pumpHexGame(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(500, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    container.read(pieceSkinProvider.notifier).select(PieceSkin.romeCarthage);
    startingBoard(BoardSpec.hex6);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: GameScreen()),
    ));
    final rect = tester.getRect(find.byType(GameBoard));
    return BoardLayout.within(BoardSpec.hex6.geometry, rect.size,
        tilt: boardTiltFor(BoardSpec.hex6, PieceSkin.romeCarthage));
  }

  /// Where [layout]'s origin sits on screen: GameBoard centres the board
  /// in the space it gets.
  Offset originOf(WidgetTester tester, BoardLayout layout) =>
      tester.getRect(find.byType(GameBoard)).center -
      Offset(layout.size.width / 2, layout.size.height / 2);

  testWidgets('the tilted hex board paints its figures back to front',
      (tester) async {
    final layout = await pumpHexGame(tester);
    final origin = originOf(tester, layout);
    final board = container.read(gameStateProvider).board;

    final tops = [
      for (final element in find
          .descendant(
              of: find.byType(GameBoard), matching: find.byType(Positioned))
          .evaluate())
        if (element.widget.key case ValueKey(:final value)
            when value is (String, Position))
          (element.widget as Positioned).top!,
    ];
    final cells =
        board.geometry.cells.where((c) => board.pieceAt(c) != null).toList();
    expect(tops, hasLength(cells.length));
    final expected = [
      for (final p in layout.inDrawOrder(cells)) layout.pieceBox(p).top,
    ];
    for (var i = 0; i < tops.length; i++) {
      expect(tops[i], closeTo(expected[i], 1e-6));
    }
    for (var i = 1; i < tops.length; i++) {
      expect(tops[i], greaterThanOrEqualTo(tops[i - 1] - 1e-9));
    }

    // The figure stands on its cell: plinth on the cell's centre.
    const king = Position(row: 0, col: 6);
    final kingBox = tester.getRect(find.byKey(const ValueKey(('piece', king))));
    final centre = origin + layout.centreOf(king);
    expect(kingBox.center.dx, closeTo(centre.dx, 0.01));
    expect(kingBox.top + StandingFigure.plinthAnchor * kingBox.height,
        closeTo(centre.dy, 0.01));
  });

  testWidgets('a tap on the king\'s head selects him, one on the pawn '
      'behind him the pawn', (tester) async {
    final layout = await pumpHexGame(tester);
    final origin = originOf(tester, layout);
    final board = container.read(gameStateProvider).board;

    const king = Position(row: 0, col: 6);
    const pawn = Position(row: 2, col: 6);
    expect(board.pieceAt(king)?.type, PieceType.king);
    expect(board.pieceAt(pawn)?.type, PieceType.pawn);

    // The head reaches up over the empty cell behind the king.
    final head = layout.headOf(king, PieceType.king);
    final under = layout.positionAt(head);
    expect(under, isNot(king));
    expect(board.pieceAt(under!), isNull);

    await tester.tapAt(origin + head);
    await tester.pump();
    expect(container.read(boardInteractionProvider).selectedPosition, king);

    await tester.tapAt(origin + layout.headOf(pawn, PieceType.pawn));
    await tester.pump();
    expect(container.read(boardInteractionProvider).selectedPosition, pawn);
  });
}
