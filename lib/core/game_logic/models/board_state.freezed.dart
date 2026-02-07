// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'board_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

BoardState _$BoardStateFromJson(Map<String, dynamic> json) {
  return _BoardState.fromJson(json);
}

/// @nodoc
mixin _$BoardState {
  /// 8x8 grid indexed as grid[row][col]. Null = empty square.
  List<List<Piece?>> get grid => throw _privateConstructorUsedError;
  List<PowerField> get powerFields => throw _privateConstructorUsedError;

  /// Serializes this BoardState to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of BoardState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $BoardStateCopyWith<BoardState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BoardStateCopyWith<$Res> {
  factory $BoardStateCopyWith(
    BoardState value,
    $Res Function(BoardState) then,
  ) = _$BoardStateCopyWithImpl<$Res, BoardState>;
  @useResult
  $Res call({List<List<Piece?>> grid, List<PowerField> powerFields});
}

/// @nodoc
class _$BoardStateCopyWithImpl<$Res, $Val extends BoardState>
    implements $BoardStateCopyWith<$Res> {
  _$BoardStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of BoardState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? grid = null, Object? powerFields = null}) {
    return _then(
      _value.copyWith(
            grid: null == grid
                ? _value.grid
                : grid // ignore: cast_nullable_to_non_nullable
                      as List<List<Piece?>>,
            powerFields: null == powerFields
                ? _value.powerFields
                : powerFields // ignore: cast_nullable_to_non_nullable
                      as List<PowerField>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$BoardStateImplCopyWith<$Res>
    implements $BoardStateCopyWith<$Res> {
  factory _$$BoardStateImplCopyWith(
    _$BoardStateImpl value,
    $Res Function(_$BoardStateImpl) then,
  ) = __$$BoardStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<List<Piece?>> grid, List<PowerField> powerFields});
}

/// @nodoc
class __$$BoardStateImplCopyWithImpl<$Res>
    extends _$BoardStateCopyWithImpl<$Res, _$BoardStateImpl>
    implements _$$BoardStateImplCopyWith<$Res> {
  __$$BoardStateImplCopyWithImpl(
    _$BoardStateImpl _value,
    $Res Function(_$BoardStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of BoardState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? grid = null, Object? powerFields = null}) {
    return _then(
      _$BoardStateImpl(
        grid: null == grid
            ? _value._grid
            : grid // ignore: cast_nullable_to_non_nullable
                  as List<List<Piece?>>,
        powerFields: null == powerFields
            ? _value._powerFields
            : powerFields // ignore: cast_nullable_to_non_nullable
                  as List<PowerField>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$BoardStateImpl extends _BoardState {
  const _$BoardStateImpl({
    required final List<List<Piece?>> grid,
    required final List<PowerField> powerFields,
  }) : _grid = grid,
       _powerFields = powerFields,
       super._();

  factory _$BoardStateImpl.fromJson(Map<String, dynamic> json) =>
      _$$BoardStateImplFromJson(json);

  /// 8x8 grid indexed as grid[row][col]. Null = empty square.
  final List<List<Piece?>> _grid;

  /// 8x8 grid indexed as grid[row][col]. Null = empty square.
  @override
  List<List<Piece?>> get grid {
    if (_grid is EqualUnmodifiableListView) return _grid;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_grid);
  }

  final List<PowerField> _powerFields;
  @override
  List<PowerField> get powerFields {
    if (_powerFields is EqualUnmodifiableListView) return _powerFields;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_powerFields);
  }

  @override
  String toString() {
    return 'BoardState(grid: $grid, powerFields: $powerFields)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BoardStateImpl &&
            const DeepCollectionEquality().equals(other._grid, _grid) &&
            const DeepCollectionEquality().equals(
              other._powerFields,
              _powerFields,
            ));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_grid),
    const DeepCollectionEquality().hash(_powerFields),
  );

  /// Create a copy of BoardState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BoardStateImplCopyWith<_$BoardStateImpl> get copyWith =>
      __$$BoardStateImplCopyWithImpl<_$BoardStateImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$BoardStateImplToJson(this);
  }
}

abstract class _BoardState extends BoardState {
  const factory _BoardState({
    required final List<List<Piece?>> grid,
    required final List<PowerField> powerFields,
  }) = _$BoardStateImpl;
  const _BoardState._() : super._();

  factory _BoardState.fromJson(Map<String, dynamic> json) =
      _$BoardStateImpl.fromJson;

  /// 8x8 grid indexed as grid[row][col]. Null = empty square.
  @override
  List<List<Piece?>> get grid;
  @override
  List<PowerField> get powerFields;

  /// Create a copy of BoardState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BoardStateImplCopyWith<_$BoardStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
