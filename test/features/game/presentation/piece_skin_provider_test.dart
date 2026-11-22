import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbitron_tactics/features/game/data/piece_skin.dart';
import 'package:orbitron_tactics/features/game/presentation/providers/piece_skin_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<ProviderContainer> containerWith(Map<String, Object> values) async {
    SharedPreferences.setMockInitialValues(values);
    final store = PieceSkinStore(await SharedPreferences.getInstance());
    final container = ProviderContainer(
      overrides: [pieceSkinStoreProvider.overrideWithValue(store)],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('starts classic without marks', () async {
    final container = await containerWith({});

    expect(container.read(pieceSkinProvider), const PieceSkinSettings());
    expect(container.read(pieceSkinProvider).skin, PieceSkin.classic);
  });

  test('saves the chosen pack and the marks toggle', () async {
    final container = await containerWith({});
    final notifier = container.read(pieceSkinProvider.notifier);

    notifier.select(PieceSkin.heavenHell);
    notifier.setClassicMarks(true);
    await pumpEventQueue();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(PieceSkinStore.skinKey), 'heaven_hell');
    expect(prefs.getBool(PieceSkinStore.classicMarksKey), isTrue);
  });

  test('loads what was saved', () async {
    final container = await containerWith({
      PieceSkinStore.skinKey: 'heaven_hell',
      PieceSkinStore.classicMarksKey: true,
    });

    expect(
      container.read(pieceSkinProvider),
      const PieceSkinSettings(skin: PieceSkin.heavenHell, classicMarks: true),
    );
  });

  test('an unknown stored pack falls back to classic', () async {
    final container = await containerWith({PieceSkinStore.skinKey: 'gone'});

    expect(container.read(pieceSkinProvider).skin, PieceSkin.classic);
  });

  test('works in memory without a store', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(pieceSkinProvider.notifier).select(PieceSkin.heavenHell);

    expect(container.read(pieceSkinProvider).skin, PieceSkin.heavenHell);
  });
}
