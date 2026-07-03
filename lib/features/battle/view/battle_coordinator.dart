import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/game_logic/models/piece.dart';
import '../../comcenter/presentation/providers/upgrade_providers.dart';
import '../../game/data/game_session.dart';
import '../../game/presentation/providers/game_state_provider.dart';
import '../model/battle_simulation.dart';
import '../net/battle_controller.dart';
import '../net/transport_battle_link.dart';
import 'battle_screen.dart';

/// Wraps the game screen and opens the real-time arena whenever the active
/// session reports a capture battle ([GameSession.onBattleRequested]).
///
/// Builds a host or guest [BattleController] over a [TransportBattleLink] (so
/// the arena rides the match's existing transport), shows [BattleScreen], and
/// — on the host — reports the winner back via
/// [GameSession.submitBattleResult], which mutates both boards.
class BattleCoordinator extends ConsumerStatefulWidget {
  final Widget child;

  const BattleCoordinator({super.key, required this.child});

  @override
  ConsumerState<BattleCoordinator> createState() => _BattleCoordinatorState();
}

class _BattleCoordinatorState extends ConsumerState<BattleCoordinator> {
  StreamSubscription<BattleStartRequest>? _sub;
  StreamSubscription<int>? _rewardSub;
  bool _inArena = false;

  @override
  void initState() {
    super.initState();
    // The session is attached before this screen is shown.
    final notifier = ref.read(gameStateProvider.notifier);
    _sub = notifier.onBattleRequested?.listen(_openArena);
    // Won battles pay out credits spendable in the ComCenter.
    _rewardSub = notifier.session?.onBattleReward.listen((credits) {
      ref.read(playerCreditsProvider.notifier).state += credits;
      persistUpgrades(ref);
    });
  }

  Future<void> _openArena(BattleStartRequest req) async {
    if (_inArena || !mounted) return;
    _inArena = true;

    final session = ref.read(gameStateProvider.notifier).session;
    if (session == null) {
      _inArena = false;
      return;
    }

    final localRole =
        req.localIsAttacker ? BattleRole.attacker : BattleRole.defender;
    final link = TransportBattleLink(session.transport);
    final controller = req.localIsHost
        ? BattleController.host(
            link: link,
            localRole: localRole,
            seed: req.seed,
            attackerSpec: req.attackerSpec,
            defenderSpec: req.defenderSpec,
          )
        : BattleController.guest(
            link: link, localRole: localRole, seed: req.seed);

    await Navigator.of(context).push(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => BattleScreen(
        controller: controller,
        localRole: localRole,
        onResolved: (winnerRole) {
          // Only the host owns the authoritative outcome.
          if (!req.localIsHost) return;
          final attackerColor = req.move.piece.color;
          final winnerColor = winnerRole == BattleRole.attacker
              ? attackerColor
              : attackerColor.opposite;
          session.submitBattleResult(winnerColor);
        },
      ),
    ));

    controller.dispose();
    link.dispose();
    _inArena = false;
  }

  @override
  void dispose() {
    _sub?.cancel();
    _rewardSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
