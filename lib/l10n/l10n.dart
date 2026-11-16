import 'package:flutter/widgets.dart';

import 'generated/app_localizations.dart';

export 'game_l10n.dart';
export 'generated/app_localizations.dart';

extension AppLocalizationsContext on BuildContext {
  /// The app's strings; English where no localizations are installed above
  /// this context, such as a bare MaterialApp in a test.
  AppLocalizations get l10n =>
      AppLocalizations.of(this) ?? lookupAppLocalizations(const Locale('en'));
}
