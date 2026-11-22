import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'entitlements.dart';

/// Where entitlements are cached between launches, so purchases work
/// offline. The store stays the source of truth: every sync overwrites the
/// products.
abstract class EntitlementsStore {
  /// The cached entitlements, or null on the first launch with a store.
  Entitlements? load();

  Future<void> save(Entitlements entitlements);
}

class PrefsEntitlementsStore implements EntitlementsStore {
  PrefsEntitlementsStore(this._prefs);

  final SharedPreferences _prefs;

  static const key = 'store.entitlements';

  @override
  Entitlements? load() {
    final raw = _prefs.getString(key);
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw);
      if (json is Map<String, dynamic>) return Entitlements.fromJson(json);
    } on FormatException {
      // Unreadable: the next sync rebuilds it from the store.
    }
    return const Entitlements();
  }

  @override
  Future<void> save(Entitlements entitlements) =>
      _prefs.setString(key, jsonEncode(entitlements.toJson()));
}

/// Keeps entitlements for the app session only: tests and previews.
class MemoryEntitlementsStore implements EntitlementsStore {
  MemoryEntitlementsStore([this._saved]);

  Entitlements? _saved;

  @override
  Entitlements? load() => _saved;

  @override
  Future<void> save(Entitlements entitlements) async => _saved = entitlements;
}
