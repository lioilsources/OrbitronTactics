// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'victory_condition.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

VictoryCondition _$VictoryConditionFromJson(Map<String, dynamic> json) {
  switch (json['runtimeType']) {
    case 'powerFieldDomination':
      return PowerFieldDomination.fromJson(json);
    case 'royalElimination':
      return RoyalElimination.fromJson(json);
    case 'infiltration':
      return Infiltration.fromJson(json);
    case 'abandonment':
      return Abandonment.fromJson(json);

    default:
      throw CheckedFromJsonException(
        json,
        'runtimeType',
        'VictoryCondition',
        'Invalid union type "${json['runtimeType']}"!',
      );
  }
}

/// @nodoc
mixin _$VictoryCondition {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() powerFieldDomination,
    required TResult Function() royalElimination,
    required TResult Function(Position pawnPosition) infiltration,
    required TResult Function() abandonment,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? powerFieldDomination,
    TResult? Function()? royalElimination,
    TResult? Function(Position pawnPosition)? infiltration,
    TResult? Function()? abandonment,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? powerFieldDomination,
    TResult Function()? royalElimination,
    TResult Function(Position pawnPosition)? infiltration,
    TResult Function()? abandonment,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(PowerFieldDomination value) powerFieldDomination,
    required TResult Function(RoyalElimination value) royalElimination,
    required TResult Function(Infiltration value) infiltration,
    required TResult Function(Abandonment value) abandonment,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(PowerFieldDomination value)? powerFieldDomination,
    TResult? Function(RoyalElimination value)? royalElimination,
    TResult? Function(Infiltration value)? infiltration,
    TResult? Function(Abandonment value)? abandonment,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(PowerFieldDomination value)? powerFieldDomination,
    TResult Function(RoyalElimination value)? royalElimination,
    TResult Function(Infiltration value)? infiltration,
    TResult Function(Abandonment value)? abandonment,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;

  /// Serializes this VictoryCondition to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $VictoryConditionCopyWith<$Res> {
  factory $VictoryConditionCopyWith(
    VictoryCondition value,
    $Res Function(VictoryCondition) then,
  ) = _$VictoryConditionCopyWithImpl<$Res, VictoryCondition>;
}

