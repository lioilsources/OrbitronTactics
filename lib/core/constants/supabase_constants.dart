/// Supabase connection constants.
/// These default to local dev (supabase start) values.
/// Override via environment or .env for production.
class SupabaseConstants {
  const SupabaseConstants._();

  /// Local Supabase URL (supabase start).
  static const String localUrl = 'http://127.0.0.1:54321';

  /// Local Supabase anon key (supabase start default).
  /// This is the standard local dev key, not a secret.
  static const String localAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0';

  /// Current URL (swap for production later).
  static String get url => localUrl;

  /// Current anon key (swap for production later).
  static String get anonKey => localAnonKey;
}
