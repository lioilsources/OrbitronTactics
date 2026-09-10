import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/ai/ai_difficulty.dart';
import '../../../../core/game_logic/engine/game_engine.dart';
import '../../../../core/game_logic/models/game_phase.dart';
import '../../../../core/game_logic/models/game_state.dart';
import '../../../../core/game_logic/models/move.dart';
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

  /// Local WiFi coop — includes realtime battle arena.
  localWifi,

  /// One player against the on-device AI — includes the battle arena.
  singlePlayer,
}

/// Manages the game state for hot-seat, single player and multiplayer modes.
class GameStateNotifier extends StateNotifier<GameState> {
  GameMode _mode;
  GameSession? _session;
  StreamSubscription<GameState>? _sessionSub;
  StreamSubscription<void>? _disconnectSub;
  PlayerColor? _localColor;
  bool _opponentDisconnected = false;
  Move? _localPendingBattleMove;
  AiProfile? _aiProfile;
  PlayerColor? _aiColor;
  String _humanName = 'Player';

  /// Distinguishes games started within the same millisecond.
  static int _gameSeq = 0;

  /// Called after a locally resolved battle (hot-seat, single player) with
  /// the winning color and the credits the battle earned.
  void Function(PlayerColor winner, int credits)? onBattleReward;

  GameStateNotifier(super.initial, {GameMode mode = GameMode.hotSeat})
      : _mode = mode;

  GameMode get mode => _mode;
  GameSession? get session => _session;

  /// The local player's color. Null in hot-seat mode.
  PlayerColor? get localColor => _localColor;

  /// The AI opponent's profile. Null outside single player.
  AiProfile? get aiProfile => _aiProfile;

  /// The AI-controlled color. Null outside single player.
  PlayerColor? get aiColor => _aiColor;

  /// Whether the opponent has disconnected.
  bool get opponentDisconnected => _opponentDisconnected;

  /// The capture move awaiting battle resolution, regardless of mode.
  Move? get pendingBattleMove =>
      _session?.pendingBattleMove ?? _localPendingBattleMove;

  /// Stream that fires when the opponent disconnects.
  Stream<void>? get onOpponentDisconnect => _session?.onOpponentDisconnect;

  /// Attach a multiplayer session. State updates come from the session.
  void attachSession(GameSession session) {
    _sessionSub?.cancel();
    _disconnectSub?.cancel();
    _session = session;
    _mode = GameMode.multiplayer;
    _localColor = session.localColor;
    _aiProfile = null;
    _aiColor = null;
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
    if ((_mode == GameMode.multiplayer || _mode == GameMode.localWifi) &&
        _session != null) {
      return _session!.tryMove(from, to);
    }

    // Single player: the human moves only their own pieces.
    if (_mode == GameMode.singlePlayer &&
        state.board.pieceAt(from)?.color != _localColor) {
      return false;
    }

    // Hot-seat and single player: direct apply.
    final move = MoveValidator.createMove(state, from, to);
    if (move == null) return false;
    _applyLocalMove(move);
    return true;
  }

  /// Plays [move] for the AI in single player. Returns false when it is not
  /// the AI's turn or the move is illegal (a guard against AI bugs).
  bool applyAiMove(Move move) {
    if (_mode != GameMode.singlePlayer ||
        state.phase != GamePhase.playing ||
        state.currentTurn != _aiColor) {
      return false;
    }
    final legal = MoveValidator.createMove(state, move.from, move.to);
    if (legal == null) return false;
    _applyLocalMove(legal);
    return true;
  }

  /// Applies a validated move without a session. Captures enter the battle
  /// arena and wait for [resolveBattle].
  void _applyLocalMove(Move move) {
    if (move.capturedPiece != null) {
      _localPendingBattleMove = move;
      state = GameEngine.applyMove(state, move, triggerBattle: true);
      return;
    }
    state = GameEngine.applyMove(state, move);
  }

  /// Send shield activation to opponent (localWifi mode only).
  void activateShield() {
    _session?.sendShieldActivated();
  }

