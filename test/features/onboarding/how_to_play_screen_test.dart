import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbitron_tactics/features/onboarding/presentation/how_to_play_screen.dart';

void main() {
  testWidgets('pages through the rules and closes on the last one',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const HowToPlayScreen()),
          ),
          child: const Text('open'),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Three ways to win'), findsOneWidget);
    for (final title in [
      'Pieces move their own way',
      'Every capture is a battle',
      'Maneuvers and your fleet',
    ]) {
      await tester.tap(find.text('NEXT'));
      await tester.pumpAndSettle();
      expect(find.text(title), findsOneWidget);
    }
    expect(find.text('SKIP'), findsNothing);

    await tester.tap(find.text("LET'S PLAY"));
    await tester.pumpAndSettle();

    expect(find.byType(HowToPlayScreen), findsNothing);
  });

  testWidgets('can be skipped', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const HowToPlayScreen()),
          ),
          child: const Text('open'),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('SKIP'));
    await tester.pumpAndSettle();

    expect(find.byType(HowToPlayScreen), findsNothing);
  });
}
