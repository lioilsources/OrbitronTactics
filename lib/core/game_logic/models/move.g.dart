// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'move.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$MoveImpl _$$MoveImplFromJson(Map<String, dynamic> json) => _$MoveImpl(
  from: Position.fromJson(json['from'] as Map<String, dynamic>),
  to: Position.fromJson(json['to'] as Map<String, dynamic>),
  piece: Piece.fromJson(json['piece'] as Map<String, dynamic>),
  capturedPiece: json['capturedPiece'] == null
      ? null
      : Piece.fromJson(json['capturedPiece'] as Map<String, dynamic>),
  isSnipe: json['isSnipe'] as bool? ?? false,
);

Map<String, dynamic> _$$MoveImplToJson(_$MoveImpl instance) =>
    <String, dynamic>{
      'from': instance.from,
      'to': instance.to,
      'piece': instance.piece,
      'capturedPiece': instance.capturedPiece,
      'isSnipe': instance.isSnipe,
    };
