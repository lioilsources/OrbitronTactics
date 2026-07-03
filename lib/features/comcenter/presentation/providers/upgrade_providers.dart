import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/game_logic/models/upgrade_profile.dart';
import '../../data/upgrade_repository.dart';

/// The local player's unit upgrade levels. Session-scoped; loaded from and
/// persisted to Supabase only when a user is signed in (local co-op stays
/// fully offline otherwise).
final upgradeProfileProvider =
    StateProvider<UpgradeProfile>((ref) => UpgradeProfile.empty());

/// Credits the local player can spend on upgrades in the ComCenter.
final playerCreditsProvider = StateProvider<int>((ref) => 0);

final upgradeRepositoryProvider =
    Provider<UpgradeRepository>((ref) => UpgradeRepository(Supabase.instance.client));

/// Persist the current profile + credits for the signed-in user, if any.
Future<void> persistUpgrades(WidgetRef ref) async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return;
  await ref.read(upgradeRepositoryProvider).saveProfile(
        userId: userId,
        profile: ref.read(upgradeProfileProvider),
        credits: ref.read(playerCreditsProvider),
      );
}

/// Load the persisted profile + credits for the signed-in user, if any.
Future<void> loadUpgrades(WidgetRef ref) async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return;
  final data = await ref.read(upgradeRepositoryProvider).fetchProfile(userId);
  ref.read(upgradeProfileProvider.notifier).state = data.profile;
  ref.read(playerCreditsProvider.notifier).state = data.credits;
}
