// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Czech (`cs`).
class AppLocalizationsCs extends AppLocalizations {
  AppLocalizationsCs([String locale = 'cs']) : super(locale);

  @override
  String get boardTab => 'DESKA';

  @override
  String get pieceSkinTitle => 'Figurky na desce';

  @override
  String get pieceSkinHint =>
      'Vyber armády, které se kreslí na desku ve všech režimech hry.';

  @override
  String get classicMarks => 'Klasické značky';

  @override
  String get classicMarksHint => 'Na každé figurce ukáže malý šachový symbol.';

  @override
  String get pieceSkinClassic => 'Klasické';

  @override
  String get pieceSkinClassicWhite => 'Bílí';

  @override
  String get pieceSkinClassicBlack => 'Černí';

  @override
  String get pieceSkinHeavenHell => 'Nebe × Peklo';

  @override
  String get pieceSkinHeavenHellWhite => 'Nebe';

  @override
  String get pieceSkinHeavenHellBlack => 'Peklo';

  @override
  String get pieceSkinRomeCarthage => 'Řím × Kartágo';

  @override
  String get pieceSkinRomeCarthageWhite => 'Řím';

  @override
  String get pieceSkinRomeCarthageBlack => 'Kartágo';

  @override
  String get pieceSkinFairytaleDevils => 'Pohádkové království × Čerti';

  @override
  String get pieceSkinFairytaleDevilsWhite => 'Království';

  @override
  String get pieceSkinFairytaleDevilsBlack => 'Čerti';

  @override
  String get pieceSkinKnightsOrcs => 'Rytíři × Orkové';

  @override
  String get pieceSkinKnightsOrcsWhite => 'Rytíři';

  @override
  String get pieceSkinKnightsOrcsBlack => 'Orkové';

  @override
  String get pieceSkinFairiesWitches => 'Víly × Čarodějnice';

  @override
  String get pieceSkinFairiesWitchesWhite => 'Víly';

  @override
  String get pieceSkinFairiesWitchesBlack => 'Čarodějnice';

  @override
  String get pieceSkinOlympusTitans => 'Olymp × Titáni';

  @override
  String get pieceSkinOlympusTitansWhite => 'Olymp';

  @override
  String get pieceSkinOlympusTitansBlack => 'Titáni';

  @override
  String get pieceSkinBeesHornets => 'Včely × Sršni';

  @override
  String get pieceSkinBeesHornetsWhite => 'Včely';

  @override
  String get pieceSkinBeesHornetsBlack => 'Sršni';

  @override
  String get pieceSkinSamuraiYokai => 'Samurajové × Yōkai';

  @override
  String get pieceSkinSamuraiYokaiWhite => 'Samurajové';

  @override
  String get pieceSkinSamuraiYokaiBlack => 'Yōkai';

  @override
  String get pieceSkinDinosIceAge => 'Dinosauři × Doba ledová';

  @override
  String get pieceSkinDinosIceAgeWhite => 'Dinosauři';

  @override
  String get pieceSkinDinosIceAgeBlack => 'Doba ledová';

  @override
  String get pieceSkinHussitesCrusaders => 'Husité × Křižáci';

  @override
  String get pieceSkinHussitesCrusadersWhite => 'Husité';

  @override
  String get pieceSkinHussitesCrusadersBlack => 'Křižáci';

  @override
  String get pieceSkinCatsDogs => 'Kočky × Psi';

  @override
  String get pieceSkinCatsDogsWhite => 'Kočky';

  @override
  String get pieceSkinCatsDogsBlack => 'Psi';

  @override
  String get pieceSkinFruitVeggies => 'Ovoce × Zelenina';

  @override
  String get pieceSkinFruitVeggiesWhite => 'Ovoce';

  @override
  String get pieceSkinFruitVeggiesBlack => 'Zelenina';

  @override
  String get appTitle => 'OrbitronTactics';

  @override
  String get comcenterTooltip => 'Velitelství';

  @override
  String get cancel => 'Zrušit';

