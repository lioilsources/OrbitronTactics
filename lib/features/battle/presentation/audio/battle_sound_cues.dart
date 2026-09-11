import '../../../../core/game_logic/models/battle_state.dart';
import '../../data/battle_element.dart';

/// An impact to be heard: the shooter's element and how hard it struck.
class ImpactCue {
  final BattleElement element;
  final int damage;
  final bool shielded;

  const ImpactCue(this.element, this.damage, {required this.shielded});
}

/// The sounds between two consecutive battle states: shots fired, impacts
/// landed and, when the battle has just ended, the losing ship's explosion.
class BattleSoundCues {
  /// The element of each shot fired.
  final List<BattleElement> shots;
  final List<ImpactCue> impacts;

  /// The losing ship's element, on the state that ends the battle.
  final BattleElement? destroyed;

  const BattleSoundCues({
    this.shots = const [],
    this.impacts = const [],
    this.destroyed,
  });

  bool get isEmpty => shots.isEmpty && impacts.isEmpty && destroyed == null;

  factory BattleSoundCues.between(BattleState previous, BattleState next) {
    BattleElement elementOf({required bool attacker}) => BattleElement.of(
        (attacker ? next.attacker : next.defender).piece.type);

    final fired = {for (final shot in previous.projectiles) shot.id};
    final struck = {for (final impact in previous.impacts) impact.id};
    final justEnded = next.isFinished && !previous.isFinished;
    final loser = !justEnded
        ? null
        : next.winner == next.attacker.piece.color
            ? next.defender
            : next.attacker;

    return BattleSoundCues(
      shots: [
        for (final shot in next.projectiles)
          if (!fired.contains(shot.id)) elementOf(attacker: shot.fromAttacker),
      ],
      impacts: [
        for (final impact in next.impacts)
          if (!struck.contains(impact.id))
            ImpactCue(
              // The struck ship's opponent fired the shot.
              elementOf(attacker: !impact.onAttacker),
              impact.damage,
              shielded: impact.shielded,
            ),
      ],
      destroyed: loser == null ? null : BattleElement.of(loser.piece.type),
    );
  }
}
