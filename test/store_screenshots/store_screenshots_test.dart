// Store screenshots, rendered from the real screens with the SDK's Roboto:
//
//   STORE_SCREENSHOTS=1 flutter test test/store_screenshots
//
// writes docs/store/screenshots/{en,cs}/NN_name.png (1080 x 1920) and
// docs/store/feature_graphic_{en,cs}.png (1024 x 500). Skipped unless the variable
// is set, so CI and ordinary runs leave the images alone.
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbitron_tactics/core/ai/ai_difficulty.dart';
import 'package:orbitron_tactics/core/ai/battle_ai.dart';
import 'package:orbitron_tactics/core/game_logic/engine/battle_engine.dart';
import 'package:orbitron_tactics/core/game_logic/models/battle_state.dart';
import 'package:orbitron_tactics/core/game_logic/models/piece.dart';
import 'package:orbitron_tactics/core/game_logic/models/position.dart';
import 'package:orbitron_tactics/core/game_logic/models/upgrade_profile.dart';
import 'package:orbitron_tactics/core/game_logic/validators/move_validator.dart';
import 'package:orbitron_tactics/core/maneuvers/maneuver.dart';
import 'package:orbitron_tactics/core/maneuvers/maneuver_catalog.dart';
import 'package:orbitron_tactics/features/battle/data/fleet_skin.dart';
import 'package:orbitron_tactics/features/battle/presentation/providers/battle_state_provider.dart';
import 'package:orbitron_tactics/features/battle/presentation/screens/battle_screen.dart';
import 'package:orbitron_tactics/features/comcenter/presentation/screens/comcenter_screen.dart';
import 'package:orbitron_tactics/features/game/data/game_repository.dart';
import 'package:orbitron_tactics/features/game/presentation/providers/game_state_provider.dart';
import 'package:orbitron_tactics/features/game/presentation/providers/lobby_providers.dart';
import 'package:orbitron_tactics/features/game/presentation/screens/game_screen.dart';
import 'package:orbitron_tactics/features/onboarding/presentation/how_to_play_screen.dart';
import 'package:orbitron_tactics/features/progress/data/fleet_progress_store.dart';
import 'package:orbitron_tactics/features/progress/presentation/providers/fleet_progress_provider.dart';
import 'package:orbitron_tactics/features/store/data/purchase_service.dart';
import 'package:orbitron_tactics/features/store/data/store_catalog.dart';
import 'package:orbitron_tactics/features/store/presentation/providers/store_providers.dart';
import 'package:orbitron_tactics/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _logical = Size(360, 640);
const _scale = 3.0;

final _enabled = Platform.environment['STORE_SCREENSHOTS'] != null;
final _out = Directory('docs/store');

/// Prices as the stores would show them.
class _ShopWindow extends PurchaseService {
  const _ShopWindow(this.czech);

  final bool czech;

  @override
  bool get available => true;

  @override
  Future<Map<String, String>> prices(List<String> ids) async => {
        for (final id in ids)
          id: _price(id),
      };

  String _price(String id) {
    final euro = switch (id) {
      StoreCatalog.commanderId => 9.99,
      StoreCatalog.fleetBundleId => 6.99,
      final id when id.startsWith('fleet.') => 1.99,
      final id when id.startsWith('music.') => 0.99,
      _ => 2.99,
    };
    final crowns = switch (id) {
      StoreCatalog.commanderId => 249,
      StoreCatalog.fleetBundleId => 179,
      final id when id.startsWith('fleet.') => 49,
      final id when id.startsWith('music.') => 25,
      _ => 79,
    };
    return czech ? '$crowns Kč' : '€${euro.toStringAsFixed(2)}';
  }

  @override
  Future<Set<String>> owned() async => {};

  @override
  Future<PurchaseOutcome> buy(String productId) async =>
      const PurchaseCancelled();

  @override
  Future<Set<String>> restore() async => {};
}