  @override
  String get back => 'Zpět';

  @override
  String get leave => 'Odejít';

  @override
  String get newGame => 'Nová hra';

  @override
  String creditsAmount(int credits) {
    return '$credits kr';
  }

  @override
  String creditsReward(int credits) {
    return '+$credits kr';
  }

  @override
  String get defaultPlayerName => 'Hráč';

  @override
  String get defaultHostName => 'Hostitel';

  @override
  String get defaultGuestName => 'Host';

  @override
  String get defaultOpponentName => 'Soupeř';

  @override
  String get lobbyYourName => 'Tvoje jméno';

  @override
  String get lobbySinglePlayer => 'Hra proti AI';

  @override
  String get lobbyCreateGame => 'Založit hru';

  @override
  String get lobbyLocalGame => 'Hra na jednom zařízení';

  @override
  String get lobbyHostWifi => 'Hostit přes WiFi';

  @override
  String get lobbyJoinWifi => 'Připojit přes WiFi';

  @override
  String get lobbyWifiHint => 'Režim WiFi má bitevní arénu v reálném čase';

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
  String get lobbyJoin => 'Připojit';

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
  String errorWifiHost(String error) {
    return 'Chyba hostování přes WiFi: $error';
  }

  @override
  String errorWifiJoin(String error) {
    return 'Chyba připojení přes WiFi: $error';
  }

  @override
  String get singlePlayerDifficulty => 'Obtížnost';

  @override
  String get singlePlayerAiFleets => 'Flotily AI';

  @override
  String get singlePlayerYourSide => 'Tvoje strana';

  @override
  String get singlePlayerYouMoveFirst => 'Táhneš první';

  @override
  String get singlePlayerAiMovesFirst => 'AI táhne první';

  @override
  String get start => 'Začít';

  @override
  String get difficultyEasy => 'Lehká';

  @override
  String get difficultyMedium => 'Střední';

  @override
  String get difficultyHard => 'Těžká';

  @override
  String aiPlayerName(String difficulty) {
    return 'Orbitron AI · $difficulty';
  }

  @override
  String fleetRecord(int wins, int losses) {
    return '$wins V / $losses P';
  }

  @override
  String get wifiHostTitle => 'Hostování přes WiFi';

  @override
  String get wifiShareAddress => 'Pošli tuto adresu soupeři:';

  @override
  String get wifiWaitingForGuest => 'Čekám, až se host připojí…';

  @override
  String get wifiJoinTitle => 'Připojit se ke hře přes WiFi';

  @override
  String get wifiEnterHostAddress => 'Zadej IP adresu hostitele:';

  @override
  String get connect => 'Připojit';

  @override
  String get waitingTitle => 'Čekání na soupeře';

  @override
  String get waitingGameId => 'ID hry:';

  @override
  String get waitingForPlayer => 'Čekám, až se připojí další hráč…';

  @override
  String get leaveGameTooltip => 'Opustit hru';

  @override
  String get leaveGameTitle => 'Opustit hru?';

  @override
  String get leaveGameBody => 'Soupeř si bude moci připsat vítězství.';

  @override
  String get turnBadge => 'TAH';

  @override
  String get thinkingBadge => 'PŘEMÝŠLÍ…';

  @override
  String get powerFieldsLabel => 'Silová pole:';

  @override
  String powerFieldsNeed(int total) {
    return '(potřeba $total)';
  }

  @override
  String get opponentDisconnected => 'Soupeř se odpojil';

  @override
  String get opponentLeftBody => 'Soupeř opustil hru.';

  @override
  String get claimVictory => 'Připsat vítězství';

  @override
  String sideWins(String side) {
    return '$side vítězí!';
  }

  @override
  String get victoryPowerFieldDomination => 'Ovládnutí silových polí!';

  @override
  String get victoryRoyalElimination => 'Vyřazení královského páru!';

  @override
  String get victoryInfiltration => 'Průnik pěšce!';

  @override
  String get victoryAbandonment => 'Soupeř to vzdal!';

