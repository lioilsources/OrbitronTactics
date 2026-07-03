import 'dart:async';

import '../model/battle_simulation.dart';

/// Messages exchanged over a [BattleLink] during a real-time battle.
///
/// These are intentionally separate from the turn-based `GameEvent` hierarchy:
/// battle traffic is high-frequency and short-lived, so it travels on its own
/// fast lane. The in-memory [LocalBattleLink] passes objects directly; a
/// network transport serializes them via [toJson] / [fromJson].
sealed class BattleMessage {
  const BattleMessage();

  Map<String, dynamic> toJson();

  static BattleMessage fromJson(Map<String, dynamic> json) {
    switch (json['type'] as String) {
      case 'start':
        return BattleStartMsg(seed: json['seed'] as int);
      case 'input':
        return BattleInputMsg(
          input: BattleInput.fromJson(json['input'] as Map<String, dynamic>),
        );
      case 'snapshot':
        return BattleSnapshotMsg(
          snapshot: BattleSnapshot.fromJson(
              json['snapshot'] as Map<String, dynamic>),
        );
      case 'resolved':
        return BattleResolvedMsg(
          winner: BattleRole.values.byName(json['winner'] as String),
        );
      default:
        throw ArgumentError('Unknown battle message: ${json['type']}');
    }
  }
}

/// Host → guest: open the arena with the given deterministic [seed].
class BattleStartMsg extends BattleMessage {
  final int seed;
  const BattleStartMsg({required this.seed});

  @override
  Map<String, dynamic> toJson() => {'type': 'start', 'seed': seed};
}

/// Guest → host: the guest's control input for the current frame.
class BattleInputMsg extends BattleMessage {
  final BattleInput input;
  const BattleInputMsg({required this.input});

  @override
  Map<String, dynamic> toJson() => {'type': 'input', 'input': input.toJson()};
}

/// Host → guest: an authoritative snapshot of the arena.
class BattleSnapshotMsg extends BattleMessage {
  final BattleSnapshot snapshot;
  const BattleSnapshotMsg({required this.snapshot});

  @override
  Map<String, dynamic> toJson() =>
      {'type': 'snapshot', 'snapshot': snapshot.toJson()};
}

/// Host → guest: the authoritative final result.
class BattleResolvedMsg extends BattleMessage {
  final BattleRole winner;
  const BattleResolvedMsg({required this.winner});

  @override
  Map<String, dynamic> toJson() =>
      {'type': 'resolved', 'winner': winner.name};
}

/// A bidirectional channel for [BattleMessage]s between the two players.
abstract class BattleLink {
  Stream<BattleMessage> get incoming;
  void send(BattleMessage message);
  void dispose();
}

/// In-memory [BattleLink] used for head-less tests and a single-device debug
/// mode. Mirrors the existing `LocalGameTransport.createPair()` pattern.
class LocalBattleLink implements BattleLink {
  final StreamController<BattleMessage> _incoming =
      StreamController<BattleMessage>.broadcast();
  LocalBattleLink? _peer;

  @override
  Stream<BattleMessage> get incoming => _incoming.stream;

  @override
  void send(BattleMessage message) {
    final peer = _peer;
    if (peer != null && !peer._incoming.isClosed) {
      peer._incoming.add(message);
    }
  }

  @override
  void dispose() {
    if (!_incoming.isClosed) _incoming.close();
  }

  /// Create a wired pair of links that forward messages to each other.
  static (LocalBattleLink, LocalBattleLink) createPair() {
    final a = LocalBattleLink();
    final b = LocalBattleLink();
    a._peer = b;
    b._peer = a;
    return (a, b);
  }
}
