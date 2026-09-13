import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/game_logic/models/piece.dart';
import '../../data/battle_element.dart';
import '../../data/battle_sounds.dart';
import 'battle_sound_cues.dart';

/// Plays a battle's sound with SoLoud: the attacker's theme on a loop, a
/// shot for every shot fired, the head of an explosion for every impact and
/// the whole echoing explosion when a ship is destroyed.
///
/// Sound is a nicety, so nothing here may break a battle: a failure — no
/// audio device, a missing asset — is logged and the arena stays quiet.
class BattleAudio {
  BattleAudio._();

  static final instance = BattleAudio._();

  static const _mutedKey = 'battle_audio_muted';

  static const double _musicVolume = 0.45;
  static const double _shotVolume = 0.5;
  static const _musicFadeIn = Duration(milliseconds: 800);
  static const _musicFadeOut = Duration(milliseconds: 1800);

  /// An impact plays only this much of its explosion, so rapid hits do not
  /// pile their echoes up; a destroyed ship gets the whole tail.
  static const _impactLength = Duration(milliseconds: 450);

  /// Shortest gap between two plays of one sound. Faster repeats smear into
  /// a wash that buries everything else.
  static const _minShotGap = Duration(milliseconds: 60);
  static const _minImpactGap = Duration(milliseconds: 120);

  final _random = Random();
  final Map<String, AudioSource> _effects = {};
  final Map<String, int> _lastPlayedMs = {};
  AudioSource? _music;
  SoundHandle? _musicHandle;
  Future<bool>? _ready;
  bool _muted = false;

  /// Counts battles started and stopped, so a slow start that is overtaken
  /// by a stop never brings the music back.
  int _generation = 0;

  bool get muted => _muted;

  SoLoud get _soloud => SoLoud.instance;

  Future<bool> _init() => _ready ??= () async {
        try {
          final prefs = await SharedPreferences.getInstance();
          _muted = prefs.getBool(_mutedKey) ?? false;
          if (!_soloud.isInitialized) await _soloud.init();
          _soloud.setGlobalVolume(_muted ? 0 : 1);
          return true;
        } catch (error) {
          _log('init', error);
          return false;
        }
      }();

  /// Starts [attacker]'s theme and loads the effects of [elements].
  Future<void> start({
    required PieceType attacker,
    required Set<BattleElement> elements,
  }) async {
    final generation = ++_generation;
    if (!await _init()) return;
    await _stopMusic(fade: Duration.zero);
    try {
      for (final element in elements) {
        await _load(BattleSounds.shot(element));
        await _load(BattleSounds.explosion(element));
      }
      final music = await _soloud.loadAsset(
        BattleSounds.music(attacker),
        mode: LoadMode.disk,
      );
      if (generation != _generation) {
        await _soloud.disposeSource(music);
        return;
      }
      _music = music;
      final handle = _soloud.play(music, volume: 0, looping: true);
      _musicHandle = handle;
      _soloud.fadeVolume(handle, _musicVolume, _musicFadeIn);
    } catch (error) {
      _log('start', error);
    }
  }

  /// Plays what happened between two battle states.
  void play(BattleSoundCues cues) {
    if (cues.isEmpty) return;
    try {
      // Reaching the engine at all can fail where there is no native
      // library, so even this check belongs inside the guard.
      if (!_soloud.isInitialized) return;
      for (final element in cues.shots) {
        _fire(BattleSounds.shot(element), _shotVolume * _jitter(), _minShotGap);
      }
      for (final impact in cues.impacts) {
        final strength = (impact.damage / 40).clamp(0.2, 1.0);
        final volume = (0.25 + 0.4 * strength) *
            (impact.shielded ? 0.6 : 1.0) *
            _jitter();
        final handle = _fire(
            BattleSounds.explosion(impact.element), volume, _minImpactGap);
        if (handle != null) {
          _soloud.fadeVolume(handle, 0, _impactLength);
          _soloud.scheduleStop(handle, _impactLength);
        }
      }
      final destroyed = cues.destroyed;
      if (destroyed != null) {
        _fire(BattleSounds.explosion(destroyed), 1, Duration.zero);
        unawaited(_stopMusic(fade: _musicFadeOut));
      }
    } catch (error) {
      _log('play', error);
    }
  }

  /// Fades the theme out; call when the battle screen closes.
  Future<void> stop() {
    _generation++;
    return _stopMusic(fade: _musicFadeOut);
  }

  Future<void> toggleMute() async {
    _muted = !_muted;
    if (_soloud.isInitialized) _soloud.setGlobalVolume(_muted ? 0 : 1);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_mutedKey, _muted);
  }

  Future<void> _load(String asset) async {
    if (_effects.containsKey(asset)) return;
    _effects[asset] = await _soloud.loadAsset(asset);
  }

  SoundHandle? _fire(String asset, double volume, Duration minGap) {
    final source = _effects[asset];
    if (source == null) return null;
    final now = DateTime.now().millisecondsSinceEpoch;
    final last = _lastPlayedMs[asset];
    if (last != null && now - last < minGap.inMilliseconds) return null;
    _lastPlayedMs[asset] = now;
    return _soloud.play(source, volume: volume.clamp(0.0, 1.0));
  }

  Future<void> _stopMusic({required Duration fade}) async {
    final handle = _musicHandle;
    final music = _music;
    _musicHandle = null;
    _music = null;
    if (handle == null || music == null) return;
    try {
      if (fade > Duration.zero) {
        _soloud.fadeVolume(handle, 0, fade);
        await Future<void>.delayed(fade);
      }
      await _soloud.disposeSource(music);
    } catch (error) {
      _log('stop music', error);
    }
  }

  /// A little volume variation, so repeated shots aren't machine-stamped.
  double _jitter() => 0.9 + 0.2 * _random.nextDouble();

  void _log(String what, Object error) =>
      debugPrint('BattleAudio: $what failed: $error');
}
