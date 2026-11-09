// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Czech (`cs`).
class AppLocalizationsCs extends AppLocalizations {
  AppLocalizationsCs([String locale = 'cs']) : super(locale);

  @override
  String get appTitle => 'OrbitronTactics';

  @override
  String get defaultPlayerName => 'Hráč';

  @override
  String get defaultHostName => 'Hostitel';

  @override
  String get defaultGuestName => 'Host';

  @override
  String get defaultOpponentName => 'Soupeř';

  @override
  String get cancel => 'Zrušit';

  @override
  String get leave => 'Odejít';

  @override
  String get back => 'Zpět';

  @override
  String get newGame => 'Nová hra';

  @override
  String get start => 'Začít';

  @override
  String get join => 'Připojit';

  @override
  String get connect => 'Připojit';

  @override
  String get howToPlayTooltip => 'Jak hrát';

  @override
  String get comcenterTooltip => 'Velitelství';

  @override
  String credits(int credits) {
    return '$credits kr';
  }

  @override
  String creditsReward(int credits) {
    return '+$credits kr';
  }

  @override
  String get unitPawn => 'Pěšec';

  @override
  String get unitRook => 'Věž';

  @override
  String get unitKnight => 'Jezdec';

  @override
  String get unitBishop => 'Střelec';

  @override
  String get unitQueen => 'Královna';

  @override
  String get unitKing => 'Král';

  @override
  String get lobbyYourName => 'Tvé jméno';

  @override
  String get lobbySinglePlayer => 'Hra proti AI';

  @override
  String get lobbyCreateGame => 'Založit hru';

  @override
  String get lobbyLocalGame => 'Na jednom zařízení';

  @override
  String get lobbyHostWifi => 'Hostit přes WiFi';

  @override
  String get lobbyJoinWifi => 'Připojit přes WiFi';

  @override
  String get lobbyWifiNote => 'Hra přes WiFi má i bitevní arénu v reálném čase';

  @override
  String get lobbyOpenGames => 'Otevřené hry';

  @override
  String get lobbyNoOpenGames => 'Žádné otevřené hry.\nZaložte novou!';

  @override
  String get lobbyJustNow => 'právě teď';

  @override
  String lobbyMinutesAgo(int minutes) {
    return 'před $minutes min';
  }

  @override
  String get lobbyCannotConnect => 'Nelze se připojit k serveru';

  @override
  String errorCreatingGame(String error) {
    return 'Hru se nepodařilo založit: $error';
  }

  @override
  String errorJoiningGame(String error) {
    return 'Ke hře se nepodařilo připojit: $error';
  }

  @override
  String get gameNotOpen => 'Tahle hra už není otevřená';

  @override
  String wifiHostError(String error) {
    return 'Chyba hostování přes WiFi: $error';
  }

  @override
  String wifiJoinError(String error) {
    return 'Chyba připojení přes WiFi: $error';
  }

  @override
  String get dialogDifficulty => 'Obtížnost';

  @override
  String get dialogAiFleets => 'Flotily AI';

  @override
  String get dialogYourColor => 'Tvá barva';

  @override
  String get difficultyEasy => 'Lehká';

  @override
  String get difficultyMedium => 'Střední';

  @override
  String get difficultyHard => 'Těžká';

  @override
  String get colorWhite => 'Bílá';

  @override
  String get colorBlack => 'Černá';

  @override
  String get youMoveFirst => 'Táhneš první';

  @override
  String get aiMovesFirst => 'AI táhne první';

  @override
  String fleetRecord(int wins, int losses) {
    return '${wins}V / ${losses}P';
  }

  @override
  String get wifiHostTitle => 'Hostování přes WiFi';

  @override
  String get wifiShareAddress => 'Pošli tuhle adresu soupeři:';

  @override
  String get wifiWaitingGuest => 'Čekám, až se soupeř připojí...';

  @override
  String get wifiJoinTitle => 'Připojit ke hře přes WiFi';

  @override
  String get wifiEnterIp => 'Zadej IP adresu hostitele:';

  @override
  String get waitingForOpponent => 'Čekání na soupeře';

  @override
  String get gameIdLabel => 'ID hry:';

  @override
  String get waitingForPlayer => 'Čekám, až se připojí druhý hráč...';

  @override
  String get leaveGameTooltip => 'Opustit hru';

  @override
  String get newGameTooltip => 'Nová hra';

  @override
  String get leaveGameTitle => 'Opustit hru?';

  @override
  String get leaveGameBody => 'Soupeř si bude moct připsat vítězství.';

  @override
  String get turnThinking => 'PŘEMÝŠLÍ…';

  @override
  String get turnLabel => 'NA TAHU';

  @override
  String get powerFieldsLabel => 'Silová pole: ';

