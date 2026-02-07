import '../../../core/game_logic/models/formation.dart';
import '../../../core/game_logic/models/move.dart';
import '../../../core/game_logic/models/piece.dart';

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
