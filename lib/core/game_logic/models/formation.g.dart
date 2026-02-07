// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'formation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$FormationImpl _$$FormationImplFromJson(Map<String, dynamic> json) =>
    _$FormationImpl(
      placements: (json['placements'] as List<dynamic>)
          .map((e) => FormationPlacement.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$FormationImplToJson(_$FormationImpl instance) =>
    <String, dynamic>{'placements': instance.placements};

_$FormationPlacementImpl _$$FormationPlacementImplFromJson(
  Map<String, dynamic> json,
) => _$FormationPlacementImpl(
  position: Position.fromJson(json['position'] as Map<String, dynamic>),
  piece: Piece.fromJson(json['piece'] as Map<String, dynamic>),
);

Map<String, dynamic> _$$FormationPlacementImplToJson(
  _$FormationPlacementImpl instance,
) => <String, dynamic>{'position': instance.position, 'piece': instance.piece};
