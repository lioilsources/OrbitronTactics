import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbitron_tactics/features/game/data/game_repository.dart';
import 'package:orbitron_tactics/features/game/presentation/providers/lobby_providers.dart';
import 'package:orbitron_tactics/features/game/presentation/screens/lobby_screen.dart';
import 'package:orbitron_tactics/features/onboarding/data/onboarding_store.dart';
import 'package:orbitron_tactics/features/onboarding/presentation/onboarding_provider.dart';
import 'package:orbitron_tactics/features/progress/data/fleet_progress_store.dart';
import 'package:orbitron_tactics/features/progress/presentation/providers/fleet_progress_provider.dart';
import 'package:orbitron_tactics/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets(
      'the lobby lists open games, and so signs in, only when asked to',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(500, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final onboarding = PrefsOnboardingStore(prefs);
    await onboarding.markHowToPlaySeen();

    var listened = false;
    await tester.pumpWidget(ProviderScope(
      overrides: [
        fleetProgressStoreProvider.overrideWithValue(FleetProgressStore(prefs)),
        onboardingStoreProvider.overrideWithValue(onboarding),
        onlineLobbyProvider.overrideWith((ref) => false),
        waitingGamesProvider.overrideWith((ref) {
          listened = true;
          return Stream.value(const <GameLobbyEntry>[]);
        }),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: LobbyScreen(),
      ),
    ));
    await tester.pump();

    expect(listened, isFalse);
    await tester.tap(find.text('Show open games'));
    await tester.pump();
    await tester.pump();

    expect(listened, isTrue);
    expect(find.text('Show open games'), findsNothing);
  });
}
