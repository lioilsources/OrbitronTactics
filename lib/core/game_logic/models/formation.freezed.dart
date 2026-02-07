// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'formation.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Formation _$FormationFromJson(Map<String, dynamic> json) {
  return _Formation.fromJson(json);
}

/// @nodoc
mixin _$Formation {
  /// Map from position (within player's first 2 rows) to piece.
  /// White uses rows 0-1, black uses rows 6-7.
  List<FormationPlacement> get placements => throw _privateConstructorUsedError;

  /// Serializes this Formation to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Formation
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FormationCopyWith<Formation> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FormationCopyWith<$Res> {
  factory $FormationCopyWith(Formation value, $Res Function(Formation) then) =
      _$FormationCopyWithImpl<$Res, Formation>;
  @useResult
  $Res call({List<FormationPlacement> placements});
}

/// @nodoc
class _$FormationCopyWithImpl<$Res, $Val extends Formation>
    implements $FormationCopyWith<$Res> {
  _$FormationCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Formation
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? placements = null}) {
    return _then(
      _value.copyWith(
            placements: null == placements
                ? _value.placements
                : placements // ignore: cast_nullable_to_non_nullable
                      as List<FormationPlacement>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$FormationImplCopyWith<$Res>
    implements $FormationCopyWith<$Res> {
  factory _$$FormationImplCopyWith(
    _$FormationImpl value,
    $Res Function(_$FormationImpl) then,
  ) = __$$FormationImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<FormationPlacement> placements});
}

/// @nodoc
class __$$FormationImplCopyWithImpl<$Res>
    extends _$FormationCopyWithImpl<$Res, _$FormationImpl>
    implements _$$FormationImplCopyWith<$Res> {
  __$$FormationImplCopyWithImpl(
    _$FormationImpl _value,
    $Res Function(_$FormationImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Formation
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? placements = null}) {
    return _then(
      _$FormationImpl(
        placements: null == placements
            ? _value._placements
            : placements // ignore: cast_nullable_to_non_nullable
                  as List<FormationPlacement>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$FormationImpl implements _Formation {
  const _$FormationImpl({required final List<FormationPlacement> placements})
    : _placements = placements;

  factory _$FormationImpl.fromJson(Map<String, dynamic> json) =>
      _$$FormationImplFromJson(json);

  /// Map from position (within player's first 2 rows) to piece.
  /// White uses rows 0-1, black uses rows 6-7.
  final List<FormationPlacement> _placements;

  /// Map from position (within player's first 2 rows) to piece.
  /// White uses rows 0-1, black uses rows 6-7.
  @override
  List<FormationPlacement> get placements {
    if (_placements is EqualUnmodifiableListView) return _placements;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_placements);
  }

  @override
  String toString() {
    return 'Formation(placements: $placements)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FormationImpl &&
            const DeepCollectionEquality().equals(
              other._placements,
              _placements,
            ));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_placements),
  );

  /// Create a copy of Formation
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FormationImplCopyWith<_$FormationImpl> get copyWith =>
      __$$FormationImplCopyWithImpl<_$FormationImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$FormationImplToJson(this);
  }
}

abstract class _Formation implements Formation {
  const factory _Formation({
    required final List<FormationPlacement> placements,
  }) = _$FormationImpl;

  factory _Formation.fromJson(Map<String, dynamic> json) =
      _$FormationImpl.fromJson;

  /// Map from position (within player's first 2 rows) to piece.
  /// White uses rows 0-1, black uses rows 6-7.
  @override
  List<FormationPlacement> get placements;

  /// Create a copy of Formation
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FormationImplCopyWith<_$FormationImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

FormationPlacement _$FormationPlacementFromJson(Map<String, dynamic> json) {
  return _FormationPlacement.fromJson(json);
}

/// @nodoc
mixin _$FormationPlacement {
  Position get position => throw _privateConstructorUsedError;
  Piece get piece => throw _privateConstructorUsedError;

  /// Serializes this FormationPlacement to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of FormationPlacement
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FormationPlacementCopyWith<FormationPlacement> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FormationPlacementCopyWith<$Res> {
  factory $FormationPlacementCopyWith(
    FormationPlacement value,
    $Res Function(FormationPlacement) then,
  ) = _$FormationPlacementCopyWithImpl<$Res, FormationPlacement>;
  @useResult
  $Res call({Position position, Piece piece});

  $PositionCopyWith<$Res> get position;
  $PieceCopyWith<$Res> get piece;
}

/// @nodoc
class _$FormationPlacementCopyWithImpl<$Res, $Val extends FormationPlacement>
    implements $FormationPlacementCopyWith<$Res> {
  _$FormationPlacementCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of FormationPlacement
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? position = null, Object? piece = null}) {
    return _then(
      _value.copyWith(
            position: null == position
                ? _value.position
                : position // ignore: cast_nullable_to_non_nullable
                      as Position,
            piece: null == piece
                ? _value.piece
                : piece // ignore: cast_nullable_to_non_nullable
                      as Piece,
          )
          as $Val,
    );
  }

  /// Create a copy of FormationPlacement
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PositionCopyWith<$Res> get position {
    return $PositionCopyWith<$Res>(_value.position, (value) {
      return _then(_value.copyWith(position: value) as $Val);
    });
  }

  /// Create a copy of FormationPlacement
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PieceCopyWith<$Res> get piece {
    return $PieceCopyWith<$Res>(_value.piece, (value) {
      return _then(_value.copyWith(piece: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$FormationPlacementImplCopyWith<$Res>
    implements $FormationPlacementCopyWith<$Res> {
  factory _$$FormationPlacementImplCopyWith(
    _$FormationPlacementImpl value,
    $Res Function(_$FormationPlacementImpl) then,
  ) = __$$FormationPlacementImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({Position position, Piece piece});

  @override
  $PositionCopyWith<$Res> get position;
  @override
  $PieceCopyWith<$Res> get piece;
}

/// @nodoc
class __$$FormationPlacementImplCopyWithImpl<$Res>
    extends _$FormationPlacementCopyWithImpl<$Res, _$FormationPlacementImpl>
    implements _$$FormationPlacementImplCopyWith<$Res> {
  __$$FormationPlacementImplCopyWithImpl(
    _$FormationPlacementImpl _value,
    $Res Function(_$FormationPlacementImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of FormationPlacement
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? position = null, Object? piece = null}) {
    return _then(
      _$FormationPlacementImpl(
        position: null == position
            ? _value.position
            : position // ignore: cast_nullable_to_non_nullable
                  as Position,
        piece: null == piece
            ? _value.piece
            : piece // ignore: cast_nullable_to_non_nullable
                  as Piece,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$FormationPlacementImpl implements _FormationPlacement {
  const _$FormationPlacementImpl({required this.position, required this.piece});

  factory _$FormationPlacementImpl.fromJson(Map<String, dynamic> json) =>
      _$$FormationPlacementImplFromJson(json);

  @override
  final Position position;
  @override
  final Piece piece;

  @override
  String toString() {
    return 'FormationPlacement(position: $position, piece: $piece)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FormationPlacementImpl &&
            (identical(other.position, position) ||
                other.position == position) &&
            (identical(other.piece, piece) || other.piece == piece));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, position, piece);

  /// Create a copy of FormationPlacement
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FormationPlacementImplCopyWith<_$FormationPlacementImpl> get copyWith =>
      __$$FormationPlacementImplCopyWithImpl<_$FormationPlacementImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$FormationPlacementImplToJson(this);
  }
}

abstract class _FormationPlacement implements FormationPlacement {
  const factory _FormationPlacement({
    required final Position position,
    required final Piece piece,
  }) = _$FormationPlacementImpl;

  factory _FormationPlacement.fromJson(Map<String, dynamic> json) =
      _$FormationPlacementImpl.fromJson;

  @override
  Position get position;
  @override
  Piece get piece;

  /// Create a copy of FormationPlacement
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FormationPlacementImplCopyWith<_$FormationPlacementImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
