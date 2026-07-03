import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Current connectivity, seeded with an initial check and kept live.
final connectivityProvider =
    StreamProvider<List<ConnectivityResult>>((ref) async* {
  final connectivity = Connectivity();
  yield await connectivity.checkConnectivity();
  yield* connectivity.onConnectivityChanged;
});

/// Local co-op (nearby battles) requires a local network — wifi or ethernet.
/// On cellular-only connections the game is turn-based cloud play only.
final localPlayAllowedProvider = Provider<bool>((ref) {
  final results =
      ref.watch(connectivityProvider).valueOrNull ?? const <ConnectivityResult>[];
  return results.contains(ConnectivityResult.wifi) ||
      results.contains(ConnectivityResult.ethernet);
});
