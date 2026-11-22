import '../core/ai/ai_difficulty.dart';
import '../core/game_logic/models/piece.dart';
import '../core/game_logic/models/victory_condition.dart';
import '../core/maneuvers/maneuver.dart';
import 'app_localizations.dart';

/// Display names for the pure-Dart game model, which keeps ids and enums
/// and stays free of Flutter.
extension GameL10n on AppLocalizations {
  String pieceTypeName(PieceType type) => switch (type) {
        PieceType.pawn => pieceTypePawn,
        PieceType.rook => pieceTypeRook,
        PieceType.knight => pieceTypeKnight,
        PieceType.bishop => pieceTypeBishop,
        PieceType.queen => pieceTypeQueen,
        PieceType.king => pieceTypeKing,
      };

  String difficultyName(AiDifficulty difficulty) => switch (difficulty) {
        AiDifficulty.easy => difficultyEasy,
        AiDifficulty.medium => difficultyMedium,
        AiDifficulty.hard => difficultyHard,
      };

  /// The AI player's name for the fleet stored as [identity], or null when
  /// [identity] is no AI fleet.
  String? aiNameForIdentity(String identity) {
    for (final difficulty in AiDifficulty.values) {
      if (AiProfile.of(difficulty).identity == identity) {
        return aiPlayerName(difficultyName(difficulty));
      }
    }
    return null;
  }

  String victoryText(VictoryCondition condition) => condition.when(
        powerFieldDomination: () => victoryPowerFieldDomination,
        royalElimination: () => victoryRoyalElimination,
        infiltration: (_) => victoryInfiltration,
        abandonment: () => victoryAbandonment,
      );

  String maneuverTierName(ManeuverTier tier) => switch (tier) {
        ManeuverTier.starter => tierStarter,
        ManeuverTier.basic => tierBasic,
        ManeuverTier.advanced => tierAdvanced,
        ManeuverTier.signature => tierSignature,
        ManeuverTier.pack => tierPack,
      };
}
