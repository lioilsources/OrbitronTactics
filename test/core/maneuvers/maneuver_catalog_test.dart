import 'package:flutter_test/flutter_test.dart';
import 'package:orbitron_tactics/core/game_logic/models/piece.dart';
import 'package:orbitron_tactics/core/maneuvers/maneuver.dart';
import 'package:orbitron_tactics/core/maneuvers/maneuver_catalog.dart';
import 'package:orbitron_tactics/core/maneuvers/maneuver_pattern.dart';

void main() {
  const context = ManeuverContext(
    origin: (x: 0.4, altitude: 0.3),
    enemyAtStart: (x: 0.7, altitude: 0.8),
    enemyLive: (x: 0.2, altitude: 0.6),
  );

  Maneuver of(PieceType ship, ManeuverFamily family) => ManeuverCatalog
      .forShip(ship)
      .firstWhere((maneuver) => maneuver.family == family);

  group('ManeuverCatalog', () {
    test('every ship flies at least ten maneuvers', () {
      for (final ship in PieceType.values) {
        expect(ManeuverCatalog.forShip(ship).length,
            greaterThanOrEqualTo(10), reason: ship.name);
      }
    });

    test('every ship starts with two and has a signature of its own', () {
      for (final ship in PieceType.values) {
        expect(ManeuverCatalog.starterIds(ship).length, 2, reason: ship.name);
        final signature = of(ship, ManeuverFamily.signature);
        expect(signature.tier, ManeuverTier.signature);
        expect(signature.ship, ship);
      }
    });

    test('the heavy ships neither loop nor corkscrew', () {
      for (final ship in [PieceType.rook, PieceType.king]) {
        final families =
            ManeuverCatalog.forShip(ship).map((m) => m.family).toSet();
        expect(families, isNot(contains(ManeuverFamily.loop)));
        expect(families, isNot(contains(ManeuverFamily.spiral)));
      }
    });

    test('ids are unique and resolve', () {
      final ids = <String>{};
      for (final ship in PieceType.values) {
        for (final maneuver in ManeuverCatalog.forShip(ship)) {
          expect(ids.add(maneuver.id), isTrue, reason: maneuver.id);
          expect(ManeuverCatalog.byId(maneuver.id), same(maneuver));
        }
      }
      expect(ManeuverCatalog.byId('nobody.nothing'), isNull);
    });

    test('every gesture can be drawn, and no two of a ship collide', () {
      for (final ship in PieceType.values) {
        final seen = <String, String>{};
        for (final maneuver in ManeuverCatalog.forShip(ship)) {
          expect(Pattern.isValid(maneuver.pattern), isTrue,
              reason: '${maneuver.id} ${maneuver.pattern}');
          for (final gesture in [
            maneuver.pattern,
            if (maneuver.mirrorable) Pattern.mirror(maneuver.pattern),
          ]) {
            final key = gesture.join('-');
            expect(seen.containsKey(key), isFalse,
                reason: '${maneuver.id} clashes with ${seen[key]} on $key');
            seen[key] = maneuver.id;
          }
        }
      }
    });

    test('the pack holds what cannot be earned', () {
      final pack = ManeuverCatalog.inPack('ace');

      expect(pack, isNotEmpty);
      for (final maneuver in pack) {
        expect(maneuver.family, ManeuverFamily.spiral);
        expect(maneuver.unlock, isA<PackUnlock>());
        expect(maneuver.price, isNull, reason: 'a pack is not sold in credits');
      }
    });

    test('a pawn flies its family quicker than a rook', () {
      expect(of(PieceType.pawn, ManeuverFamily.sidestep).durationMs,
          lessThan(of(PieceType.rook, ManeuverFamily.sidestep).durationMs));
      expect(of(PieceType.pawn, ManeuverFamily.sidestep).energyCost,
          lessThan(of(PieceType.queen, ManeuverFamily.sidestep).energyCost));
    });

    test('a knight stays untouchable longer than a bishop', () {
      final knight = of(PieceType.knight, ManeuverFamily.roll).untouchable!;
      final bishop = of(PieceType.bishop, ManeuverFamily.roll).untouchable!;

      expect(knight.$2 - knight.$1, greaterThan(bishop.$2 - bishop.$1));
    });

    test('a pawn fires wider bursts for less damage', () {
      final pawn = of(PieceType.pawn, ManeuverFamily.strike).fire.first;
      final queen = of(PieceType.queen, ManeuverFamily.strike).fire.first;

      expect(pawn.shots, queen.shots + 1);
      expect(pawn.damage, lessThan(queen.damage));
      expect(pawn.spread, greaterThan(0));
    });
  });

  group('Maneuver levels', () {
    final leap = of(PieceType.knight, ManeuverFamily.signature);
    final roll = of(PieceType.knight, ManeuverFamily.roll);

    test('upgrades make a maneuver cheaper and quicker', () {
      expect(leap.costAt(2), lessThan(leap.costAt(1)));
      expect(leap.costAt(3), lessThan(leap.costAt(2)));
      expect(leap.durationAt(3), lessThan(leap.durationAt(1)));
    });

    test('the last level adds a shot where there is firing', () {
      final cue = leap.fire.first;

      expect(leap.shotsAt(cue, 1), cue.shots);
      expect(leap.shotsAt(cue, 3), cue.shots + 1);
    });

    test('and a longer window where there is none', () {
      expect(roll.fire, isEmpty);
      expect(roll.untouchableAt(3)!.$2, greaterThan(roll.untouchable!.$2));
    });

    test('credits per upgrade grow with the tier', () {
      expect(ManeuverCatalog.upgradePrice(roll, 2),
          lessThan(ManeuverCatalog.upgradePrice(leap, 2)));
      expect(ManeuverCatalog.upgradePrice(leap, 3),
          greaterThan(ManeuverCatalog.upgradePrice(leap, 2)));
    });
  });

  group('Maneuver.poseAt', () {
    test('starts where the ship is', () {
      for (final ship in PieceType.values) {
        for (final maneuver in ManeuverCatalog.forShip(ship)) {
          final pose = maneuver.poseAt(0, context: context);
          expect(pose.x, closeTo(context.origin.x, 1e-9), reason: maneuver.id);
          expect(pose.altitude, closeTo(context.origin.altitude, 1e-9),
              reason: maneuver.id);
        }
      }
    });

    test('a sidestep ends aside, on the enemy\'s starting altitude', () {
      final sidestep = of(PieceType.queen, ManeuverFamily.sidestep);

      final pose = sidestep.poseAt(1, context: context);

      expect(pose.x, closeTo(context.origin.x + 0.22, 1e-9));
      expect(pose.altitude, closeTo(context.enemyAtStart.altitude, 1e-9));
    });

    test('the mirrored gesture flies the mirrored maneuver', () {
      final sidestep = of(PieceType.queen, ManeuverFamily.sidestep);

      final pose = sidestep.poseAt(1, context: context, mirrored: true);

      expect(pose.x, closeTo(context.origin.x - 0.22, 1e-9));
      expect(pose.altitude, closeTo(context.enemyAtStart.altitude, 1e-9));
    });

    test('a loop goes over the top and comes back home', () {
      final loop = of(PieceType.knight, ManeuverFamily.loop);

      expect(loop.poseAt(0.35, context: context).altitude, closeTo(1, 1e-9));
      expect(loop.poseAt(1, context: context).altitude,
          closeTo(context.origin.altitude, 1e-9));
      expect(loop.poseAt(0.35, context: context).attitude.flip, closeTo(1, 1e-9));
    });

    test('a shadow rides on the enemy', () {
      final shadow = of(PieceType.queen, ManeuverFamily.shadow);

      final pose = shadow.poseAt(1, context: context);

      expect(pose.x, closeTo(context.enemyLive.x, 1e-9));
      expect(pose.altitude, closeTo(context.enemyLive.altitude, 1e-9));
    });

    test('the pose moves on through the maneuver', () {
      final dash = of(PieceType.queen, ManeuverFamily.dash);
      var last = dash.poseAt(0, context: context).x;

      for (var step = 1; step <= 10; step++) {
        final x = dash.poseAt(step / 10, context: context).x;
        expect(x, greaterThan(last), reason: 'at ${step / 10}');
        last = x;
      }
    });
  });
}