  @override
  String powerFieldsNeed(int total) {
    return '  (potřeba $total)';
  }

  @override
  String get opponentDisconnected => 'Soupeř se odpojil';

  @override
  String get opponentLeftBody => 'Soupeř opustil hru.';

  @override
  String get claimVictory => 'Připsat vítězství';

  @override
  String get victoryPowerFields => 'Ovládnutí silových polí!';

  @override
  String get victoryRoyal => 'Konec královského páru!';

  @override
  String get victoryInfiltration => 'Průnik pěšce!';

  @override
  String get victoryAbandonment => 'Soupeř to vzdal!';

  @override
  String get whiteWins => 'Vyhrává bílý!';

  @override
  String get blackWins => 'Vyhrává černý!';

  @override
  String get yourShield => 'TVŮJ ŠTÍT';

  @override
  String get whiteShield => 'BÍLÝ ŠTÍT';

  @override
  String get blackShield => 'ČERNÝ ŠTÍT';

  @override
  String get battleTitle => 'BITVA';

  @override
  String get soundOn => 'Zapnout zvuk';

  @override
  String get soundOff => 'Vypnout zvuk';

  @override
  String get battleVictory => 'VÍTĚZSTVÍ!';

  @override
  String get battleDefeated => 'PORÁŽKA';

