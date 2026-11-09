// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'OrbitronTactics';

  @override
  String get defaultPlayerName => 'Player';

  @override
  String get defaultHostName => 'Host';

  @override
  String get defaultGuestName => 'Guest';

  @override
  String get defaultOpponentName => 'Opponent';

  @override
  String get cancel => 'Cancel';

  @override
  String get leave => 'Leave';

  @override
  String get back => 'Back';

  @override
  String get newGame => 'New Game';

  @override
  String get start => 'Start';

  @override
  String get join => 'Join';

  @override
  String get connect => 'Connect';

  @override
  String get howToPlayTooltip => 'How to play';

  @override
  String get comcenterTooltip => 'Comcenter';

  @override
  String credits(int credits) {
    return '$credits cr';
  }

  @override
  String creditsReward(int credits) {
    return '+$credits cr';
  }

  @override
  String get unitPawn => 'Pawn';

  @override
  String get unitRook => 'Rook';

  @override
  String get unitKnight => 'Knight';

  @override
  String get unitBishop => 'Bishop';

  @override
  String get unitQueen => 'Queen';

  @override
  String get unitKing => 'King';

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
  String get lobbyWifiNote => 'WiFi mode includes realtime battle arena';

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
  String get gameNotOpen => 'That game is no longer open';

  @override
  String wifiHostError(String error) {
    return 'WiFi host error: $error';
  }

  @override
  String wifiJoinError(String error) {
    return 'WiFi join error: $error';
  }

  @override
  String get dialogDifficulty => 'Difficulty';

  @override
  String get dialogAiFleets => 'AI fleets';

  @override
  String get dialogYourColor => 'Your color';

  @override
  String get difficultyEasy => 'Easy';

  @override
  String get difficultyMedium => 'Medium';

  @override
  String get difficultyHard => 'Hard';

  @override
  String get colorWhite => 'White';

  @override
  String get colorBlack => 'Black';

  @override
  String get youMoveFirst => 'You move first';

  @override
  String get aiMovesFirst => 'The AI moves first';

  @override
  String fleetRecord(int wins, int losses) {
    return '${wins}W / ${losses}L';
  }

  @override
  String get wifiHostTitle => 'WiFi Host';

  @override
  String get wifiShareAddress => 'Share this address with your opponent:';

  @override
  String get wifiWaitingGuest => 'Waiting for guest to connect...';

  @override
  String get wifiJoinTitle => 'Join WiFi Game';

  @override
  String get wifiEnterIp => 'Enter the host\'s IP address:';

  @override
  String get waitingForOpponent => 'Waiting for opponent';

  @override
  String get gameIdLabel => 'Game ID:';

  @override
  String get waitingForPlayer => 'Waiting for another player to join...';

  @override
  String get leaveGameTooltip => 'Leave Game';

  @override
  String get newGameTooltip => 'New Game';

  @override
  String get leaveGameTitle => 'Leave Game?';

  @override
  String get leaveGameBody => 'Your opponent will be able to claim victory.';

  @override
  String get turnThinking => 'THINKING…';

  @override
  String get turnLabel => 'TURN';

  @override
  String get powerFieldsLabel => 'Power Fields: ';

  @override
  String powerFieldsNeed(int total) {
    return '  (need $total)';
  }

  @override
  String get opponentDisconnected => 'Opponent Disconnected';

  @override
  String get opponentLeftBody => 'Your opponent has left the game.';

  @override
  String get claimVictory => 'Claim Victory';

  @override
  String get victoryPowerFields => 'Power Field Domination!';

  @override
  String get victoryRoyal => 'Royal Elimination!';

  @override
  String get victoryInfiltration => 'Pawn Infiltration!';

  @override
  String get victoryAbandonment => 'Opponent Abandoned!';

  @override
  String get whiteWins => 'White Wins!';

  @override
  String get blackWins => 'Black Wins!';

  @override
  String get yourShield => 'YOUR SHIELD';

  @override
  String get whiteShield => 'WHITE SHIELD';

  @override
  String get blackShield => 'BLACK SHIELD';

  @override
  String get battleTitle => 'BATTLE';

  @override
  String get soundOn => 'Sound on';

  @override
  String get soundOff => 'Sound off';

  @override
  String get battleVictory => 'VICTORY!';

  @override
  String get battleDefeated => 'DEFEATED';

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
  String get controlsHint =>
      'Drag across your half to dodge, forward to climb, back to dive. Hit the enemy at its own altitude. Draw a gesture on the pad to fly a maneuver.';

  @override
  String get comcenterTitle => 'COMCENTER';

  @override
  String get tabUnits => 'UNITS';

  @override
  String get tabManeuvers => 'MANEUVERS';

  @override
  String get tabStore => 'STORE';

  @override
  String yourFleet(String name) {
    return 'Your fleet: $name';
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
      one: '1 battle won',
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
  String upgradeCost(int cost) {
    return '${cost}cr';
  }

  @override
  String get maxLevel => 'MAX LEVEL';

  @override
  String maneuverStats(int energy, String seconds) {
    return '$energy energy · $seconds s';
  }

  @override
  String get maneuverMirrors => ' · mirrors';

  @override
  String trainPrice(int price) {
    return 'TRAIN $price';
  }

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
  String get maneuverArmed => 'ARMED';

  @override
  String get maneuverArm => 'ARM';

  @override
  String get maneuverPadFull => 'PAD FULL';

  @override
  String unlockWins(int won, int needed) {
    return 'Win $won/$needed battles';
  }

  @override
  String unlockPack(String pack) {
    return 'In the $pack';
  }

  @override
  String get unlockStarter => 'From the start';

  @override
  String buyCredits(int price) {
    return 'BUY $price';
  }

  @override
  String get getPack => 'GET PACK';

  @override
  String get storeIntro =>
      'The whole game is free. These change how it looks, not who wins.';

  @override
  String get storeUnavailable => 'The store is not available on this build.';

  @override
  String get storeUnavailableShort =>
      'The store is not available on this build';

  @override
  String get restorePurchases => 'RESTORE PURCHASES';

  @override
  String get restoring => 'RESTORING…';

  @override
  String get restoreFailed => 'The store could not be reached';

  @override
  String get restoreNone => 'No earlier purchases on this account';

  @override
  String restoredCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Restored $count purchases',
      one: 'Restored 1 purchase',
    );
    return '$_temp0';
  }

  @override
  String get battleMusic => 'BATTLE MUSIC';

  @override
  String get musicStandard => 'Standard';

  @override
  String get listen => 'LISTEN';

  @override
  String get owned => 'OWNED';

  @override
  String get storeNotAvailableButton => 'STORE NOT AVAILABLE';

  @override
  String get notInStoreYet => 'NOT IN THE STORE YET';

  @override
  String buyPrice(String price) {
    return 'BUY $price';
  }

  @override
  String purchaseDone(String item) {
    return '$item is yours';
  }

  @override
  String purchasePending(String item) {
    return 'Waiting for the payment; $item arrives once it clears';
  }

  @override
  String get itemCommanderTitle => 'Commander Edition';

  @override
  String get itemCommanderDescription =>
      'Every premium fleet, maneuver pack and music pack, and everything added to the store later.';

  @override
  String get itemFleetsTitle => 'Fleet Collection';

  @override
  String itemFleetsDescription(int count) {
    return 'All $count premium fleets, and every fleet added later.';
  }

  @override
  String get itemFleetDescription =>
      'Ship art for all six units, white and black. Looks only: it flies like any other fleet.';

  @override
  String itemMusicTitle(String name) {
    return '$name music';
  }

  @override
  String get itemMusicDescription =>
      'Every battle theme again as 8-bit chiptune, from the pawn\'s quick synth line to the king\'s march.';

  @override
  String get howToPlayTitle => 'HOW TO PLAY';

  @override
  String get skip => 'SKIP';

  @override
  String get next => 'NEXT';

  @override
  String get letsPlay => 'LET\'S PLAY';

  @override
  String get rulesWinTitle => 'Three ways to win';

  @override
  String get rulesWin1 => 'Hold all five power fields at the end of your turn.';

  @override
  String get rulesWin2 => 'Capture both the enemy\'s King and Queen.';

  @override
  String get rulesWin3 => 'Get a Pawn to the enemy\'s back rank.';

  @override
  String get rulesWin4 =>
      'Lose your King or Queen and the other becomes the Last Warrior: it moves one square in any direction.';

  @override
  String get rulesPiecesTitle => 'Pieces move their own way';

  @override
  String get rulesPieces1 =>
      'Pawn: sideways and back to move, diagonally forward to move or capture. Never straight ahead.';

  @override
  String get rulesPieces2 =>
      'Rook: up to 4 squares straight. Bishop: up to 3 diagonally, or snipe 3 squares straight ahead over anything.';

  @override
  String get rulesPieces3 =>
      'Knight: an L forward or sideways, only a low L back, blocked by a Rook right in front.';

  @override
  String get rulesPieces4 =>
      'Queen: 4 diagonally, 2 straight. King: 4 straight, 2 diagonally.';

  @override
  String get rulesPieces5 =>
      'Tap a piece to see where it can go. A red ! means it can be taken.';

  @override
  String get rulesBattleTitle => 'Every capture is a battle';

  @override
  String get rulesBattle1 =>
      'The two pieces become ships and fight it out in the arena. The winner keeps the square.';

  @override
  String get rulesBattle2 =>
      'Drag across your half to dodge, forward to climb, back to dive.';

  @override
  String get rulesBattle3 =>
      'A shot only hits a ship at about its own altitude, so to hit the enemy you have to fly where it can hit you.';

  @override
  String get rulesBattle4 =>
      'Raise the shield when fire is coming and you cannot get away.';

  @override
  String get rulesFleetTitle => 'Maneuvers and your fleet';

  @override
  String get rulesFleet1 =>
      'Draw a gesture on the pad and the ship flies a maneuver on its own. Each costs energy, which recharges during the battle.';

  @override
  String get rulesFleet2 =>
      'Single player battles earn credits. Spend them in the Comcenter on upgrades and new maneuvers.';

  @override
  String get rulesFleet3 =>
      'The whole game is free. The store only sells new looks and maneuver packs.';
}
