import 'dart:async';

import '../model/battle_simulation.dart';
import 'battle_link.dart';

/// Drives a single real-time battle over a [BattleLink] using a
/// host-authoritative model.
///
/// - The **host** owns the authoritative [BattleSimulation]. Each frame it
///   steps the sim using its own input and the latest input received from the
///   guest, then periodically broadcasts a [BattleSnapshot]. When the sim ends
///   it broadcasts the result.
/// - The **guest** runs no simulation. Each frame it sends its input and
///   renders the most recent snapshot it received.
///
/// The controller is time-agnostic: call [tick] once per rendered frame (the
/// Flame layer does this in `update`). Tests can call it directly, which keeps
/// the netcode deterministic and head-less-testable.
class BattleController {
  final BattleLink link;
  final bool isHost;

  /// Which role the *local* player controls in this battle.
  final BattleRole localRole;

  final BattleConfig config;
  final int seed;
  final int snapshotInterval;

  BattleSimulation? _sim;
  BattleSnapshot? _latest;
  BattleInput _localInput = BattleInput.idle;
  BattleInput _remoteInput = BattleInput.idle;
  int _sinceSnapshot = 0;
  BattleRole? _winner;

  final StreamController<BattleRole> _resolved =
      StreamController<BattleRole>.broadcast();
  StreamSubscription<BattleMessage>? _sub;

  BattleController.host({
    required this.link,
    required this.localRole,
    required this.seed,
    this.config = const BattleConfig(),
    this.snapshotInterval = 2,
  }) : isHost = true {
    _sim = BattleSimulation(seed: seed, config: config);
    _latest = _sim!.snapshot();
    _listen();
  }

  BattleController.guest({
    required this.link,
    required this.localRole,
    required this.seed,
    this.config = const BattleConfig(),
  })  : isHost = false,
        snapshotInterval = 0 {
    _listen();
  }

  /// The most recent arena snapshot to render (null until the first one).
  BattleSnapshot? get latestSnapshot => _latest;

  /// The winning role once the battle is over, otherwise null.
  BattleRole? get winner => _winner;

  bool get finished => _winner != null;

  /// Fires once with the authoritative winning role.
  Stream<BattleRole> get onResolved => _resolved.stream;

  /// Update the local player's control input for the next [tick].
  set localInput(BattleInput input) => _localInput = input;

  void _listen() {
    _sub = link.incoming.listen((msg) {
      switch (msg) {
        case BattleInputMsg(:final input):
          // Only the host consumes remote input (the guest's controls).
          _remoteInput = input;
        case BattleSnapshotMsg(:final snapshot):
          // Only the guest consumes snapshots. A finished snapshot also tells
          // the guest the outcome, so the arena can close without relying on a
          // separate resolved message (which some links do not carry).
          if (!isHost) {
            _latest = snapshot;
            if (snapshot.finished && snapshot.winner != null) {
              _resolve(snapshot.winner!);
            }
          }
        case BattleResolvedMsg(:final winner):
          _resolve(winner);
        case BattleStartMsg():
          break;
      }
    });
  }

  /// Advance one frame. Safe to call after the battle has finished (no-op).
  void tick() {
    if (_winner != null) return;

    if (isHost) {
      final sim = _sim!;
      final attackerInput =
          localRole == BattleRole.attacker ? _localInput : _remoteInput;
      final defenderInput =
          localRole == BattleRole.defender ? _localInput : _remoteInput;

      sim.step(attackerInput, defenderInput);
      _latest = sim.snapshot();

      if (++_sinceSnapshot >= snapshotInterval || sim.finished) {
        _sinceSnapshot = 0;
        link.send(BattleSnapshotMsg(snapshot: _latest!));
      }

      if (sim.finished) {
        final w = sim.winner!;
        link.send(BattleResolvedMsg(winner: w));
        _resolve(w);
      }
    } else {
      // Guest: report input; rendering uses the latest received snapshot.
      link.send(BattleInputMsg(input: _localInput));
    }
  }

  void _resolve(BattleRole w) {
    if (_winner != null) return;
    _winner = w;
    _resolved.add(w);
  }

  void dispose() {
    _sub?.cancel();
    if (!_resolved.isClosed) _resolved.close();
  }
}
