import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/game_logic/engine/battle_engine.dart';
import '../../../../core/game_logic/models/battle_state.dart';
import '../../../../core/game_logic/models/piece.dart';
import '../../../../core/game_logic/models/upgrade_profile.dart';
import '../../../game/data/game_event.dart';
import '../../../game/presentation/providers/game_state_provider.dart';

class BattleStateNotifier extends StateNotifier<BattleState?> {
  final Ref _ref;
  Timer? _timer;
  DateTime? _lastTick;
  bool _resolveSent = false;
  PlayerColor? _attackerColor;
  StreamSubscription<GameEvent>? _shieldSub;

  BattleStateNotifier(this._ref) : super(null);

  void startBattle({
    required BattleState initial,
    required PlayerColor? attackerColor,
  }) {
    _resolveSent = false;
    _attackerColor = attackerColor;
    state = initial;
    _lastTick = DateTime.now();
    _timer?.cancel();
    _shieldSub?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 16), _onTick);

    // Subscribe to opponent shield activations over the transport
    final session = _ref.read(gameStateProvider.notifier).session;
    if (session != null) {
      _shieldSub = session.transport.events.listen((event) {
        if (event is ShieldActivatedEvent) {
          applyOpponentShield(isAttacker: event.color == _attackerColor);
        }
      });
    }
  }

  void _onTick(Timer _) {
    final current = state;
    if (current == null || current.isFinished) return;

    final now = DateTime.now();
    final deltaMs = now.difference(_lastTick!).inMilliseconds;
    _lastTick = now;

    final next = BattleEngine.tick(current, deltaMs.clamp(1, 100));
    state = next;

    if (next.isFinished && !_resolveSent) {
      _resolveSent = true;
      _timer?.cancel();
      _timer = null;
      final winner = next.winner!;
      _ref.read(gameStateProvider.notifier).resolveBattle(winner);
    }
  }

  void activateLocalShield({
    required bool isAttacker,
  }) {
    final current = state;
    if (current == null) return;
    state = BattleEngine.activateShield(current, isAttacker);
    _ref.read(gameStateProvider.notifier).activateShield();
  }

  void applyOpponentShield({required bool isAttacker}) {
    final current = state;
    if (current == null) return;
    state = BattleEngine.activateShield(current, !isAttacker);
  }

  void stopBattle() {
    _timer?.cancel();
    _timer = null;
    _shieldSub?.cancel();
    _shieldSub = null;
    state = null;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _shieldSub?.cancel();
    super.dispose();
  }
}

final battleStateProvider =
    StateNotifierProvider<BattleStateNotifier, BattleState?>(
  (ref) => BattleStateNotifier(ref),
);

/// Provider for the upgrade profile of each player (in-memory for now).
final upgradeProfileProvider =
    StateProvider.family<UpgradeProfile, PlayerColor>(
  (ref, _) => UpgradeProfile.empty(),
);

/// Provider for credits earned during the session.
final playerCreditsProvider =
    StateProvider.family<int, PlayerColor>((ref, _) => 0);
