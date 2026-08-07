/// Central app configuration.
///
/// Supabase credentials are injected at build/run time via --dart-define:
///   flutter run -d chrome \
///     --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
///     --dart-define=SUPABASE_ANON_KEY=eyJ...
///
/// If they are missing (or still the placeholder values), the app runs in
/// DEMO MODE: SupabaseService serves realistic mock data and the login
/// screen shows a demo-mode banner. Production builds MUST pass real
/// credentials — [AppConfig.assertProductionReady] guards this.
class AppConfig {
  // Real project credentials (Paul's float-financial project, created 2026-08-06).
  // These are PUBLIC client credentials — safe to ship. The anon key is only
  // usable with Row-Level Security policies; never put the service_role key here.
  static const String _defaultUrl = 'https://spzpumfmrtnqcoahzzub.supabase.co';
  static const String _defaultAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNwenB1bWZtcnRucWNvYWh6enViIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODQ5Mjc2MDgsImV4cCI6MjEwMDUwMzYwOH0.0bbXvIXl80nBLjAEwOmyOtsUsS2Vhc3KkFXoTzYMZ1E';

  static const String supabaseUrl =
      String.fromEnvironment('SUPABASE_URL', defaultValue: _defaultUrl);
  static const String supabaseAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: _defaultAnonKey);

  /// True when real Supabase credentials were provided at build time.
  static bool get hasSupabaseCredentials =>
      supabaseUrl.isNotEmpty &&
      supabaseUrl.startsWith('https://') &&
      !supabaseUrl.contains('xxxx') &&
      supabaseAnonKey.isNotEmpty &&
      supabaseAnonKey.length > 40 &&
      !supabaseAnonKey.contains('...');

  /// True when running with mock data (no real backend wired up).
  static bool get isDemoMode => !hasSupabaseCredentials;

  /// Call after Supabase.initialize in main(). Throws in release builds if
  /// credentials are missing so a demo build can never ship by accident.
  static void assertProductionReady({required bool isReleaseMode}) {
    if (isReleaseMode && isDemoMode) {
      throw StateError(
        'Float Financial release build started without Supabase credentials. '
        'Build with --dart-define=SUPABASE_URL=... and '
        '--dart-define=SUPABASE_ANON_KEY=...',
      );
    }
  }
}
