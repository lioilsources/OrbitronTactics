import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/ai/battle_ai.dart';
import '../../../../core/game_logic/engine/battle_engine.dart';
import '../../../../core/game_logic/models/battle_state.dart';
import '../../../../core/game_logic/models/piece.dart';
import '../../../../core/game_logic/models/upgrade_profile.dart';
import '../../../../core/maneuvers/maneuver.dart';
import '../../../../core/maneuvers/maneuver_catalog.dart';
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
  BattleAi? _ai;
  bool _aiIsAttacker = false;

  /// Minimum interval between ship-position sync messages.
  static const _shipSyncIntervalMs = 50;

  BattleStateNotifier(this._ref) : super(null);

  /// Starts ticking [initial]. With an [ai], it pilots the attacker's ship
  /// when [aiIsAttacker], otherwise the defender's.
  void startBattle({
    required BattleState initial,
    required PlayerColor? attackerColor,
    BattleAi? ai,
    bool aiIsAttacker = false,
  }) {
    _resolveSent = false;
    _attackerColor = attackerColor;
    _ai = ai;
    _aiIsAttacker = aiIsAttacker;
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
            altitude: event.altitude,
          );
        } else if (event is ManeuverStartedEvent) {
          applyOpponentManeuver(event);
        }
      });
    }
  }

  void _onTick(Timer _) {
    final current = state;
    if (current == null || current.isFinished) return;

    final now = DateTime.now();
    final deltaMs = now.difference(_lastTick!).inMilliseconds.clamp(1, 100);
    _lastTick = now;

    var next = BattleEngine.tick(current, deltaMs);

    // The AI steers straight on the engine: no transport, no throttling.
    final ai = _ai;
    if (ai != null) {
      final action = ai.decide(next, isAttacker: _aiIsAttacker, deltaMs: deltaMs);
      if (action.targetX != null || action.targetAltitude != null) {
        final me = _aiIsAttacker ? next.attacker : next.defender;
        next = BattleEngine.moveShip(
          next,
          _aiIsAttacker,
          action.targetX ?? me.xFraction,
          altitude: action.targetAltitude,
        );
      }
      if (action.activateShield) {
        next = BattleEngine.activateShield(next, _aiIsAttacker);
      }
      final maneuver = action.maneuver;
      if (maneuver != null) {
        next = BattleEngine.startManeuver(next, _aiIsAttacker, maneuver,
            mirrored: action.mirrored);
      }
    }
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

  /// Hands the local player's ship over to [maneuver]; does nothing when it
  /// is already flying one or cannot pay for it.
  void startLocalManeuver({
    required bool isAttacker,
    required Maneuver maneuver,
    int level = 1,
    bool mirrored = false,
  }) {
    final current = state;
    if (current == null) return;
    final next = BattleEngine.startManeuver(
      current,
      isAttacker,
      maneuver,
      level: level,
      mirrored: mirrored,
    );
    if (identical(next, current)) return;
    state = next;

    final run = (isAttacker ? next.attacker : next.defender).maneuver;
    if (run == null) return;
    _ref.read(gameStateProvider.notifier).startManeuver(
          maneuverId: maneuver.id,
          level: level,
          mirrored: mirrored,
          origin: run.origin,
          enemyAtStart: run.enemyAtStart,
        );
  }

  /// Flies the maneuver the opponent started on their device. It is already
  /// paid for over there, and it carries its own anchors.
  void applyOpponentManeuver(ManeuverStartedEvent event) {
    final current = state;
    if (current == null) return;
    // A maneuver this version does not know: the ship simply keeps flying.
    final maneuver = ManeuverCatalog.byId(event.maneuverId);
    if (maneuver == null) return;
    state = BattleEngine.startManeuver(
      current,
      event.color == _attackerColor,
      maneuver,
      level: event.level,
      mirrored: event.mirrored,
      force: true,
      origin: (x: event.originX, altitude: event.originAltitude),
      enemyAtStart: (x: event.enemyX, altitude: event.enemyAltitude),
    );
  }

  void applyOpponentShield({required bool isAttacker}) {
    final current = state;
    if (current == null) return;
    state = BattleEngine.activateShield(current, isAttacker);
  }

  /// Move the local player's ship across to [xFraction] and up or down by
  /// [altitudeDelta], and sync it to the opponent (throttled).
  void moveLocalShip({
    required bool isAttacker,
    required double xFraction,
    double altitudeDelta = 0,
  }) {
    final current = state;
    if (current == null || current.isFinished) return;
    final unit = isAttacker ? current.attacker : current.defender;
    state = BattleEngine.moveShip(current, isAttacker, xFraction,
        altitude: unit.altitude + altitudeDelta);

    final now = DateTime.now();
    if (_lastShipSyncAt == null ||
        now.difference(_lastShipSyncAt!).inMilliseconds >= _shipSyncIntervalMs) {
      _lastShipSyncAt = now;
      final moved = isAttacker ? state!.attacker : state!.defender;
      _ref
          .read(gameStateProvider.notifier)
          .moveShip(moved.xFraction, moved.altitude);
    }
  }

  void applyOpponentShipMove({
    required bool isAttacker,
    required double xFraction,
    required double altitude,
  }) {
    final current = state;
    if (current == null) return;
    state = BattleEngine.moveShip(current, isAttacker, xFraction,
        altitude: altitude);
  }

  void stopBattle() {
    _timer?.cancel();
    _timer = null;
    _shieldSub?.cancel();
    _shieldSub = null;
    _ai = null;
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
