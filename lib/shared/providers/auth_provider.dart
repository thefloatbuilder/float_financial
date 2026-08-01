import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/user_model.dart';
import '../services/supabase_service.dart';

final currentUserProvider = FutureProvider<UserModel?>((ref) async {
  return SupabaseService.getCurrentUser();
});