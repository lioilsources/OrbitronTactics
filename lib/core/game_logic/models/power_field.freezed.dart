// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'power_field.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

PowerField _$PowerFieldFromJson(Map<String, dynamic> json) {
  return _PowerField.fromJson(json);
}

/// @nodoc
mixin _$PowerField {
  Position get position => throw _privateConstructorUsedError;

  /// Serializes this PowerField to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PowerField
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PowerFieldCopyWith<PowerField> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PowerFieldCopyWith<$Res> {
  factory $PowerFieldCopyWith(
    PowerField value,
    $Res Function(PowerField) then,
  ) = _$PowerFieldCopyWithImpl<$Res, PowerField>;
  @useResult
  $Res call({Position position});

  $PositionCopyWith<$Res> get position;
}

/// @nodoc
class _$PowerFieldCopyWithImpl<$Res, $Val extends PowerField>
    implements $PowerFieldCopyWith<$Res> {
  _$PowerFieldCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PowerField
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? position = null}) {
    return _then(
      _value.copyWith(
            position: null == position
                ? _value.position
                : position // ignore: cast_nullable_to_non_nullable
                      as Position,
          )
          as $Val,
    );
  }

  /// Create a copy of PowerField
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PositionCopyWith<$Res> get position {
    return $PositionCopyWith<$Res>(_value.position, (value) {
      return _then(_value.copyWith(position: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$PowerFieldImplCopyWith<$Res>
    implements $PowerFieldCopyWith<$Res> {
  factory _$$PowerFieldImplCopyWith(
    _$PowerFieldImpl value,
    $Res Function(_$PowerFieldImpl) then,
  ) = __$$PowerFieldImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({Position position});

  @override
  $PositionCopyWith<$Res> get position;
}

/// @nodoc
class __$$PowerFieldImplCopyWithImpl<$Res>
    extends _$PowerFieldCopyWithImpl<$Res, _$PowerFieldImpl>
    implements _$$PowerFieldImplCopyWith<$Res> {
  __$$PowerFieldImplCopyWithImpl(
    _$PowerFieldImpl _value,
    $Res Function(_$PowerFieldImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PowerField
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? position = null}) {
    return _then(
      _$PowerFieldImpl(
        position: null == position
            ? _value.position
            : position // ignore: cast_nullable_to_non_nullable
                  as Position,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PowerFieldImpl implements _PowerField {
  const _$PowerFieldImpl({required this.position});

  factory _$PowerFieldImpl.fromJson(Map<String, dynamic> json) =>
      _$$PowerFieldImplFromJson(json);

  @override
  final Position position;

  @override
  String toString() {
    return 'PowerField(position: $position)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PowerFieldImpl &&
            (identical(other.position, position) ||
                other.position == position));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, position);

  /// Create a copy of PowerField
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PowerFieldImplCopyWith<_$PowerFieldImpl> get copyWith =>
      __$$PowerFieldImplCopyWithImpl<_$PowerFieldImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PowerFieldImplToJson(this);
  }
}

abstract class _PowerField implements PowerField {
  const factory _PowerField({required final Position position}) =
      _$PowerFieldImpl;

  factory _PowerField.fromJson(Map<String, dynamic> json) =
      _$PowerFieldImpl.fromJson;

  @override
  Position get position;

  /// Create a copy of PowerField
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PowerFieldImplCopyWith<_$PowerFieldImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
