import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbitron_tactics/core/game_logic/models/piece.dart';
import 'package:orbitron_tactics/core/maneuvers/maneuver_catalog.dart';
import 'package:orbitron_tactics/features/comcenter/presentation/screens/comcenter_screen.dart';
import 'package:orbitron_tactics/features/onboarding/presentation/how_to_play_screen.dart';
import 'package:orbitron_tactics/features/progress/data/fleet_progress_store.dart';
import 'package:orbitron_tactics/features/progress/presentation/providers/fleet_progress_provider.dart';
import 'package:orbitron_tactics/features/store/data/store_catalog.dart';
import 'package:orbitron_tactics/l10n/content_cs.dart';
import 'package:orbitron_tactics/l10n/l10n.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

Map<String, dynamic> _arb(String locale) =>
    jsonDecode(File('lib/l10n/app_$locale.arb').readAsStringSync())
        as Map<String, dynamic>;

Set<String> _placeholders(String text) =>
    RegExp(r'\{(\w+)(?:,|\})')
        .allMatches(text)
        .map((match) => match.group(1)!)
        .toSet();

void main() {
  group('ARB files', () {
    final en = _arb('en');
    final cs = _arb('cs');
    final keys = en.keys.where((key) => !key.startsWith('@')).toSet();

    test('Czech has every English key and nothing else', () {
      final csKeys = cs.keys.where((key) => !key.startsWith('@')).toSet();
      expect(keys.difference(csKeys), isEmpty, reason: 'missing in Czech');
      expect(csKeys.difference(keys), isEmpty, reason: 'unknown in Czech');
    });

    test('both languages use the same placeholders', () {
      for (final key in keys) {
        expect(_placeholders(cs[key] as String), _placeholders(en[key] as String),
            reason: key);
      }
    });

    test('no Czech text is left as the English one, bar names and numbers',
        () {
      const same = {
        'appTitle', 'tierStarter', 'upgradeMax', 'difficultyEasy',
        'maneuverStats', 'musicStandard', 'itemMusicTitle',
      };
      for (final key in keys.difference(same)) {
        final english = en[key] as String;
        final czech = cs[key] as String;
        if (english == czech) {
          // Allowed only when there is nothing to translate.
          expect(RegExp(r'[A-Za-z]{4,}').hasMatch(english.replaceAll(
                  RegExp(r'\{[^}]*\}'), '')),
              isFalse,
              reason: '$key is still English: $english');
        }
      }
    });
  });

  group('content', () {
    test('every maneuver and pack has a Czech text', () {
      final english = <String>{
        for (final ship in PieceType.values)
          for (final maneuver in ManeuverCatalog.forShip(ship)) ...[
            maneuver.name,
            maneuver.description,
          ],
        for (final pack in ManeuverCatalog.packs) ...[
          pack.name,
          pack.description,
        ],
      };
      expect(english.where((text) => !contentCs.containsKey(text)), isEmpty);
    });

    test('every Czech content entry belongs to something in the game', () {
      final english = <String>{
        for (final ship in PieceType.values)
          for (final maneuver in ManeuverCatalog.forShip(ship)) ...[
            maneuver.name,
            maneuver.description,
          ],
        for (final pack in ManeuverCatalog.packs) ...[
          pack.name,
          pack.description,
        ],
      };
      expect(contentCs.keys.where((text) => !english.contains(text)), isEmpty);
    });

    test('every store item reads in both languages', () {
      final cs = lookupAppLocalizations(const Locale('cs'));
      final en = lookupAppLocalizations(const Locale('en'));
      for (final item in StoreCatalog.items) {
        for (final l10n in [en, cs]) {
          expect(l10n.storeTitle(item), isNotEmpty, reason: item.id);
          expect(l10n.storeDescription(item), isNotEmpty, reason: item.id);
        }
      }
    });
  });

  group('resolveAppLocale', () {
    const supported = [Locale('cs'), Locale('en')];

    test('speaks Czech to a Czech device', () {
      expect(resolveAppLocale(const [Locale('cs', 'CZ')], supported),
          const Locale('cs'));
    });

    test('takes the first language of the list it knows', () {
      expect(resolveAppLocale(const [Locale('de'), Locale('cs')], supported),
          const Locale('cs'));
    });

    test('speaks English to everyone else', () {
      expect(resolveAppLocale(const [Locale('de'), Locale('fr')], supported),
          const Locale('en'));
      expect(resolveAppLocale(null, supported), const Locale('en'));
      expect(resolveAppLocale(const [], supported), const Locale('en'));
    });
  });

  group('plurals', () {
    final cs = lookupAppLocalizations(const Locale('cs'));
    final en = lookupAppLocalizations(const Locale('en'));

    test('Czech has one, few and many forms', () {
      expect(cs.battlesWon(1), '1 vyhraná bitva');
      expect(cs.battlesWon(3), '3 vyhrané bitvy');
      expect(cs.battlesWon(5), '5 vyhraných bitev');
      expect(cs.restoredCount(1), 'Obnoven 1 nákup');
      expect(cs.restoredCount(2), 'Obnoveny 2 nákupy');
      expect(cs.restoredCount(7), 'Obnoveno 7 nákupů');
    });

    test('English has one and other', () {
      expect(en.battlesWon(1), '1 battle won');
      expect(en.battlesWon(2), '2 battles won');
      expect(en.newManeuvers(1), 'NEW MANEUVER');
      expect(en.newManeuvers(2), 'NEW MANEUVERS');
    });
  });

  group('in the app', () {
    Widget app(Widget home, Locale locale, ProviderContainer container) =>
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            locale: locale,
            localeListResolutionCallback: resolveAppLocale,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: home,
          ),
        );

    Future<ProviderContainer> container() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final c = ProviderContainer(overrides: [
        fleetProgressStoreProvider
            .overrideWithValue(FleetProgressStore(prefs)),
      ]);
      addTearDown(c.dispose);
      return c;
    }

    testWidgets('the Comcenter speaks Czech', (tester) async {
      tester.view.physicalSize = const Size(420, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
          app(const ComcenterScreen(), const Locale('cs'), await container()));
      await tester.pumpAndSettle();

      expect(find.text('VELITELSTVÍ'), findsOneWidget);
      expect(find.text('JEDNOTKY'), findsOneWidget);
      expect(find.text('OBCHOD'), findsOneWidget);
      expect(find.text('Pěšec'), findsOneWidget);

      await tester.tap(find.text('MANÉVRY'));
      await tester.pumpAndSettle();
      expect(find.text('Úskok'), findsOneWidget);
      expect(find.text('Sidestep'), findsNothing);
    });

    testWidgets('an unsupported language falls back to English',
        (tester) async {
      await tester.pumpWidget(app(
          const HowToPlayScreen(), const Locale('de'), await container()));
      await tester.pumpAndSettle();

      expect(find.text('HOW TO PLAY'), findsOneWidget);
      expect(find.text('Three ways to win'), findsOneWidget);
    });

    testWidgets('How to play reads in Czech', (tester) async {
      await tester.pumpWidget(app(
          const HowToPlayScreen(), const Locale('cs'), await container()));
      await tester.pumpAndSettle();

      expect(find.text('JAK HRÁT'), findsOneWidget);
      expect(find.text('Tři cesty k vítězství'), findsOneWidget);
      expect(find.text('DÁL'), findsOneWidget);
    });
  });
}
