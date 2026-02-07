// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'player.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PlayerImpl _$$PlayerImplFromJson(Map<String, dynamic> json) => _$PlayerImpl(
  userId: json['userId'] as String,
  displayName: json['displayName'] as String,
  color: $enumDecode(_$PlayerColorEnumMap, json['color']),
  formation: json['formation'] == null
      ? null
      : Formation.fromJson(json['formation'] as Map<String, dynamic>),
  formationLocked: json['formationLocked'] as bool? ?? false,
  hasKing: json['hasKing'] as bool? ?? true,
  hasQueen: json['hasQueen'] as bool? ?? true,
);

Map<String, dynamic> _$$PlayerImplToJson(_$PlayerImpl instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'displayName': instance.displayName,
      'color': _$PlayerColorEnumMap[instance.color]!,
      'formation': instance.formation,
      'formationLocked': instance.formationLocked,
      'hasKing': instance.hasKing,
      'hasQueen': instance.hasQueen,
    };

const _$PlayerColorEnumMap = {
  PlayerColor.white: 'white',
  PlayerColor.black: 'black',
};
