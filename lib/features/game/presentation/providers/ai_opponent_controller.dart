import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/ai/ai_difficulty.dart';
import '../../../../core/ai/board_ai.dart';
import '../../../../core/ai/fleet_progression.dart';
import '../../../../core/game_logic/models/game_phase.dart';
import '../../../../core/game_logic/models/game_state.dart';
import '../../../../core/game_logic/models/move.dart';
import '../../../../core/game_logic/models/piece.dart';
import '../../../../core/game_logic/models/upgrade_profile.dart';
import '../../../battle/data/fleet_skin.dart';
import '../../../progress/presentation/providers/fleet_progress_provider.dart';
import 'game_state_provider.dart';

/// Plays the AI side of a single-player game and keeps both fleets' books.
///
/// Purely reactive: every game-state change re-checks whether the AI is on
/// turn — after the player's move, after a battle (whoever attacked), after
/// a restart — and if so plays a move after the profile's think delay.
/// Battle rewards go to the winner's fleet; at the end of a game both
/// records are updated and the AI fleet spends its credits.
///
/// One controller serves every game played while [GameScreen] is open and
/// resets itself whenever the game id changes.
class AiOpponentController {
  AiOpponentController(Ref ref, {Random? random})
      : _ref = ref,
        _game = ref.read(gameStateProvider.notifier),
        _random = random ?? Random();

  final Ref _ref;
  final GameStateNotifier _game;
  final Random _random;

  /// True while the AI is deliberating its board move.
  final ValueNotifier<bool> isThinking = ValueNotifier(false);

  String? _gameId;
  Timer? _pending;
  int _generation = 0;
  bool _thinking = false;
  bool _missedChange = false;
  bool _battleScreenOpen = false;
  bool _disposed = false;

  // Bookkeeping of the current game.
  final Map<PlayerColor, int> _creditsEarned = {};
  final Map<PieceType, int> _battlesFought = {};
  bool _gameEndRecorded = false;

  /// Holds AI moves while the battle screen is up, so the AI never moves
  /// underneath a battle result the player has not dismissed yet.
  set battleScreenOpen(bool open) {
    _battleScreenOpen = open;
    _maybeSchedule(_ref.read(gameStateProvider));
  }

  /// Credits [color] won in battles this game.
  int creditsEarned(PlayerColor color) => _creditsEarned[color] ?? 0;

  /// Upgrades of the fleet playing [color]. Read live, so a Comcenter
  /// purchase counts from the very next battle.
  UpgradeProfile upgradesFor(PlayerColor color) =>
      _ref.read(fleetProgressProvider(_fleetOf(color))).profile;

  /// Ship art of the fleet playing [color]: the skin chosen for that fleet,
  /// else the AI difficulty's own, else the default.
  FleetSkin skinFor(PlayerColor color) {
    final chosen = _ref.read(fleetProgressProvider(_fleetOf(color))).skin;
    final profile = _game.aiProfile;
    final aiDefault =
        profile != null && color == _game.aiColor ? profile.fleetSkin : null;
    return FleetSkin.fromSlug(chosen ?? aiDefault);
  }

  void attach() {
    _game.onBattleReward = _onBattleReward;
    _ref.listen<GameState>(
      gameStateProvider,
      _onGameState,
      fireImmediately: true,
    );
  }

  void dispose() {
    _cancelPending();
    _disposed = true;
    if (_game.onBattleReward == _onBattleReward) _game.onBattleReward = null;
    isThinking.dispose();
  }

  String _fleetOf(PlayerColor color) {
    final profile = _game.aiProfile;
    return profile != null && color == _game.aiColor
        ? profile.identity
        : playerFleetIdentity;
  }

  void _onGameState(GameState? previous, GameState state) {
    if (state.gameId != _gameId) {
      _startGame(state);
    } else if (previous != null && _game.mode == GameMode.singlePlayer) {
      if (state.phase == GamePhase.battle &&
          previous.phase != GamePhase.battle) {
        _countBattle();
      }
      if (state.isFinished && !_gameEndRecorded) _recordGameEnd(state);
    }
    _maybeSchedule(state);
  }

  void _startGame(GameState state) {
    // A move planned for the previous game must never reach this one.
    _cancelPending();
    _gameId = state.gameId;
    _gameEndRecorded = state.isFinished;
    _creditsEarned.clear();
    _battlesFought.clear();
  }

  void _countBattle() {
    final battle = _game.pendingBattleMove;
    final defender = battle?.capturedPiece;
    if (battle == null || defender == null) return;
    final aiPiece =
        battle.piece.color == _game.aiColor ? battle.piece : defender;
    _battlesFought.update(aiPiece.type, (count) => count + 1,
        ifAbsent: () => 1);
  }

  void _onBattleReward(PlayerColor winner, int credits) {
    if (_disposed || _game.mode != GameMode.singlePlayer) return;
    _creditsEarned.update(winner, (sum) => sum + credits,
        ifAbsent: () => credits);
    _ref
        .read(fleetProgressProvider(_fleetOf(winner)).notifier)
        .addCredits(credits);
  }

  void _recordGameEnd(GameState state) {
    _gameEndRecorded = true;
    final profile = _game.aiProfile;
    final aiColor = _game.aiColor;
    if (profile == null || aiColor == null) return;

    final aiWon = state.winner == aiColor;
    _ref
        .read(fleetProgressProvider(playerFleetIdentity).notifier)
        .recordGame(won: !aiWon);
    final aiFleet = _ref.read(fleetProgressProvider(profile.identity).notifier)
      ..recordGame(won: aiWon);
    aiFleet.replace(FleetProgression.spend(
      _ref.read(fleetProgressProvider(profile.identity)),
      _ref.read(fleetProgressProvider(playerFleetIdentity)),
      profile,
      battlesFoughtByType: _battlesFought,
      random: _random,
      lostRoyals: {
        for (final royal in [PieceType.king, PieceType.queen])
          if (state.board.findPieces(type: royal, color: aiColor).isEmpty)
            royal,
      },
    ));
  }

  void _cancelPending() {
    _generation++;
    _pending?.cancel();
    _pending = null;
    _thinking = false;
    _missedChange = false;
    _setThinking(false);
  }

  bool _isAiTurn(GameState state) =>
      _game.mode == GameMode.singlePlayer &&
      state.phase == GamePhase.playing &&
      state.currentTurn == _game.aiColor;

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
    final ownUpgrades = upgradesFor(color);
    final oppUpgrades = upgradesFor(color.opposite);
    if (profile.searchDepth == 0) {
      return BoardAi.forProfile(
        profile,
        random: _random,
        ownUpgrades: ownUpgrades,
        oppUpgrades: oppUpgrades,
      ).chooseMove(state, color);
    }
    return compute(
      _searchMove,
      _SearchRequest(
        profile: profile,
        // The search never reads the history; don't copy it across.
        state: state.copyWith(moveHistory: const []),
        color: color,
        seed: _random.nextInt(1 << 32),
        ownUpgrades: ownUpgrades,
        oppUpgrades: oppUpgrades,
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
    required this.ownUpgrades,
    required this.oppUpgrades,
  });

  final AiProfile profile;
  final GameState state;
  final PlayerColor color;
  final int seed;
  final UpgradeProfile ownUpgrades;
  final UpgradeProfile oppUpgrades;
}

Move? _searchMove(_SearchRequest request) {
  final ai = BoardAi.forProfile(
    request.profile,
    random: Random(request.seed),
    ownUpgrades: request.ownUpgrades,
    oppUpgrades: request.oppUpgrades,
  );
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
