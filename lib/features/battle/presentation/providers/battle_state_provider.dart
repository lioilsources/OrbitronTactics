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
  DateTime? _lastShipSyncAt;

  /// Minimum interval between ship-position sync messages.
  static const _shipSyncIntervalMs = 50;

  BattleStateNotifier(this._ref) : super(null);

  void startBattle({
    required BattleState initial,
    required PlayerColor? attackerColor,
  }) {
    _resolveSent = false;
    _attackerColor = attackerColor;
    _lastShipSyncAt = null;
    state = initial;
    _lastTick = DateTime.now();
    _timer?.cancel();
    _shieldSub?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 16), _onTick);

    // Subscribe to opponent battle actions over the transport
    final session = _ref.read(gameStateProvider.notifier).session;
    if (session != null) {
      _shieldSub = session.transport.events.listen((event) {
        if (event is ShieldActivatedEvent) {
          applyOpponentShield(isAttacker: event.color == _attackerColor);
        } else if (event is ShipMovedEvent) {
          applyOpponentShipMove(
            isAttacker: event.color == _attackerColor,
            xFraction: event.xFraction,
          );
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
    state = BattleEngine.activateShield(current, isAttacker);
  }

  /// Move the local player's ship and sync it to the opponent (throttled).
  void moveLocalShip({required bool isAttacker, required double xFraction}) {
    final current = state;
    if (current == null || current.isFinished) return;
    state = BattleEngine.moveShip(current, isAttacker, xFraction);

    final now = DateTime.now();
    if (_lastShipSyncAt == null ||
        now.difference(_lastShipSyncAt!).inMilliseconds >= _shipSyncIntervalMs) {
      _lastShipSyncAt = now;
      final moved = isAttacker ? state!.attacker : state!.defender;
      _ref.read(gameStateProvider.notifier).moveShip(moved.xFraction);
    }
  }

  void applyOpponentShipMove({
    required bool isAttacker,
    required double xFraction,
  }) {
    final current = state;
    if (current == null) return;
    state = BattleEngine.moveShip(current, isAttacker, xFraction);
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
