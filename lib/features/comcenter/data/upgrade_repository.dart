import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/game_logic/models/piece.dart';
import '../../../core/game_logic/models/upgrade_profile.dart';

class UpgradeRepository {
  final SupabaseClient _client;

  const UpgradeRepository(this._client);

  Future<({UpgradeProfile profile, int credits})> fetchProfile(
      String userId) async {
    final response = await _client
        .from('user_upgrades')
        .select('credits, upgrades')
        .eq('user_id', userId)
        .maybeSingle();

    if (response == null) {
      return (profile: UpgradeProfile.empty(), credits: 0);
    }

    final levelsRaw =
        (response['upgrades'] as Map<String, dynamic>?) ?? {};
    final levels = {
      for (final e in levelsRaw.entries)
        PieceType.values.firstWhere(
          (t) => t.name == e.key,
          orElse: () => PieceType.pawn,
        ): (e.value as num).toInt(),
    };

    return (
      profile: UpgradeProfile(levels: levels),
      credits: (response['credits'] as num?)?.toInt() ?? 0,
    );
  }

  Future<void> saveProfile({
    required String userId,
    required UpgradeProfile profile,
    required int credits,
  }) async {
    final levelsJson = {
      for (final e in profile.levels.entries) e.key.name: e.value,
    };

    await _client.from('user_upgrades').upsert({
      'user_id': userId,
      'credits': credits,
      'upgrades': levelsJson,
    });
  }
}
