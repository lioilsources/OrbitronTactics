import 'package:shared_preferences/shared_preferences.dart';

/// The battle music the player picked, by slug.
abstract class MusicChoiceStore {
  String? load();
  Future<void> save(String slug);
}

class PrefsMusicChoiceStore implements MusicChoiceStore {
  PrefsMusicChoiceStore(this._prefs);

  final SharedPreferences _prefs;

  static const key = 'battle_music';

  @override
  String? load() => _prefs.getString(key);

  @override
  Future<void> save(String slug) => _prefs.setString(key, slug);
}

class MemoryMusicChoiceStore implements MusicChoiceStore {
  String? _slug;

  @override
  String? load() => _slug;

  @override
  Future<void> save(String slug) async => _slug = slug;
}
