import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants/release_constants.dart';
import 'core/constants/supabase_constants.dart';
import 'features/game/data/game_repository.dart';
import 'features/game/presentation/screens/lobby_screen.dart';
import 'features/onboarding/data/onboarding_store.dart';
import 'features/onboarding/presentation/onboarding_provider.dart';
import 'features/progress/data/fleet_progress_store.dart';
import 'features/progress/presentation/providers/fleet_progress_provider.dart';
import 'features/store/data/entitlements_store.dart';
import 'features/store/data/music_choice_store.dart';
import 'features/store/data/purchase_service.dart';
import 'features/store/data/revenuecat_purchase_service.dart';
import 'features/store/presentation/providers/store_providers.dart';
import 'features/telemetry/data/supabase_telemetry.dart';
import 'features/telemetry/presentation/telemetry_provider.dart';
import 'l10n/l10n.dart';

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

  final container = ProviderContainer(
    overrides: [
      fleetProgressStoreProvider.overrideWithValue(FleetProgressStore(prefs)),
      telemetryProvider.overrideWithValue(telemetry),
      purchaseServiceProvider.overrideWithValue(_purchaseService(prefs)),
      entitlementsStoreProvider
          .overrideWithValue(PrefsEntitlementsStore(prefs)),
      onboardingStoreProvider.overrideWithValue(PrefsOnboardingStore(prefs)),
      musicChoiceStoreProvider.overrideWithValue(PrefsMusicChoiceStore(prefs)),
    ],
  );

  void run() {
    runApp(UncontrolledProviderScope(
      container: container,
      child: const OrbitronTacticsApp(),
    ));
    telemetry.event('app_opened');
    // Purchases made on another device, refunds, payments that cleared.
    container.read(entitlementsProvider.notifier).sync();
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

/// RevenueCat when the build carries this platform's key, the free debug
/// store in debug builds, otherwise none.
PurchaseService _purchaseService(SharedPreferences prefs) {
  final key = switch (defaultTargetPlatform) {
    TargetPlatform.android => ReleaseConstants.revenueCatGoogleKey,
    TargetPlatform.iOS => ReleaseConstants.revenueCatAppleKey,
    _ => '',
  };
  if (key.isNotEmpty) return RevenueCatPurchaseService(key);
  if (kDebugMode) return DebugPurchaseService(prefs);
  return const UnavailablePurchaseService();
}

ThemeData orbitronTheme() => ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.indigo,
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
    );

class OrbitronTacticsApp extends StatelessWidget {
  /// [home], [locale] and [theme] are for the store screenshots; the app
  /// starts in the lobby, in the device's language, in [orbitronTheme].
  const OrbitronTacticsApp({
    super.key,
    this.home = const LobbyScreen(),
    this.locale,
    this.theme,
  });

  final Widget home;
  final Locale? locale;
  final ThemeData? theme;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OrbitronTactics',
      debugShowCheckedModeBanner: false,
      locale: locale,
      // The device's language when the app speaks it, else English.
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      localeListResolutionCallback: resolveAppLocale,
      theme: theme ?? orbitronTheme(),
      home: home,
    );
  }
}
