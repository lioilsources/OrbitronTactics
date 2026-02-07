import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbitron_tactics/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: OrbitronTacticsApp()),
    );
    expect(find.text('OrbitronTactics'), findsOneWidget);
  });
}
