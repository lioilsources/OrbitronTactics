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
/// import 'generated/app_localizations.dart';
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

  /// Comcenter tab with the board piece skin picker
  ///
  /// In en, this message translates to:
  /// **'BOARD'**
  String get boardTab;

  /// Heading above the piece skin packs
  ///
  /// In en, this message translates to:
  /// **'Board pieces'**
  String get pieceSkinTitle;

  /// Explains what the piece skin picker changes
  ///
  /// In en, this message translates to:
  /// **'Pick the armies drawn on the board in every game mode.'**
  String get pieceSkinHint;

  /// Toggle that draws a small chess glyph on every image piece
  ///
  /// In en, this message translates to:
  /// **'Classic marks'**
  String get classicMarks;

  /// Subtitle of the classic marks toggle
  ///
  /// In en, this message translates to:
  /// **'Show a small chess symbol on each figure.'**
  String get classicMarksHint;

  /// Name of the default symbol pieces
  ///
  /// In en, this message translates to:
  /// **'Classic'**
  String get pieceSkinClassic;

  /// White side of the classic pieces
  ///
  /// In en, this message translates to:
  /// **'White'**
  String get pieceSkinClassicWhite;

  /// Black side of the classic pieces
  ///
  /// In en, this message translates to:
  /// **'Black'**
  String get pieceSkinClassicBlack;

  /// Name of the Heaven against Hell piece pack
  ///
  /// In en, this message translates to:
  /// **'Heaven × Hell'**
  String get pieceSkinHeavenHell;

  /// White side of the Heaven against Hell pack
  ///
  /// In en, this message translates to:
  /// **'Heaven'**
  String get pieceSkinHeavenHellWhite;

  /// Black side of the Heaven against Hell pack
  ///
  /// In en, this message translates to:
  /// **'Hell'**
  String get pieceSkinHeavenHellBlack;

  /// Name of the Rome × Carthage piece pack
  ///
  /// In en, this message translates to:
  /// **'Rome × Carthage'**
  String get pieceSkinRomeCarthage;

  /// White side of the Rome × Carthage piece pack
  ///
  /// In en, this message translates to:
  /// **'Rome'**
  String get pieceSkinRomeCarthageWhite;

  /// Black side of the Rome × Carthage piece pack
  ///
  /// In en, this message translates to:
  /// **'Carthage'**
  String get pieceSkinRomeCarthageBlack;

  /// Name of the Knights × Orcs piece pack
  ///
  /// In en, this message translates to:
  /// **'Knights × Orcs'**
  String get pieceSkinKnightsOrcs;

  /// White side of the Knights × Orcs piece pack
  ///
  /// In en, this message translates to:
  /// **'Knights'**
  String get pieceSkinKnightsOrcsWhite;

  /// Black side of the Knights × Orcs piece pack
  ///
  /// In en, this message translates to:
  /// **'Orcs'**
  String get pieceSkinKnightsOrcsBlack;

  /// Name of the Olympus × Titans piece pack
  ///
  /// In en, this message translates to:
  /// **'Olympus × Titans'**
  String get pieceSkinOlympusTitans;

  /// White side of the Olympus × Titans piece pack
  ///
  /// In en, this message translates to:
  /// **'Olympus'**
  String get pieceSkinOlympusTitansWhite;

  /// Black side of the Olympus × Titans piece pack
  ///
  /// In en, this message translates to:
  /// **'Titans'**
  String get pieceSkinOlympusTitansBlack;

  /// Name of the Samurai × Yōkai piece pack
  ///
  /// In en, this message translates to:
  /// **'Samurai × Yōkai'**
  String get pieceSkinSamuraiYokai;

  /// White side of the Samurai × Yōkai piece pack
  ///
  /// In en, this message translates to:
  /// **'Samurai'**
  String get pieceSkinSamuraiYokaiWhite;

  /// Black side of the Samurai × Yōkai piece pack
  ///
  /// In en, this message translates to:
  /// **'Yōkai'**
  String get pieceSkinSamuraiYokaiBlack;

  /// Name of the Hussites × Crusaders piece pack
  ///
  /// In en, this message translates to:
  /// **'Hussites × Crusaders'**
  String get pieceSkinHussitesCrusaders;

  /// White side of the Hussites × Crusaders piece pack
  ///
  /// In en, this message translates to:
  /// **'Hussites'**
  String get pieceSkinHussitesCrusadersWhite;

  /// Black side of the Hussites × Crusaders piece pack
  ///
  /// In en, this message translates to:
  /// **'Crusaders'**
  String get pieceSkinHussitesCrusadersBlack;

  /// App name in the title bar
  ///
  /// In en, this message translates to:
  /// **'OrbitronTactics'**
  String get appTitle;

  /// Tooltip of the button that opens the Comcenter
  ///
  /// In en, this message translates to:
  /// **'Comcenter'**
  String get comcenterTooltip;

  /// Generic cancel button
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Button back to the lobby
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// Button that leaves the game
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get leave;

  /// Starts a new game
  ///
  /// In en, this message translates to:
  /// **'New Game'**
  String get newGame;

  /// An amount of credits
  ///
  /// In en, this message translates to:
  /// **'{credits} cr'**
  String creditsAmount(int credits);

  /// Credits earned in one game
  ///
  /// In en, this message translates to:
  /// **'+{credits} cr'**
  String creditsReward(int credits);

  /// Default name of the local player
  ///
  /// In en, this message translates to:
  /// **'Player'**
  String get defaultPlayerName;

  /// Default name of the WiFi host
  ///
  /// In en, this message translates to:
  /// **'Host'**
  String get defaultHostName;

  /// Default name of the WiFi guest
  ///
  /// In en, this message translates to:
  /// **'Guest'**
  String get defaultGuestName;

  /// Placeholder name until the opponent joins
  ///
  /// In en, this message translates to:
  /// **'Opponent'**
  String get defaultOpponentName;

  /// Label of the player name field
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get lobbyYourName;

  /// Starts a game against the AI
  ///
  /// In en, this message translates to:
  /// **'Single Player'**
  String get lobbySinglePlayer;

  /// Creates an online game
  ///
  /// In en, this message translates to:
  /// **'Create Game'**
  String get lobbyCreateGame;

  /// Starts a hot-seat game on one device
  ///
  /// In en, this message translates to:
  /// **'Local Game'**
  String get lobbyLocalGame;

  /// Hosts a game on the local network
  ///
  /// In en, this message translates to:
  /// **'Host WiFi'**
  String get lobbyHostWifi;

  /// Joins a game on the local network
  ///
  /// In en, this message translates to:
  /// **'Join WiFi'**
  String get lobbyJoinWifi;

  /// Hint under the WiFi buttons
  ///
  /// In en, this message translates to:
  /// **'WiFi mode includes realtime battle arena'**
  String get lobbyWifiHint;

  /// Heading of the list of games waiting for a player
  ///
  /// In en, this message translates to:
  /// **'Open Games'**
  String get lobbyOpenGames;

  /// Shown when no online game waits for a player
  ///
  /// In en, this message translates to:
  /// **'No open games.\nCreate one to start!'**
  String get lobbyNoOpenGames;

  /// Age of a game created less than a minute ago
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get lobbyJustNow;

  /// Age of an open game in minutes
  ///
  /// In en, this message translates to:
  /// **'{minutes}m ago'**
  String lobbyMinutesAgo(int minutes);

  /// Joins an open online game
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get lobbyJoin;

  /// Shown when the lobby cannot reach the server
  ///
  /// In en, this message translates to:
  /// **'Cannot connect to server'**
  String get lobbyCannotConnect;

  /// Snackbar when creating an online game fails
  ///
  /// In en, this message translates to:
  /// **'Error creating game: {error}'**
  String errorCreatingGame(String error);

  /// Snackbar when joining an online game fails
  ///
  /// In en, this message translates to:
  /// **'Error joining game: {error}'**
  String errorJoiningGame(String error);

  /// Snackbar when hosting a WiFi game fails
  ///
  /// In en, this message translates to:
  /// **'WiFi host error: {error}'**
  String errorWifiHost(String error);

  /// Snackbar when joining a WiFi game fails
  ///
  /// In en, this message translates to:
  /// **'WiFi join error: {error}'**
  String errorWifiJoin(String error);

  /// Label of the AI difficulty picker
  ///
  /// In en, this message translates to:
  /// **'Difficulty'**
  String get singlePlayerDifficulty;

  /// Label of the AI fleets' progress list
  ///
  /// In en, this message translates to:
  /// **'AI fleets'**
  String get singlePlayerAiFleets;

  /// Label of the side picker; the options are the active piece skin's side names
  ///
  /// In en, this message translates to:
  /// **'Your side'**
  String get singlePlayerYourSide;

  /// Shown when the player picks the side that moves first
  ///
  /// In en, this message translates to:
  /// **'You move first'**
  String get singlePlayerYouMoveFirst;

  /// Shown when the AI gets the side that moves first
  ///
  /// In en, this message translates to:
  /// **'The AI moves first'**
  String get singlePlayerAiMovesFirst;

  /// Starts the single-player game
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// Easy AI difficulty
  ///
  /// In en, this message translates to:
  /// **'Easy'**
  String get difficultyEasy;

  /// Medium AI difficulty
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get difficultyMedium;

  /// Hard AI difficulty
  ///
  /// In en, this message translates to:
  /// **'Hard'**
  String get difficultyHard;

  /// Name of the AI opponent, with its difficulty
  ///
  /// In en, this message translates to:
  /// **'Orbitron AI · {difficulty}'**
  String aiPlayerName(String difficulty);

  /// An AI fleet's wins and losses
  ///
  /// In en, this message translates to:
  /// **'{wins}W / {losses}L'**
  String fleetRecord(int wins, int losses);

  /// Title of the dialog shown while hosting a WiFi game
  ///
  /// In en, this message translates to:
  /// **'WiFi Host'**
  String get wifiHostTitle;

  /// Above the host's address
  ///
  /// In en, this message translates to:
  /// **'Share this address with your opponent:'**
  String get wifiShareAddress;

  /// Shown while the WiFi host waits
  ///
  /// In en, this message translates to:
  /// **'Waiting for guest to connect...'**
  String get wifiWaitingForGuest;

  /// Title of the WiFi join dialog
  ///
  /// In en, this message translates to:
  /// **'Join WiFi Game'**
  String get wifiJoinTitle;

  /// Above the host address field
  ///
  /// In en, this message translates to:
  /// **'Enter the host\'s IP address:'**
  String get wifiEnterHostAddress;

  /// Connects to the WiFi host
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get connect;

  /// Title of the screen waiting for an online opponent
  ///
  /// In en, this message translates to:
  /// **'Waiting for opponent'**
  String get waitingTitle;

  /// Label above the online game's id
  ///
  /// In en, this message translates to:
  /// **'Game ID:'**
  String get waitingGameId;

  /// Shown while waiting for an online opponent
  ///
  /// In en, this message translates to:
  /// **'Waiting for another player to join...'**
  String get waitingForPlayer;

  /// Tooltip of the leave button
  ///
  /// In en, this message translates to:
  /// **'Leave Game'**
  String get leaveGameTooltip;

  /// Title of the leave confirmation
  ///
  /// In en, this message translates to:
  /// **'Leave Game?'**
  String get leaveGameTitle;

  /// Body of the leave confirmation
  ///
  /// In en, this message translates to:
  /// **'Your opponent will be able to claim victory.'**
  String get leaveGameBody;

  /// Badge on the player whose turn it is
  ///
  /// In en, this message translates to:
  /// **'TURN'**
  String get turnBadge;

  /// Badge on the AI while it picks a move
  ///
  /// In en, this message translates to:
  /// **'THINKING…'**
  String get thinkingBadge;

  /// Label of the power field count
  ///
  /// In en, this message translates to:
  /// **'Power Fields:'**
  String get powerFieldsLabel;

  /// How many power fields win the game
  ///
  /// In en, this message translates to:
  /// **'(need {total})'**
  String powerFieldsNeed(int total);

  /// Title of the disconnect overlay
  ///
  /// In en, this message translates to:
  /// **'Opponent Disconnected'**
  String get opponentDisconnected;

  /// Body of the disconnect overlay
  ///
  /// In en, this message translates to:
  /// **'Your opponent has left the game.'**
  String get opponentLeftBody;

  /// Claims the win after the opponent left
  ///
  /// In en, this message translates to:
  /// **'Claim Victory'**
  String get claimVictory;

  /// Game over title; side is the winning side's name from the piece skin
  ///
  /// In en, this message translates to:
  /// **'{side} Wins!'**
  String sideWins(String side);

  /// Victory by holding the power fields
  ///
  /// In en, this message translates to:
  /// **'Power Field Domination!'**
  String get victoryPowerFieldDomination;

  /// Victory by capturing both royals
  ///
  /// In en, this message translates to:
  /// **'Royal Elimination!'**
  String get victoryRoyalElimination;

  /// Victory by a pawn reaching the far row
  ///
  /// In en, this message translates to:
  /// **'Pawn Infiltration!'**
  String get victoryInfiltration;

  /// Victory because the opponent left
  ///
  /// In en, this message translates to:
  /// **'Opponent Abandoned!'**
  String get victoryAbandonment;

  /// Title bar of the battle arena
  ///
  /// In en, this message translates to:
  /// **'BATTLE'**
  String get battleTitle;

  /// Battle time in seconds, already formatted
  ///
  /// In en, this message translates to:
  /// **'{seconds}s'**
  String battleElapsed(String seconds);

  /// Tooltip that unmutes battle audio
  ///
  /// In en, this message translates to:
  /// **'Sound on'**
  String get soundOn;

  /// Tooltip that mutes battle audio
  ///
  /// In en, this message translates to:
  /// **'Sound off'**
  String get soundOff;

  /// Shield button of the local player
  ///
  /// In en, this message translates to:
  /// **'YOUR SHIELD'**
  String get yourShield;

  /// Shield button in hot-seat; side is the side's name in capitals
  ///
  /// In en, this message translates to:
  /// **'{side} SHIELD'**
  String sideShield(String side);

  /// Battle result for the winner
  ///
  /// In en, this message translates to:
  /// **'VICTORY!'**
  String get battleVictory;

  /// Battle result for the loser
  ///
  /// In en, this message translates to:
  /// **'DEFEATED'**
  String get battleDefeated;

  /// Battle result; side is the winning side's name
  ///
  /// In en, this message translates to:
  /// **'{side} unit survives'**
  String unitSurvives(String side);

  /// Heading above the maneuvers a battle win unlocked
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{NEW MANEUVER} other{NEW MANEUVERS}}'**
  String newManeuvers(int count);

  /// Hint on the battle result
  ///
  /// In en, this message translates to:
  /// **'Tap to continue'**
  String get tapToContinue;

  /// Title of the Comcenter
  ///
  /// In en, this message translates to:
  /// **'COMCENTER'**
  String get comcenterTitle;

  /// Comcenter tab with unit upgrades
  ///
  /// In en, this message translates to:
  /// **'UNITS'**
  String get unitsTab;

  /// Comcenter tab with maneuvers
  ///
  /// In en, this message translates to:
  /// **'MANEUVERS'**
  String get maneuversTab;

  /// The player's chosen fleet
  ///
  /// In en, this message translates to:
  /// **'Your fleet: {fleet}'**
  String yourFleet(String fleet);

  /// Hint above the unit upgrades
  ///
  /// In en, this message translates to:
  /// **'Upgrade your units to gain advantage in battle'**
  String get upgradeHint;

  /// How many maneuver slots are armed
  ///
  /// In en, this message translates to:
  /// **'ARMED {armed}/{slots}'**
  String armedCount(int armed, int slots);

  /// Battles a ship has won
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} battle won} other{{count} battles won}}'**
  String battlesWon(int count);

  /// Hit points stat label
  ///
  /// In en, this message translates to:
  /// **'HP'**
  String get statHp;

  /// Damage stat label
  ///
  /// In en, this message translates to:
  /// **'DMG'**
  String get statDamage;

  /// Upgrade button when no level is left
  ///
  /// In en, this message translates to:
  /// **'MAX'**
  String get upgradeMax;

  /// Badge on a fully upgraded unit
  ///
  /// In en, this message translates to:
  /// **'MAX LEVEL'**
  String get upgradeMaxLevel;

  /// Badge with a maneuver's trained level
  ///
  /// In en, this message translates to:
  /// **'L{level}'**
  String maneuverLevel(int level);

  /// A maneuver's energy cost and duration (already formatted)
  ///
  /// In en, this message translates to:
  /// **'{energy} energy · {seconds} s'**
  String maneuverStats(int energy, String seconds);

  /// The maneuver can be flown mirrored
  ///
  /// In en, this message translates to:
  /// **'mirrors'**
  String get maneuverMirrors;

  /// Button that trains a maneuver to the next level
  ///
  /// In en, this message translates to:
  /// **'TRAIN {price}'**
  String maneuverTrain(int price);

  /// Button that buys a maneuver
  ///
  /// In en, this message translates to:
  /// **'BUY {price}'**
  String maneuverBuy(int price);

  /// Button on an armed maneuver; tap disarms it
  ///
  /// In en, this message translates to:
  /// **'ARMED'**
  String get maneuverArmed;

  /// Arms an owned maneuver
  ///
  /// In en, this message translates to:
  /// **'ARM'**
  String get maneuverArm;

  /// All maneuver slots are taken
  ///
  /// In en, this message translates to:
  /// **'PAD FULL'**
  String get maneuverPadFull;

  /// Battles still needed to unlock a maneuver
  ///
  /// In en, this message translates to:
  /// **'Win {won}/{needed} battles'**
  String maneuverWinBattles(int won, int needed);

  /// The maneuver comes with the Ace pack
  ///
  /// In en, this message translates to:
  /// **'In the Ace pack'**
  String get maneuverInAcePack;

  /// The maneuver is available from the start
  ///
  /// In en, this message translates to:
  /// **'From the start'**
  String get maneuverFromStart;

  /// Debug button that grants a pack
  ///
  /// In en, this message translates to:
  /// **'UNLOCK PACK'**
  String get maneuverUnlockPack;

  /// Maneuver tier badge
  ///
  /// In en, this message translates to:
  /// **'START'**
  String get tierStarter;

  /// Maneuver tier badge
  ///
  /// In en, this message translates to:
  /// **'BASIC'**
  String get tierBasic;

  /// Maneuver tier badge
  ///
  /// In en, this message translates to:
  /// **'ADVANCED'**
  String get tierAdvanced;

  /// Maneuver tier badge: the ship's own maneuver
  ///
  /// In en, this message translates to:
  /// **'SIGNATURE'**
  String get tierSignature;

  /// Maneuver tier badge
  ///
  /// In en, this message translates to:
  /// **'PACK'**
  String get tierPack;

  /// Unit type
  ///
  /// In en, this message translates to:
  /// **'Pawn'**
  String get pieceTypePawn;

  /// Unit type
  ///
  /// In en, this message translates to:
  /// **'Rook'**
  String get pieceTypeRook;

  /// Unit type
  ///
  /// In en, this message translates to:
  /// **'Knight'**
  String get pieceTypeKnight;

  /// Unit type
  ///
  /// In en, this message translates to:
  /// **'Bishop'**
  String get pieceTypeBishop;

  /// Unit type
  ///
  /// In en, this message translates to:
  /// **'Queen'**
  String get pieceTypeQueen;

  /// Unit type
  ///
  /// In en, this message translates to:
  /// **'King'**
  String get pieceTypeKing;

  /// Fleet name
  ///
  /// In en, this message translates to:
  /// **'Orbitron Vanguard'**
  String get fleetVanguard;

  /// Fleet name
  ///
  /// In en, this message translates to:
  /// **'Solar Crusade'**
  String get fleetSolarCrusade;

  /// Fleet name
  ///
  /// In en, this message translates to:
  /// **'Void Hive'**
  String get fleetVoidHive;

  /// Fleet name
  ///
  /// In en, this message translates to:
  /// **'Neon Runners'**
  String get fleetNeonRunners;

  /// Fleet name
  ///
  /// In en, this message translates to:
  /// **'Iron Armada'**
  String get fleetIronArmada;

  /// Fleet name
  ///
  /// In en, this message translates to:
  /// **'Crystal Choir'**
  String get fleetCrystalChoir;

  /// Fleet name
  ///
  /// In en, this message translates to:
  /// **'Ronin Blades'**
  String get fleetRoninBlades;

  /// Fleet name
  ///
  /// In en, this message translates to:
  /// **'Atomic Age'**
  String get fleetAtomicAge;

  /// Fleet name
  ///
  /// In en, this message translates to:
  /// **'Abyssal Tide'**
  String get fleetAbyssalTide;

  /// Fleet name
  ///
  /// In en, this message translates to:
  /// **'Star Nomads'**
  String get fleetStarNomads;

  /// Maneuver name
  ///
  /// In en, this message translates to:
  /// **'Sidestep'**
  String get maneuverSidestep;

  /// What the maneuver does
  ///
  /// In en, this message translates to:
  /// **'A quick step aside, matching the enemy\'s altitude.'**
  String get maneuverSidestepDesc;

  /// Maneuver name
  ///
  /// In en, this message translates to:
  /// **'Castle'**
  String get maneuverCastle;

  /// What the maneuver does
  ///
  /// In en, this message translates to:
  /// **'A long slide across the arena onto the enemy\'s altitude.'**
  String get maneuverCastleDesc;

  /// Maneuver name
  ///
  /// In en, this message translates to:
  /// **'Strike'**
  String get maneuverStrike;

  /// What the maneuver does
  ///
  /// In en, this message translates to:
  /// **'Climbs onto the enemy, fires twice and drops back.'**
  String get maneuverStrikeDesc;

  /// Maneuver name
  ///
  /// In en, this message translates to:
  /// **'Steamroller'**
  String get maneuverSteamroller;

  /// What the maneuver does
  ///
  /// In en, this message translates to:
  /// **'Grinds forward, firing all the way.'**
  String get maneuverSteamrollerDesc;

  /// Maneuver name
  ///
  /// In en, this message translates to:
  /// **'Retreat'**
  String get maneuverRetreat;

  /// What the maneuver does
  ///
  /// In en, this message translates to:
  /// **'Falls back to its own edge behind a shield.'**
  String get maneuverRetreatDesc;

  /// Maneuver name
  ///
  /// In en, this message translates to:
  /// **'Barrel Roll'**
  String get maneuverRoll;

  /// What the maneuver does
  ///
  /// In en, this message translates to:
  /// **'Rolls out of the way; shots pass through.'**
  String get maneuverRollDesc;

  /// Maneuver name
  ///
  /// In en, this message translates to:
  /// **'Feint'**
  String get maneuverFeint;

  /// What the maneuver does
  ///
  /// In en, this message translates to:
  /// **'Leans one way, cuts back the other and fires.'**
  String get maneuverFeintDesc;

  /// Maneuver name
  ///
  /// In en, this message translates to:
  /// **'Charged Shot'**
  String get maneuverChargedShot;

  /// What the maneuver does
  ///
  /// In en, this message translates to:
  /// **'Holds still, charges, and lands one heavy round.'**
  String get maneuverChargedShotDesc;

  /// Maneuver name
  ///
  /// In en, this message translates to:
  /// **'Volley'**
  String get maneuverVolley;

  /// What the maneuver does
  ///
  /// In en, this message translates to:
  /// **'Four rounds in a row from a standing ship.'**
  String get maneuverVolleyDesc;

  /// What the maneuver does
  ///
  /// In en, this message translates to:
  /// **'Two heavy rounds from a standing ship.'**
  String get maneuverVolleyHeavyDesc;

  /// Maneuver name
  ///
  /// In en, this message translates to:
  /// **'Slalom'**
  String get maneuverSlalom;

  /// What the maneuver does
  ///
  /// In en, this message translates to:
  /// **'Weaves across the enemy\'s altitude, firing throughout.'**
  String get maneuverSlalomDesc;

  /// Maneuver name
  ///
  /// In en, this message translates to:
  /// **'Dash'**
  String get maneuverDash;

  /// What the maneuver does
  ///
  /// In en, this message translates to:
  /// **'Crosses the arena at the enemy\'s altitude, firing.'**
  String get maneuverDashDesc;

  /// Maneuver name
  ///
  /// In en, this message translates to:
  /// **'Shadow'**
  String get maneuverShadow;

  /// What the maneuver does
  ///
  /// In en, this message translates to:
  /// **'Sticks to the enemy wherever it goes, firing steadily.'**
  String get maneuverShadowDesc;

  /// Maneuver name
  ///
  /// In en, this message translates to:
  /// **'Overdrive'**
  String get maneuverOverdrive;

  /// What the maneuver does
  ///
  /// In en, this message translates to:
  /// **'Keeps the helm, but the guns run hot for three seconds.'**
  String get maneuverOverdriveDesc;

  /// Maneuver name
  ///
  /// In en, this message translates to:
  /// **'Loop'**
  String get maneuverLoop;

  /// What the maneuver does
  ///
  /// In en, this message translates to:
  /// **'Over the top and down; shots pass under the ship.'**
  String get maneuverLoopDesc;

  /// Maneuver name
  ///
  /// In en, this message translates to:
  /// **'Corkscrew'**
  String get maneuverCorkscrew;

  /// What the maneuver does
  ///
  /// In en, this message translates to:
  /// **'Climbs and dives through a rolling spiral.'**
  String get maneuverCorkscrewDesc;

  /// Maneuver name
  ///
  /// In en, this message translates to:
  /// **'Double Step'**
  String get maneuverDoubleStep;

  /// What the maneuver does
  ///
  /// In en, this message translates to:
  /// **'Two hops forward, a burst after each.'**
  String get maneuverDoubleStepDesc;

  /// Maneuver name
  ///
  /// In en, this message translates to:
  /// **'Leap'**
  String get maneuverLeap;

  /// What the maneuver does
  ///
  /// In en, this message translates to:
  /// **'Jumps clear and lands a lane over, on the enemy.'**
  String get maneuverLeapDesc;

  /// Maneuver name
  ///
  /// In en, this message translates to:
  /// **'Sniper Shot'**
  String get maneuverSniperShot;

  /// What the maneuver does
  ///
  /// In en, this message translates to:
  /// **'Stands still for a second, then one devastating round.'**
  String get maneuverSniperShotDesc;

  /// Maneuver name
  ///
  /// In en, this message translates to:
  /// **'Bulwark'**
  String get maneuverBulwark;

  /// What the maneuver does
  ///
  /// In en, this message translates to:
  /// **'Shield up even on cooldown, three heavy rounds out.'**
  String get maneuverBulwarkDesc;

  /// Maneuver name
  ///
  /// In en, this message translates to:
  /// **'Royal Waltz'**
  String get maneuverRoyalWaltz;

  /// What the maneuver does
  ///
  /// In en, this message translates to:
  /// **'Sweeps the whole arena on the enemy\'s altitude.'**
  String get maneuverRoyalWaltzDesc;

  /// Maneuver name
  ///
  /// In en, this message translates to:
  /// **'Crown'**
  String get maneuverCrown;

  /// What the maneuver does
  ///
  /// In en, this message translates to:
  /// **'Holds the line behind a shield, every battery firing.'**
  String get maneuverCrownDesc;
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
