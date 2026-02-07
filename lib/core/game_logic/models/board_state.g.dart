// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'board_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$BoardStateImpl _$$BoardStateImplFromJson(Map<String, dynamic> json) =>
    _$BoardStateImpl(
      grid: (json['grid'] as List<dynamic>)
          .map(
            (e) => (e as List<dynamic>)
                .map(
                  (e) => e == null
                      ? null
                      : Piece.fromJson(e as Map<String, dynamic>),
                )
                .toList(),
          )
          .toList(),
      powerFields: (json['powerFields'] as List<dynamic>)
          .map((e) => PowerField.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$BoardStateImplToJson(_$BoardStateImpl instance) =>
    <String, dynamic>{
      'grid': instance.grid,
      'powerFields': instance.powerFields,
    };
