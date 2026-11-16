// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get boardTab => 'BOARD';

  @override
  String get pieceSkinTitle => 'Board pieces';

  @override
  String get pieceSkinHint =>
      'Pick the armies drawn on the board in every game mode.';

  @override
  String get classicMarks => 'Classic marks';

  @override
  String get classicMarksHint => 'Show a small chess symbol on each figure.';

  @override
  String get pieceSkinClassic => 'Classic';

  @override
  String get pieceSkinClassicWhite => 'White';

  @override
  String get pieceSkinClassicBlack => 'Black';

  @override
  String get pieceSkinHeavenHell => 'Heaven × Hell';

  @override
  String get pieceSkinHeavenHellWhite => 'Heaven';

  @override
  String get pieceSkinHeavenHellBlack => 'Hell';

  @override
  String get pieceSkinRomeCarthage => 'Rome × Carthage';

  @override
  String get pieceSkinRomeCarthageWhite => 'Rome';

  @override
  String get pieceSkinRomeCarthageBlack => 'Carthage';

  @override
  String get pieceSkinKnightsOrcs => 'Knights × Orcs';

  @override
  String get pieceSkinKnightsOrcsWhite => 'Knights';

  @override
  String get pieceSkinKnightsOrcsBlack => 'Orcs';

  @override
  String get pieceSkinOlympusTitans => 'Olympus × Titans';

  @override
  String get pieceSkinOlympusTitansWhite => 'Olympus';

  @override
  String get pieceSkinOlympusTitansBlack => 'Titans';

  @override
  String get pieceSkinSamuraiYokai => 'Samurai × Yōkai';

  @override
  String get pieceSkinSamuraiYokaiWhite => 'Samurai';

  @override
  String get pieceSkinSamuraiYokaiBlack => 'Yōkai';

  @override
  String get pieceSkinHussitesCrusaders => 'Hussites × Crusaders';

  @override
  String get pieceSkinHussitesCrusadersWhite => 'Hussites';

  @override
  String get pieceSkinHussitesCrusadersBlack => 'Crusaders';

  @override
  String get appTitle => 'OrbitronTactics';

  @override
  String get comcenterTooltip => 'Comcenter';

  @override
  String get cancel => 'Cancel';

  @override
  String get back => 'Back';

  @override
  String get leave => 'Leave';

  @override
  String get newGame => 'New Game';

  @override
  String creditsAmount(int credits) {
    return '$credits cr';
  }

  @override
  String creditsReward(int credits) {
    return '+$credits cr';
  }

  @override
  String get defaultPlayerName => 'Player';

  @override
  String get defaultHostName => 'Host';

  @override
  String get defaultGuestName => 'Guest';

  @override
  String get defaultOpponentName => 'Opponent';

  @override
  String get lobbyYourName => 'Your name';

  @override
  String get lobbySinglePlayer => 'Single Player';

  @override
  String get lobbyCreateGame => 'Create Game';

  @override
  String get lobbyLocalGame => 'Local Game';

  @override
  String get lobbyHostWifi => 'Host WiFi';

  @override
  String get lobbyJoinWifi => 'Join WiFi';

  @override
  String get lobbyWifiHint => 'WiFi mode includes realtime battle arena';

  @override
  String get lobbyOpenGames => 'Open Games';

  @override
  String get lobbyNoOpenGames => 'No open games.\nCreate one to start!';

  @override
  String get lobbyJustNow => 'just now';

  @override
  String lobbyMinutesAgo(int minutes) {
    return '${minutes}m ago';
  }

  @override
  String get lobbyJoin => 'Join';

  @override
  String get lobbyCannotConnect => 'Cannot connect to server';

  @override
  String errorCreatingGame(String error) {
    return 'Error creating game: $error';
  }

  @override
  String errorJoiningGame(String error) {
    return 'Error joining game: $error';
  }

  @override
  String errorWifiHost(String error) {
    return 'WiFi host error: $error';
  }

  @override
  String errorWifiJoin(String error) {
    return 'WiFi join error: $error';
  }

  @override
  String get singlePlayerDifficulty => 'Difficulty';

  @override
  String get singlePlayerAiFleets => 'AI fleets';

  @override
  String get singlePlayerYourSide => 'Your side';

  @override
  String get singlePlayerYouMoveFirst => 'You move first';

  @override
  String get singlePlayerAiMovesFirst => 'The AI moves first';

  @override
  String get start => 'Start';

  @override
  String get difficultyEasy => 'Easy';

  @override
  String get difficultyMedium => 'Medium';

  @override
  String get difficultyHard => 'Hard';

  @override
  String aiPlayerName(String difficulty) {
    return 'Orbitron AI · $difficulty';
  }

  @override
  String fleetRecord(int wins, int losses) {
    return '${wins}W / ${losses}L';
  }

  @override
  String get wifiHostTitle => 'WiFi Host';

  @override
  String get wifiShareAddress => 'Share this address with your opponent:';

  @override
  String get wifiWaitingForGuest => 'Waiting for guest to connect...';

  @override
  String get wifiJoinTitle => 'Join WiFi Game';

  @override
  String get wifiEnterHostAddress => 'Enter the host\'s IP address:';

  @override
  String get connect => 'Connect';

  @override
  String get waitingTitle => 'Waiting for opponent';

  @override
  String get waitingGameId => 'Game ID:';

  @override
  String get waitingForPlayer => 'Waiting for another player to join...';

  @override
  String get leaveGameTooltip => 'Leave Game';

  @override
  String get leaveGameTitle => 'Leave Game?';

  @override
  String get leaveGameBody => 'Your opponent will be able to claim victory.';

  @override
  String get turnBadge => 'TURN';

  @override
  String get thinkingBadge => 'THINKING…';

  @override
  String get powerFieldsLabel => 'Power Fields:';

  @override
  String powerFieldsNeed(int total) {
    return '(need $total)';
  }

  @override
  String get opponentDisconnected => 'Opponent Disconnected';

  @override
  String get opponentLeftBody => 'Your opponent has left the game.';

  @override
  String get claimVictory => 'Claim Victory';

  @override
  String sideWins(String side) {
    return '$side Wins!';
  }

  @override
  String get victoryPowerFieldDomination => 'Power Field Domination!';

  @override
  String get victoryRoyalElimination => 'Royal Elimination!';

  @override
  String get victoryInfiltration => 'Pawn Infiltration!';

  @override
  String get victoryAbandonment => 'Opponent Abandoned!';

  @override
  String get battleTitle => 'BATTLE';

  @override
  String battleElapsed(String seconds) {
    return '${seconds}s';
  }

  @override
  String get soundOn => 'Sound on';

  @override
  String get soundOff => 'Sound off';

  @override
  String get yourShield => 'YOUR SHIELD';

  @override
  String sideShield(String side) {
    return '$side SHIELD';
  }

  @override
  String get battleVictory => 'VICTORY!';

  @override
  String get battleDefeated => 'DEFEATED';

  @override
  String unitSurvives(String side) {
    return '$side unit survives';
  }

  @override
  String newManeuvers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'NEW MANEUVERS',
      one: 'NEW MANEUVER',
    );
    return '$_temp0';
  }

  @override
  String get tapToContinue => 'Tap to continue';

  @override
  String get comcenterTitle => 'COMCENTER';

  @override
  String get unitsTab => 'UNITS';

  @override
  String get maneuversTab => 'MANEUVERS';

  @override
  String yourFleet(String fleet) {
    return 'Your fleet: $fleet';
  }

  @override
  String get upgradeHint => 'Upgrade your units to gain advantage in battle';

  @override
  String armedCount(int armed, int slots) {
    return 'ARMED $armed/$slots';
  }

  @override
  String battlesWon(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count battles won',
      one: '$count battle won',
    );
    return '$_temp0';
  }

  @override
  String get statHp => 'HP';

  @override
  String get statDamage => 'DMG';

  @override
  String get upgradeMax => 'MAX';

  @override
  String get upgradeMaxLevel => 'MAX LEVEL';

  @override
  String maneuverLevel(int level) {
    return 'L$level';
  }

  @override
  String maneuverStats(int energy, String seconds) {
    return '$energy energy · $seconds s';
  }

  @override
  String get maneuverMirrors => 'mirrors';

  @override
  String maneuverTrain(int price) {
    return 'TRAIN $price';
  }

  @override
  String maneuverBuy(int price) {
    return 'BUY $price';
  }

  @override
  String get maneuverArmed => 'ARMED';

  @override
  String get maneuverArm => 'ARM';

  @override
  String get maneuverPadFull => 'PAD FULL';

  @override
  String maneuverWinBattles(int won, int needed) {
    return 'Win $won/$needed battles';
  }

  @override
  String get maneuverInAcePack => 'In the Ace pack';

  @override
  String get maneuverFromStart => 'From the start';

  @override
  String get maneuverUnlockPack => 'UNLOCK PACK';

  @override
  String get tierStarter => 'START';

  @override
  String get tierBasic => 'BASIC';

  @override
  String get tierAdvanced => 'ADVANCED';

  @override
  String get tierSignature => 'SIGNATURE';

  @override
  String get tierPack => 'PACK';

  @override
  String get pieceTypePawn => 'Pawn';

  @override
  String get pieceTypeRook => 'Rook';

  @override
  String get pieceTypeKnight => 'Knight';

  @override
  String get pieceTypeBishop => 'Bishop';

  @override
  String get pieceTypeQueen => 'Queen';

  @override
  String get pieceTypeKing => 'King';

  @override
  String get fleetVanguard => 'Orbitron Vanguard';

  @override
  String get fleetSolarCrusade => 'Solar Crusade';

  @override
  String get fleetVoidHive => 'Void Hive';

  @override
  String get fleetNeonRunners => 'Neon Runners';

  @override
  String get fleetIronArmada => 'Iron Armada';

  @override
  String get fleetCrystalChoir => 'Crystal Choir';

  @override
  String get fleetRoninBlades => 'Ronin Blades';

  @override
  String get fleetAtomicAge => 'Atomic Age';

  @override
  String get fleetAbyssalTide => 'Abyssal Tide';

  @override
  String get fleetStarNomads => 'Star Nomads';

  @override
  String get maneuverSidestep => 'Sidestep';

  @override
  String get maneuverSidestepDesc =>
      'A quick step aside, matching the enemy\'s altitude.';

  @override
  String get maneuverCastle => 'Castle';

  @override
  String get maneuverCastleDesc =>
      'A long slide across the arena onto the enemy\'s altitude.';

  @override
  String get maneuverStrike => 'Strike';

  @override
  String get maneuverStrikeDesc =>
      'Climbs onto the enemy, fires twice and drops back.';

  @override
  String get maneuverSteamroller => 'Steamroller';

  @override
  String get maneuverSteamrollerDesc => 'Grinds forward, firing all the way.';

  @override
  String get maneuverRetreat => 'Retreat';

  @override
  String get maneuverRetreatDesc =>
      'Falls back to its own edge behind a shield.';

  @override
  String get maneuverRoll => 'Barrel Roll';

  @override
  String get maneuverRollDesc => 'Rolls out of the way; shots pass through.';

  @override
  String get maneuverFeint => 'Feint';

  @override
  String get maneuverFeintDesc =>
      'Leans one way, cuts back the other and fires.';

  @override
  String get maneuverChargedShot => 'Charged Shot';

  @override
  String get maneuverChargedShotDesc =>
      'Holds still, charges, and lands one heavy round.';

  @override
  String get maneuverVolley => 'Volley';

  @override
  String get maneuverVolleyDesc => 'Four rounds in a row from a standing ship.';

  @override
  String get maneuverVolleyHeavyDesc =>
      'Two heavy rounds from a standing ship.';

  @override
  String get maneuverSlalom => 'Slalom';

  @override
  String get maneuverSlalomDesc =>
      'Weaves across the enemy\'s altitude, firing throughout.';

  @override
  String get maneuverDash => 'Dash';

  @override
  String get maneuverDashDesc =>
      'Crosses the arena at the enemy\'s altitude, firing.';

  @override
  String get maneuverShadow => 'Shadow';

  @override
  String get maneuverShadowDesc =>
      'Sticks to the enemy wherever it goes, firing steadily.';

  @override
  String get maneuverOverdrive => 'Overdrive';

  @override
  String get maneuverOverdriveDesc =>
      'Keeps the helm, but the guns run hot for three seconds.';

  @override
  String get maneuverLoop => 'Loop';

  @override
  String get maneuverLoopDesc =>
      'Over the top and down; shots pass under the ship.';

  @override
  String get maneuverCorkscrew => 'Corkscrew';

  @override
  String get maneuverCorkscrewDesc =>
      'Climbs and dives through a rolling spiral.';

  @override
  String get maneuverDoubleStep => 'Double Step';

  @override
  String get maneuverDoubleStepDesc => 'Two hops forward, a burst after each.';

  @override
  String get maneuverLeap => 'Leap';

  @override
  String get maneuverLeapDesc =>
      'Jumps clear and lands a lane over, on the enemy.';

  @override
  String get maneuverSniperShot => 'Sniper Shot';

  @override
  String get maneuverSniperShotDesc =>
      'Stands still for a second, then one devastating round.';

  @override
  String get maneuverBulwark => 'Bulwark';

  @override
  String get maneuverBulwarkDesc =>
      'Shield up even on cooldown, three heavy rounds out.';

  @override
  String get maneuverRoyalWaltz => 'Royal Waltz';

  @override
  String get maneuverRoyalWaltzDesc =>
      'Sweeps the whole arena on the enemy\'s altitude.';

  @override
  String get maneuverCrown => 'Crown';

  @override
  String get maneuverCrownDesc =>
      'Holds the line behind a shield, every battery firing.';
}
