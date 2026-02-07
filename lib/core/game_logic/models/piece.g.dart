// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'piece.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PieceImpl _$$PieceImplFromJson(Map<String, dynamic> json) => _$PieceImpl(
  type: $enumDecode(_$PieceTypeEnumMap, json['type']),
  color: $enumDecode(_$PlayerColorEnumMap, json['color']),
  isLastWarrior: json['isLastWarrior'] as bool? ?? false,
);

Map<String, dynamic> _$$PieceImplToJson(_$PieceImpl instance) =>
    <String, dynamic>{
      'type': _$PieceTypeEnumMap[instance.type]!,
      'color': _$PlayerColorEnumMap[instance.color]!,
      'isLastWarrior': instance.isLastWarrior,
    };

const _$PieceTypeEnumMap = {
  PieceType.pawn: 'pawn',
  PieceType.rook: 'rook',
  PieceType.knight: 'knight',
  PieceType.bishop: 'bishop',
  PieceType.queen: 'queen',
  PieceType.king: 'king',
};

const _$PlayerColorEnumMap = {
  PlayerColor.white: 'white',
  PlayerColor.black: 'black',
};
