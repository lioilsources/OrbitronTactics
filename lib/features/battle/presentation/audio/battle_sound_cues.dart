import '../../../../core/game_logic/models/battle_state.dart';
import '../../../../core/game_logic/models/battle_unit.dart';
import '../../../../core/game_logic/models/strike_run.dart';
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
/// A melee strike is heard when its lunge starts and, on contact, as an
/// impact — or as a block when a shield stops it.
class BattleSoundCues {
  /// The element of each shot fired.
  final List<BattleElement> shots;
  final List<ImpactCue> impacts;

  /// The element of each unit that has just lunged.
  final List<BattleElement> strikes;

  /// Strikes a shield has just blocked.
  final int blocks;

  /// The losing ship's element, on the state that ends the battle.
  final BattleElement? destroyed;

  /// The other unit's element when both fell together.
  final BattleElement? alsoDestroyed;

  const BattleSoundCues({
    this.shots = const [],
    this.impacts = const [],
    this.strikes = const [],
    this.blocks = 0,
    this.destroyed,
    this.alsoDestroyed,
  });

  bool get isEmpty =>
      shots.isEmpty &&
      impacts.isEmpty &&
      strikes.isEmpty &&
      blocks == 0 &&
      destroyed == null;

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
    final fresh = [
      for (final impact in next.impacts)
        if (!struck.contains(impact.id)) impact,
    ];

    return BattleSoundCues(
      shots: [
        for (final shot in next.projectiles)
          if (!fired.contains(shot.id)) elementOf(attacker: shot.fromAttacker),
      ],
      impacts: [
        for (final impact in fresh)
          if (!(impact.melee && impact.shielded))
            ImpactCue(
              // The struck ship's opponent fired the shot.
              elementOf(attacker: !impact.onAttacker),
              impact.damage,
              shielded: impact.shielded,
            ),
      ],
      strikes: [
        if (_lunged(previous.attacker, previous.elapsedMs, next.attacker,
            next.elapsedMs))
          elementOf(attacker: true),
        if (_lunged(previous.defender, previous.elapsedMs, next.defender,
            next.elapsedMs))
          elementOf(attacker: false),
      ],
      blocks: fresh.where((impact) => impact.melee && impact.shielded).length,
      destroyed: loser == null ? null : BattleElement.of(loser.piece.type),
      // The attacker is the [destroyed] one above when both fell.
      alsoDestroyed: justEnded && next.isMutualDestruction
          ? BattleElement.of(next.defender.piece.type)
          : null,
    );
  }

  /// Whether [next]'s strike has left its wind-up since [previous]
  /// (at [previousMs]).
  static bool _lunged(
      BattleUnit previous, int previousMs, BattleUnit next, int nowMs) {
    final strike = next.strike;
    if (strike == null || strike.phaseAt(nowMs) == StrikePhase.windup) {
      return false;
    }
    final before = previous.strike;
    if (before == null || before.startedMs != strike.startedMs) return true;
    return before.phaseAt(previousMs) == StrikePhase.windup;
  }
}
