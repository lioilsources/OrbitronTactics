import '../../../core/game_logic/models/piece.dart';
import '../../../l10n/generated/app_localizations.dart';

/// Ship art for the battle arena: ten fleets, each drawing every unit type
/// in a white and a black variant. Sprites are bow-up PNGs in
/// `assets/fleets/<slug>/`.
enum FleetSkin {
  vanguard('vanguard', 'Orbitron Vanguard'),
  solarCrusade('solar_crusade', 'Solar Crusade'),
  voidHive('void_hive', 'Void Hive'),
  neonRunners('neon_runners', 'Neon Runners'),
  ironArmada('iron_armada', 'Iron Armada'),
  crystalChoir('crystal_choir', 'Crystal Choir'),
  roninBlades('ronin_blades', 'Ronin Blades'),
  atomicAge('atomic_age', 'Atomic Age'),
  abyssalTide('abyssal_tide', 'Abyssal Tide'),
  starNomads('star_nomads', 'Star Nomads');

  const FleetSkin(this.slug, this.displayName);

  /// Stable id: the asset folder name and what fleet progress stores.
  final String slug;
  final String displayName;

  /// The fleet flown when none is chosen.
  static const fallback = FleetSkin.vanguard;

  /// The fleet stored as [slug], or [fallback] for none or an unknown id.
  static FleetSkin fromSlug(String? slug) =>
      values.firstWhere((skin) => skin.slug == slug, orElse: () => fallback);

  /// The fleet's name as shown to the player.
  String localizedName(AppLocalizations l10n) => switch (this) {
        vanguard => l10n.fleetVanguard,
        solarCrusade => l10n.fleetSolarCrusade,
        voidHive => l10n.fleetVoidHive,
        neonRunners => l10n.fleetNeonRunners,
        ironArmada => l10n.fleetIronArmada,
        crystalChoir => l10n.fleetCrystalChoir,
        roninBlades => l10n.fleetRoninBlades,
        atomicAge => l10n.fleetAtomicAge,
        abyssalTide => l10n.fleetAbyssalTide,
        starNomads => l10n.fleetStarNomads,
      };

  /// The bow-up sprite of [type]'s ship in [color]'s variant.
  String assetFor(PieceType type, PlayerColor color) =>
      'assets/fleets/$slug/${type.name}_${color.name}.png';
}
