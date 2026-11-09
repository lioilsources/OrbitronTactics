import 'package:flutter/widgets.dart';

import '../core/game_logic/models/piece.dart';
import '../core/maneuvers/maneuver.dart';
import '../features/battle/data/battle_music.dart';
import '../features/store/data/store_catalog.dart';
import 'app_localizations.dart';
import 'content_cs.dart';

export 'app_localizations.dart';

/// The language the app speaks for the device's [locales]: the first one it
/// supports, else English. Flutter's own fallback is the first supported
/// locale, which alphabetically is Czech.
Locale resolveAppLocale(
  List<Locale>? locales,
  Iterable<Locale> supported,
) {
  for (final locale in locales ?? const <Locale>[]) {
    for (final candidate in supported) {
      if (candidate.languageCode == locale.languageCode) return candidate;
    }
  }
  return const Locale('en');
}

extension L10nContext on BuildContext {
  /// The app's strings in the device's language; English where no
  /// localizations are set up, as in widget tests.
  AppLocalizations get l10n =>
      AppLocalizations.of(this) ?? lookupAppLocalizations(const Locale('en'));
}

extension ContentL10n on AppLocalizations {
  /// [english] content from a catalog, in this language.
  String content(String english) =>
      localeName == 'cs' ? contentCs[english] ?? english : english;

  String unit(PieceType type) => switch (type) {
        PieceType.pawn => unitPawn,
        PieceType.rook => unitRook,
        PieceType.knight => unitKnight,
        PieceType.bishop => unitBishop,
        PieceType.queen => unitQueen,
        PieceType.king => unitKing,
      };

  String maneuverName(Maneuver maneuver) => content(maneuver.name);

  String maneuverDescription(Maneuver maneuver) =>
      content(maneuver.description);

  String packName(ManeuverPack pack) => content(pack.name);

  String musicName(BattleMusic music) => switch (music) {
        BattleMusic.standard => musicStandard,
        BattleMusic.retro => music.displayName,
      };

  String storeTitle(StoreItem item) => switch (item.kind) {
        StoreItemKind.commander => itemCommanderTitle,
        StoreItemKind.fleetBundle => itemFleetsTitle,
        StoreItemKind.fleet => item.fleet!.displayName,
        StoreItemKind.maneuverPack => packName(item.pack!),
        StoreItemKind.music => itemMusicTitle(musicName(item.music!)),
      };

  String storeDescription(StoreItem item) => switch (item.kind) {
        StoreItemKind.commander => itemCommanderDescription,
        StoreItemKind.fleetBundle =>
          itemFleetsDescription(StoreCatalog.premiumFleets.length),
        StoreItemKind.fleet => itemFleetDescription,
        StoreItemKind.maneuverPack => content(item.pack!.description),
        StoreItemKind.music => itemMusicDescription,
      };
}
