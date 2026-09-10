import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/ai/ai_difficulty.dart';
import '../../../../core/ai/board_ai.dart';
import '../../../../core/game_logic/models/game_phase.dart';
import '../../../../core/game_logic/models/game_state.dart';
import '../../../../core/game_logic/models/move.dart';
import '../../../../core/game_logic/models/piece.dart';
import 'game_state_provider.dart';

/// Plays the AI side of a single-player game.
///
/// Purely reactive: every game-state change re-checks whether the AI is on
/// turn — after the player's move, after a battle (whoever attacked), after
/// a restart — and if so plays a move after the profile's think delay.
///
/// One controller serves every game played while [GameScreen] is open and
/// resets itself whenever the game id changes.
class AiOpponentController {
  AiOpponentController(this._ref, {Random? random})
      : _random = random ?? Random();

  final Ref _ref;
  final Random _random;

  /// True while the AI is deliberating its board move.
  final ValueNotifier<bool> isThinking = ValueNotifier(false);

  String? _gameId;
  BoardAi? _ai;
  Timer? _pending;
  int _generation = 0;
  bool _thinking = false;
  bool _missedChange = false;
  bool _battleScreenOpen = false;
  bool _disposed = false;

  GameStateNotifier get _game => _ref.read(gameStateProvider.notifier);

  /// Holds AI moves while the battle screen is up, so the AI never moves
  /// underneath a battle result the player has not dismissed yet.
  set battleScreenOpen(bool open) {
    _battleScreenOpen = open;
    _maybeSchedule(_ref.read(gameStateProvider));
  }

  void attach() {
    _ref.listen<GameState>(
      gameStateProvider,
      (_, next) => _onGameState(next),
      fireImmediately: true,
    );
  }

  void dispose() {
    _cancelPending();
    _disposed = true;
    isThinking.dispose();
  }

  void _onGameState(GameState state) {
    if (state.gameId != _gameId) _startGame(state);
    _maybeSchedule(state);
  }

  void _startGame(GameState state) {
    // A move planned for the previous game must never reach this one.
    _cancelPending();
    _gameId = state.gameId;
    final profile = _game.aiProfile;
    _ai = profile == null
        ? null
        : BoardAi.forProfile(profile, random: _random);
  }

  void _cancelPending() {
    _generation++;
    _pending?.cancel();
    _pending = null;
    _thinking = false;
    _missedChange = false;
    _setThinking(false);
  }

  bool _isAiTurn(GameState state) {
    final game = _game;
    return game.mode == GameMode.singlePlayer &&
        state.phase == GamePhase.playing &&
        state.currentTurn == game.aiColor;
  }

  void _maybeSchedule(GameState state) {
    if (_disposed) return;
    if (_thinking) {
      _missedChange = true;
      return;
    }
    final profile = _game.aiProfile;
    if (_battleScreenOpen || profile == null || !_isAiTurn(state)) return;

    _thinking = true;
    _setThinking(true);
    final generation = ++_generation;
    _pending = Timer(
      Duration(milliseconds: profile.thinkDelayMs),
      () => _playMove(generation, state.gameId, state.moveCount),
    );
  }

  Future<void> _playMove(int generation, String gameId, int moveCount) async {
    if (generation != _generation) return;
    _pending = null;
    try {
      final profile = _game.aiProfile;
      final color = _game.aiColor;
      final state = _ref.read(gameStateProvider);
      if (profile == null ||
          color == null ||
          !_isCurrent(state, gameId, moveCount)) {
        return;
      }

      final move = await _chooseMove(profile, state, color);
      // The game may have moved on while the AI was thinking.
      if (generation != _generation || move == null) return;
      final current = _ref.read(gameStateProvider);
      if (!_isCurrent(current, gameId, moveCount)) return;

      if (!_game.applyAiMove(move)) {
        debugPrint('AI chose an illegal move $move; playing a random one');
        final fallback = RandomAi(_random).chooseMove(current, color);
        if (fallback != null) _game.applyAiMove(fallback);
      }
    } finally {
      if (generation == _generation) {
        _thinking = false;
        _setThinking(false);
        if (_missedChange) {
          _missedChange = false;
          _maybeSchedule(_ref.read(gameStateProvider));
        }
      }
    }
  }

  bool _isCurrent(GameState state, String gameId, int moveCount) =>
      !_battleScreenOpen &&
      state.gameId == gameId &&
      state.moveCount == moveCount &&
      _isAiTurn(state);

  /// Greedy difficulties answer within a frame. A search takes far longer,
  /// so it runs on a background isolate and the UI keeps animating.
  Future<Move?> _chooseMove(
    AiProfile profile,
    GameState state,
    PlayerColor color,
  ) async {
    if (profile.searchDepth == 0) return _ai?.chooseMove(state, color);
    return compute(
      _searchMove,
      _SearchRequest(
        profile: profile,
        // The search never reads the history; don't copy it across.
        state: state.copyWith(moveHistory: const []),
        color: color,
        seed: _random.nextInt(1 << 32),
      ),
    );
  }

  void _setThinking(bool value) {
    if (!_disposed) isThinking.value = value;
  }
}

/// Everything a background search needs; all of it crosses isolates.
class _SearchRequest {
  const _SearchRequest({
    required this.profile,
    required this.state,
    required this.color,
    required this.seed,
  });

  final AiProfile profile;
  final GameState state;
  final PlayerColor color;
  final int seed;
}

Move? _searchMove(_SearchRequest request) {
  final ai = BoardAi.forProfile(request.profile, random: Random(request.seed));
  return ai.chooseMove(request.state, request.color);
}

/// The AI opponent of the current single-player game; null in other modes.
///
/// [GameScreen] watches it, so the controller lives as long as the screen.
final aiOpponentProvider =
    Provider.autoDispose<AiOpponentController?>((ref) {
  if (ref.read(gameStateProvider.notifier).mode != GameMode.singlePlayer) {
    return null;
  }
  final controller = AiOpponentController(ref);
  ref.onDispose(controller.dispose);
  controller.attach();
  return controller;
});
