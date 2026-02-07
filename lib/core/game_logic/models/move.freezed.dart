// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'move.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Move _$MoveFromJson(Map<String, dynamic> json) {
  return _Move.fromJson(json);
}

/// @nodoc
mixin _$Move {
  Position get from => throw _privateConstructorUsedError;
  Position get to => throw _privateConstructorUsedError;
  Piece get piece => throw _privateConstructorUsedError;
  Piece? get capturedPiece => throw _privateConstructorUsedError;
  bool get isSnipe => throw _privateConstructorUsedError;

  /// Serializes this Move to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Move
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MoveCopyWith<Move> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MoveCopyWith<$Res> {
  factory $MoveCopyWith(Move value, $Res Function(Move) then) =
      _$MoveCopyWithImpl<$Res, Move>;
  @useResult
  $Res call({
    Position from,
    Position to,
    Piece piece,
    Piece? capturedPiece,
    bool isSnipe,
  });

  $PositionCopyWith<$Res> get from;
  $PositionCopyWith<$Res> get to;
  $PieceCopyWith<$Res> get piece;
  $PieceCopyWith<$Res>? get capturedPiece;
}

/// @nodoc
class _$MoveCopyWithImpl<$Res, $Val extends Move>
    implements $MoveCopyWith<$Res> {
  _$MoveCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Move
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? from = null,
    Object? to = null,
    Object? piece = null,
    Object? capturedPiece = freezed,
    Object? isSnipe = null,
  }) {
    return _then(
      _value.copyWith(
            from: null == from
                ? _value.from
                : from // ignore: cast_nullable_to_non_nullable
                      as Position,
            to: null == to
                ? _value.to
                : to // ignore: cast_nullable_to_non_nullable
                      as Position,
            piece: null == piece
                ? _value.piece
                : piece // ignore: cast_nullable_to_non_nullable
                      as Piece,
            capturedPiece: freezed == capturedPiece
                ? _value.capturedPiece
                : capturedPiece // ignore: cast_nullable_to_non_nullable
                      as Piece?,
            isSnipe: null == isSnipe
                ? _value.isSnipe
                : isSnipe // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }

  /// Create a copy of Move
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PositionCopyWith<$Res> get from {
    return $PositionCopyWith<$Res>(_value.from, (value) {
      return _then(_value.copyWith(from: value) as $Val);
    });
  }

  /// Create a copy of Move
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PositionCopyWith<$Res> get to {
    return $PositionCopyWith<$Res>(_value.to, (value) {
      return _then(_value.copyWith(to: value) as $Val);
    });
  }

  /// Create a copy of Move
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PieceCopyWith<$Res> get piece {
    return $PieceCopyWith<$Res>(_value.piece, (value) {
      return _then(_value.copyWith(piece: value) as $Val);
    });
  }

  /// Create a copy of Move
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PieceCopyWith<$Res>? get capturedPiece {
    if (_value.capturedPiece == null) {
      return null;
    }

    return $PieceCopyWith<$Res>(_value.capturedPiece!, (value) {
      return _then(_value.copyWith(capturedPiece: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$MoveImplCopyWith<$Res> implements $MoveCopyWith<$Res> {
  factory _$$MoveImplCopyWith(
    _$MoveImpl value,
    $Res Function(_$MoveImpl) then,
  ) = __$$MoveImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    Position from,
    Position to,
    Piece piece,
    Piece? capturedPiece,
    bool isSnipe,
  });

  @override
  $PositionCopyWith<$Res> get from;
  @override
  $PositionCopyWith<$Res> get to;
  @override
  $PieceCopyWith<$Res> get piece;
  @override
  $PieceCopyWith<$Res>? get capturedPiece;
}

/// @nodoc
class __$$MoveImplCopyWithImpl<$Res>
    extends _$MoveCopyWithImpl<$Res, _$MoveImpl>
    implements _$$MoveImplCopyWith<$Res> {
  __$$MoveImplCopyWithImpl(_$MoveImpl _value, $Res Function(_$MoveImpl) _then)
    : super(_value, _then);

  /// Create a copy of Move
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? from = null,
    Object? to = null,
    Object? piece = null,
    Object? capturedPiece = freezed,
    Object? isSnipe = null,
  }) {
    return _then(
      _$MoveImpl(
        from: null == from
            ? _value.from
            : from // ignore: cast_nullable_to_non_nullable
                  as Position,
        to: null == to
            ? _value.to
            : to // ignore: cast_nullable_to_non_nullable
                  as Position,
        piece: null == piece
            ? _value.piece
            : piece // ignore: cast_nullable_to_non_nullable
                  as Piece,
        capturedPiece: freezed == capturedPiece
            ? _value.capturedPiece
            : capturedPiece // ignore: cast_nullable_to_non_nullable
                  as Piece?,
        isSnipe: null == isSnipe
            ? _value.isSnipe
            : isSnipe // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$MoveImpl implements _Move {
  const _$MoveImpl({
    required this.from,
    required this.to,
    required this.piece,
    this.capturedPiece,
    this.isSnipe = false,
  });

  factory _$MoveImpl.fromJson(Map<String, dynamic> json) =>
      _$$MoveImplFromJson(json);

  @override
  final Position from;
  @override
  final Position to;
  @override
  final Piece piece;
  @override
  final Piece? capturedPiece;
  @override
  @JsonKey()
  final bool isSnipe;

  @override
  String toString() {
    return 'Move(from: $from, to: $to, piece: $piece, capturedPiece: $capturedPiece, isSnipe: $isSnipe)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MoveImpl &&
            (identical(other.from, from) || other.from == from) &&
            (identical(other.to, to) || other.to == to) &&
            (identical(other.piece, piece) || other.piece == piece) &&
            (identical(other.capturedPiece, capturedPiece) ||
                other.capturedPiece == capturedPiece) &&
            (identical(other.isSnipe, isSnipe) || other.isSnipe == isSnipe));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, from, to, piece, capturedPiece, isSnipe);

  /// Create a copy of Move
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MoveImplCopyWith<_$MoveImpl> get copyWith =>
      __$$MoveImplCopyWithImpl<_$MoveImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MoveImplToJson(this);
  }
}

abstract class _Move implements Move {
  const factory _Move({
    required final Position from,
    required final Position to,
    required final Piece piece,
    final Piece? capturedPiece,
    final bool isSnipe,
  }) = _$MoveImpl;

  factory _Move.fromJson(Map<String, dynamic> json) = _$MoveImpl.fromJson;

  @override
  Position get from;
  @override
  Position get to;
  @override
  Piece get piece;
  @override
  Piece? get capturedPiece;
  @override
  bool get isSnipe;

  /// Create a copy of Move
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MoveImplCopyWith<_$MoveImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
