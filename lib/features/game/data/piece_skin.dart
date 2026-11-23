import 'dart:ui' show Color;

import '../../../core/game_logic/models/piece.dart';
import '../../../core/theme/board_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../battle/data/unit_art.dart' show UnitPose;

/// The world a game is played in: what stands on the board and what fights
/// in the arena. [classic] is Space — chess symbols on the board, the
/// player's fleet in the arena; every other world is an image pack with
/// twelve figures in `assets/pieces/<slug>/` and its own square colors, and
/// the same figures fight in the arena.
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
  ),
  asgardRagnarok(
    'asgard_ragnarok',
    lightSquare: Color(0xFFE6E1D3),
    darkSquare: Color(0xFF7D8DA3),
  ),
  bogatyrsKoschei(
    'bogatyrs_koschei',
    lightSquare: Color(0xFFEBE2CF),
    darkSquare: Color(0xFF80919F),
  ),
  camelotMorgana(
    'camelot_morgana',
    lightSquare: Color(0xFFE7E2D2),
    darkSquare: Color(0xFF7D8E9E),
  ),
  dwarvesDragons(
    'dwarves_dragons',
    lightSquare: Color(0xFFE9E0CE),
    darkSquare: Color(0xFF7C8BA0),
  ),
  egyptAssyria(
    'egypt_assyria',
    lightSquare: Color(0xFFEEE4CC),
    darkSquare: Color(0xFF7E93A6),
  ),
  elvesGoblins(
    'elves_goblins',
    lightSquare: Color(0xFFE5E3D0),
    darkSquare: Color(0xFF7F9A8E),
  ),
  horusSeth(
    'horus_seth',
    lightSquare: Color(0xFFEFE3C8),
    darkSquare: Color(0xFF8A97A8),
  ),
  livingUndead(
    'living_undead',
    lightSquare: Color(0xFFECE3CF),
    darkSquare: Color(0xFF7F8FA0),
  ),
  vampiresWerewolves(
    'vampires_werewolves',
    lightSquare: Color(0xFFE8E0D2),
    darkSquare: Color(0xFF7E8AA3),
  ),
  whiteBlackMagic(
    'white_black_magic',
    lightSquare: Color(0xFFECE6DA),
    darkSquare: Color(0xFF8792A8),
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

  /// The worlds everyone gets; every other one is sold in the store.
  static const free = {classic, romeCarthage, knightsOrcs, heavenHell};

  /// The skin stored as [slug], or [fallback] for none or an unknown id.
  static PieceSkin fromSlug(String? slug) =>
      values.firstWhere((skin) => skin.slug == slug, orElse: () => fallback);

  /// Whether the pieces are pictures rather than the classic symbols.
  bool get isImagePack => this != classic;

  /// Whether this is Space: symbols on the board, ships in the arena.
  bool get isSpace => this == classic;

  /// How this world's units stand in the arena.
  UnitPose get pose => isSpace ? UnitPose.topDown : UnitPose.standing;

  /// Sold in the store rather than given to everyone.
  bool get premium => !free.contains(this);

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
        asgardRagnarok => l10n.pieceSkinAsgardRagnarok,
        bogatyrsKoschei => l10n.pieceSkinBogatyrsKoschei,
        camelotMorgana => l10n.pieceSkinCamelotMorgana,
        dwarvesDragons => l10n.pieceSkinDwarvesDragons,
        egyptAssyria => l10n.pieceSkinEgyptAssyria,
        elvesGoblins => l10n.pieceSkinElvesGoblins,
        horusSeth => l10n.pieceSkinHorusSeth,
        livingUndead => l10n.pieceSkinLivingUndead,
        vampiresWerewolves => l10n.pieceSkinVampiresWerewolves,
        whiteBlackMagic => l10n.pieceSkinWhiteBlackMagic,
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
      asgardRagnarok =>
        white ? l10n.pieceSkinAsgardRagnarokWhite : l10n.pieceSkinAsgardRagnarokBlack,
      bogatyrsKoschei =>
        white ? l10n.pieceSkinBogatyrsKoscheiWhite : l10n.pieceSkinBogatyrsKoscheiBlack,
      camelotMorgana =>
        white ? l10n.pieceSkinCamelotMorganaWhite : l10n.pieceSkinCamelotMorganaBlack,
      dwarvesDragons =>
        white ? l10n.pieceSkinDwarvesDragonsWhite : l10n.pieceSkinDwarvesDragonsBlack,
      egyptAssyria =>
        white ? l10n.pieceSkinEgyptAssyriaWhite : l10n.pieceSkinEgyptAssyriaBlack,
      elvesGoblins =>
        white ? l10n.pieceSkinElvesGoblinsWhite : l10n.pieceSkinElvesGoblinsBlack,
      horusSeth =>
        white ? l10n.pieceSkinHorusSethWhite : l10n.pieceSkinHorusSethBlack,
      livingUndead =>
        white ? l10n.pieceSkinLivingUndeadWhite : l10n.pieceSkinLivingUndeadBlack,
      vampiresWerewolves =>
        white ? l10n.pieceSkinVampiresWerewolvesWhite : l10n.pieceSkinVampiresWerewolvesBlack,
      whiteBlackMagic =>
        white ? l10n.pieceSkinWhiteBlackMagicWhite : l10n.pieceSkinWhiteBlackMagicBlack,
    };
  }
}
