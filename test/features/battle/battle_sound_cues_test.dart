import 'package:flutter_test/flutter_test.dart';
import 'package:orbitron_tactics/core/game_logic/engine/battle_engine.dart';
import 'package:orbitron_tactics/core/game_logic/models/impact.dart';
import 'package:orbitron_tactics/core/game_logic/models/piece.dart';
import 'package:orbitron_tactics/core/game_logic/models/projectile.dart';
import 'package:orbitron_tactics/core/game_logic/models/upgrade_profile.dart';
import 'package:orbitron_tactics/features/battle/data/battle_element.dart';
import 'package:orbitron_tactics/features/battle/presentation/audio/battle_sound_cues.dart';

void main() {
  // A bishop (fire) attacking a rook (ice).
  final start = BattleEngine.createBattle(
    attacker: const Piece(type: PieceType.bishop, color: PlayerColor.white),
    defender: const Piece(type: PieceType.rook, color: PlayerColor.black),
    attackerUpgrades: const UpgradeProfile(),
    defenderUpgrades: const UpgradeProfile(),
  );

  const bishopShot = Projectile(
    id: 'bishop shot',
    positionFraction: 0,
    damage: 25,
    fromAttacker: true,
  );

  Impact impactOnRook({bool shielded = false}) => Impact(
        id: 'bishop shot',
        onAttacker: false,
        xFraction: 0.5,
        altitude: 0.5,
        damage: 25,
        shielded: shielded,
        atMs: 900,
      );

  group('BattleSoundCues', () {
    test('a ship moving makes no sound', () {
      final moved = BattleEngine.moveShip(start, true, 0.2, altitude: 0.9);

      expect(BattleSoundCues.between(start, moved).isEmpty, isTrue);
    });

    test('a new shot sounds in its shooter\'s element', () {
      final fired = start.copyWith(projectiles: const [bishopShot]);

      expect(BattleSoundCues.between(start, fired).shots, [BattleElement.fire]);
    });

    test('shots and impacts already heard stay quiet', () {
      final state = start.copyWith(
        projectiles: const [bishopShot],
        impacts: [impactOnRook()],
      );

      expect(BattleSoundCues.between(state, state.copyWith()).isEmpty, isTrue);
    });

    test('an impact sounds in the shooter\'s element, with its power', () {
      final struck = start.copyWith(impacts: [impactOnRook(shielded: true)]);

      final impact = BattleSoundCues.between(start, struck).impacts.single;

      expect(impact.element, BattleElement.fire);
      expect(impact.damage, 25);
      expect(impact.shielded, isTrue);
    });

    test('the end of the battle blows the loser up in its own element', () {
      final won = start.copyWith(isFinished: true, winner: PlayerColor.white);

      expect(BattleSoundCues.between(start, won).destroyed, BattleElement.ice);
      expect(BattleSoundCues.between(won, won.copyWith()).destroyed, isNull);
    });
  });
}
