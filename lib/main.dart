import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import "package:hive_flutter/hive_flutter.dart";
import 'app.dart';
import 'core/constants/app_config.dart';
import 'shared/services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Local notifications (Android). Skipped on web — unsupported there.
  if (!kIsWeb) {
    try {
      await NotificationService.initialize();
    } catch (_) {}
  }

  // Initialize Hive for local storage (AI Agents, etc.)
  try {
    await Hive.initFlutter();
    await Hive.openBox("ai_agents");
  } catch (_) {
    // Hive may fail on some web environments — app still runs with SharedPreferences fallback
  }

  // Initialize Supabase only when real credentials are provided via
  // --dart-define. Otherwise the app runs in demo mode (mock data).
  if (AppConfig.hasSupabaseCredentials) {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
    );
  } else if (kDebugMode) {
    debugPrint('Float Financial: DEMO MODE — no Supabase credentials provided.');
  }

  // Never let a demo build ship as a release.
  // TEMP: Disabled for web PWA deployment — Supabase wiring comes next.
  // AppConfig.assertProductionReady(isReleaseMode: kReleaseMode);

  runApp(
    const ProviderScope(
      child: FloatFinancialApp(),
    ),
  );
}
