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
}
