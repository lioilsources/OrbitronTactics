import '../../../core/game_logic/models/piece.dart';
import '../../game/data/piece_skin.dart';
import 'fleet_skin.dart';

/// How a unit's picture is drawn in the arena.
enum UnitPose {
  /// A ship seen from straight above, bow up: it banks into its turns and
  /// grows with altitude.
  topDown,

  /// A figure standing upright, seen from the front as on the board: it
  /// keeps its size, and altitude only moves it forward.
  standing,
}

/// The picture a unit fights as, and how the arena draws it.
class UnitArt {
  const UnitArt({
    required this.asset,
    required this.pose,
    this.mirrored = false,
  });

  final String asset;
  final UnitPose pose;

  /// Drawn flipped left to right, so the black army faces the white one.
  final bool mirrored;

  @override
  bool operator ==(Object other) =>
      other is UnitArt &&
      other.asset == asset &&
      other.pose == pose &&
      other.mirrored == mirrored;

  @override
  int get hashCode => Object.hash(asset, pose, mirrored);
}

/// What [type] of [color]'s army fights as in [world]: in Space, the ship
/// of [fleet]; in a figure world, the same figure that stands on the board.
///
/// There is no plinth-less battle variant of the figures in the app: the
/// figure from the board, plinth and all, steps into the arena.
UnitArt unitArt(
  PieceSkin world,
  FleetSkin fleet,
  PieceType type,
  PlayerColor color,
) {
  if (world.isSpace) {
    return UnitArt(asset: fleet.assetFor(type, color), pose: UnitPose.topDown);
  }
  return UnitArt(
    asset: world.assetFor(type, color)!,
    pose: UnitPose.standing,
    mirrored: color == PlayerColor.black,
  );
}
