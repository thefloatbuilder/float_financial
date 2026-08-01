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
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY');

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