Future<void> _loadFonts() async {
  final roots = <String>[
    if (Platform.environment['FLUTTER_ROOT'] != null)
      Platform.environment['FLUTTER_ROOT']!,
  ];
  var dir = File(Platform.resolvedExecutable).parent;
  for (var i = 0; i < 8; i++) {
    roots.add(dir.path);
    dir = dir.parent;
  }
  final fonts = roots
      .map((root) => Directory('$root/bin/cache/artifacts/material_fonts'))
      .firstWhere((dir) => dir.existsSync(),
          orElse: () => throw StateError('Flutter SDK fonts not found'));

  Future<void> load(String family, List<String> files) async {
    final loader = FontLoader(family);
    for (final file in files) {
      final bytes = File('${fonts.path}/$file').readAsBytesSync();
      loader.addFont(Future.value(ByteData.sublistView(bytes)));
    }
    await loader.load();
  }

  await load('Roboto', [
    'Roboto-Regular.ttf',
    'Roboto-Medium.ttf',
    'Roboto-Bold.ttf',
    'Roboto-Light.ttf',
  ]);
  await load('MaterialIcons', ['MaterialIcons-Regular.otf']);

  // Roboto has no chess symbols; phones fall back to a system font, and
  // this machine's DejaVu Sans does the same here.
  const dejaVu = '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf';
  if (File(dejaVu).existsSync()) {
    final loader = FontLoader('DejaVu Sans')
      ..addFont(Future.value(
          ByteData.sublistView(File(dejaVu).readAsBytesSync())));
    await loader.load();
  }
}

/// The app's theme, with the symbol font to fall back on.
ThemeData _theme() {
  final theme = orbitronTheme();
  const fallback = ['DejaVu Sans'];
  return theme.copyWith(
    textTheme: theme.textTheme.apply(fontFamilyFallback: fallback),
    primaryTextTheme:
        theme.primaryTextTheme.apply(fontFamilyFallback: fallback),
  );
}

final _boundary = GlobalKey();

Future<void> _shoot(WidgetTester tester, String path) async {
  await tester.runAsync(() async {
    final boundary =
        _boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: _scale);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('${_out.path}/$path')..createSync(recursive: true);
    file.writeAsBytesSync(data!.buffer.asUint8List());
  });
}

/// Lets sprites and fonts finish decoding, which needs real time.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 3; i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 150)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

class _Scene {
  _Scene(this.tester, this.container, this.locale);

  final WidgetTester tester;
  final ProviderContainer container;
  final Locale locale;

  Future<void> show(Widget home) async {
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: RepaintBoundary(
        key: _boundary,
        child: OrbitronTacticsApp(home: home, locale: locale, theme: _theme()),
      ),
    ));
    await _settle(tester);
  }
}

/// A progressed player fleet, the way a few evenings of play leave it.
Future<ProviderContainer> _container(Locale locale) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(overrides: [
    fleetProgressStoreProvider.overrideWithValue(FleetProgressStore(prefs)),
    purchaseServiceProvider
        .overrideWithValue(_ShopWindow(locale.languageCode == 'cs')),
    waitingGamesProvider.overrideWith((ref) => Stream.value([
          GameLobbyEntry(
              gameId: 'a',
              hostName: locale.languageCode == 'cs' ? 'Honza' : 'Alex',
              createdAt: DateTime.now().subtract(const Duration(minutes: 2))),
          GameLobbyEntry(
              gameId: 'b',
              hostName: 'Mira',
              createdAt: DateTime.now().subtract(const Duration(seconds: 20))),
        ])),
  ]);
  final player = container.read(fleetProgressProvider(playerFleetIdentity).notifier)
    ..addCredits(2150);
  for (final ship in PieceType.values) {
    player.upgrade(ship);
  }
  for (final ship in [PieceType.knight, PieceType.queen, PieceType.pawn]) {
    player.upgrade(ship);
  }
  for (var i = 0; i < 9; i++) {
    player.recordBattleWin(PieceType.knight);
  }
  final knight = player.state.maneuversFor(PieceType.knight);
  player.armManeuvers(PieceType.knight, [
    for (final family in [
      ManeuverFamily.sidestep,
      ManeuverFamily.strike,
      ManeuverFamily.roll,
      ManeuverFamily.volley,
    ])
      knight.owned.firstWhere((id) => id == 'knight.${family.name}'),
  ]);
  return container;
}

/// Plays a few quiet moves each way so the board looks lived in.
void _playOpening(ProviderContainer container, String name) {
  final game = container.read(gameStateProvider.notifier)
    ..startSinglePlayerGame(
        profile: AiProfile.medium,
        humanColor: PlayerColor.white,
        humanName: name);
  final random = Random(5);

  ({Position from, Position to})? quietMove(PlayerColor color) {
    final state = container.read(gameStateProvider);
    final moves = <({Position from, Position to})>[];
    for (final from in state.board.findPieces(color: color)) {
      for (final to in MoveValidator.getLegalMoves(state, from)) {
        if (state.board.isEmpty(to)) moves.add((from: from, to: to));
      }
    }
    return moves.isEmpty ? null : moves[random.nextInt(moves.length)];
  }

  for (var round = 0; round < 5; round++) {
    final human = quietMove(PlayerColor.white)!;
    game.tryMove(human.from, human.to);
    final ai = quietMove(PlayerColor.black)!;
    final move = MoveValidator.createMove(
        container.read(gameStateProvider), ai.from, ai.to)!;
    game.applyAiMove(move);
  }
}

