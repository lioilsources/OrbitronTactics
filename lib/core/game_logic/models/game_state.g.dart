// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'game_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$GameStateImpl _$$GameStateImplFromJson(Map<String, dynamic> json) =>
    _$GameStateImpl(
      gameId: json['gameId'] as String,
      phase: $enumDecode(_$GamePhaseEnumMap, json['phase']),
      board: BoardState.fromJson(json['board'] as Map<String, dynamic>),
      currentTurn: $enumDecode(_$PlayerColorEnumMap, json['currentTurn']),
      playerWhite: Player.fromJson(json['playerWhite'] as Map<String, dynamic>),
      playerBlack: Player.fromJson(json['playerBlack'] as Map<String, dynamic>),
      moveHistory: (json['moveHistory'] as List<dynamic>)
          .map((e) => Move.fromJson(e as Map<String, dynamic>))
          .toList(),
      victoryCondition: json['victoryCondition'] == null
          ? null
          : VictoryCondition.fromJson(
              json['victoryCondition'] as Map<String, dynamic>,
            ),
      winner: $enumDecodeNullable(_$PlayerColorEnumMap, json['winner']),
      moveCount: (json['moveCount'] as num).toInt(),
    );

Map<String, dynamic> _$$GameStateImplToJson(_$GameStateImpl instance) =>
    <String, dynamic>{
      'gameId': instance.gameId,
      'phase': _$GamePhaseEnumMap[instance.phase]!,
      'board': instance.board,
      'currentTurn': _$PlayerColorEnumMap[instance.currentTurn]!,
      'playerWhite': instance.playerWhite,
      'playerBlack': instance.playerBlack,
      'moveHistory': instance.moveHistory,
      'victoryCondition': instance.victoryCondition,
      'winner': _$PlayerColorEnumMap[instance.winner],
      'moveCount': instance.moveCount,
    };

const _$GamePhaseEnumMap = {
  GamePhase.waitingForPlayers: 'waitingForPlayers',
  GamePhase.formation: 'formation',
  GamePhase.playing: 'playing',
  GamePhase.finished: 'finished',
};

const _$PlayerColorEnumMap = {
  PlayerColor.white: 'white',
  PlayerColor.black: 'black',
};
