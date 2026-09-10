import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants/supabase_constants.dart';
import 'features/game/presentation/screens/lobby_screen.dart';
import 'features/progress/data/fleet_progress_store.dart';
import 'features/progress/presentation/providers/fleet_progress_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConstants.url,
    anonKey: SupabaseConstants.anonKey,
  );
  final prefs = await SharedPreferences.getInstance();

  runApp(ProviderScope(
    overrides: [
      fleetProgressStoreProvider.overrideWithValue(FleetProgressStore(prefs)),
    ],
    child: const OrbitronTacticsApp(),
  ));
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
