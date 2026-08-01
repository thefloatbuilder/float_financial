import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/alert_model.dart';
import '../services/supabase_service.dart';

final alertsProvider = FutureProvider.family<List<AlertModel>, String>((ref, userId) async {
  return SupabaseService.getUserAlerts(userId);
});