import 'package:shared_preferences/shared_preferences.dart';

/// Which first-time explanations a player has already seen.
abstract class OnboardingStore {
  bool get howToPlaySeen;
  bool get battleHintSeen;
  Future<void> markHowToPlaySeen();
  Future<void> markBattleHintSeen();
}

class PrefsOnboardingStore implements OnboardingStore {
  PrefsOnboardingStore(this._prefs);

  final SharedPreferences _prefs;

  static const howToPlayKey = 'onboarding.how_to_play_seen';
  static const battleHintKey = 'onboarding.battle_hint_seen';

  @override
  bool get howToPlaySeen => _prefs.getBool(howToPlayKey) ?? false;

  @override
  bool get battleHintSeen => _prefs.getBool(battleHintKey) ?? false;

  @override
  Future<void> markHowToPlaySeen() => _prefs.setBool(howToPlayKey, true);

  @override
  Future<void> markBattleHintSeen() => _prefs.setBool(battleHintKey, true);
}

/// Everything already seen, for tests and previews; or nothing, to test
/// the first launch.
class MemoryOnboardingStore implements OnboardingStore {
  MemoryOnboardingStore({bool seen = true})
      : howToPlaySeen = seen,
        battleHintSeen = seen;

  @override
  bool howToPlaySeen;

  @override
  bool battleHintSeen;

  @override
  Future<void> markHowToPlaySeen() async => howToPlaySeen = true;

  @override
  Future<void> markBattleHintSeen() async => battleHintSeen = true;
}
