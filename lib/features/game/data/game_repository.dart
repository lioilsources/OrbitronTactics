import 'package:supabase_flutter/supabase_flutter.dart';

/// Manages game records in Supabase for lobby/matchmaking.
class GameRepository {
  final SupabaseClient _client;

  GameRepository(this._client);

  /// Create a new game and return its ID.
  Future<String> createGame({required String playerName}) async {
    final response = await _client
        .from('games')
        .insert({
          'status': 'waiting',
          'white_player_name': playerName,
        })
        .select('id')
        .single();
    return response['id'] as String;
  }

  /// Join an existing game as the black player.
  Future<void> joinGame({
    required String gameId,
    required String playerName,
  }) async {
    await _client.from('games').update({
      'black_player_name': playerName,
      'status': 'playing',
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', gameId);
  }

  /// List games waiting for a second player.
  Future<List<GameLobbyEntry>> listWaitingGames() async {
    final response = await _client
        .from('games')
        .select('id, white_player_name, created_at')
        .eq('status', 'waiting')
        .order('created_at', ascending: false)
        .limit(20);

    return (response as List)
        .map((row) => GameLobbyEntry(
              gameId: row['id'] as String,
              hostName: row['white_player_name'] as String? ?? 'Unknown',
              createdAt: DateTime.parse(row['created_at'] as String),
            ))
        .toList();
  }

  /// Mark a game as finished.
  Future<void> finishGame(String gameId) async {
    await _client.from('games').update({
      'status': 'finished',
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', gameId);
  }

  /// Stream of waiting games (realtime updates).
  Stream<List<GameLobbyEntry>> watchWaitingGames() {
    return _client
        .from('games')
        .stream(primaryKey: ['id'])
        .eq('status', 'waiting')
        .order('created_at', ascending: false)
        .map((rows) => rows
            .map((row) => GameLobbyEntry(
                  gameId: row['id'] as String,
                  hostName: row['white_player_name'] as String? ?? 'Unknown',
                  createdAt: DateTime.parse(row['created_at'] as String),
                ))
            .toList());
  }
}

class GameLobbyEntry {
  final String gameId;
  final String hostName;
  final DateTime createdAt;

  const GameLobbyEntry({
    required this.gameId,
    required this.hostName,
    required this.createdAt,
  });
}
