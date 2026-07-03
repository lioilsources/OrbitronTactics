import '../../../core/game_logic/models/formation.dart';
import '../../../core/game_logic/models/move.dart';
import '../../../core/game_logic/models/piece.dart';
import '../../../core/game_logic/models/upgrade_profile.dart';
import '../../battle/model/battle_simulation.dart';

/// Events exchanged between players over the transport layer.
sealed class GameEvent {
  const GameEvent();

  Map<String, dynamic> toJson();

  static GameEvent fromJson(Map<String, dynamic> json) {
    switch (json['type'] as String) {
      case 'formation_locked':
        return FormationLockedEvent(
          color: PlayerColor.values.byName(json['color'] as String),
          formation: Formation.fromJson(json['formation'] as Map<String, dynamic>),
        );
      case 'move_made':
        return MoveMadeEvent(
          move: Move.fromJson(json['move'] as Map<String, dynamic>),
        );
      case 'game_started':
        return const GameStartedEvent();
      case 'game_over':
        return GameOverEvent(
          winner: PlayerColor.values.byName(json['winner'] as String),
          reason: json['reason'] as String,
        );
      case 'player_joined':
        return PlayerJoinedEvent(
          color: PlayerColor.values.byName(json['color'] as String),
          displayName: json['displayName'] as String,
        );
      case 'player_left':
        return PlayerLeftEvent(
          color: PlayerColor.values.byName(json['color'] as String),
        );
      case 'battle_started':
        return BattleStartedEvent(
          move: Move.fromJson(json['move'] as Map<String, dynamic>),
          seed: json['seed'] as int,
          attackerSpec: json['attackerSpec'] == null
              ? null
              : ShipSpec.fromJson(json['attackerSpec'] as Map<String, dynamic>),
          defenderSpec: json['defenderSpec'] == null
              ? null
              : ShipSpec.fromJson(json['defenderSpec'] as Map<String, dynamic>),
        );
      case 'upgrade_profile':
        return UpgradeProfileEvent(
          color: PlayerColor.values.byName(json['color'] as String),
          profile:
              UpgradeProfile.fromJson(json['profile'] as Map<String, dynamic>),
        );
      case 'battle_resolved':
        return BattleResolvedEvent(
          winner: PlayerColor.values.byName(json['winner'] as String),
        );
      case 'battle_input':
        return BattleInputEvent(
          input: BattleInput.fromJson(json['input'] as Map<String, dynamic>),
        );
      case 'battle_snapshot':
        return BattleSnapshotEvent(
          snapshot:
              BattleSnapshot.fromJson(json['snapshot'] as Map<String, dynamic>),
        );
      default:
        throw ArgumentError('Unknown event type: ${json['type']}');
    }
  }
}

class FormationLockedEvent extends GameEvent {
  final PlayerColor color;
  final Formation formation;

  const FormationLockedEvent({required this.color, required this.formation});

  @override
  Map<String, dynamic> toJson() => {
        'type': 'formation_locked',
        'color': color.name,
        'formation': formation.toJson(),
      };
}

class MoveMadeEvent extends GameEvent {
  final Move move;

  const MoveMadeEvent({required this.move});

  @override
  Map<String, dynamic> toJson() => {
        'type': 'move_made',
        'move': move.toJson(),
      };
}

class GameStartedEvent extends GameEvent {
  const GameStartedEvent();

  @override
  Map<String, dynamic> toJson() => {'type': 'game_started'};
}

class GameOverEvent extends GameEvent {
  final PlayerColor winner;
  final String reason;

  const GameOverEvent({required this.winner, required this.reason});

  @override
  Map<String, dynamic> toJson() => {
        'type': 'game_over',
        'winner': winner.name,
        'reason': reason,
      };
}

class PlayerJoinedEvent extends GameEvent {
  final PlayerColor color;
  final String displayName;

  const PlayerJoinedEvent({required this.color, required this.displayName});

  @override
  Map<String, dynamic> toJson() => {
        'type': 'player_joined',
        'color': color.name,
        'displayName': displayName,
      };
}

class PlayerLeftEvent extends GameEvent {
  final PlayerColor color;

  const PlayerLeftEvent({required this.color});

  @override
  Map<String, dynamic> toJson() => {
        'type': 'player_left',
        'color': color.name,
      };
}

/// Sent when a capturing move triggers a real-time battle (local-network
/// co-op mode only). Both players enter the arena. [seed] deterministically
/// generates the asteroid field so both sides start identically. The attacker
/// is always the colour of `move.piece`.
class BattleStartedEvent extends GameEvent {
  final Move move;
  final int seed;

  /// Arena parameters for both ships, derived from the players' upgrade
  /// profiles by the initiating device. Carried in the event so both sides
  /// build an identical simulation; null means base stats.
  final ShipSpec? attackerSpec;
  final ShipSpec? defenderSpec;

  const BattleStartedEvent({
    required this.move,
    required this.seed,
    this.attackerSpec,
    this.defenderSpec,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'battle_started',
        'move': move.toJson(),
        'seed': seed,
        if (attackerSpec != null) 'attackerSpec': attackerSpec!.toJson(),
        if (defenderSpec != null) 'defenderSpec': defenderSpec!.toJson(),
      };
}

/// Announces a player's unit upgrade levels after connecting (local-network
/// co-op only), so the capture initiator can compute both ships' arena stats.
class UpgradeProfileEvent extends GameEvent {
  final PlayerColor color;
  final UpgradeProfile profile;

  const UpgradeProfileEvent({required this.color, required this.profile});

  @override
  Map<String, dynamic> toJson() => {
        'type': 'upgrade_profile',
        'color': color.name,
        'profile': profile.toJson(),
      };
}

/// Sent by the battle host with the authoritative outcome. Both sides resolve
/// the pending capture via [GameEngine.applyResolvedCapture].
class BattleResolvedEvent extends GameEvent {
  final PlayerColor winner;

  const BattleResolvedEvent({required this.winner});

  @override
  Map<String, dynamic> toJson() => {
        'type': 'battle_resolved',
        'winner': winner.name,
      };
}

/// High-frequency guest → host control input during a battle. Carried over the
/// transport so the real-time arena works on top of any [GameTransport].
class BattleInputEvent extends GameEvent {
  final BattleInput input;

  const BattleInputEvent({required this.input});

  @override
  Map<String, dynamic> toJson() => {
        'type': 'battle_input',
        'input': input.toJson(),
      };
}

/// High-frequency host → guest authoritative arena snapshot.
class BattleSnapshotEvent extends GameEvent {
  final BattleSnapshot snapshot;

  const BattleSnapshotEvent({required this.snapshot});

  @override
  Map<String, dynamic> toJson() => {
        'type': 'battle_snapshot',
        'snapshot': snapshot.toJson(),
      };
}
