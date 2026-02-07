// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'piece.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Piece _$PieceFromJson(Map<String, dynamic> json) {
  return _Piece.fromJson(json);
}

/// @nodoc
mixin _$Piece {
  PieceType get type => throw _privateConstructorUsedError;
  PlayerColor get color => throw _privateConstructorUsedError;
  bool get isLastWarrior => throw _privateConstructorUsedError;

  /// Serializes this Piece to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Piece
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PieceCopyWith<Piece> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PieceCopyWith<$Res> {
  factory $PieceCopyWith(Piece value, $Res Function(Piece) then) =
      _$PieceCopyWithImpl<$Res, Piece>;
  @useResult
  $Res call({PieceType type, PlayerColor color, bool isLastWarrior});
}

/// @nodoc
class _$PieceCopyWithImpl<$Res, $Val extends Piece>
    implements $PieceCopyWith<$Res> {
  _$PieceCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Piece
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? type = null,
    Object? color = null,
    Object? isLastWarrior = null,
  }) {
    return _then(
      _value.copyWith(
            type: null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as PieceType,
            color: null == color
                ? _value.color
                : color // ignore: cast_nullable_to_non_nullable
                      as PlayerColor,
            isLastWarrior: null == isLastWarrior
                ? _value.isLastWarrior
                : isLastWarrior // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PieceImplCopyWith<$Res> implements $PieceCopyWith<$Res> {
  factory _$$PieceImplCopyWith(
    _$PieceImpl value,
    $Res Function(_$PieceImpl) then,
  ) = __$$PieceImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({PieceType type, PlayerColor color, bool isLastWarrior});
}

/// @nodoc
class __$$PieceImplCopyWithImpl<$Res>
    extends _$PieceCopyWithImpl<$Res, _$PieceImpl>
    implements _$$PieceImplCopyWith<$Res> {
  __$$PieceImplCopyWithImpl(
    _$PieceImpl _value,
    $Res Function(_$PieceImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Piece
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? type = null,
    Object? color = null,
    Object? isLastWarrior = null,
  }) {
    return _then(
      _$PieceImpl(
        type: null == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as PieceType,
        color: null == color
            ? _value.color
            : color // ignore: cast_nullable_to_non_nullable
                  as PlayerColor,
        isLastWarrior: null == isLastWarrior
            ? _value.isLastWarrior
            : isLastWarrior // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PieceImpl extends _Piece {
  const _$PieceImpl({
    required this.type,
    required this.color,
    this.isLastWarrior = false,
  }) : super._();

  factory _$PieceImpl.fromJson(Map<String, dynamic> json) =>
      _$$PieceImplFromJson(json);

  @override
  final PieceType type;
  @override
  final PlayerColor color;
  @override
  @JsonKey()
  final bool isLastWarrior;

  @override
  String toString() {
    return 'Piece(type: $type, color: $color, isLastWarrior: $isLastWarrior)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PieceImpl &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.color, color) || other.color == color) &&
            (identical(other.isLastWarrior, isLastWarrior) ||
                other.isLastWarrior == isLastWarrior));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, type, color, isLastWarrior);

  /// Create a copy of Piece
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PieceImplCopyWith<_$PieceImpl> get copyWith =>
      __$$PieceImplCopyWithImpl<_$PieceImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PieceImplToJson(this);
  }
}

abstract class _Piece extends Piece {
  const factory _Piece({
    required final PieceType type,
    required final PlayerColor color,
    final bool isLastWarrior,
  }) = _$PieceImpl;
  const _Piece._() : super._();

  factory _Piece.fromJson(Map<String, dynamic> json) = _$PieceImpl.fromJson;

  @override
  PieceType get type;
  @override
  PlayerColor get color;
  @override
  bool get isLastWarrior;

  /// Create a copy of Piece
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PieceImplCopyWith<_$PieceImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
