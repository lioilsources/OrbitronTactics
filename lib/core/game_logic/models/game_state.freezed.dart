// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'game_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

GameState _$GameStateFromJson(Map<String, dynamic> json) {
  return _GameState.fromJson(json);
}

/// @nodoc
mixin _$GameState {
  String get gameId => throw _privateConstructorUsedError;
  GamePhase get phase => throw _privateConstructorUsedError;
  BoardState get board => throw _privateConstructorUsedError;
  PlayerColor get currentTurn => throw _privateConstructorUsedError;
  Player get playerWhite => throw _privateConstructorUsedError;
  Player get playerBlack => throw _privateConstructorUsedError;
  List<Move> get moveHistory => throw _privateConstructorUsedError;
  VictoryCondition? get victoryCondition => throw _privateConstructorUsedError;
  PlayerColor? get winner => throw _privateConstructorUsedError;
  int get moveCount => throw _privateConstructorUsedError;

  /// Serializes this GameState to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of GameState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $GameStateCopyWith<GameState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GameStateCopyWith<$Res> {
  factory $GameStateCopyWith(GameState value, $Res Function(GameState) then) =
      _$GameStateCopyWithImpl<$Res, GameState>;
  @useResult
  $Res call({
    String gameId,
    GamePhase phase,
    BoardState board,
    PlayerColor currentTurn,
    Player playerWhite,
    Player playerBlack,
    List<Move> moveHistory,
    VictoryCondition? victoryCondition,
    PlayerColor? winner,
    int moveCount,
  });

  $BoardStateCopyWith<$Res> get board;
  $PlayerCopyWith<$Res> get playerWhite;
  $PlayerCopyWith<$Res> get playerBlack;
  $VictoryConditionCopyWith<$Res>? get victoryCondition;
}

