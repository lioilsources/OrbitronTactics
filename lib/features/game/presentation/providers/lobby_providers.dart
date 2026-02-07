import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/game_repository.dart';

/// Provider for the Supabase client.
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

/// Provider for the game repository.
final gameRepositoryProvider = Provider<GameRepository>((ref) {
  return GameRepository(ref.watch(supabaseClientProvider));
});

/// Stream of waiting games.
final waitingGamesProvider = StreamProvider<List<GameLobbyEntry>>((ref) {
  final repo = ref.watch(gameRepositoryProvider);
  return repo.watchWaitingGames();
});
