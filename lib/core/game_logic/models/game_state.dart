import 'package:freezed_annotation/freezed_annotation.dart';
import 'board_state.dart';
import 'game_phase.dart';
import 'move.dart';
import 'piece.dart';
import 'player.dart';
import 'victory_condition.dart';

part 'game_state.freezed.dart';
part 'game_state.g.dart';

@freezed
class GameState with _$GameState {
  const GameState._();

  const factory GameState({
    required String gameId,
    required GamePhase phase,
    required BoardState board,
    required PlayerColor currentTurn,
    required Player playerWhite,
    required Player playerBlack,
    required List<Move> moveHistory,
    VictoryCondition? victoryCondition,
    PlayerColor? winner,
    required int moveCount,
  }) = _GameState;

  factory GameState.fromJson(Map<String, dynamic> json) =>
      _$GameStateFromJson(json);

  Player playerFor(PlayerColor color) =>
      color == PlayerColor.white ? playerWhite : playerBlack;

  Player get currentPlayer => playerFor(currentTurn);

  Player get waitingPlayer => playerFor(currentTurn.opposite);

  bool get isFinished => phase == GamePhase.finished;
}