  @override
  String get battleTitle => 'BITVA';

  @override
  String battleElapsed(String seconds) {
    return '$seconds s';
  }

  @override
  String get soundOn => 'Zapnout zvuk';

  @override
  String get soundOff => 'Vypnout zvuk';

  @override
  String get yourShield => 'TVŮJ ŠTÍT';

  @override
  String sideShield(String side) {
    return 'ŠTÍT: $side';
  }

  @override
  String get battleVictory => 'VÍTĚZSTVÍ!';

  @override
  String get battleDefeated => 'PORÁŽKA';

  @override
  String unitSurvives(String side) {
    return 'Přežívá jednotka: $side';
  }

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
  String get tapToContinue => 'Klepni pro pokračování';

  @override
  String get comcenterTitle => 'VELITELSTVÍ';

  @override
  String get unitsTab => 'JEDNOTKY';

  @override
  String get maneuversTab => 'MANÉVRY';

  @override
  String yourFleet(String fleet) {
    return 'Tvoje flotila: $fleet';
  }

  @override
  String get upgradeHint => 'Vylepši jednotky a získej v bitvě výhodu';

  @override
  String armedCount(int armed, int slots) {
    return 'AKTIVNÍ $armed/$slots';
  }

  @override
  String battlesWon(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count vyhraných bitev',
      few: '$count vyhrané bitvy',
      one: '$count vyhraná bitva',
    );
    return '$_temp0';
  }

  @override
  String get statHp => 'ŽIV';

  @override
  String get statDamage => 'ÚTOK';

  @override
  String get upgradeMax => 'MAX';

  @override
  String get upgradeMaxLevel => 'MAX. ÚROVEŇ';

  @override
  String maneuverLevel(int level) {
    return 'Ú$level';
  }

  @override
  String maneuverStats(int energy, String seconds) {
    return '$energy energie · $seconds s';
  }

  @override
  String get maneuverMirrors => 'zrcadlí se';

  @override
  String maneuverTrain(int price) {
    return 'TRÉNOVAT $price';
  }

  @override
  String maneuverBuy(int price) {
    return 'KOUPIT $price';
  }

  @override
  String get maneuverArmed => 'AKTIVNÍ';

  @override
  String get maneuverArm => 'AKTIVOVAT';

  @override
  String get maneuverPadFull => 'PLNO';

  @override
  String maneuverWinBattles(int won, int needed) {
    return 'Vyhraj bitvy: $won/$needed';
  }

  @override
  String get maneuverInAcePack => 'V balíčku Eso';

  @override
  String get maneuverFromStart => 'Od začátku';

  @override
  String get maneuverUnlockPack => 'ODEMKNOUT BALÍČEK';

  @override
  String get tierStarter => 'ZÁKLAD';

  @override
  String get tierBasic => 'BĚŽNÝ';

  @override
  String get tierAdvanced => 'POKROČILÝ';

  @override
  String get tierSignature => 'PODPIS';

  @override
  String get tierPack => 'BALÍČEK';

  @override
  String get pieceTypePawn => 'Pěšec';

  @override
  String get pieceTypeRook => 'Věž';

  @override
  String get pieceTypeKnight => 'Jezdec';

  @override
  String get pieceTypeBishop => 'Střelec';

  @override
  String get pieceTypeQueen => 'Dáma';

  @override
  String get pieceTypeKing => 'Král';

  @override
  String get fleetVanguard => 'Orbitronský předvoj';

  @override
  String get fleetSolarCrusade => 'Sluneční výprava';

  @override
  String get fleetVoidHive => 'Úl prázdnoty';

  @override
  String get fleetNeonRunners => 'Neonoví běžci';

  @override
  String get fleetIronArmada => 'Železná armada';

  @override
  String get fleetCrystalChoir => 'Křišťálový chór';

  @override
  String get fleetRoninBlades => 'Čepele róninů';

  @override
  String get fleetAtomicAge => 'Atomový věk';

  @override
  String get fleetAbyssalTide => 'Příliv hlubin';

  @override
  String get fleetStarNomads => 'Hvězdní nomádi';

  @override
  String get maneuverSidestep => 'Úkrok';

  @override
  String get maneuverSidestepDesc => 'Rychlý úkrok stranou do výšky nepřítele.';

  @override
  String get maneuverCastle => 'Rošáda';

  @override
  String get maneuverCastleDesc =>
      'Dlouhý přesun napříč arénou do výšky nepřítele.';

  @override
  String get maneuverStrike => 'Úder';

  @override
  String get maneuverStrikeDesc =>
      'Vystoupá k nepříteli, dvakrát vystřelí a zase klesne.';

  @override
  String get maneuverSteamroller => 'Parní válec';

  @override
  String get maneuverSteamrollerDesc => 'Valí se vpřed a celou cestu pálí.';

  @override
  String get maneuverRetreat => 'Ústup';

  @override
  String get maneuverRetreatDesc => 'Stáhne se ke svému okraji za štít.';

  @override
  String get maneuverRoll => 'Výkrut';

  @override
  String get maneuverRollDesc => 'Odvalí se z cesty; střely jím proletí.';

  @override
  String get maneuverFeint => 'Klam';

  @override
  String get maneuverFeintDesc =>
      'Nakloní se na jednu stranu, strhne to na druhou a vystřelí.';

  @override
  String get maneuverChargedShot => 'Nabitá rána';

  @override
  String get maneuverChargedShotDesc =>
      'Zastaví se, nabije a vypálí jednu těžkou ránu.';

  @override
  String get maneuverVolley => 'Salva';

  @override
  String get maneuverVolleyDesc => 'Čtyři rány za sebou ze stojící lodi.';

  @override
  String get maneuverVolleyHeavyDesc => 'Dvě těžké rány ze stojící lodi.';

  @override
  String get maneuverSlalom => 'Slalom';

  @override
  String get maneuverSlalomDesc =>
      'Kličkuje napříč výškou nepřítele a celou dobu pálí.';

  @override
  String get maneuverDash => 'Průlet';

  @override
  String get maneuverDashDesc => 'Přeletí arénu ve výšce nepřítele a pálí.';

  @override
  String get maneuverShadow => 'Stín';

  @override
  String get maneuverShadowDesc =>
      'Drží se nepřítele, ať letí kamkoli, a vytrvale pálí.';

  @override
  String get maneuverOverdrive => 'Přetížení';

  @override
  String get maneuverOverdriveDesc =>
      'Kormidlo zůstává, ale děla tři sekundy jedou naplno.';

  @override
  String get maneuverLoop => 'Looping';

  @override
  String get maneuverLoopDesc => 'Přes hlavu a dolů; střely proletí pod lodí.';

  @override
  String get maneuverCorkscrew => 'Vývrtka';

  @override
  String get maneuverCorkscrewDesc => 'Stoupá a klesá v točité spirále.';

  @override
  String get maneuverDoubleStep => 'Dvojkrok';

  @override
  String get maneuverDoubleStepDesc => 'Dva skoky vpřed, po každém dávka.';

  @override
  String get maneuverLeap => 'Skok';

  @override
  String get maneuverLeapDesc =>
      'Vyskočí a přistane o pruh vedle, přímo na nepříteli.';

  @override
  String get maneuverSniperShot => 'Odstřel';

  @override
  String get maneuverSniperShotDesc =>
      'Vteřinu stojí, pak vypálí jednu zničující ránu.';

  @override
  String get maneuverBulwark => 'Hradba';

  @override
  String get maneuverBulwarkDesc =>
      'Štít i během dobíjení, k tomu tři těžké rány.';

  @override
  String get maneuverRoyalWaltz => 'Královský valčík';

  @override
  String get maneuverRoyalWaltzDesc =>
      'Přežene se celou arénou ve výšce nepřítele.';

  @override
  String get maneuverCrown => 'Koruna';

  @override
  String get maneuverCrownDesc =>
      'Drží linii za štítem a pálí ze všech baterií.';
}
