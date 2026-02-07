// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'player.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Player _$PlayerFromJson(Map<String, dynamic> json) {
  return _Player.fromJson(json);
}

/// @nodoc
mixin _$Player {
  String get userId => throw _privateConstructorUsedError;
  String get displayName => throw _privateConstructorUsedError;
  PlayerColor get color => throw _privateConstructorUsedError;
  Formation? get formation => throw _privateConstructorUsedError;
  bool get formationLocked => throw _privateConstructorUsedError;
  bool get hasKing => throw _privateConstructorUsedError;
  bool get hasQueen => throw _privateConstructorUsedError;

  /// Serializes this Player to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Player
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PlayerCopyWith<Player> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PlayerCopyWith<$Res> {
  factory $PlayerCopyWith(Player value, $Res Function(Player) then) =
      _$PlayerCopyWithImpl<$Res, Player>;
  @useResult
  $Res call({
    String userId,
    String displayName,
    PlayerColor color,
    Formation? formation,
    bool formationLocked,
    bool hasKing,
    bool hasQueen,
  });

  $FormationCopyWith<$Res>? get formation;
}

/// @nodoc
class _$PlayerCopyWithImpl<$Res, $Val extends Player>
    implements $PlayerCopyWith<$Res> {
  _$PlayerCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Player
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? displayName = null,
    Object? color = null,
    Object? formation = freezed,
    Object? formationLocked = null,
    Object? hasKing = null,
    Object? hasQueen = null,
  }) {
    return _then(
      _value.copyWith(
            userId: null == userId
                ? _value.userId
                : userId // ignore: cast_nullable_to_non_nullable
                      as String,
            displayName: null == displayName
                ? _value.displayName
                : displayName // ignore: cast_nullable_to_non_nullable
                      as String,
            color: null == color
                ? _value.color
                : color // ignore: cast_nullable_to_non_nullable
                      as PlayerColor,
            formation: freezed == formation
                ? _value.formation
                : formation // ignore: cast_nullable_to_non_nullable
                      as Formation?,
            formationLocked: null == formationLocked
                ? _value.formationLocked
                : formationLocked // ignore: cast_nullable_to_non_nullable
                      as bool,
            hasKing: null == hasKing
                ? _value.hasKing
                : hasKing // ignore: cast_nullable_to_non_nullable
                      as bool,
            hasQueen: null == hasQueen
                ? _value.hasQueen
                : hasQueen // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }

  /// Create a copy of Player
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $FormationCopyWith<$Res>? get formation {
    if (_value.formation == null) {
      return null;
    }

    return $FormationCopyWith<$Res>(_value.formation!, (value) {
      return _then(_value.copyWith(formation: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$PlayerImplCopyWith<$Res> implements $PlayerCopyWith<$Res> {
  factory _$$PlayerImplCopyWith(
    _$PlayerImpl value,
    $Res Function(_$PlayerImpl) then,
  ) = __$$PlayerImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String userId,
    String displayName,
    PlayerColor color,
    Formation? formation,
    bool formationLocked,
    bool hasKing,
    bool hasQueen,
  });

  @override
  $FormationCopyWith<$Res>? get formation;
}

/// @nodoc
class __$$PlayerImplCopyWithImpl<$Res>
    extends _$PlayerCopyWithImpl<$Res, _$PlayerImpl>
    implements _$$PlayerImplCopyWith<$Res> {
  __$$PlayerImplCopyWithImpl(
    _$PlayerImpl _value,
    $Res Function(_$PlayerImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Player
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? displayName = null,
    Object? color = null,
    Object? formation = freezed,
    Object? formationLocked = null,
    Object? hasKing = null,
    Object? hasQueen = null,
  }) {
    return _then(
      _$PlayerImpl(
        userId: null == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as String,
        displayName: null == displayName
            ? _value.displayName
            : displayName // ignore: cast_nullable_to_non_nullable
                  as String,
        color: null == color
            ? _value.color
            : color // ignore: cast_nullable_to_non_nullable
                  as PlayerColor,
        formation: freezed == formation
            ? _value.formation
            : formation // ignore: cast_nullable_to_non_nullable
                  as Formation?,
        formationLocked: null == formationLocked
            ? _value.formationLocked
            : formationLocked // ignore: cast_nullable_to_non_nullable
                  as bool,
        hasKing: null == hasKing
            ? _value.hasKing
            : hasKing // ignore: cast_nullable_to_non_nullable
                  as bool,
        hasQueen: null == hasQueen
            ? _value.hasQueen
            : hasQueen // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PlayerImpl implements _Player {
  const _$PlayerImpl({
    required this.userId,
    required this.displayName,
    required this.color,
    this.formation,
    this.formationLocked = false,
    this.hasKing = true,
    this.hasQueen = true,
  });

  factory _$PlayerImpl.fromJson(Map<String, dynamic> json) =>
      _$$PlayerImplFromJson(json);

  @override
  final String userId;
  @override
  final String displayName;
  @override
  final PlayerColor color;
  @override
  final Formation? formation;
  @override
  @JsonKey()
  final bool formationLocked;
  @override
  @JsonKey()
  final bool hasKing;
  @override
  @JsonKey()
  final bool hasQueen;

  @override
  String toString() {
    return 'Player(userId: $userId, displayName: $displayName, color: $color, formation: $formation, formationLocked: $formationLocked, hasKing: $hasKing, hasQueen: $hasQueen)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PlayerImpl &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.displayName, displayName) ||
                other.displayName == displayName) &&
            (identical(other.color, color) || other.color == color) &&
            (identical(other.formation, formation) ||
                other.formation == formation) &&
            (identical(other.formationLocked, formationLocked) ||
                other.formationLocked == formationLocked) &&
            (identical(other.hasKing, hasKing) || other.hasKing == hasKing) &&
            (identical(other.hasQueen, hasQueen) ||
                other.hasQueen == hasQueen));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    userId,
    displayName,
    color,
    formation,
    formationLocked,
    hasKing,
    hasQueen,
  );

  /// Create a copy of Player
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PlayerImplCopyWith<_$PlayerImpl> get copyWith =>
      __$$PlayerImplCopyWithImpl<_$PlayerImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PlayerImplToJson(this);
  }
}

abstract class _Player implements Player {
  const factory _Player({
    required final String userId,
    required final String displayName,
    required final PlayerColor color,
    final Formation? formation,
    final bool formationLocked,
    final bool hasKing,
    final bool hasQueen,
  }) = _$PlayerImpl;

  factory _Player.fromJson(Map<String, dynamic> json) = _$PlayerImpl.fromJson;

  @override
  String get userId;
  @override
  String get displayName;
  @override
  PlayerColor get color;
  @override
  Formation? get formation;
  @override
  bool get formationLocked;
  @override
  bool get hasKing;
  @override
  bool get hasQueen;

  /// Create a copy of Player
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PlayerImplCopyWith<_$PlayerImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
