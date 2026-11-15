import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/piece_skin.dart';

/// The board's look: which piece skin is drawn and whether image pieces
/// carry a small classic chess glyph.
class PieceSkinSettings {
  const PieceSkinSettings({
    this.skin = PieceSkin.fallback,
    this.classicMarks = false,
  });

  final PieceSkin skin;
  final bool classicMarks;

  PieceSkinSettings copyWith({PieceSkin? skin, bool? classicMarks}) =>
      PieceSkinSettings(
        skin: skin ?? this.skin,
        classicMarks: classicMarks ?? this.classicMarks,
      );

  @override
  bool operator ==(Object other) =>
      other is PieceSkinSettings &&
      other.skin == skin &&
      other.classicMarks == classicMarks;

  @override
  int get hashCode => Object.hash(skin, classicMarks);
}

/// Keeps the board's look on the device.
class PieceSkinStore {
  PieceSkinStore(this._prefs);

  final SharedPreferences _prefs;

  static const skinKey = 'piece_skin';
  static const classicMarksKey = 'piece_skin_classic_marks';

  PieceSkinSettings load() => PieceSkinSettings(
        skin: PieceSkin.fromSlug(_prefs.getString(skinKey)),
        classicMarks: _prefs.getBool(classicMarksKey) ?? false,
      );

  Future<void> save(PieceSkinSettings settings) async {
    await _prefs.setString(skinKey, settings.skin.slug);
    await _prefs.setBool(classicMarksKey, settings.classicMarks);
  }
}

/// Device storage for the board's look. `main()` overrides it once
/// SharedPreferences has loaded; without it the choice lives only in memory.
final pieceSkinStoreProvider = Provider<PieceSkinStore?>((ref) => null);

/// The board's look. Every change is saved right away.
class PieceSkinNotifier extends StateNotifier<PieceSkinSettings> {
  PieceSkinNotifier(this._store)
      : super(_store?.load() ?? const PieceSkinSettings());

  final PieceSkinStore? _store;

  @override
  set state(PieceSkinSettings value) {
    super.state = value;
    final store = _store;
    if (store != null) unawaited(store.save(value));
  }

  void select(PieceSkin skin) => state = state.copyWith(skin: skin);

  void setClassicMarks(bool on) => state = state.copyWith(classicMarks: on);
}

/// The look of the board, shared by every game mode.
final pieceSkinProvider =
    StateNotifierProvider<PieceSkinNotifier, PieceSkinSettings>(
  (ref) => PieceSkinNotifier(ref.watch(pieceSkinStoreProvider)),
);
