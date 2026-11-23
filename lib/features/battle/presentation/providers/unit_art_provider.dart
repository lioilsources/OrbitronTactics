import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/game_logic/models/piece.dart';
import '../../../game/presentation/providers/ai_opponent_controller.dart';
import '../../../game/presentation/providers/piece_skin_provider.dart';
import '../../data/fleet_skin.dart';
import '../../data/unit_art.dart';

/// The fleet [color]'s side flies in the Space world: in single player the
/// saved fleets (`AiOpponentController.skinFor`), in every other mode the
/// default one. The one place that decides it, so the arena and anything
/// else showing a side's ships cannot drift apart.
final sideFleetProvider =
    Provider.autoDispose.family<FleetSkin, PlayerColor>((ref, color) {
  final ai = ref.watch(aiOpponentProvider);
  return ai?.skinFor(color) ?? FleetSkin.fallback;
});

/// What [type] of [color]'s army fights as in the chosen world.
final sideUnitArtProvider = Provider.autoDispose
    .family<UnitArt, (PieceType, PlayerColor)>((ref, key) {
  final (type, color) = key;
  return unitArt(ref.watch(pieceSkinProvider).skin,
      ref.watch(sideFleetProvider(color)), type, color);
});
