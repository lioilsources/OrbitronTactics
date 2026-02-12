// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'victory_condition.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PowerFieldDominationImpl _$$PowerFieldDominationImplFromJson(
  Map<String, dynamic> json,
) => _$PowerFieldDominationImpl($type: json['runtimeType'] as String?);

Map<String, dynamic> _$$PowerFieldDominationImplToJson(
  _$PowerFieldDominationImpl instance,
) => <String, dynamic>{'runtimeType': instance.$type};

_$RoyalEliminationImpl _$$RoyalEliminationImplFromJson(
  Map<String, dynamic> json,
) => _$RoyalEliminationImpl($type: json['runtimeType'] as String?);

Map<String, dynamic> _$$RoyalEliminationImplToJson(
  _$RoyalEliminationImpl instance,
) => <String, dynamic>{'runtimeType': instance.$type};

_$InfiltrationImpl _$$InfiltrationImplFromJson(Map<String, dynamic> json) =>
    _$InfiltrationImpl(
      pawnPosition: Position.fromJson(
        json['pawnPosition'] as Map<String, dynamic>,
      ),
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$$InfiltrationImplToJson(_$InfiltrationImpl instance) =>
    <String, dynamic>{
      'pawnPosition': instance.pawnPosition,
      'runtimeType': instance.$type,
    };

_$AbandonmentImpl _$$AbandonmentImplFromJson(Map<String, dynamic> json) =>
    _$AbandonmentImpl($type: json['runtimeType'] as String?);

Map<String, dynamic> _$$AbandonmentImplToJson(_$AbandonmentImpl instance) =>
    <String, dynamic>{'runtimeType': instance.$type};
