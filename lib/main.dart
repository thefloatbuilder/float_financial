import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import "package:hive_flutter/hive_flutter.dart";
import 'app.dart';
import 'core/constants/app_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive for local storage (AI Agents, etc.)
  await Hive.initFlutter();
  await Hive.openBox("ai_agents");

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
  AppConfig.assertProductionReady(isReleaseMode: kReleaseMode);

  runApp(
    const ProviderScope(
      child: FloatFinancialApp(),
    ),
  );
}
