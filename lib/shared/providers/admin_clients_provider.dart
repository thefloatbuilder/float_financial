import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/supabase_service.dart';

final adminClientsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return SupabaseService.getAllClients();
});