/// @nodoc
class _$VictoryConditionCopyWithImpl<$Res, $Val extends VictoryCondition>
    implements $VictoryConditionCopyWith<$Res> {
  _$VictoryConditionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of VictoryCondition
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$PowerFieldDominationImplCopyWith<$Res> {
  factory _$$PowerFieldDominationImplCopyWith(
    _$PowerFieldDominationImpl value,
    $Res Function(_$PowerFieldDominationImpl) then,
  ) = __$$PowerFieldDominationImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$PowerFieldDominationImplCopyWithImpl<$Res>
    extends _$VictoryConditionCopyWithImpl<$Res, _$PowerFieldDominationImpl>
    implements _$$PowerFieldDominationImplCopyWith<$Res> {
  __$$PowerFieldDominationImplCopyWithImpl(
    _$PowerFieldDominationImpl _value,
    $Res Function(_$PowerFieldDominationImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of VictoryCondition
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
@JsonSerializable()
class _$PowerFieldDominationImpl implements PowerFieldDomination {
  const _$PowerFieldDominationImpl({final String? $type})
    : $type = $type ?? 'powerFieldDomination';

  factory _$PowerFieldDominationImpl.fromJson(Map<String, dynamic> json) =>
      _$$PowerFieldDominationImplFromJson(json);

  @JsonKey(name: 'runtimeType')
  final String $type;

  @override
  String toString() {
    return 'VictoryCondition.powerFieldDomination()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PowerFieldDominationImpl);
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() powerFieldDomination,
    required TResult Function() royalElimination,
    required TResult Function(Position pawnPosition) infiltration,
    required TResult Function() abandonment,
  }) {
    return powerFieldDomination();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? powerFieldDomination,
    TResult? Function()? royalElimination,
    TResult? Function(Position pawnPosition)? infiltration,
    TResult? Function()? abandonment,
  }) {
    return powerFieldDomination?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? powerFieldDomination,
    TResult Function()? royalElimination,
    TResult Function(Position pawnPosition)? infiltration,
    TResult Function()? abandonment,
    required TResult orElse(),
  }) {
    if (powerFieldDomination != null) {
      return powerFieldDomination();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(PowerFieldDomination value) powerFieldDomination,
    required TResult Function(RoyalElimination value) royalElimination,
    required TResult Function(Infiltration value) infiltration,
    required TResult Function(Abandonment value) abandonment,
  }) {
    return powerFieldDomination(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(PowerFieldDomination value)? powerFieldDomination,
    TResult? Function(RoyalElimination value)? royalElimination,
    TResult? Function(Infiltration value)? infiltration,
    TResult? Function(Abandonment value)? abandonment,
  }) {
    return powerFieldDomination?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(PowerFieldDomination value)? powerFieldDomination,
    TResult Function(RoyalElimination value)? royalElimination,
    TResult Function(Infiltration value)? infiltration,
    TResult Function(Abandonment value)? abandonment,
    required TResult orElse(),
  }) {
    if (powerFieldDomination != null) {
      return powerFieldDomination(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$PowerFieldDominationImplToJson(this);
  }
}

abstract class PowerFieldDomination implements VictoryCondition {
  const factory PowerFieldDomination() = _$PowerFieldDominationImpl;

  factory PowerFieldDomination.fromJson(Map<String, dynamic> json) =
      _$PowerFieldDominationImpl.fromJson;
}

/// @nodoc
abstract class _$$RoyalEliminationImplCopyWith<$Res> {
  factory _$$RoyalEliminationImplCopyWith(
    _$RoyalEliminationImpl value,
    $Res Function(_$RoyalEliminationImpl) then,
  ) = __$$RoyalEliminationImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$RoyalEliminationImplCopyWithImpl<$Res>
    extends _$VictoryConditionCopyWithImpl<$Res, _$RoyalEliminationImpl>
    implements _$$RoyalEliminationImplCopyWith<$Res> {
  __$$RoyalEliminationImplCopyWithImpl(
    _$RoyalEliminationImpl _value,
    $Res Function(_$RoyalEliminationImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of VictoryCondition
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
@JsonSerializable()
class _$RoyalEliminationImpl implements RoyalElimination {
  const _$RoyalEliminationImpl({final String? $type})
    : $type = $type ?? 'royalElimination';

  factory _$RoyalEliminationImpl.fromJson(Map<String, dynamic> json) =>
      _$$RoyalEliminationImplFromJson(json);

  @JsonKey(name: 'runtimeType')
  final String $type;

  @override
  String toString() {
    return 'VictoryCondition.royalElimination()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$RoyalEliminationImpl);
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() powerFieldDomination,
    required TResult Function() royalElimination,
    required TResult Function(Position pawnPosition) infiltration,
    required TResult Function() abandonment,
  }) {
    return royalElimination();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? powerFieldDomination,
    TResult? Function()? royalElimination,
    TResult? Function(Position pawnPosition)? infiltration,
    TResult? Function()? abandonment,
  }) {
    return royalElimination?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? powerFieldDomination,
    TResult Function()? royalElimination,
    TResult Function(Position pawnPosition)? infiltration,
    TResult Function()? abandonment,
    required TResult orElse(),
  }) {
    if (royalElimination != null) {
      return royalElimination();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(PowerFieldDomination value) powerFieldDomination,
    required TResult Function(RoyalElimination value) royalElimination,
    required TResult Function(Infiltration value) infiltration,
    required TResult Function(Abandonment value) abandonment,
  }) {
    return royalElimination(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(PowerFieldDomination value)? powerFieldDomination,
    TResult? Function(RoyalElimination value)? royalElimination,
    TResult? Function(Infiltration value)? infiltration,
    TResult? Function(Abandonment value)? abandonment,
  }) {
    return royalElimination?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(PowerFieldDomination value)? powerFieldDomination,
    TResult Function(RoyalElimination value)? royalElimination,
    TResult Function(Infiltration value)? infiltration,
    TResult Function(Abandonment value)? abandonment,
    required TResult orElse(),
  }) {
    if (royalElimination != null) {
      return royalElimination(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$RoyalEliminationImplToJson(this);
  }
}

abstract class RoyalElimination implements VictoryCondition {
  const factory RoyalElimination() = _$RoyalEliminationImpl;

  factory RoyalElimination.fromJson(Map<String, dynamic> json) =
      _$RoyalEliminationImpl.fromJson;
}

/// @nodoc
abstract class _$$InfiltrationImplCopyWith<$Res> {
  factory _$$InfiltrationImplCopyWith(
    _$InfiltrationImpl value,
    $Res Function(_$InfiltrationImpl) then,
  ) = __$$InfiltrationImplCopyWithImpl<$Res>;
  @useResult
  $Res call({Position pawnPosition});

  $PositionCopyWith<$Res> get pawnPosition;
}

/// @nodoc
class __$$InfiltrationImplCopyWithImpl<$Res>
    extends _$VictoryConditionCopyWithImpl<$Res, _$InfiltrationImpl>
    implements _$$InfiltrationImplCopyWith<$Res> {
  __$$InfiltrationImplCopyWithImpl(
    _$InfiltrationImpl _value,
    $Res Function(_$InfiltrationImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of VictoryCondition
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? pawnPosition = null}) {
    return _then(
      _$InfiltrationImpl(
        pawnPosition: null == pawnPosition
            ? _value.pawnPosition
            : pawnPosition // ignore: cast_nullable_to_non_nullable
                  as Position,
      ),
    );
  }

  /// Create a copy of VictoryCondition
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PositionCopyWith<$Res> get pawnPosition {
    return $PositionCopyWith<$Res>(_value.pawnPosition, (value) {
      return _then(_value.copyWith(pawnPosition: value));
    });
  }
}

/// @nodoc
@JsonSerializable()
class _$InfiltrationImpl implements Infiltration {
  const _$InfiltrationImpl({required this.pawnPosition, final String? $type})
    : $type = $type ?? 'infiltration';

  factory _$InfiltrationImpl.fromJson(Map<String, dynamic> json) =>
      _$$InfiltrationImplFromJson(json);

  @override
  final Position pawnPosition;

  @JsonKey(name: 'runtimeType')
  final String $type;

  @override
  String toString() {
    return 'VictoryCondition.infiltration(pawnPosition: $pawnPosition)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$InfiltrationImpl &&
            (identical(other.pawnPosition, pawnPosition) ||
                other.pawnPosition == pawnPosition));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, pawnPosition);

  /// Create a copy of VictoryCondition
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$InfiltrationImplCopyWith<_$InfiltrationImpl> get copyWith =>
      __$$InfiltrationImplCopyWithImpl<_$InfiltrationImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() powerFieldDomination,
    required TResult Function() royalElimination,
    required TResult Function(Position pawnPosition) infiltration,
    required TResult Function() abandonment,
  }) {
    return infiltration(pawnPosition);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? powerFieldDomination,
    TResult? Function()? royalElimination,
    TResult? Function(Position pawnPosition)? infiltration,
    TResult? Function()? abandonment,
  }) {
    return infiltration?.call(pawnPosition);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? powerFieldDomination,
    TResult Function()? royalElimination,
    TResult Function(Position pawnPosition)? infiltration,
    TResult Function()? abandonment,
    required TResult orElse(),
  }) {
    if (infiltration != null) {
      return infiltration(pawnPosition);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(PowerFieldDomination value) powerFieldDomination,
    required TResult Function(RoyalElimination value) royalElimination,
    required TResult Function(Infiltration value) infiltration,
    required TResult Function(Abandonment value) abandonment,
  }) {
    return infiltration(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(PowerFieldDomination value)? powerFieldDomination,
    TResult? Function(RoyalElimination value)? royalElimination,
    TResult? Function(Infiltration value)? infiltration,
    TResult? Function(Abandonment value)? abandonment,
  }) {
    return infiltration?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(PowerFieldDomination value)? powerFieldDomination,
    TResult Function(RoyalElimination value)? royalElimination,
    TResult Function(Infiltration value)? infiltration,
    TResult Function(Abandonment value)? abandonment,
    required TResult orElse(),
  }) {
    if (infiltration != null) {
      return infiltration(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$InfiltrationImplToJson(this);
  }
}

abstract class Infiltration implements VictoryCondition {
  const factory Infiltration({required final Position pawnPosition}) =
      _$InfiltrationImpl;

  factory Infiltration.fromJson(Map<String, dynamic> json) =
      _$InfiltrationImpl.fromJson;

  Position get pawnPosition;

  /// Create a copy of VictoryCondition
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$InfiltrationImplCopyWith<_$InfiltrationImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$AbandonmentImplCopyWith<$Res> {
  factory _$$AbandonmentImplCopyWith(
    _$AbandonmentImpl value,
    $Res Function(_$AbandonmentImpl) then,
  ) = __$$AbandonmentImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$AbandonmentImplCopyWithImpl<$Res>
    extends _$VictoryConditionCopyWithImpl<$Res, _$AbandonmentImpl>
    implements _$$AbandonmentImplCopyWith<$Res> {
  __$$AbandonmentImplCopyWithImpl(
    _$AbandonmentImpl _value,
    $Res Function(_$AbandonmentImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of VictoryCondition
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
@JsonSerializable()
class _$AbandonmentImpl implements Abandonment {
  const _$AbandonmentImpl({final String? $type})
    : $type = $type ?? 'abandonment';

  factory _$AbandonmentImpl.fromJson(Map<String, dynamic> json) =>
      _$$AbandonmentImplFromJson(json);

  @JsonKey(name: 'runtimeType')
  final String $type;

  @override
  String toString() {
    return 'VictoryCondition.abandonment()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$AbandonmentImpl);
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() powerFieldDomination,
    required TResult Function() royalElimination,
    required TResult Function(Position pawnPosition) infiltration,
    required TResult Function() abandonment,
  }) {
    return abandonment();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? powerFieldDomination,
    TResult? Function()? royalElimination,
    TResult? Function(Position pawnPosition)? infiltration,
    TResult? Function()? abandonment,
  }) {
    return abandonment?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? powerFieldDomination,
    TResult Function()? royalElimination,
    TResult Function(Position pawnPosition)? infiltration,
    TResult Function()? abandonment,
    required TResult orElse(),
  }) {
    if (abandonment != null) {
      return abandonment();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(PowerFieldDomination value) powerFieldDomination,
    required TResult Function(RoyalElimination value) royalElimination,
    required TResult Function(Infiltration value) infiltration,
    required TResult Function(Abandonment value) abandonment,
  }) {
    return abandonment(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(PowerFieldDomination value)? powerFieldDomination,
    TResult? Function(RoyalElimination value)? royalElimination,
    TResult? Function(Infiltration value)? infiltration,
    TResult? Function(Abandonment value)? abandonment,
  }) {
    return abandonment?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(PowerFieldDomination value)? powerFieldDomination,
    TResult Function(RoyalElimination value)? royalElimination,
    TResult Function(Infiltration value)? infiltration,
    TResult Function(Abandonment value)? abandonment,
    required TResult orElse(),
  }) {
    if (abandonment != null) {
      return abandonment(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$AbandonmentImplToJson(this);
  }
}

abstract class Abandonment implements VictoryCondition {
  const factory Abandonment() = _$AbandonmentImpl;

  factory Abandonment.fromJson(Map<String, dynamic> json) =
      _$AbandonmentImpl.fromJson;
}
