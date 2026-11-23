import 'dart:ui' show Locale;

import 'package:flutter_test/flutter_test.dart';
import 'package:orbitron_tactics/core/game_logic/models/piece.dart';
import 'package:orbitron_tactics/core/maneuvers/maneuver_catalog.dart';
import 'package:orbitron_tactics/features/battle/data/fleet_skin.dart';
import 'package:orbitron_tactics/l10n/l10n.dart';

void main() {
  final en = lookupAppLocalizations(const Locale('en'));
  final cs = lookupAppLocalizations(const Locale('cs'));

  test('English maneuver texts match the catalog', () {
    for (final ship in PieceType.values) {
      for (final maneuver in ManeuverCatalog.forShip(ship)) {
        expect(en.maneuverName(maneuver), maneuver.name, reason: maneuver.id);
        expect(en.maneuverDescription(maneuver), maneuver.description,
            reason: maneuver.id);
      }
    }
  });

  test('English fleet names match the fleet skins', () {
    for (final skin in FleetSkin.values) {
      expect(skin.localizedName(en), skin.displayName);
    }
  });

  test('Czech plurals pick one, few and other', () {
    expect(cs.battlesWon(1), '1 vyhraná bitva');
    expect(cs.battlesWon(3), '3 vyhrané bitvy');
    expect(cs.battlesWon(5), '5 vyhraných bitev');
    expect(en.battlesWon(1), '1 battle won');
    expect(en.battlesWon(2), '2 battles won');
  });

  test('AI player names follow the difficulty', () {
    expect(en.aiNameForIdentity('ai-hard'), 'Archion AI · Hard');
    expect(cs.aiNameForIdentity('ai-easy'), 'Archion AI · Lehká');
    expect(en.aiNameForIdentity('player'), isNull);
  });
}
