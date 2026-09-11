import 'battle_unit.dart';
import 'impact.dart';
import 'piece.dart';
import 'projectile.dart';

class BattleState {
  final BattleUnit attacker;
  final BattleUnit defender;
  final List<Projectile> projectiles;

  /// Shots that recently struck a ship or its shield, oldest first.
  final List<Impact> impacts;
  final int elapsedMs;
  final bool isFinished;
  final PlayerColor? winner;

  const BattleState({
    required this.attacker,
    required this.defender,
    this.projectiles = const [],
    this.impacts = const [],
    this.elapsedMs = 0,
    this.isFinished = false,
    this.winner,
  });

  BattleState copyWith({
    BattleUnit? attacker,
    BattleUnit? defender,
    List<Projectile>? projectiles,
    List<Impact>? impacts,
    int? elapsedMs,
    bool? isFinished,
    PlayerColor? winner,
  }) {
    return BattleState(
      attacker: attacker ?? this.attacker,
      defender: defender ?? this.defender,
      projectiles: projectiles ?? this.projectiles,
      impacts: impacts ?? this.impacts,
      elapsedMs: elapsedMs ?? this.elapsedMs,
      isFinished: isFinished ?? this.isFinished,
      winner: winner ?? this.winner,
    );
  }
}