/// @nodoc
class _$GameStateCopyWithImpl<$Res, $Val extends GameState>
    implements $GameStateCopyWith<$Res> {
  _$GameStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of GameState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? gameId = null,
    Object? phase = null,
    Object? board = null,
    Object? currentTurn = null,
    Object? playerWhite = null,
    Object? playerBlack = null,
    Object? moveHistory = null,
    Object? victoryCondition = freezed,
    Object? winner = freezed,
    Object? moveCount = null,
  }) {
    return _then(
      _value.copyWith(
            gameId: null == gameId
                ? _value.gameId
                : gameId // ignore: cast_nullable_to_non_nullable
                      as String,
            phase: null == phase
                ? _value.phase
                : phase // ignore: cast_nullable_to_non_nullable
                      as GamePhase,
            board: null == board
                ? _value.board
                : board // ignore: cast_nullable_to_non_nullable
                      as BoardState,
            currentTurn: null == currentTurn
                ? _value.currentTurn
                : currentTurn // ignore: cast_nullable_to_non_nullable
                      as PlayerColor,
            playerWhite: null == playerWhite
                ? _value.playerWhite
                : playerWhite // ignore: cast_nullable_to_non_nullable
                      as Player,
            playerBlack: null == playerBlack
                ? _value.playerBlack
                : playerBlack // ignore: cast_nullable_to_non_nullable
                      as Player,
            moveHistory: null == moveHistory
                ? _value.moveHistory
                : moveHistory // ignore: cast_nullable_to_non_nullable
                      as List<Move>,
            victoryCondition: freezed == victoryCondition
                ? _value.victoryCondition
                : victoryCondition // ignore: cast_nullable_to_non_nullable
                      as VictoryCondition?,
            winner: freezed == winner
                ? _value.winner
                : winner // ignore: cast_nullable_to_non_nullable
                      as PlayerColor?,
            moveCount: null == moveCount
                ? _value.moveCount
                : moveCount // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }

  /// Create a copy of GameState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $BoardStateCopyWith<$Res> get board {
    return $BoardStateCopyWith<$Res>(_value.board, (value) {
      return _then(_value.copyWith(board: value) as $Val);
    });
  }

  /// Create a copy of GameState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PlayerCopyWith<$Res> get playerWhite {
    return $PlayerCopyWith<$Res>(_value.playerWhite, (value) {
      return _then(_value.copyWith(playerWhite: value) as $Val);
    });
  }

  /// Create a copy of GameState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PlayerCopyWith<$Res> get playerBlack {
    return $PlayerCopyWith<$Res>(_value.playerBlack, (value) {
      return _then(_value.copyWith(playerBlack: value) as $Val);
    });
  }

  /// Create a copy of GameState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $VictoryConditionCopyWith<$Res>? get victoryCondition {
    if (_value.victoryCondition == null) {
      return null;
    }

    return $VictoryConditionCopyWith<$Res>(_value.victoryCondition!, (value) {
      return _then(_value.copyWith(victoryCondition: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$GameStateImplCopyWith<$Res>
    implements $GameStateCopyWith<$Res> {
  factory _$$GameStateImplCopyWith(
    _$GameStateImpl value,
    $Res Function(_$GameStateImpl) then,
  ) = __$$GameStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String gameId,
    GamePhase phase,
    BoardState board,
    PlayerColor currentTurn,
    Player playerWhite,
    Player playerBlack,
    List<Move> moveHistory,
    VictoryCondition? victoryCondition,
    PlayerColor? winner,
    int moveCount,
  });

  @override
  $BoardStateCopyWith<$Res> get board;
  @override
  $PlayerCopyWith<$Res> get playerWhite;
  @override
  $PlayerCopyWith<$Res> get playerBlack;
  @override
  $VictoryConditionCopyWith<$Res>? get victoryCondition;
}

/// @nodoc
class __$$GameStateImplCopyWithImpl<$Res>
    extends _$GameStateCopyWithImpl<$Res, _$GameStateImpl>
    implements _$$GameStateImplCopyWith<$Res> {
  __$$GameStateImplCopyWithImpl(
    _$GameStateImpl _value,
    $Res Function(_$GameStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of GameState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? gameId = null,
    Object? phase = null,
    Object? board = null,
    Object? currentTurn = null,
    Object? playerWhite = null,
    Object? playerBlack = null,
    Object? moveHistory = null,
    Object? victoryCondition = freezed,
    Object? winner = freezed,
    Object? moveCount = null,
  }) {
    return _then(
      _$GameStateImpl(
        gameId: null == gameId
            ? _value.gameId
            : gameId // ignore: cast_nullable_to_non_nullable
                  as String,
        phase: null == phase
            ? _value.phase
            : phase // ignore: cast_nullable_to_non_nullable
                  as GamePhase,
        board: null == board
            ? _value.board
            : board // ignore: cast_nullable_to_non_nullable
                  as BoardState,
        currentTurn: null == currentTurn
            ? _value.currentTurn
            : currentTurn // ignore: cast_nullable_to_non_nullable
                  as PlayerColor,
        playerWhite: null == playerWhite
            ? _value.playerWhite
            : playerWhite // ignore: cast_nullable_to_non_nullable
                  as Player,
        playerBlack: null == playerBlack
            ? _value.playerBlack
            : playerBlack // ignore: cast_nullable_to_non_nullable
                  as Player,
        moveHistory: null == moveHistory
            ? _value._moveHistory
            : moveHistory // ignore: cast_nullable_to_non_nullable
                  as List<Move>,
        victoryCondition: freezed == victoryCondition
            ? _value.victoryCondition
            : victoryCondition // ignore: cast_nullable_to_non_nullable
                  as VictoryCondition?,
        winner: freezed == winner
            ? _value.winner
            : winner // ignore: cast_nullable_to_non_nullable
                  as PlayerColor?,
        moveCount: null == moveCount
            ? _value.moveCount
            : moveCount // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$GameStateImpl extends _GameState {
  const _$GameStateImpl({
    required this.gameId,
    required this.phase,
    required this.board,
    required this.currentTurn,
    required this.playerWhite,
    required this.playerBlack,
    required final List<Move> moveHistory,
    this.victoryCondition,
    this.winner,
    required this.moveCount,
  }) : _moveHistory = moveHistory,
       super._();

  factory _$GameStateImpl.fromJson(Map<String, dynamic> json) =>
      _$$GameStateImplFromJson(json);

  @override
  final String gameId;
  @override
  final GamePhase phase;
  @override
  final BoardState board;
  @override
  final PlayerColor currentTurn;
  @override
  final Player playerWhite;
  @override
  final Player playerBlack;
  final List<Move> _moveHistory;
  @override
  List<Move> get moveHistory {
    if (_moveHistory is EqualUnmodifiableListView) return _moveHistory;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_moveHistory);
  }

  @override
  final VictoryCondition? victoryCondition;
  @override
  final PlayerColor? winner;
  @override
  final int moveCount;

  @override
  String toString() {
    return 'GameState(gameId: $gameId, phase: $phase, board: $board, currentTurn: $currentTurn, playerWhite: $playerWhite, playerBlack: $playerBlack, moveHistory: $moveHistory, victoryCondition: $victoryCondition, winner: $winner, moveCount: $moveCount)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GameStateImpl &&
            (identical(other.gameId, gameId) || other.gameId == gameId) &&
            (identical(other.phase, phase) || other.phase == phase) &&
            (identical(other.board, board) || other.board == board) &&
            (identical(other.currentTurn, currentTurn) ||
                other.currentTurn == currentTurn) &&
            (identical(other.playerWhite, playerWhite) ||
                other.playerWhite == playerWhite) &&
            (identical(other.playerBlack, playerBlack) ||
                other.playerBlack == playerBlack) &&
            const DeepCollectionEquality().equals(
              other._moveHistory,
              _moveHistory,
            ) &&
            (identical(other.victoryCondition, victoryCondition) ||
                other.victoryCondition == victoryCondition) &&
            (identical(other.winner, winner) || other.winner == winner) &&
            (identical(other.moveCount, moveCount) ||
                other.moveCount == moveCount));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    gameId,
    phase,
    board,
    currentTurn,
    playerWhite,
    playerBlack,
    const DeepCollectionEquality().hash(_moveHistory),
    victoryCondition,
    winner,
    moveCount,
  );

  /// Create a copy of GameState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GameStateImplCopyWith<_$GameStateImpl> get copyWith =>
      __$$GameStateImplCopyWithImpl<_$GameStateImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$GameStateImplToJson(this);
  }
}

abstract class _GameState extends GameState {
  const factory _GameState({
    required final String gameId,
    required final GamePhase phase,
    required final BoardState board,
    required final PlayerColor currentTurn,
    required final Player playerWhite,
    required final Player playerBlack,
    required final List<Move> moveHistory,
    final VictoryCondition? victoryCondition,
    final PlayerColor? winner,
    required final int moveCount,
  }) = _$GameStateImpl;
  const _GameState._() : super._();

  factory _GameState.fromJson(Map<String, dynamic> json) =
      _$GameStateImpl.fromJson;

  @override
  String get gameId;
  @override
  GamePhase get phase;
  @override
  BoardState get board;
  @override
  PlayerColor get currentTurn;
  @override
  Player get playerWhite;
  @override
  Player get playerBlack;
  @override
  List<Move> get moveHistory;
  @override
  VictoryCondition? get victoryCondition;
  @override
  PlayerColor? get winner;
  @override
  int get moveCount;

  /// Create a copy of GameState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GameStateImplCopyWith<_$GameStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
