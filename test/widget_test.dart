import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbitron_tactics/features/game/presentation/screens/game_screen.dart';

void main() {
  testWidgets('GameScreen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: GameScreen()),
      ),
    );
    expect(find.text('OrbitronTactics'), findsOneWidget);
  });
}