  @override
  String newManeuvers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'NOVÉ MANÉVRY',
      few: 'NOVÉ MANÉVRY',
      one: 'NOVÝ MANÉVR',
    );
    return '$_temp0';
  }

  @override
  String get tapToContinue => 'Klepni a pokračuj';

  @override
  String get controlsHint =>
      'Táhni po své polovině do stran a uhýbej, dopředu stoupáš, dozadu klesáš. Nepřítele zasáhneš jen v jeho výšce. Gestem na mřížce spustíš manévr.';

  @override
  String get comcenterTitle => 'VELITELSTVÍ';

  @override
  String get tabUnits => 'JEDNOTKY';

  @override
  String get tabManeuvers => 'MANÉVRY';

  @override
  String get tabStore => 'OBCHOD';

  @override
  String yourFleet(String name) {
    return 'Tvá flotila: $name';
  }

  @override
  String get upgradeHint => 'Vylepšuj jednotky a získej v bitvě výhodu';

  @override
  String armedCount(int armed, int slots) {
    return 'VYZBROJENO $armed/$slots';
  }

  @override
  String battlesWon(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count vyhraných bitev',
      few: '$count vyhrané bitvy',
      one: '1 vyhraná bitva',
    );
    return '$_temp0';
  }

  @override
  String get statHp => 'ŽIV';

  @override
  String get statDamage => 'POŠK';

  @override
  String get upgradeMax => 'MAX';

  @override
  String upgradeCost(int cost) {
    return '${cost}kr';
  }

  @override
  String get maxLevel => 'MAX. ÚROVEŇ';

  @override
  String maneuverStats(int energy, String seconds) {
    return '$energy energie · $seconds s';
  }

  @override
  String get maneuverMirrors => ' · zrcadlí se';

  @override
  String trainPrice(int price) {
    return 'TRÉNOVAT $price';
  }

  @override
  String get tierStarter => 'START';

  @override
  String get tierBasic => 'ZÁKLAD';

  @override
  String get tierAdvanced => 'POKROČILÝ';

  @override
  String get tierSignature => 'PODPISOVÝ';

  @override
  String get tierPack => 'BALÍČEK';

  @override
  String get maneuverArmed => 'VE VÝZBROJI';

  @override
  String get maneuverArm => 'VYZBROJIT';

  @override
  String get maneuverPadFull => 'PLNO';

  @override
  String unlockWins(int won, int needed) {
    return 'Vyhraj $won/$needed bitev';
  }

  @override
  String unlockPack(String pack) {
    return 'V balíčku $pack';
  }

  @override
  String get unlockStarter => 'Od začátku';

  @override
  String buyCredits(int price) {
    return 'KOUPIT $price';
  }

  @override
  String get getPack => 'ZÍSKAT BALÍČEK';

  @override
  String get storeIntro =>
      'Celá hra je zdarma. Tohle mění, jak vypadá, ne kdo vyhraje.';

  @override
  String get storeUnavailable => 'Obchod v téhle verzi není dostupný.';

  @override
  String get storeUnavailableShort => 'Obchod v téhle verzi není dostupný';

  @override
  String get restorePurchases => 'OBNOVIT NÁKUPY';

  @override
  String get restoring => 'OBNOVUJI…';

  @override
  String get restoreFailed => 'Obchod není dosažitelný';

  @override
  String get restoreNone => 'Na tomhle účtu nejsou žádné dřívější nákupy';

  @override
  String restoredCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Obnoveno $count nákupů',
      few: 'Obnoveny $count nákupy',
      one: 'Obnoven 1 nákup',
    );
    return '$_temp0';
  }

  @override
  String get battleMusic => 'HUDBA V BITVĚ';

  @override
  String get musicStandard => 'Standardní';

  @override
  String get listen => 'POSLECHNOUT';

  @override
  String get owned => 'VLASTNÍŠ';

  @override
  String get storeNotAvailableButton => 'OBCHOD NENÍ DOSTUPNÝ';

  @override
  String get notInStoreYet => 'ZATÍM NENÍ V OBCHODĚ';

  @override
  String buyPrice(String price) {
    return 'KOUPIT ZA $price';
  }

  @override
  String purchaseDone(String item) {
    return '$item je tvoje';
  }

  @override
  String purchasePending(String item) {
    return 'Čeká se na platbu; $item dorazí, jakmile projde';
  }

  @override
  String get itemCommanderTitle => 'Edice Velitel';

  @override
  String get itemCommanderDescription =>
      'Všechny prémiové flotily, balíčky manévrů i hudby a vše, co do obchodu přibude.';

  @override
  String get itemFleetsTitle => 'Sbírka flotil';

  @override
  String itemFleetsDescription(int count) {
    return 'Všech $count prémiových flotil a každá další, která přibude.';
  }

  @override
  String get itemFleetDescription =>
      'Vzhled lodí všech šesti jednotek, bílých i černých. Jen vzhled: létá jako každá jiná flotila.';

  @override
  String itemMusicTitle(String name) {
    return 'Hudba $name';
  }

  @override
  String get itemMusicDescription =>
      'Všechna bitevní témata znovu jako 8bitový chiptune, od pěšcovy rychlé syntezátorové linky po královský pochod.';

  @override
  String get howToPlayTitle => 'JAK HRÁT';

  @override
  String get skip => 'PŘESKOČIT';

  @override
  String get next => 'DÁL';

  @override
  String get letsPlay => 'HRAJEME';

  @override
  String get rulesWinTitle => 'Tři cesty k vítězství';

  @override
  String get rulesWin1 => 'Na konci tahu drž všech pět silových polí.';

  @override
  String get rulesWin2 => 'Vezmi soupeři krále i královnu.';

  @override
  String get rulesWin3 => 'Dostaň pěšce na soupeřovu zadní řadu.';

  @override
  String get rulesWin4 =>
      'Přijdeš-li o krále nebo královnu, zbylý se stane Posledním bojovníkem: táhne o jedno pole libovolným směrem.';

  @override
  String get rulesPiecesTitle => 'Figurky mají vlastní pravidla';

  @override
  String get rulesPieces1 =>
      'Pěšec: do stran a dozadu jen táhne, šikmo vpřed táhne i bere. Nikdy rovně vpřed.';

  @override
  String get rulesPieces2 =>
      'Věž: až 4 pole rovně. Střelec: až 3 pole šikmo, nebo odstřel přesně 3 pole rovně vpřed přes cokoli.';

  @override
  String get rulesPieces3 =>
      'Jezdec: L vpřed nebo do strany, dozadu jen nízké L, zastaví ho věž těsně před ním.';

  @override
  String get rulesPieces4 =>
      'Královna: 4 pole šikmo, 2 rovně. Král: 4 rovně, 2 šikmo.';

  @override
  String get rulesPieces5 =>
      'Klepni na figurku a uvidíš, kam může. Červený vykřičník znamená, že ji lze vzít.';

  @override
  String get rulesBattleTitle => 'Každé braní je bitva';

  @override
  String get rulesBattle1 =>
      'Obě figurky se promění v lodě a utkají se v aréně. Vítěz pole drží.';

  @override
  String get rulesBattle2 =>
      'Táhni po své polovině do stran a uhýbej, dopředu stoupáš, dozadu klesáš.';

  @override
  String get rulesBattle3 =>
      'Střela zasáhne jen loď ve stejné výšce, takže abys trefil nepřítele, musíš letět tam, kde může trefit on tebe.';

  @override
  String get rulesBattle4 =>
      'Když letí střely a nemáš kam uhnout, zvedni štít.';

  @override
  String get rulesFleetTitle => 'Manévry a tvá flotila';

  @override
  String get rulesFleet1 =>
      'Nakresli gesto na mřížce a loď sama provede manévr. Každý stojí energii, která se během bitvy dobíjí.';

  @override
  String get rulesFleet2 =>
      'Bitvy proti AI vynášejí kredity. Ve Velitelství za ně kupuješ vylepšení a nové manévry.';

  @override
  String get rulesFleet3 =>
      'Celá hra je zdarma. Obchod prodává jen nový vzhled a balíčky manévrů.';
}