  /// Send local ship movement to opponent (localWifi mode only).
  void moveShip(double xFraction) {
    _session?.sendShipMoved(xFraction);
  }

  /// Called by BattleStateNotifier when the battle ends locally.
  void resolveBattle(PlayerColor winner) {
    if (_session != null) {
      _session!.resolveBattle(winner);
      return;
    }

    // Hot-seat and single player: resolve directly against the engine.
    final pending = _localPendingBattleMove;
    if (pending == null || state.phase != GamePhase.battle) return;
    final (newState, credits) =
        GameEngine.resolveBattle(state, pending, winner);
    _localPendingBattleMove = null;
    state = newState;
    onBattleReward?.call(winner, credits);
  }

  /// Attach a local WiFi session (host or guest).
  void attachLocalWifiSession(GameSession session) {
    _detachSession();
    _session = session;
    _mode = GameMode.localWifi;
    _localColor = session.localColor;
    _opponentDisconnected = false;
    state = session.state;

    _sessionSub = session.stateStream.listen((newState) {
      state = newState;
    });
    _disconnectSub = session.onOpponentDisconnect.listen((_) {
      _opponentDisconnected = true;
      state = state;
    });
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

    state = _buildDefaultGame(
      gameId: 'local-${DateTime.now().millisecondsSinceEpoch}',
      white: _localWhite,
      black: _localBlack,
    );
  }

  /// Start a game against the AI described by [profile]. The human plays
  /// [humanColor] (white moves first).
  void startSinglePlayerGame({
    required AiProfile profile,
    PlayerColor humanColor = PlayerColor.white,
    String humanName = 'Player',
  }) {
    _detachSession();
    _mode = GameMode.singlePlayer;
    _localColor = humanColor;
    _aiColor = humanColor.opposite;
    _aiProfile = profile;
    _humanName = humanName;

    final human = Player(
      userId: 'player',
      displayName: humanName,
      color: humanColor,
    );
    final ai = Player(
      userId: profile.identity,
      displayName: profile.displayName,
      color: humanColor.opposite,
    );
    state = _buildDefaultGame(
      gameId: 'single-${DateTime.now().millisecondsSinceEpoch}-${_gameSeq++}',
      white: humanColor == PlayerColor.white ? human : ai,
      black: humanColor == PlayerColor.white ? ai : human,
    );
  }

  /// Start a fresh game in the current mode: single player keeps its AI
  /// and colors, every other mode starts a hot-seat game.
  void restartCurrentMode() {
    final profile = _aiProfile;
    final humanColor = _localColor;
    if (_mode == GameMode.singlePlayer &&
        profile != null &&
        humanColor != null) {
      startSinglePlayerGame(
        profile: profile,
        humanColor: humanColor,
        humanName: _humanName,
      );
    } else {
      startNewGame();
    }
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
    _localPendingBattleMove = null;
    _aiProfile = null;
    _aiColor = null;
  }

  @override
  void dispose() {
    _detachSession();
    super.dispose();
  }
}

const _localWhite = Player(
  userId: 'local-white',
  displayName: 'White',
  color: PlayerColor.white,
);

const _localBlack = Player(
  userId: 'local-black',
  displayName: 'Black',
  color: PlayerColor.black,
);

/// A game in playing phase with both default formations placed.
GameState _buildDefaultGame({
  required String gameId,
  required Player white,
  required Player black,
}) {
  final created = GameEngine.createGame(
    gameId: gameId,
    playerWhite: white,
    playerBlack: black,
  );
  final withWhite = GameEngine.applyFormation(
    created,
    PlayerColor.white,
    GameEngine.defaultFormation(PlayerColor.white),
  );
  return GameEngine.applyFormation(
    withWhite,
    PlayerColor.black,
    GameEngine.defaultFormation(PlayerColor.black),
  );
}

/// Provider for the game state notifier.
final gameStateProvider =
    StateNotifierProvider<GameStateNotifier, GameState>((ref) {
  return GameStateNotifier(_buildDefaultGame(
    gameId: 'local-${DateTime.now().millisecondsSinceEpoch}',
    white: _localWhite,
    black: _localBlack,
  ));
});
