/// Supabase connection constants.
/// Passed via --dart-define at build time, or defaults to local dev values.
///
/// Usage:
///   flutter run \
///     --dart-define=SUPABASE_URL=https://xxx.supabase.co \
///     --dart-define=SUPABASE_ANON_KEY=your-key
class SupabaseConstants {
  const SupabaseConstants._();

  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://sgyqrkaajmgpyutmmyqj.supabase.co',
  );

  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_rcIp_1oaBpuuoBRO2UshNA_WvWfUiuf',
  );
}
