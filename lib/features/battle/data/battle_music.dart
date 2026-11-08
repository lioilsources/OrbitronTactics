import '../../../core/game_logic/models/piece.dart';

/// A set of battle themes, one per attacking unit type.
enum BattleMusic {
  /// The orchestral and electronic themes every player has.
  standard('standard', 'Standard', 'music'),

  /// Every theme again as 1980s console chiptune, from
  /// `tools/battle_audio/chiptune.py`.
  retro('retro', 'Retro Arcade', 'music_retro', premium: true);

  const BattleMusic(this.slug, this.displayName, this.folder,
      {this.premium = false});

  /// Stable id: what the setting stores.
  final String slug;
  final String displayName;

  /// Folder under `assets/audio/`.
  final String folder;

  /// Sold in the store.
  final bool premium;

  static BattleMusic fromSlug(String? slug) => values.firstWhere(
      (music) => music.slug == slug,
      orElse: () => BattleMusic.standard);

  /// The theme played while [attacker] attacks.
  String theme(PieceType attacker) =>
      'assets/audio/$folder/${attacker.name}.ogg';
}
