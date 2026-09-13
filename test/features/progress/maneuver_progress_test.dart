import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbitron_tactics/core/game_logic/models/fleet_progress.dart';
import 'package:orbitron_tactics/core/game_logic/models/piece.dart';
import 'package:orbitron_tactics/core/game_logic/models/ship_maneuvers.dart';
import 'package:orbitron_tactics/core/maneuvers/maneuver.dart';
import 'package:orbitron_tactics/core/maneuvers/maneuver_catalog.dart';
import 'package:orbitron_tactics/features/progress/data/fleet_progress_store.dart';
import 'package:orbitron_tactics/features/progress/presentation/providers/fleet_progress_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const knight = PieceType.knight;
  late FleetProgressStore store;
  late ProviderContainer container;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    store = FleetProgressStore(await SharedPreferences.getInstance());
    container = ProviderContainer(
      overrides: [fleetProgressStoreProvider.overrideWithValue(store)],
    );
    addTearDown(container.dispose);
  });

  FleetProgressNotifier fleet() =>
      container.read(fleetProgressProvider(playerFleetIdentity).notifier);
  FleetProgress progress() =>
      container.read(fleetProgressProvider(playerFleetIdentity));

  String idOf(PieceType ship, ManeuverFamily family) => ManeuverCatalog
      .forShip(ship)
      .firstWhere((maneuver) => maneuver.family == family)
      .id;

  group('maneuver progress', () {
    test('a ship starts with its two starters armed', () {
      final starting = progress().maneuversFor(knight);

      expect(starting.owned, ManeuverCatalog.starterIds(knight).toSet());
      expect(starting.active, ManeuverCatalog.starterIds(knight));
      expect(starting.levelOf(starting.active.first), 1);
    });

    test('battles won unlock maneuvers, armed while the pad has room', () {
      final retreat = idOf(knight, ManeuverFamily.retreat);

      expect(fleet().recordBattleWin(knight), isEmpty);
      final second = fleet().recordBattleWin(knight);

      expect(second.map((maneuver) => maneuver.id), [retreat]);
      expect(progress().battleWinsWith(knight), 2);
      expect(progress().maneuversFor(knight).owned, contains(retreat));
      expect(progress().maneuversFor(knight).active, contains(retreat));
    });

    test('the pad fills up and later unlocks wait in the hangar', () {
      for (var win = 0; win < 5; win++) {
        fleet().recordBattleWin(knight);
      }
      final learned = progress().maneuversFor(knight);

      expect(learned.owned.length, 6, reason: '2 starters + 4 won');
      expect(learned.active.length, ShipManeuvers.slots);
    });

    test('only the ship that fought is credited', () {
      fleet().recordBattleWin(knight);
      fleet().recordBattleWin(knight);

      expect(progress().battleWinsWith(PieceType.rook), 0);
      expect(progress().maneuversFor(PieceType.rook).owned,
          ManeuverCatalog.starterIds(PieceType.rook).toSet());
    });

    test('a maneuver can be bought instead of earned', () {
      final volley = ManeuverCatalog.forShip(knight)
          .firstWhere((maneuver) => maneuver.family == ManeuverFamily.volley);
      fleet().addCredits(volley.price!);

      expect(fleet().buyManeuver(knight, volley.id), isTrue);

      expect(progress().credits, 0);
      expect(progress().maneuversFor(knight).owned, contains(volley.id));
      // A second buy, or one without the credits, changes nothing.
      expect(fleet().buyManeuver(knight, volley.id), isFalse);
      expect(fleet().buyManeuver(knight, idOf(knight, ManeuverFamily.dash)),
          isFalse);
    });

    test('a starter cannot be bought, and neither can another ship\'s', () {
      fleet().addCredits(5000);

      expect(fleet().buyManeuver(knight, idOf(knight, ManeuverFamily.sidestep)),
          isFalse);
      expect(
          fleet().buyManeuver(knight, idOf(PieceType.rook, ManeuverFamily.dash)),
          isFalse);
    });

    test('training raises the level and costs credits', () {
      final sidestep = ManeuverCatalog.byId(idOf(knight, ManeuverFamily.sidestep))!;
      fleet().addCredits(ManeuverCatalog.upgradePrice(sidestep, 2));

      expect(fleet().upgradeManeuver(knight, sidestep.id), isTrue);

      expect(progress().maneuversFor(knight).levelOf(sidestep.id), 2);
      expect(progress().credits, 0);
      // No credits left for the next level.
      expect(fleet().upgradeManeuver(knight, sidestep.id), isFalse);
    });

    test('training stops at the last level', () {
      final sidestep = ManeuverCatalog.byId(idOf(knight, ManeuverFamily.sidestep))!;
      fleet().addCredits(10000);

      expect(fleet().upgradeManeuver(knight, sidestep.id), isTrue);
      expect(fleet().upgradeManeuver(knight, sidestep.id), isTrue);
      expect(fleet().upgradeManeuver(knight, sidestep.id), isFalse);
      expect(progress().maneuversFor(knight).levelOf(sidestep.id),
          Maneuver.maxLevel);
    });

    test('arming takes owned maneuvers, up to the slots', () {
      final starters = ManeuverCatalog.starterIds(knight);

      expect(fleet().armManeuvers(knight, [starters.last]), isTrue);
      expect(progress().maneuversFor(knight).active, [starters.last]);

      expect(fleet().armManeuvers(knight, [idOf(knight, ManeuverFamily.loop)]),
          isFalse);
      expect(
        fleet().armManeuvers(knight, [
          for (var slot = 0; slot <= ShipManeuvers.slots; slot++) starters.first,
        ]),
        isFalse,
      );
      expect(progress().maneuversFor(knight).active, [starters.last]);
    });

    test('a pack hands its maneuvers to every ship that can fly them', () {
      fleet().grantPack('ace');

      final packed = ManeuverCatalog.inPack('ace');
      expect(packed, isNotEmpty);
      for (final maneuver in packed) {
        expect(progress().maneuversFor(maneuver.ship).owned,
            contains(maneuver.id));
      }
    });

    test('what a ship learned survives a save and load', () {
      fleet().addCredits(2000);
      fleet().recordBattleWin(knight);
      fleet().recordBattleWin(knight);
      fleet().upgradeManeuver(knight, idOf(knight, ManeuverFamily.sidestep));

      final loaded = store.load(playerFleetIdentity);

      expect(loaded, progress());
      expect(loaded.maneuversFor(knight).levelOf(idOf(knight, ManeuverFamily.sidestep)), 2);
      expect(loaded.battleWinsWith(knight), 2);
    });

    test('progress saved before maneuvers loads its starters', () async {
      SharedPreferences.setMockInitialValues({
        'fleet_progress.player':
            '{"credits":10,"upgrades":{},"gamesPlayed":1,"wins":1}',
      });
      final old = FleetProgressStore(await SharedPreferences.getInstance())
          .load(playerFleetIdentity);

      expect(old.maneuversFor(knight).active,
          ManeuverCatalog.starterIds(knight));
      expect(old.battleWinsWith(knight), 0);
    });
  });
}
