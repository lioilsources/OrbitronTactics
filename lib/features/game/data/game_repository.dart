import 'package:supabase_flutter/supabase_flutter.dart';

/// Manages game records in Supabase for lobby/matchmaking.
///
/// Every call signs the install in anonymously first: the games table only
/// lets signed-in players in, and a game belongs to the uids of its two
/// players (see the `games_owned_by_players` migration).
class GameRepository {
  final SupabaseClient _client;

  GameRepository(this._client);

  /// Network protocol of this build. Bump it whenever a [GameEvent] changes
  /// in a way an older build cannot read: the lobby lists only games opened
  /// by the same protocol.
  static const protocol = 1;

  /// Signs this install in anonymously unless it already has a session. The
  /// session is kept on the device, so one install stays one player.
  Future<void> ensureSignedIn() async {
    if (_client.auth.currentSession != null) return;
    await _client.auth.signInAnonymously();
  }

  /// Create a new game and return its ID.
  Future<String> createGame({required String playerName}) async {
    await ensureSignedIn();
    final response = await _client
        .from('games')
        .insert({
          'status': 'waiting',
          'white_player_name': playerName,
          'protocol': protocol,
        })
        .select('id')
        .single();
    return response['id'] as String;
  }

  /// Join an existing game as the black player. Throws [GameNotOpen] when
  /// someone else took the seat first or the game is gone.
  Future<void> joinGame({
    required String gameId,
    required String playerName,
  }) async {
    await ensureSignedIn();
    final joined = await _client.rpc<bool>('join_game', params: {
      'p_game_id': gameId,
      'p_player_name': playerName,
    });
    if (joined != true) throw const GameNotOpen();
  }

  /// List games waiting for a second player.
  Future<List<GameLobbyEntry>> listWaitingGames() async {
    await ensureSignedIn();
    final response = await _client
        .from('games')
        .select('id, white_player_name, created_at')
        .eq('status', 'waiting')
        .eq('protocol', protocol)
        .order('created_at', ascending: false)
        .limit(20);

    return (response as List).map(_entry).toList();
  }

  /// Mark a game as finished.
  Future<void> finishGame(String gameId) async {
    await ensureSignedIn();
    await _client.from('games').update({
      'status': 'finished',
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', gameId);
  }

  /// Stream of waiting games (realtime updates).
  Stream<List<GameLobbyEntry>> watchWaitingGames() async* {
    await ensureSignedIn();
    // A realtime stream takes one filter; the protocol is checked here.
    yield* _client
        .from('games')
        .stream(primaryKey: ['id'])
        .eq('status', 'waiting')
        .order('created_at', ascending: false)
        .map((rows) => rows
            .where((row) => row['protocol'] == protocol)
            .map(_entry)
            .toList());
  }

  static GameLobbyEntry _entry(dynamic row) => GameLobbyEntry(
        gameId: row['id'] as String,
        hostName: row['white_player_name'] as String? ?? 'Unknown',
        createdAt: DateTime.parse(row['created_at'] as String),
      );
}

/// The game was taken by another player or no longer exists.
class GameNotOpen implements Exception {
  const GameNotOpen();

  @override
  String toString() => 'That game is no longer open';
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
