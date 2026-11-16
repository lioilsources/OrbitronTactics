import '../core/ai/ai_difficulty.dart';
import '../core/game_logic/models/piece.dart';
import '../core/game_logic/models/victory_condition.dart';
import '../core/maneuvers/maneuver.dart';
import 'generated/app_localizations.dart';

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

  /// [maneuver]'s name; mirrors the variants `ManeuverCatalog` builds.
  String maneuverName(Maneuver maneuver) {
    final ship = maneuver.ship;
    return switch (maneuver.family) {
      ManeuverFamily.sidestep =>
        ship == PieceType.rook ? maneuverCastle : maneuverSidestep,
      ManeuverFamily.strike =>
        ship == PieceType.rook ? maneuverSteamroller : maneuverStrike,
      ManeuverFamily.retreat => maneuverRetreat,
      ManeuverFamily.roll => maneuverRoll,
      ManeuverFamily.feint => maneuverFeint,
      ManeuverFamily.volley =>
        ship == PieceType.bishop ? maneuverChargedShot : maneuverVolley,
      ManeuverFamily.slalom => maneuverSlalom,
      ManeuverFamily.dash => maneuverDash,
      ManeuverFamily.shadow => maneuverShadow,
      ManeuverFamily.overdrive => maneuverOverdrive,
      ManeuverFamily.loop => maneuverLoop,
      ManeuverFamily.spiral => maneuverCorkscrew,
      ManeuverFamily.signature => switch (ship) {
          PieceType.pawn => maneuverDoubleStep,
          PieceType.knight => maneuverLeap,
          PieceType.bishop => maneuverSniperShot,
          PieceType.rook => maneuverBulwark,
          PieceType.queen => maneuverRoyalWaltz,
          PieceType.king => maneuverCrown,
        },
    };
  }

  /// What [maneuver] does; mirrors the variants `ManeuverCatalog` builds.
  String maneuverDescription(Maneuver maneuver) {
    final ship = maneuver.ship;
    return switch (maneuver.family) {
      ManeuverFamily.sidestep =>
        ship == PieceType.rook ? maneuverCastleDesc : maneuverSidestepDesc,
      ManeuverFamily.strike =>
        ship == PieceType.rook ? maneuverSteamrollerDesc : maneuverStrikeDesc,
      ManeuverFamily.retreat => maneuverRetreatDesc,
      ManeuverFamily.roll => maneuverRollDesc,
      ManeuverFamily.feint => maneuverFeintDesc,
      ManeuverFamily.volley => switch (ship) {
          PieceType.bishop => maneuverChargedShotDesc,
          PieceType.rook => maneuverVolleyHeavyDesc,
          _ => maneuverVolleyDesc,
        },
      ManeuverFamily.slalom => maneuverSlalomDesc,
      ManeuverFamily.dash => maneuverDashDesc,
      ManeuverFamily.shadow => maneuverShadowDesc,
      ManeuverFamily.overdrive => maneuverOverdriveDesc,
      ManeuverFamily.loop => maneuverLoopDesc,
      ManeuverFamily.spiral => maneuverCorkscrewDesc,
      ManeuverFamily.signature => switch (ship) {
          PieceType.pawn => maneuverDoubleStepDesc,
          PieceType.knight => maneuverLeapDesc,
          PieceType.bishop => maneuverSniperShotDesc,
          PieceType.rook => maneuverBulwarkDesc,
          PieceType.queen => maneuverRoyalWaltzDesc,
          PieceType.king => maneuverCrownDesc,
        },
    };
  }
}
