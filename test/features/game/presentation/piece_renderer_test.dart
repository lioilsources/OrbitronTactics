import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbitron_tactics/core/game_logic/models/piece.dart';
import 'package:orbitron_tactics/features/game/data/piece_skin.dart';
import 'package:orbitron_tactics/features/game/presentation/widgets/board/piece_renderer.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget piece) =>
      tester.pumpWidget(MaterialApp(home: Center(child: piece)));

  const whiteKnight = Piece(type: PieceType.knight, color: PlayerColor.white);
  const blackKnight = Piece(type: PieceType.knight, color: PlayerColor.black);

  group('PieceRenderer classic', () {
    testWidgets('draws the symbol and no image', (tester) async {
      await pump(tester, PieceRenderer.build(whiteKnight, 64));

      expect(find.text(PieceRenderer.symbol(PieceType.knight)), findsOneWidget);
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('keeps the threat badge', (tester) async {
      await pump(tester, PieceRenderer.build(whiteKnight, 64, isThreatened: true));

      expect(find.text('!'), findsOneWidget);
    });
  });

  group('PieceRenderer image pack', () {
    const skin = PieceSkin.heavenHell;

    Image image(WidgetTester tester) => tester.widget<Image>(find.byType(Image));
    Transform flip(WidgetTester tester) => tester.widget<Transform>(find
        .ancestor(of: find.byType(Image), matching: find.byType(Transform))
        .first);

    testWidgets('draws the figure bottom-aligned without the symbol',
        (tester) async {
      await pump(tester, PieceRenderer.build(whiteKnight, 64, skin: skin));

      final drawn = image(tester);
      expect((drawn.image as AssetImage).assetName,
          skin.assetFor(PieceType.knight, PlayerColor.white));
      expect(drawn.fit, BoxFit.contain);
      expect(drawn.alignment, Alignment.bottomCenter);
      expect(find.text(PieceRenderer.symbol(PieceType.knight)), findsNothing);
    });

    testWidgets('mirrors black pieces only', (tester) async {
      await pump(tester, PieceRenderer.build(whiteKnight, 64, skin: skin));
      expect(flip(tester).transform.entry(0, 0), 1);

      await pump(tester, PieceRenderer.build(blackKnight, 64, skin: skin));
      expect((image(tester).image as AssetImage).assetName,
          skin.assetFor(PieceType.knight, PlayerColor.black));
      expect(flip(tester).transform.entry(0, 0), -1);
    });

    testWidgets('adds the classic mark when asked', (tester) async {
      await pump(tester, PieceRenderer.build(whiteKnight, 64, skin: skin));
      expect(find.byKey(const ValueKey('classic-mark')), findsNothing);

      await pump(
          tester,
          PieceRenderer.build(whiteKnight, 64,
              skin: skin, classicMarks: true));
      expect(find.byKey(const ValueKey('classic-mark')), findsOneWidget);
      expect(find.text(PieceRenderer.symbol(PieceType.knight)), findsOneWidget);
    });

    testWidgets('keeps the threat badge and the last warrior glow',
        (tester) async {
      await pump(
          tester,
          PieceRenderer.build(whiteKnight.copyWith(isLastWarrior: true), 64,
              skin: skin, isThreatened: true));

      expect(find.text('!'), findsOneWidget);
      expect(find.byKey(const ValueKey('last-warrior-glow')), findsOneWidget);
    });
  });
}
