import 'dart:ui' show Color;

import '../../../core/game_logic/models/piece.dart';
import '../../../core/theme/board_theme.dart';
import '../../../l10n/generated/app_localizations.dart';

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
  fairytaleDevils(
    'fairytale_devils',
    lightSquare: Color(0xFFF2E6D0),
    darkSquare: Color(0xFF9DB4C0),
  ),
  knightsOrcs(
    'knights_orcs',
    lightSquare: Color(0xFFE6DECB),
    darkSquare: Color(0xFF7E8F9E),
  ),
  fairiesWitches(
    'fairies_witches',
    lightSquare: Color(0xFFF3E3EA),
    darkSquare: Color(0xFFA9C7B8),
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
        fairytaleDevils => l10n.pieceSkinFairytaleDevils,
        romeCarthage => l10n.pieceSkinRomeCarthage,
        knightsOrcs => l10n.pieceSkinKnightsOrcs,
        fairiesWitches => l10n.pieceSkinFairiesWitches,
      };

  /// The name of [color]'s army in this skin.
  String sideName(AppLocalizations l10n, PlayerColor color) {
    final white = color == PlayerColor.white;
    return switch (this) {
      classic => white ? l10n.pieceSkinClassicWhite : l10n.pieceSkinClassicBlack,
      heavenHell =>
        white ? l10n.pieceSkinHeavenHellWhite : l10n.pieceSkinHeavenHellBlack,
      fairytaleDevils =>
        white ? l10n.pieceSkinFairytaleDevilsWhite : l10n.pieceSkinFairytaleDevilsBlack,
      romeCarthage =>
        white ? l10n.pieceSkinRomeCarthageWhite : l10n.pieceSkinRomeCarthageBlack,
      knightsOrcs =>
        white ? l10n.pieceSkinKnightsOrcsWhite : l10n.pieceSkinKnightsOrcsBlack,
      fairiesWitches =>
        white ? l10n.pieceSkinFairiesWitchesWhite : l10n.pieceSkinFairiesWitchesBlack,
    };
  }
}