/// A fight in progress, picked from simulated duels: both ships hurt, shots
/// in the air, an impact just landed and the player's ship mid-maneuver.
BattleState _midBattle() {
  BattleState? fallback;
  for (var seed = 1; seed <= 80; seed++) {
    var state = BattleEngine.createBattle(
      attacker: const Piece(type: PieceType.knight, color: PlayerColor.white),
      defender: const Piece(type: PieceType.queen, color: PlayerColor.black),
      attackerUpgrades: const UpgradeProfile(levels: {PieceType.knight: 2}),
      defenderUpgrades: const UpgradeProfile(),
    );
    final random = Random(seed);
    final attackerAi = BattleAi(profile: AiProfile.medium, random: random);
    final defenderAi = BattleAi(profile: AiProfile.medium, random: random);
    for (var elapsed = 0;
        elapsed < 14000 && !state.isFinished;
        elapsed += 16) {
      state = BattleEngine.tick(state, 16);
      for (final (ai, isAttacker) in [(attackerAi, true), (defenderAi, false)]) {
        final action = ai.decide(state, isAttacker: isAttacker, deltaMs: 16);
        final me = isAttacker ? state.attacker : state.defender;
        if (action.targetX != null || action.targetAltitude != null) {
          state = BattleEngine.moveShip(
              state, isAttacker, action.targetX ?? me.xFraction,
              altitude: action.targetAltitude);
        }
        if (action.activateShield) {
          state = BattleEngine.activateShield(state, isAttacker);
        }
        if (action.maneuver != null) {
          state = BattleEngine.startManeuver(
              state, isAttacker, action.maneuver!,
              mirrored: action.mirrored);
        }
      }
      // The player flies a roll once in a while.
      if (state.attacker.maneuver == null &&
          state.attacker.energy >= 50 &&
          elapsed % 1600 == 0) {
        state = BattleEngine.startManeuver(
            state, true, ManeuverCatalog.byId('knight.roll')!);
      }
      final attacker = state.attacker;
      final defender = state.defender;
      fallback = state;
      if (elapsed > 3000 &&
          attacker.maneuver != null &&
          attacker.currentHp < attacker.stats.maxHp * 0.9 &&
          attacker.currentHp > attacker.stats.maxHp * 0.5 &&
          defender.currentHp < defender.stats.maxHp * 0.75 &&
          defender.currentHp > defender.stats.maxHp * 0.3 &&
          !attacker.shieldState.isActive &&
          !defender.shieldState.isActive &&
          state.projectiles.length >= 3 &&
          state.impacts.isNotEmpty) {
        return state;
      }
    }
  }
  return fallback!;
}

List<ManeuverSlot> _slots(PieceType ship, List<ManeuverFamily> families) => [
      for (final family in families)
        (maneuver: ManeuverCatalog.byId('${ship.name}.${family.name}')!, level: 1),
    ];

