import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/game_logic/engine/game_engine.dart';
import '../../../../core/game_logic/models/game_state.dart';
import '../../../../core/game_logic/models/piece.dart';
import '../../../../core/game_logic/models/player.dart';
import '../../../../core/game_logic/models/position.dart';
import '../../../../core/game_logic/validators/move_validator.dart';
import '../../data/game_session.dart';

/// The mode in which the game is running.
enum GameMode {
  /// Both players on same device, no transport needed.
  hotSeat,

  /// Each player has their own session with transport.
  multiplayer,
}

/// Manages the game state for both local hot-seat and multiplayer modes.
class GameStateNotifier extends StateNotifier<GameState> {
  GameMode _mode;
  GameSession? _session;
  StreamSubscription<GameState>? _sessionSub;
  StreamSubscription<void>? _disconnectSub;
  PlayerColor? _localColor;
  bool _opponentDisconnected = false;

  GameStateNotifier(GameState initial, {GameMode mode = GameMode.hotSeat})
      : _mode = mode,
        super(initial);

  GameMode get mode => _mode;
  GameSession? get session => _session;

  /// The local player's color. Null in hot-seat mode.
  PlayerColor? get localColor => _localColor;

  /// Whether the opponent has disconnected.
  bool get opponentDisconnected => _opponentDisconnected;

  /// Stream that fires when the opponent disconnects.
  Stream<void>? get onOpponentDisconnect => _session?.onOpponentDisconnect;

  /// Attach a multiplayer session. State updates come from the session.
  void attachSession(GameSession session) {
    _sessionSub?.cancel();
    _disconnectSub?.cancel();
    _session = session;
    _mode = GameMode.multiplayer;
    _localColor = session.localColor;
    _opponentDisconnected = false;
    state = session.state;

    _sessionSub = session.stateStream.listen((newState) {
      state = newState;
    });

    _disconnectSub = session.onOpponentDisconnect.listen((_) {
      _opponentDisconnected = true;
      // Trigger a state rebuild by re-setting the same state
      state = state;
    });
  }

  /// Claim victory by abandonment (opponent disconnected).
  void claimVictory() {
    _session?.claimVictory();
  }

  /// Update the remote player's display name (e.g. after they join).
  void updateRemotePlayerName(String name) {
    final remoteColor = _localColor?.opposite ?? PlayerColor.black;
    if (remoteColor == PlayerColor.black) {
      state = state.copyWith(
        playerBlack: state.playerBlack.copyWith(displayName: name),
      );
    } else {
      state = state.copyWith(
        playerWhite: state.playerWhite.copyWith(displayName: name),
      );
    }
  }

  /// Attempt to make a move from [from] to [to].
  /// Returns true if the move was successful.
  bool tryMove(Position from, Position to) {
    if (_mode == GameMode.multiplayer && _session != null) {
      final success = _session!.tryMove(from, to);
      return success;
    }

    // Hot-seat mode: direct apply
    final newState = GameEngine.tryMove(state, from, to);
    if (newState == null) return false;
    state = newState;
    return true;
  }

  /// Get legal moves for the piece at [position].
  List<Position> getLegalMoves(Position position) {
    if (_mode == GameMode.multiplayer && _session != null) {
      return _session!.getLegalMoves(position);
    }
    return MoveValidator.getLegalMoves(state, position);
  }

  /// Start a new local hot-seat game with default formations.
  void startNewGame() {
    _detachSession();
    _mode = GameMode.hotSeat;
    _localColor = null;

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

  /// Start a new multiplayer game using paired local sessions.
  /// Returns the opponent's session (for testing / hot-seat-over-transport).
  GameSession startLocalMultiplayerGame() {
    _detachSession();

    final (whiteSession, blackSession) = GameSession.createLocalGame();
    whiteSession.start();
    blackSession.start();

    // This notifier acts as white; return black session for the opponent.
    attachSession(whiteSession);
    return blackSession;
  }

  void _detachSession() {
    _sessionSub?.cancel();
    _sessionSub = null;
    _disconnectSub?.cancel();
    _disconnectSub = null;
    _session?.dispose();
    _session = null;
    _opponentDisconnected = false;
  }

  @override
  void dispose() {
    _detachSession();
    super.dispose();
  }
}

/// Provider for the game state notifier.
final gameStateProvider =
    StateNotifierProvider<GameStateNotifier, GameState>((ref) {
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
