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

/// Whether the lobby lists open games. Watching them signs the install in,
/// so a player who never asked for online play stays without an account;
/// one who has played online before sees them right away.
final onlineLobbyProvider = StateProvider<bool>(
    (ref) => ref.watch(gameRepositoryProvider).isSignedIn);

/// Stream of waiting games.
final waitingGamesProvider = StreamProvider<List<GameLobbyEntry>>((ref) {
  final repo = ref.watch(gameRepositoryProvider);
  return repo.watchWaitingGames();
});
