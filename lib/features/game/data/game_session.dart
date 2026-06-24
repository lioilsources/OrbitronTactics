import 'dart:async';
import '../../../core/game_logic/engine/game_engine.dart';
import '../../../core/game_logic/models/formation.dart';
import '../../../core/game_logic/models/game_phase.dart';
import '../../../core/game_logic/models/game_state.dart';
import '../../../core/game_logic/models/move.dart';
import '../../../core/game_logic/models/piece.dart';
import '../../../core/game_logic/models/player.dart';
import '../../../core/game_logic/models/position.dart';
import '../../../core/game_logic/models/victory_condition.dart';
import '../../../core/game_logic/validators/move_validator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'game_event.dart';
import 'game_transport.dart';
import 'supabase_game_transport.dart';

/// Asks the UI to open the real-time battle arena for a pending capture.
///
/// Carries everything the arena needs without coupling the session to the
/// battle package: the [seed] for the deterministic asteroid field and the
/// local player's roles. The board mutation itself is applied later from the
/// authoritative [BattleResolvedEvent].
class BattleStartRequest {
  final Move move;
  final int seed;

  /// Whether the local player controls the attacking ship.
  final bool localIsAttacker;

  /// Whether the local player hosts the authoritative simulation.
  final bool localIsHost;

  const BattleStartRequest({
    required this.move,
    required this.seed,
    required this.localIsAttacker,
    required this.localIsHost,
  });
}

/// Coordinates multiplayer game flow over a [GameTransport].
///
/// Each player has their own [GameSession] instance. The session:
/// - Validates and applies local moves
/// - Sends moves to the opponent via transport
/// - Receives and applies opponent moves
/// - Manages formation phase
/// - Detects opponent disconnect via transport connection status
///
/// When [battleOnCapture] is true (local-network co-op mode), a capturing move
/// does not resolve immediately: both players enter a real-time arena and the
/// capture is decided by [BattleResolvedEvent].
class GameSession {
  final PlayerColor localColor;
  final GameTransport transport;

  /// When true, capturing moves are resolved by a real-time battle.
  final bool battleOnCapture;

  final _stateController = StreamController<GameState>.broadcast();
  final _disconnectController = StreamController<void>.broadcast();
  final _battleRequestController =
      StreamController<BattleStartRequest>.broadcast();
  StreamSubscription<GameEvent>? _eventSub;
  StreamSubscription<ConnectionStatus>? _connectionSub;

  /// The capturing move awaiting a battle outcome, if any.
  Move? _pendingBattleMove;

  GameState _state;

  GameSession({
    required this.localColor,
    required this.transport,
    required GameState initialState,
    this.battleOnCapture = false,
  }) : _state = initialState;

  /// Current game state.
  GameState get state => _state;

  /// Stream of state updates (both local and remote).
  Stream<GameState> get stateStream => _stateController.stream;

  /// Fires when the opponent disconnects.
  Stream<void> get onOpponentDisconnect => _disconnectController.stream;

  /// Fires when a capture should open the real-time battle arena.
  Stream<BattleStartRequest> get onBattleRequested =>
      _battleRequestController.stream;

  /// Whether a battle is currently being resolved (board input suspended).
  bool get battlePending => _pendingBattleMove != null;

  /// White hosts the lobby, so it also hosts the authoritative battle sim.
  bool get _localIsBattleHost => localColor == PlayerColor.white;

  /// Whether it's this player's turn.
  bool get isMyTurn =>
      _state.currentTurn == localColor &&
      !_state.isFinished &&
      !battlePending;

  /// Start listening for remote events and connection status.
  Future<void> start() async {
    await transport.connect();
    _eventSub = transport.events.listen(_handleRemoteEvent);
    _connectionSub = transport.connectionStatus.listen(_handleConnectionStatus);
  }

  void _handleConnectionStatus(ConnectionStatus status) {
    if (status == ConnectionStatus.opponentLeft && !_state.isFinished) {
      _disconnectController.add(null);
    }
  }

  /// Claim victory by abandonment (opponent disconnected).
  void claimVictory() {
    if (_state.isFinished) return;
    _state = _state.copyWith(
      phase: GamePhase.finished,
      winner: localColor,
      victoryCondition: const VictoryCondition.abandonment(),
    );
    _stateController.add(_state);
  }

