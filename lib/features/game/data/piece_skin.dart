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
  ),
  olympusTitans(
    'olympus_titans',
    lightSquare: Color(0xFFE7E0CF),
    darkSquare: Color(0xFF7F95A3),
  ),
  beesHornets(
    'bees_hornets',
    lightSquare: Color(0xFFF2E4C4),
    darkSquare: Color(0xFF8FB7B3),
  ),
  samuraiYokai(
    'samurai_yokai',
    lightSquare: Color(0xFFEADCC8),
    darkSquare: Color(0xFF7C86A6),
  ),
  dinosIceAge(
    'dinos_iceage',
    lightSquare: Color(0xFFE9E1C8),
    darkSquare: Color(0xFF8EA7B5),
  ),
  hussitesCrusaders(
    'hussites_crusaders',
    lightSquare: Color(0xFFE8DEC9),
    darkSquare: Color(0xFF8496A6),
  ),
  catsDogs(
    'cats_dogs',
    lightSquare: Color(0xFFEDE3F0),
    darkSquare: Color(0xFFA3BFD0),
  ),
  fruitVeggies(
    'fruit_veggies',
    lightSquare: Color(0xFFF4E7CF),
    darkSquare: Color(0xFFA5B88E),
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
        olympusTitans => l10n.pieceSkinOlympusTitans,
        beesHornets => l10n.pieceSkinBeesHornets,
        samuraiYokai => l10n.pieceSkinSamuraiYokai,
        dinosIceAge => l10n.pieceSkinDinosIceAge,
        hussitesCrusaders => l10n.pieceSkinHussitesCrusaders,
        catsDogs => l10n.pieceSkinCatsDogs,
        fruitVeggies => l10n.pieceSkinFruitVeggies,
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
      olympusTitans =>
        white ? l10n.pieceSkinOlympusTitansWhite : l10n.pieceSkinOlympusTitansBlack,
      beesHornets =>
        white ? l10n.pieceSkinBeesHornetsWhite : l10n.pieceSkinBeesHornetsBlack,
      samuraiYokai =>
        white ? l10n.pieceSkinSamuraiYokaiWhite : l10n.pieceSkinSamuraiYokaiBlack,
      dinosIceAge =>
        white ? l10n.pieceSkinDinosIceAgeWhite : l10n.pieceSkinDinosIceAgeBlack,
      hussitesCrusaders =>
        white ? l10n.pieceSkinHussitesCrusadersWhite : l10n.pieceSkinHussitesCrusadersBlack,
      catsDogs =>
        white ? l10n.pieceSkinCatsDogsWhite : l10n.pieceSkinCatsDogsBlack,
      fruitVeggies =>
        white ? l10n.pieceSkinFruitVeggiesWhite : l10n.pieceSkinFruitVeggiesBlack,
    };
  }
}
