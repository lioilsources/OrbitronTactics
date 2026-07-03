import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbitron_tactics/features/game/presentation/providers/connectivity_providers.dart';

void main() {
  ProviderContainer withConnectivity(List<ConnectivityResult> results) {
    final container = ProviderContainer(overrides: [
      connectivityProvider.overrideWith((ref) => Stream.value(results)),
    ]);
    addTearDown(container.dispose);
    return container;
  }

  Future<bool> localAllowed(List<ConnectivityResult> results) async {
    final container = withConnectivity(results);
    // Wait for the stream's first value to land in the provider.
    await container.read(connectivityProvider.future);
    return container.read(localPlayAllowedProvider);
  }

  group('localPlayAllowedProvider', () {
    test('cellular-only data allows turn-based play only', () async {
      expect(await localAllowed([ConnectivityResult.mobile]), isFalse);
    });

    test('wifi enables local co-op', () async {
      expect(await localAllowed([ConnectivityResult.wifi]), isTrue);
    });

    test('ethernet counts as a local network', () async {
      expect(await localAllowed([ConnectivityResult.ethernet]), isTrue);
    });

    test('wifi + cellular still allows local co-op', () async {
      expect(
        await localAllowed(
            [ConnectivityResult.wifi, ConnectivityResult.mobile]),
        isTrue,
      );
    });

    test('no connectivity (or not yet known) blocks local co-op', () async {
      expect(await localAllowed([ConnectivityResult.none]), isFalse);
    });
  });
}
