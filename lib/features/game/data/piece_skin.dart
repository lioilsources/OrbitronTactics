import 'dart:ui' show Color;

import '../../../core/game_logic/models/piece.dart';
import '../../../core/theme/board_theme.dart';
import '../../../l10n/app_localizations.dart';

/// How the board draws its pieces: the classic symbols, or an image pack
/// with twelve figures in `assets/pieces/<slug>/` and its own square colors.
///
/// An image pack's figures face slightly to the right; the black army is
/// mirrored on the board so both sides face each other.
enum PieceSkin {
  classic('classic'),
  heavenHell(
    'heaven_hell',
    lightSquare: Color(0xFFE8DCC4),
    darkSquare: Color(0xFF7C8FA8),
  ),
  romeCarthage(
    'rome_carthage',
    lightSquare: Color(0xFFE6D5B8),
    darkSquare: Color(0xFF8C7A6B),
  ),
  knightsOrcs(
    'knights_orcs',
    lightSquare: Color(0xFFE6DECB),
    darkSquare: Color(0xFF7E8F9E),
  ),
  olympusTitans(
    'olympus_titans',
    lightSquare: Color(0xFFE7E0CF),
    darkSquare: Color(0xFF7F95A3),
  ),
  samuraiYokai(
    'samurai_yokai',
    lightSquare: Color(0xFFEADCC8),
    darkSquare: Color(0xFF7C86A6),
  ),
  hussitesCrusaders(
    'hussites_crusaders',
    lightSquare: Color(0xFFE8DEC9),
    darkSquare: Color(0xFF8496A6),
  );

  const PieceSkin(this.slug, {Color? lightSquare, Color? darkSquare})
      : _lightSquare = lightSquare,
        _darkSquare = darkSquare;

  /// Stable id: the asset folder of an image pack and what settings store.
  final String slug;
  final Color? _lightSquare;
  final Color? _darkSquare;

  /// The skin drawn when none is chosen.
  static const fallback = PieceSkin.classic;

  /// The skin stored as [slug], or [fallback] for none or an unknown id.
  static PieceSkin fromSlug(String? slug) =>
      values.firstWhere((skin) => skin.slug == slug, orElse: () => fallback);

  /// Whether the pieces are pictures rather than the classic symbols.
  bool get isImagePack => this != classic;

  /// The folder of an image pack's figures and manifest.
  String get assetFolder => 'assets/pieces/$slug/';

  /// The figure of [type] in [color]'s army; null for [classic].
  String? assetFor(PieceType type, PlayerColor color) => isImagePack
      ? '$assetFolder${type.name}_${color.name}.png'
      : null;

  /// Light board squares while this skin is active.
  Color get lightSquare => _lightSquare ?? BoardTheme.lightSquare;

  /// Dark board squares while this skin is active.
  Color get darkSquare => _darkSquare ?? BoardTheme.darkSquare;

  String displayName(AppLocalizations l10n) => switch (this) {
        classic => l10n.pieceSkinClassic,
        heavenHell => l10n.pieceSkinHeavenHell,
        romeCarthage => l10n.pieceSkinRomeCarthage,
        knightsOrcs => l10n.pieceSkinKnightsOrcs,
        olympusTitans => l10n.pieceSkinOlympusTitans,
        samuraiYokai => l10n.pieceSkinSamuraiYokai,
        hussitesCrusaders => l10n.pieceSkinHussitesCrusaders,
      };

  /// The name of [color]'s army in this skin.
  String sideName(AppLocalizations l10n, PlayerColor color) {
    final white = color == PlayerColor.white;
    return switch (this) {
      classic => white ? l10n.pieceSkinClassicWhite : l10n.pieceSkinClassicBlack,
      heavenHell =>
        white ? l10n.pieceSkinHeavenHellWhite : l10n.pieceSkinHeavenHellBlack,
      romeCarthage =>
        white ? l10n.pieceSkinRomeCarthageWhite : l10n.pieceSkinRomeCarthageBlack,
      knightsOrcs =>
        white ? l10n.pieceSkinKnightsOrcsWhite : l10n.pieceSkinKnightsOrcsBlack,
      olympusTitans =>
        white ? l10n.pieceSkinOlympusTitansWhite : l10n.pieceSkinOlympusTitansBlack,
      samuraiYokai =>
        white ? l10n.pieceSkinSamuraiYokaiWhite : l10n.pieceSkinSamuraiYokaiBlack,
      hussitesCrusaders =>
        white ? l10n.pieceSkinHussitesCrusadersWhite : l10n.pieceSkinHussitesCrusadersBlack,
    };
  }
}
