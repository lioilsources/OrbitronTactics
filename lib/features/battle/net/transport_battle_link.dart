import 'dart:async';

import '../../game/data/game_event.dart';
import '../../game/data/game_transport.dart';
import 'battle_link.dart';

/// A [BattleLink] that rides on an existing [GameTransport], so the real-time
/// arena works over whatever connection the match already uses (in tests a
/// paired [LocalGameTransport]; in production the local-network transport).
///
/// Only the high-frequency input/snapshot traffic flows through here. The
/// battle start and the authoritative result travel as `BattleStartedEvent` /
/// `BattleResolvedEvent` handled by `GameSession` at the board level, so they
/// are intentionally not carried by this link.
class TransportBattleLink implements BattleLink {
  final GameTransport transport;
  final StreamController<BattleMessage> _incoming =
      StreamController<BattleMessage>.broadcast();
  StreamSubscription<GameEvent>? _sub;

  TransportBattleLink(this.transport) {
    _sub = transport.events.listen((event) {
      switch (event) {
        case BattleInputEvent(:final input):
          _incoming.add(BattleInputMsg(input: input));
        case BattleSnapshotEvent(:final snapshot):
          _incoming.add(BattleSnapshotMsg(snapshot: snapshot));
        default:
          break;
      }
    });
  }

  @override
  Stream<BattleMessage> get incoming => _incoming.stream;

  @override
  void send(BattleMessage message) {
    switch (message) {
      case BattleInputMsg(:final input):
        transport.send(BattleInputEvent(input: input));
      case BattleSnapshotMsg(:final snapshot):
        transport.send(BattleSnapshotEvent(snapshot: snapshot));
      case BattleStartMsg():
      case BattleResolvedMsg():
        // Start/result are coordinated by GameSession, not the link.
        break;
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    if (!_incoming.isClosed) _incoming.close();
    // The transport is shared with GameSession; do not dispose it here.
  }
}
