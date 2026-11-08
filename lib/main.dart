import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants/release_constants.dart';
import 'core/constants/supabase_constants.dart';
import 'features/game/data/game_repository.dart';
import 'features/game/presentation/screens/lobby_screen.dart';
import 'features/progress/data/fleet_progress_store.dart';
import 'features/progress/presentation/providers/fleet_progress_provider.dart';
import 'features/telemetry/data/supabase_telemetry.dart';
import 'features/telemetry/presentation/telemetry_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConstants.url,
    anonKey: SupabaseConstants.anonKey,
  );
  final prefs = await SharedPreferences.getInstance();
  final info = await PackageInfo.fromPlatform();
  final client = Supabase.instance.client;
  final telemetry = SupabaseTelemetry(
    client,
    appVersion: '${info.version}+${info.buildNumber}',
    ensureSignedIn: GameRepository(client).ensureSignedIn,
  );

  void run() {
    runApp(ProviderScope(
      overrides: [
        fleetProgressStoreProvider.overrideWithValue(FleetProgressStore(prefs)),
        telemetryProvider.overrideWithValue(telemetry),
      ],
      child: const OrbitronTacticsApp(),
    ));
    telemetry.event('app_opened');
  }

  if (ReleaseConstants.sentryDsn.isEmpty) {
    run();
    return;
  }
  await SentryFlutter.init(
    (options) {
      options.dsn = ReleaseConstants.sentryDsn;
      // Crashes and errors only: no performance tracing, no personal data.
      options.tracesSampleRate = 0;
      options.sendDefaultPii = false;
    },
    appRunner: run,
  );
}

class OrbitronTacticsApp extends StatelessWidget {
  const OrbitronTacticsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OrbitronTactics',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const LobbyScreen(),
    );
  }
}
