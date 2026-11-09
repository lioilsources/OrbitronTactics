import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_cs.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('cs'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'OrbitronTactics'**
  String get appTitle;

  /// No description provided for @defaultPlayerName.
  ///
  /// In en, this message translates to:
  /// **'Player'**
  String get defaultPlayerName;

  /// No description provided for @defaultHostName.
  ///
  /// In en, this message translates to:
  /// **'Host'**
  String get defaultHostName;

  /// No description provided for @defaultGuestName.
  ///
  /// In en, this message translates to:
  /// **'Guest'**
  String get defaultGuestName;

  /// No description provided for @defaultOpponentName.
  ///
  /// In en, this message translates to:
  /// **'Opponent'**
  String get defaultOpponentName;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @leave.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get leave;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @newGame.
  ///
  /// In en, this message translates to:
  /// **'New Game'**
  String get newGame;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @join.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get join;

  /// No description provided for @connect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get connect;

  /// No description provided for @howToPlayTooltip.
  ///
  /// In en, this message translates to:
  /// **'How to play'**
  String get howToPlayTooltip;

  /// No description provided for @comcenterTooltip.
  ///
  /// In en, this message translates to:
  /// **'Comcenter'**
  String get comcenterTooltip;

  /// No description provided for @credits.
  ///
  /// In en, this message translates to:
  /// **'{credits} cr'**
  String credits(int credits);

  /// No description provided for @creditsReward.
  ///
  /// In en, this message translates to:
  /// **'+{credits} cr'**
  String creditsReward(int credits);

  /// No description provided for @unitPawn.
  ///
  /// In en, this message translates to:
  /// **'Pawn'**
  String get unitPawn;

  /// No description provided for @unitRook.
  ///
  /// In en, this message translates to:
  /// **'Rook'**
  String get unitRook;

  /// No description provided for @unitKnight.
  ///
  /// In en, this message translates to:
  /// **'Knight'**
  String get unitKnight;

  /// No description provided for @unitBishop.
  ///
  /// In en, this message translates to:
  /// **'Bishop'**
  String get unitBishop;

  /// No description provided for @unitQueen.
  ///
  /// In en, this message translates to:
  /// **'Queen'**
  String get unitQueen;

  /// No description provided for @unitKing.
  ///
  /// In en, this message translates to:
  /// **'King'**
  String get unitKing;

  /// No description provided for @lobbyYourName.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get lobbyYourName;

  /// No description provided for @lobbySinglePlayer.
  ///
  /// In en, this message translates to:
  /// **'Single Player'**
  String get lobbySinglePlayer;

  /// No description provided for @lobbyCreateGame.
  ///
  /// In en, this message translates to:
  /// **'Create Game'**
  String get lobbyCreateGame;

  /// No description provided for @lobbyLocalGame.
  ///
  /// In en, this message translates to:
  /// **'Local Game'**
  String get lobbyLocalGame;

  /// No description provided for @lobbyHostWifi.
  ///
  /// In en, this message translates to:
  /// **'Host WiFi'**
  String get lobbyHostWifi;

  /// No description provided for @lobbyJoinWifi.
  ///
  /// In en, this message translates to:
  /// **'Join WiFi'**
  String get lobbyJoinWifi;

  /// No description provided for @lobbyWifiNote.
  ///
  /// In en, this message translates to:
  /// **'WiFi mode includes realtime battle arena'**
  String get lobbyWifiNote;

  /// No description provided for @lobbyOpenGames.
  ///
  /// In en, this message translates to:
  /// **'Open Games'**
  String get lobbyOpenGames;

  /// No description provided for @lobbyNoOpenGames.
  ///
  /// In en, this message translates to:
  /// **'No open games.\nCreate one to start!'**
  String get lobbyNoOpenGames;

  /// No description provided for @lobbyJustNow.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get lobbyJustNow;

  /// No description provided for @lobbyMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m ago'**
  String lobbyMinutesAgo(int minutes);

  /// No description provided for @lobbyCannotConnect.
  ///
  /// In en, this message translates to:
  /// **'Cannot connect to server'**
  String get lobbyCannotConnect;

  /// No description provided for @errorCreatingGame.
  ///
  /// In en, this message translates to:
  /// **'Error creating game: {error}'**
  String errorCreatingGame(String error);

  /// No description provided for @errorJoiningGame.
  ///
  /// In en, this message translates to:
  /// **'Error joining game: {error}'**
  String errorJoiningGame(String error);

  /// No description provided for @gameNotOpen.
  ///
  /// In en, this message translates to:
  /// **'That game is no longer open'**
  String get gameNotOpen;

  /// No description provided for @wifiHostError.
  ///
  /// In en, this message translates to:
  /// **'WiFi host error: {error}'**
  String wifiHostError(String error);

  /// No description provided for @wifiJoinError.
  ///
  /// In en, this message translates to:
  /// **'WiFi join error: {error}'**
  String wifiJoinError(String error);

  /// No description provided for @dialogDifficulty.
  ///
  /// In en, this message translates to:
  /// **'Difficulty'**
  String get dialogDifficulty;

  /// No description provided for @dialogAiFleets.
  ///
  /// In en, this message translates to:
  /// **'AI fleets'**
  String get dialogAiFleets;

  /// No description provided for @dialogYourColor.
  ///
  /// In en, this message translates to:
  /// **'Your color'**
  String get dialogYourColor;

  /// No description provided for @difficultyEasy.
  ///
  /// In en, this message translates to:
  /// **'Easy'**
  String get difficultyEasy;

  /// No description provided for @difficultyMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get difficultyMedium;

  /// No description provided for @difficultyHard.
  ///
  /// In en, this message translates to:
  /// **'Hard'**
  String get difficultyHard;

  /// No description provided for @colorWhite.
  ///
  /// In en, this message translates to:
  /// **'White'**
  String get colorWhite;

  /// No description provided for @colorBlack.
  ///
  /// In en, this message translates to:
  /// **'Black'**
  String get colorBlack;

  /// No description provided for @youMoveFirst.
  ///
  /// In en, this message translates to:
  /// **'You move first'**
  String get youMoveFirst;

  /// No description provided for @aiMovesFirst.
  ///
  /// In en, this message translates to:
  /// **'The AI moves first'**
  String get aiMovesFirst;

  /// No description provided for @fleetRecord.
  ///
  /// In en, this message translates to:
  /// **'{wins}W / {losses}L'**
  String fleetRecord(int wins, int losses);

  /// No description provided for @wifiHostTitle.
  ///
  /// In en, this message translates to:
  /// **'WiFi Host'**
  String get wifiHostTitle;

  /// No description provided for @wifiShareAddress.
  ///
  /// In en, this message translates to:
  /// **'Share this address with your opponent:'**
  String get wifiShareAddress;

  /// No description provided for @wifiWaitingGuest.
  ///
  /// In en, this message translates to:
  /// **'Waiting for guest to connect...'**
  String get wifiWaitingGuest;

  /// No description provided for @wifiJoinTitle.
  ///
  /// In en, this message translates to:
  /// **'Join WiFi Game'**
  String get wifiJoinTitle;

  /// No description provided for @wifiEnterIp.
  ///
  /// In en, this message translates to:
  /// **'Enter the host\'s IP address:'**
  String get wifiEnterIp;

  /// No description provided for @waitingForOpponent.
  ///
  /// In en, this message translates to:
  /// **'Waiting for opponent'**
  String get waitingForOpponent;

  /// No description provided for @gameIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Game ID:'**
  String get gameIdLabel;

  /// No description provided for @waitingForPlayer.
  ///
  /// In en, this message translates to:
  /// **'Waiting for another player to join...'**
  String get waitingForPlayer;

  /// No description provided for @leaveGameTooltip.
  ///
  /// In en, this message translates to:
  /// **'Leave Game'**
  String get leaveGameTooltip;

  /// No description provided for @newGameTooltip.
  ///
  /// In en, this message translates to:
  /// **'New Game'**
  String get newGameTooltip;

  /// No description provided for @leaveGameTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave Game?'**
  String get leaveGameTitle;

  /// No description provided for @leaveGameBody.
  ///
  /// In en, this message translates to:
  /// **'Your opponent will be able to claim victory.'**
  String get leaveGameBody;

  /// No description provided for @turnThinking.
  ///
  /// In en, this message translates to:
  /// **'THINKING…'**
  String get turnThinking;

  /// No description provided for @turnLabel.
  ///
  /// In en, this message translates to:
  /// **'TURN'**
  String get turnLabel;

  /// No description provided for @powerFieldsLabel.
  ///
  /// In en, this message translates to:
  /// **'Power Fields: '**
  String get powerFieldsLabel;

  /// No description provided for @powerFieldsNeed.
  ///
  /// In en, this message translates to:
  /// **'  (need {total})'**
  String powerFieldsNeed(int total);

  /// No description provided for @opponentDisconnected.
  ///
  /// In en, this message translates to:
  /// **'Opponent Disconnected'**
  String get opponentDisconnected;

  /// No description provided for @opponentLeftBody.
  ///
  /// In en, this message translates to:
  /// **'Your opponent has left the game.'**
  String get opponentLeftBody;

  /// No description provided for @claimVictory.
  ///
  /// In en, this message translates to:
  /// **'Claim Victory'**
  String get claimVictory;

  /// No description provided for @victoryPowerFields.
  ///
  /// In en, this message translates to:
  /// **'Power Field Domination!'**
  String get victoryPowerFields;

  /// No description provided for @victoryRoyal.
  ///
  /// In en, this message translates to:
  /// **'Royal Elimination!'**
  String get victoryRoyal;

  /// No description provided for @victoryInfiltration.
  ///
  /// In en, this message translates to:
  /// **'Pawn Infiltration!'**
  String get victoryInfiltration;

  /// No description provided for @victoryAbandonment.
  ///
  /// In en, this message translates to:
  /// **'Opponent Abandoned!'**
  String get victoryAbandonment;

  /// No description provided for @whiteWins.
  ///
  /// In en, this message translates to:
  /// **'White Wins!'**
  String get whiteWins;

  /// No description provided for @blackWins.
  ///
  /// In en, this message translates to:
  /// **'Black Wins!'**
  String get blackWins;

  /// No description provided for @yourShield.
  ///
  /// In en, this message translates to:
  /// **'YOUR SHIELD'**
  String get yourShield;

  /// No description provided for @whiteShield.
  ///
  /// In en, this message translates to:
  /// **'WHITE SHIELD'**
  String get whiteShield;

  /// No description provided for @blackShield.
  ///
  /// In en, this message translates to:
  /// **'BLACK SHIELD'**
  String get blackShield;

  /// No description provided for @battleTitle.
  ///
  /// In en, this message translates to:
  /// **'BATTLE'**
  String get battleTitle;

  /// No description provided for @soundOn.
  ///
  /// In en, this message translates to:
  /// **'Sound on'**
  String get soundOn;

  /// No description provided for @soundOff.
  ///
  /// In en, this message translates to:
  /// **'Sound off'**
  String get soundOff;

  /// No description provided for @battleVictory.
  ///
  /// In en, this message translates to:
  /// **'VICTORY!'**
  String get battleVictory;

  /// No description provided for @battleDefeated.
  ///
  /// In en, this message translates to:
  /// **'DEFEATED'**
  String get battleDefeated;

  /// No description provided for @newManeuvers.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{NEW MANEUVER} other{NEW MANEUVERS}}'**
  String newManeuvers(int count);

  /// No description provided for @tapToContinue.
  ///
  /// In en, this message translates to:
  /// **'Tap to continue'**
  String get tapToContinue;

  /// No description provided for @controlsHint.
  ///
  /// In en, this message translates to:
  /// **'Drag across your half to dodge, forward to climb, back to dive. Hit the enemy at its own altitude. Draw a gesture on the pad to fly a maneuver.'**
  String get controlsHint;

  /// No description provided for @comcenterTitle.
  ///
  /// In en, this message translates to:
  /// **'COMCENTER'**
  String get comcenterTitle;

  /// No description provided for @tabUnits.
  ///
  /// In en, this message translates to:
  /// **'UNITS'**
  String get tabUnits;

  /// No description provided for @tabManeuvers.
  ///
  /// In en, this message translates to:
  /// **'MANEUVERS'**
  String get tabManeuvers;

  /// No description provided for @tabStore.
  ///
  /// In en, this message translates to:
  /// **'STORE'**
  String get tabStore;

  /// No description provided for @yourFleet.
  ///
  /// In en, this message translates to:
  /// **'Your fleet: {name}'**
  String yourFleet(String name);

  /// No description provided for @upgradeHint.
  ///
  /// In en, this message translates to:
  /// **'Upgrade your units to gain advantage in battle'**
  String get upgradeHint;

  /// No description provided for @armedCount.
  ///
  /// In en, this message translates to:
  /// **'ARMED {armed}/{slots}'**
  String armedCount(int armed, int slots);

  /// No description provided for @battlesWon.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 battle won} other{{count} battles won}}'**
  String battlesWon(int count);

  /// No description provided for @statHp.
  ///
  /// In en, this message translates to:
  /// **'HP'**
  String get statHp;

  /// No description provided for @statDamage.
  ///
  /// In en, this message translates to:
  /// **'DMG'**
  String get statDamage;

  /// No description provided for @upgradeMax.
  ///
  /// In en, this message translates to:
  /// **'MAX'**
  String get upgradeMax;

  /// No description provided for @upgradeCost.
  ///
  /// In en, this message translates to:
  /// **'{cost}cr'**
  String upgradeCost(int cost);

  /// No description provided for @maxLevel.
  ///
  /// In en, this message translates to:
  /// **'MAX LEVEL'**
  String get maxLevel;

  /// No description provided for @maneuverStats.
  ///
  /// In en, this message translates to:
  /// **'{energy} energy · {seconds} s'**
  String maneuverStats(int energy, String seconds);

  /// No description provided for @maneuverMirrors.
  ///
  /// In en, this message translates to:
  /// **' · mirrors'**
  String get maneuverMirrors;

  /// No description provided for @trainPrice.
  ///
  /// In en, this message translates to:
  /// **'TRAIN {price}'**
  String trainPrice(int price);

  /// No description provided for @tierStarter.
  ///
  /// In en, this message translates to:
  /// **'START'**
  String get tierStarter;

  /// No description provided for @tierBasic.
  ///
  /// In en, this message translates to:
  /// **'BASIC'**
  String get tierBasic;

  /// No description provided for @tierAdvanced.
  ///
  /// In en, this message translates to:
  /// **'ADVANCED'**
  String get tierAdvanced;

  /// No description provided for @tierSignature.
  ///
  /// In en, this message translates to:
  /// **'SIGNATURE'**
  String get tierSignature;

  /// No description provided for @tierPack.
  ///
  /// In en, this message translates to:
  /// **'PACK'**
  String get tierPack;

  /// No description provided for @maneuverArmed.
  ///
  /// In en, this message translates to:
  /// **'ARMED'**
  String get maneuverArmed;

  /// No description provided for @maneuverArm.
  ///
  /// In en, this message translates to:
  /// **'ARM'**
  String get maneuverArm;

  /// No description provided for @maneuverPadFull.
  ///
  /// In en, this message translates to:
  /// **'PAD FULL'**
  String get maneuverPadFull;

  /// No description provided for @unlockWins.
  ///
  /// In en, this message translates to:
  /// **'Win {won}/{needed} battles'**
  String unlockWins(int won, int needed);

  /// No description provided for @unlockPack.
  ///
  /// In en, this message translates to:
  /// **'In the {pack}'**
  String unlockPack(String pack);

  /// No description provided for @unlockStarter.
  ///
  /// In en, this message translates to:
  /// **'From the start'**
  String get unlockStarter;

  /// No description provided for @buyCredits.
  ///
  /// In en, this message translates to:
  /// **'BUY {price}'**
  String buyCredits(int price);

  /// No description provided for @getPack.
  ///
  /// In en, this message translates to:
  /// **'GET PACK'**
  String get getPack;

  /// No description provided for @storeIntro.
  ///
  /// In en, this message translates to:
  /// **'The whole game is free. These change how it looks, not who wins.'**
  String get storeIntro;

  /// No description provided for @storeUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The store is not available on this build.'**
  String get storeUnavailable;

  /// No description provided for @storeUnavailableShort.
  ///
  /// In en, this message translates to:
  /// **'The store is not available on this build'**
  String get storeUnavailableShort;

  /// No description provided for @restorePurchases.
  ///
  /// In en, this message translates to:
  /// **'RESTORE PURCHASES'**
  String get restorePurchases;

  /// No description provided for @restoring.
  ///
  /// In en, this message translates to:
  /// **'RESTORING…'**
  String get restoring;

  /// No description provided for @restoreFailed.
  ///
  /// In en, this message translates to:
  /// **'The store could not be reached'**
  String get restoreFailed;

  /// No description provided for @restoreNone.
  ///
  /// In en, this message translates to:
  /// **'No earlier purchases on this account'**
  String get restoreNone;

  /// No description provided for @restoredCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Restored 1 purchase} other{Restored {count} purchases}}'**
  String restoredCount(int count);

  /// No description provided for @battleMusic.
  ///
  /// In en, this message translates to:
  /// **'BATTLE MUSIC'**
  String get battleMusic;

  /// No description provided for @musicStandard.
  ///
  /// In en, this message translates to:
  /// **'Standard'**
  String get musicStandard;

  /// No description provided for @listen.
  ///
  /// In en, this message translates to:
  /// **'LISTEN'**
  String get listen;

  /// No description provided for @owned.
  ///
  /// In en, this message translates to:
  /// **'OWNED'**
  String get owned;

  /// No description provided for @storeNotAvailableButton.
  ///
  /// In en, this message translates to:
  /// **'STORE NOT AVAILABLE'**
  String get storeNotAvailableButton;

  /// No description provided for @notInStoreYet.
  ///
  /// In en, this message translates to:
  /// **'NOT IN THE STORE YET'**
  String get notInStoreYet;

  /// No description provided for @buyPrice.
  ///
  /// In en, this message translates to:
  /// **'BUY {price}'**
  String buyPrice(String price);

  /// No description provided for @purchaseDone.
  ///
  /// In en, this message translates to:
  /// **'{item} is yours'**
  String purchaseDone(String item);

  /// No description provided for @purchasePending.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the payment; {item} arrives once it clears'**
  String purchasePending(String item);

  /// No description provided for @itemCommanderTitle.
  ///
  /// In en, this message translates to:
  /// **'Commander Edition'**
  String get itemCommanderTitle;

  /// No description provided for @itemCommanderDescription.
  ///
  /// In en, this message translates to:
  /// **'Every premium fleet, maneuver pack and music pack, and everything added to the store later.'**
  String get itemCommanderDescription;

  /// No description provided for @itemFleetsTitle.
  ///
  /// In en, this message translates to:
  /// **'Fleet Collection'**
  String get itemFleetsTitle;

  /// No description provided for @itemFleetsDescription.
  ///
  /// In en, this message translates to:
  /// **'All {count} premium fleets, and every fleet added later.'**
  String itemFleetsDescription(int count);

  /// No description provided for @itemFleetDescription.
  ///
  /// In en, this message translates to:
  /// **'Ship art for all six units, white and black. Looks only: it flies like any other fleet.'**
  String get itemFleetDescription;

  /// No description provided for @itemMusicTitle.
  ///
  /// In en, this message translates to:
  /// **'{name} music'**
  String itemMusicTitle(String name);

  /// No description provided for @itemMusicDescription.
  ///
  /// In en, this message translates to:
  /// **'Every battle theme again as 8-bit chiptune, from the pawn\'s quick synth line to the king\'s march.'**
  String get itemMusicDescription;

  /// No description provided for @howToPlayTitle.
  ///
  /// In en, this message translates to:
  /// **'HOW TO PLAY'**
  String get howToPlayTitle;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'SKIP'**
  String get skip;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'NEXT'**
  String get next;

  /// No description provided for @letsPlay.
  ///
  /// In en, this message translates to:
  /// **'LET\'S PLAY'**
  String get letsPlay;

  /// No description provided for @rulesWinTitle.
  ///
  /// In en, this message translates to:
  /// **'Three ways to win'**
  String get rulesWinTitle;

  /// No description provided for @rulesWin1.
  ///
  /// In en, this message translates to:
  /// **'Hold all five power fields at the end of your turn.'**
  String get rulesWin1;

  /// No description provided for @rulesWin2.
  ///
  /// In en, this message translates to:
  /// **'Capture both the enemy\'s King and Queen.'**
  String get rulesWin2;

  /// No description provided for @rulesWin3.
  ///
  /// In en, this message translates to:
  /// **'Get a Pawn to the enemy\'s back rank.'**
  String get rulesWin3;

  /// No description provided for @rulesWin4.
  ///
  /// In en, this message translates to:
  /// **'Lose your King or Queen and the other becomes the Last Warrior: it moves one square in any direction.'**
  String get rulesWin4;

  /// No description provided for @rulesPiecesTitle.
  ///
  /// In en, this message translates to:
  /// **'Pieces move their own way'**
  String get rulesPiecesTitle;

  /// No description provided for @rulesPieces1.
  ///
  /// In en, this message translates to:
  /// **'Pawn: sideways and back to move, diagonally forward to move or capture. Never straight ahead.'**
  String get rulesPieces1;

  /// No description provided for @rulesPieces2.
  ///
  /// In en, this message translates to:
  /// **'Rook: up to 4 squares straight. Bishop: up to 3 diagonally, or snipe 3 squares straight ahead over anything.'**
  String get rulesPieces2;

  /// No description provided for @rulesPieces3.
  ///
  /// In en, this message translates to:
  /// **'Knight: an L forward or sideways, only a low L back, blocked by a Rook right in front.'**
  String get rulesPieces3;

  /// No description provided for @rulesPieces4.
  ///
  /// In en, this message translates to:
  /// **'Queen: 4 diagonally, 2 straight. King: 4 straight, 2 diagonally.'**
  String get rulesPieces4;

  /// No description provided for @rulesPieces5.
  ///
  /// In en, this message translates to:
  /// **'Tap a piece to see where it can go. A red ! means it can be taken.'**
  String get rulesPieces5;

  /// No description provided for @rulesBattleTitle.
  ///
  /// In en, this message translates to:
  /// **'Every capture is a battle'**
  String get rulesBattleTitle;

  /// No description provided for @rulesBattle1.
  ///
  /// In en, this message translates to:
  /// **'The two pieces become ships and fight it out in the arena. The winner keeps the square.'**
  String get rulesBattle1;

  /// No description provided for @rulesBattle2.
  ///
  /// In en, this message translates to:
  /// **'Drag across your half to dodge, forward to climb, back to dive.'**
  String get rulesBattle2;

  /// No description provided for @rulesBattle3.
  ///
  /// In en, this message translates to:
  /// **'A shot only hits a ship at about its own altitude, so to hit the enemy you have to fly where it can hit you.'**
  String get rulesBattle3;

  /// No description provided for @rulesBattle4.
  ///
  /// In en, this message translates to:
  /// **'Raise the shield when fire is coming and you cannot get away.'**
  String get rulesBattle4;

  /// No description provided for @rulesFleetTitle.
  ///
  /// In en, this message translates to:
  /// **'Maneuvers and your fleet'**
  String get rulesFleetTitle;

  /// No description provided for @rulesFleet1.
  ///
  /// In en, this message translates to:
  /// **'Draw a gesture on the pad and the ship flies a maneuver on its own. Each costs energy, which recharges during the battle.'**
  String get rulesFleet1;

  /// No description provided for @rulesFleet2.
  ///
  /// In en, this message translates to:
  /// **'Single player battles earn credits. Spend them in the Comcenter on upgrades and new maneuvers.'**
  String get rulesFleet2;

  /// No description provided for @rulesFleet3.
  ///
  /// In en, this message translates to:
  /// **'The whole game is free. The store only sells new looks and maneuver packs.'**
  String get rulesFleet3;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['cs', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'cs':
      return AppLocalizationsCs();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
