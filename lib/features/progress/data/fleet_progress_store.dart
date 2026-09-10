import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/game_logic/models/fleet_progress.dart';

/// Keeps each fleet's progress on the device, one JSON blob per identity.
class FleetProgressStore {
  FleetProgressStore(this._prefs);

  final SharedPreferences _prefs;

  static String keyFor(String identity) => 'fleet_progress.$identity';

  /// The saved progress of [identity], or a fresh fleet when nothing
  /// readable is stored.
  FleetProgress load(String identity) {
    final raw = _prefs.getString(keyFor(identity));
    if (raw == null) return const FleetProgress();
    try {
      final json = jsonDecode(raw);
      if (json is Map<String, dynamic>) return FleetProgress.fromJson(json);
    } on FormatException {
      // An unreadable blob starts the fleet over instead of failing.
    }
    return const FleetProgress();
  }

  Future<void> save(String identity, FleetProgress progress) =>
      _prefs.setString(keyFor(identity), jsonEncode(progress.toJson()));
}