Future<void> _shootAll(WidgetTester tester, Locale locale) async {
  final lang = locale.languageCode;
  tester.view.physicalSize = _logical * _scale;
  tester.view.devicePixelRatio = _scale;
  addTearDown(tester.view.reset);

  final container = await _container(locale);
  addTearDown(container.dispose);
  final scene = _Scene(tester, container, locale);

  await scene.show(const OrbitronTacticsApp().home);
  await _shoot(tester, 'screenshots/$lang/01_lobby.png');

  _playOpening(container, lang == 'cs' ? 'Honza' : 'Alex');
  await scene.show(const GameScreen());
  await _shoot(tester, 'screenshots/$lang/02_board.png');

  final battle = container.read(battleStateProvider.notifier);
  battle.startBattle(initial: _midBattle(), attackerColor: PlayerColor.white);
  await scene.show(BattleScreen(
    attackerColor: PlayerColor.white,
    attackerSkin: FleetSkin.solarCrusade,
    defenderSkin: FleetSkin.voidHive,
    attackerManeuvers: _slots(PieceType.knight, const [
      ManeuverFamily.sidestep,
      ManeuverFamily.strike,
      ManeuverFamily.roll,
      ManeuverFamily.volley,
    ]),
  ));
  await _shoot(tester, 'screenshots/$lang/03_battle.png');
  battle.stopBattle();
  await tester.pump();

  await scene.show(const ComcenterScreen());
  await _shoot(tester, 'screenshots/$lang/04_fleet.png');

  await tester.tap(find.text(lang == 'cs' ? 'MANÉVRY' : 'MANEUVERS'));
  await tester.pumpAndSettle();
  await tester.tap(find.text(lang == 'cs' ? 'JEZDEC' : 'KNIGHT'));
  await tester.pumpAndSettle();
  await _settle(tester);
  await _shoot(tester, 'screenshots/$lang/05_maneuvers.png');

  await tester.tap(find.text(lang == 'cs' ? 'OBCHOD' : 'STORE'));
  await tester.pumpAndSettle();
  await _settle(tester);
  await _shoot(tester, 'screenshots/$lang/06_store.png');

  await scene.show(const HowToPlayScreen());
  await tester.tap(find.text(lang == 'cs' ? 'DÁL' : 'NEXT'));
  await tester.pumpAndSettle();
  await tester.tap(find.text(lang == 'cs' ? 'DÁL' : 'NEXT'));
  await tester.pumpAndSettle();
  await _settle(tester);
  await _shoot(tester, 'screenshots/$lang/07_how_to_play.png');
}

/// The Play Store's 1024 x 500 banner: the title over a fleet in formation.
class _FeatureGraphic extends StatelessWidget {
  const _FeatureGraphic(this.tagline);

  final String tagline;

  @override
  Widget build(BuildContext context) {
    const ships = [
      (FleetSkin.solarCrusade, PieceType.queen, 150.0, 40.0),
      (FleetSkin.voidHive, PieceType.rook, 120.0, 250.0),
      (FleetSkin.neonRunners, PieceType.knight, 130.0, 170.0),
      (FleetSkin.abyssalTide, PieceType.bishop, 110.0, 310.0),
      (FleetSkin.ironArmada, PieceType.king, 125.0, 90.0),
    ];
    return Container(
      width: 1024,
      height: 500,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D0D1A), Color(0xFF2A1458), Color(0xFF0D2B5E)],
        ),
      ),
      child: Stack(
        children: [
          for (final (skin, type, size, top) in ships)
            Positioned(
              left: 560 + (top % 5) * 3 + ships.indexOf((skin, type, size, top)) * 70,
              top: top,
              child: Image.asset(skin.assetFor(type, PlayerColor.white),
                  width: size * 1.6, height: size * 1.6),
            ),
          Positioned(
            left: 56,
            top: 130,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ORBITRON',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 78,
                    height: 1,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 8,
                    decoration: TextDecoration.none,
                  ),
                ),
                const Text(
                  'TACTICS',
                  style: TextStyle(
                    color: Color(0xFFFFC107),
                    fontSize: 78,
                    height: 1.1,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 8,
                    decoration: TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: 480,
                  child: Text(
                    tagline,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

void main() {
  setUpAll(_loadFonts);

  for (final (lang, tagline) in const [
    ('en', 'Chess-like tactics. Every capture is a real-time space battle.'),
    ('cs', 'Taktika jako šachy. Každé braní je bitva lodí v reálném čase.'),
  ]) {
    testWidgets('feature graphic in $lang', (tester) async {
      tester.view.physicalSize = const Size(1024, 500);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: DefaultTextStyle(
          style: const TextStyle(fontFamily: 'Roboto'),
          child: RepaintBoundary(
            key: _boundary,
            child: _FeatureGraphic(tagline),
          ),
        ),
      ));
      await _settle(tester);
      await tester.runAsync(() async {
        final boundary = _boundary.currentContext!.findRenderObject()!
            as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 1);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        File('${_out.path}/feature_graphic_$lang.png')
          ..createSync(recursive: true)
          ..writeAsBytesSync(data!.buffer.asUint8List());
      });
    }, skip: !_enabled);
  }

  for (final locale in const [Locale('en'), Locale('cs')]) {
    testWidgets('screenshots in ${locale.languageCode}', (tester) async {
      await _shootAll(tester, locale);
    }, skip: !_enabled);
  }
}
