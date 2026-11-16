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