  /// Submit a local move. Returns true if valid and applied.
  bool tryMove(Position from, Position to) {
    if (!isMyTurn) return false;

    // Validate piece belongs to local player
    final piece = _state.board.pieceAt(from);
    if (piece == null || piece.color != localColor) return false;

    final move = MoveValidator.createMove(_state, from, to);
    if (move == null) return false;

    // In battle mode a capture opens the arena instead of resolving now.
    if (battleOnCapture && move.capturedPiece != null) {
      final seed = _battleSeed(move);
      _pendingBattleMove = move;
      transport.send(BattleStartedEvent(move: move, seed: seed));
      _battleRequestController.add(BattleStartRequest(
        move: move,
        seed: seed,
        localIsAttacker: move.piece.color == localColor,
        localIsHost: _localIsBattleHost,
      ));
      return true;
    }

    // Apply locally
    _state = GameEngine.applyMove(_state, move);
    _stateController.add(_state);

    // Send to opponent
    transport.send(MoveMadeEvent(move: move));

    // Check game over
    if (_state.isFinished) {
      transport.send(GameOverEvent(
        winner: _state.winner!,
        reason: _state.victoryCondition.toString(),
      ));
    }

    return true;
  }

  /// Deterministic seed for a capture's arena, identical on both devices.
  int _battleSeed(Move move) =>
      Object.hash(move.from.row, move.from.col, move.to.row, move.to.col,
          _state.moveCount) &
      0x7fffffff;

  /// Called by the battle **host** once the arena produces a winner. Applies
  /// the resolved capture locally and broadcasts the authoritative result.
  void submitBattleResult(PlayerColor winner) {
    transport.send(BattleResolvedEvent(winner: winner));
    _applyBattleResult(winner);
  }

  void _applyBattleResult(PlayerColor winner) {
    final move = _pendingBattleMove;
    if (move == null) return;
    _pendingBattleMove = null;

    final attackerWon = winner == move.piece.color;
    _state = GameEngine.applyResolvedCapture(_state, move,
        attackerWon: attackerWon);
    _stateController.add(_state);

    if (_state.isFinished) {
      transport.send(GameOverEvent(
        winner: _state.winner!,
        reason: _state.victoryCondition.toString(),
      ));
    }
  }

  /// Get legal moves for a piece (only if it's our piece and our turn).
  List<Position> getLegalMoves(Position position) {
    if (!isMyTurn) return const [];
    final piece = _state.board.pieceAt(position);
    if (piece == null || piece.color != localColor) return const [];
    return MoveValidator.getLegalMoves(_state, position);
  }

  /// Lock formation for the local player.
  void lockFormation(Formation formation) {
    _state = GameEngine.applyFormation(_state, localColor, formation);
    _stateController.add(_state);

    transport.send(FormationLockedEvent(
      color: localColor,
      formation: formation,
    ));

    if (_state.phase == GamePhase.playing) {
      transport.send(const GameStartedEvent());
    }
  }

  void _handleRemoteEvent(GameEvent event) {
    switch (event) {
      case MoveMadeEvent(:final move):
        // Validate the remote move (anti-cheat for future server mode)
        if (_state.currentTurn != localColor) {
          _state = GameEngine.applyMove(_state, move);
          _stateController.add(_state);
        }
      case FormationLockedEvent(:final color, :final formation):
        if (color != localColor) {
          _state = GameEngine.applyFormation(_state, color, formation);
          _stateController.add(_state);
        }
      case GameStartedEvent():
        // State already transitioned in applyFormation
        break;
      case GameOverEvent():
        // State already reflects game over from applyMove
        break;
      case PlayerJoinedEvent():
        // Handled in lobby
        break;
      case PlayerLeftEvent():
        if (!_state.isFinished) {
          _disconnectController.add(null);
        }
      case BattleStartedEvent(:final move, :final seed):
        // The opponent initiated a capture battle — open our arena too.
        _pendingBattleMove = move;
        _battleRequestController.add(BattleStartRequest(
          move: move,
          seed: seed,
          localIsAttacker: move.piece.color == localColor,
          localIsHost: _localIsBattleHost,
        ));
      case BattleResolvedEvent(:final winner):
        // Authoritative outcome from the host — resolve the pending capture.
        _applyBattleResult(winner);
    }
  }

