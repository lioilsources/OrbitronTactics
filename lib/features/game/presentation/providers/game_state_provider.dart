import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/game_logic/engine/game_engine.dart';
import '../../../../core/game_logic/models/game_state.dart';
import '../../../../core/game_logic/models/piece.dart';
import '../../../../core/game_logic/models/player.dart';
import '../../../../core/game_logic/models/position.dart';
import '../../../../core/game_logic/validators/move_validator.dart';

/// Manages the game state for local hot-seat play.
class GameStateNotifier extends StateNotifier<GameState> {
  GameStateNotifier(GameState initial) : super(initial);

  /// Attempt to make a move from [from] to [to].
  /// Returns true if the move was successful.
  bool tryMove(Position from, Position to) {
    final newState = GameEngine.tryMove(state, from, to);
    if (newState == null) return false;
    state = newState;
    return true;
  }

  /// Get legal moves for the piece at [position].
  List<Position> getLegalMoves(Position position) {
    return MoveValidator.getLegalMoves(state, position);
  }

  /// Start a new local game with default formations.
  void startNewGame() {
    final gameState = GameEngine.createGame(
      gameId: 'local-${DateTime.now().millisecondsSinceEpoch}',
      playerWhite: const Player(
        userId: 'local-white',
        displayName: 'White',
        color: PlayerColor.white,
      ),
      playerBlack: const Player(
        userId: 'local-black',
        displayName: 'Black',
        color: PlayerColor.black,
      ),
    );

    // Apply default formations for both players
    var withWhite = GameEngine.applyFormation(
      gameState,
      PlayerColor.white,
      GameEngine.defaultFormation(PlayerColor.white),
    );
    var withBoth = GameEngine.applyFormation(
      withWhite,
      PlayerColor.black,
      GameEngine.defaultFormation(PlayerColor.black),
    );

    state = withBoth;
  }
}

/// Provider for the game state notifier.
final gameStateProvider =
    StateNotifierProvider<GameStateNotifier, GameState>((ref) {
  // Create an initial game
  final gameState = GameEngine.createGame(
    gameId: 'local-${DateTime.now().millisecondsSinceEpoch}',
    playerWhite: const Player(
      userId: 'local-white',
      displayName: 'White',
      color: PlayerColor.white,
    ),
    playerBlack: const Player(
      userId: 'local-black',
      displayName: 'Black',
      color: PlayerColor.black,
    ),
  );

  // Apply default formations
  var withWhite = GameEngine.applyFormation(
    gameState,
    PlayerColor.white,
    GameEngine.defaultFormation(PlayerColor.white),
  );
  var withBoth = GameEngine.applyFormation(
    withWhite,
    PlayerColor.black,
    GameEngine.defaultFormation(PlayerColor.black),
  );

  return GameStateNotifier(withBoth);
});