  /// Clean up resources.
  void dispose() {
    _eventSub?.cancel();
    _connectionSub?.cancel();
    transport.dispose();
    _stateController.close();
    _disconnectController.close();
    _battleRequestController.close();
  }

  /// Create a local hot-seat game with two paired sessions.
  /// Returns (whiteSession, blackSession).
  static (GameSession, GameSession) createLocalGame({
    String? gameId,
  }) {
    final id = gameId ?? 'local-${DateTime.now().millisecondsSinceEpoch}';
    final (transportW, transportB) = LocalGameTransport.createPair();

    final initialState = GameEngine.createGame(
      gameId: id,
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

    // Apply default formations for quick start
    var withWhite = GameEngine.applyFormation(
      initialState,
      PlayerColor.white,
      GameEngine.defaultFormation(PlayerColor.white),
    );
    var ready = GameEngine.applyFormation(
      withWhite,
      PlayerColor.black,
      GameEngine.defaultFormation(PlayerColor.black),
    );

    final whiteSession = GameSession(
      localColor: PlayerColor.white,
      transport: transportW,
      initialState: ready,
    );
    final blackSession = GameSession(
      localColor: PlayerColor.black,
      transport: transportB,
      initialState: ready,
    );

    return (whiteSession, blackSession);
  }

  /// Create an online game session via Supabase Broadcast.
  static GameSession createOnlineSession({
    required String gameId,
    required PlayerColor localColor,
    required String localPlayerName,
    required String remotePlayerName,
    required SupabaseClient client,
  }) {
    final transport = SupabaseGameTransport(
      gameId: gameId,
      localColorName: localColor.name,
      client: client,
    );

    final initialState = GameEngine.createGame(
      gameId: gameId,
      playerWhite: Player(
        userId: localColor == PlayerColor.white ? 'local' : 'remote',
        displayName: localColor == PlayerColor.white
            ? localPlayerName
            : remotePlayerName,
        color: PlayerColor.white,
      ),
      playerBlack: Player(
        userId: localColor == PlayerColor.black ? 'local' : 'remote',
        displayName: localColor == PlayerColor.black
            ? localPlayerName
            : remotePlayerName,
        color: PlayerColor.black,
      ),
    );

    // Apply default formations for now (formation selection comes in Phase 2)
    var withWhite = GameEngine.applyFormation(
      initialState,
      PlayerColor.white,
      GameEngine.defaultFormation(PlayerColor.white),
    );
    var ready = GameEngine.applyFormation(
      withWhite,
      PlayerColor.black,
      GameEngine.defaultFormation(PlayerColor.black),
    );

    return GameSession(
      localColor: localColor,
      transport: transport,
      initialState: ready,
    );
  }

  /// Create a local-network co-op session (battle on capture enabled).
  ///
  /// Transport-agnostic: production passes a local-network transport, tests
  /// pass a paired [LocalGameTransport]. White is the lobby/battle host.
  static GameSession createLocalNetworkSession({
    required String gameId,
    required PlayerColor localColor,
    required String localPlayerName,
    required String remotePlayerName,
    required GameTransport transport,
  }) {
    final initialState = GameEngine.createGame(
      gameId: gameId,
      playerWhite: Player(
        userId: localColor == PlayerColor.white ? 'local' : 'remote',
        displayName:
            localColor == PlayerColor.white ? localPlayerName : remotePlayerName,
        color: PlayerColor.white,
      ),
      playerBlack: Player(
        userId: localColor == PlayerColor.black ? 'local' : 'remote',
        displayName:
            localColor == PlayerColor.black ? localPlayerName : remotePlayerName,
        color: PlayerColor.black,
      ),
    );

    var withWhite = GameEngine.applyFormation(
      initialState,
      PlayerColor.white,
      GameEngine.defaultFormation(PlayerColor.white),
    );
    var ready = GameEngine.applyFormation(
      withWhite,
      PlayerColor.black,
      GameEngine.defaultFormation(PlayerColor.black),
    );

    return GameSession(
      localColor: localColor,
      transport: transport,
      initialState: ready,
      battleOnCapture: true,
    );
  }
}
