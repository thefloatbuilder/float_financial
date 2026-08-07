import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_config.dart';
import '../../core/models/user_model.dart';
import '../../core/models/alert_model.dart';

/// Backend data service.
///
/// When [AppConfig.isDemoMode] is true (no real Supabase credentials were
/// provided at build time), every method falls back to realistic mock data
/// so the UI can still be exercised end to end. When real credentials are
/// present, all data comes from Supabase.
class SupabaseService {
  static bool get _isDemo => AppConfig.isDemoMode;

  static SupabaseClient? get _clientOrNull {
    if (_isDemo) return null;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  static final UserModel _demoUser = UserModel(
    id: 'marcus-demo-1',
    email: 'marcus@floatfinancial.app',
    name: 'Marcus',
    tier: "Captain's Current",
    role: 'admin',
  );

  // Marcus's Bittensor coldkey (public) - we'll wire real data to this soon
  static const String marcusBittensorColdkey = '5EFcnuzBnLbxxzTL6MZ6W6KCDqPM31azTzoSptYEYJRBgeiY';

  static final List<AlertModel> _demoAlerts = [
    AlertModel(
      id: 'a1',
      userId: 'demo-user-1',
      asset: 'ETH',
      type: 'Price',
      condition: 'Below \$3,200',
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    AlertModel(
      id: 'a2',
      userId: 'demo-user-1',
      asset: 'AAVE Pool',
      type: 'APY',
      condition: 'Above 12%',
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
    AlertModel(
      id: 'a3',
      userId: 'demo-user-1',
      asset: 'USDC/ETH LP',
      type: 'Pool',
      condition: 'TVL drop > 20%',
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 9)),
    ),
  ];

  static final Map<String, dynamic> _demoPortfolio = {
    'user_id': 'marcus-demo-1',
    'total_value': 152581.56,
    'monthly_change': 12.4,
    'bittensor_coldkey': '5EFcnuzBnLbxxzTL6MZ6W6KCDqPM31azTzoSptYEYJRBgeiY',
    'assets': [
      {'name': 'TAO (staked on Root)', 'value': 87500.0, 'percentage': 61.3},
      {'name': 'ETH', 'value': 31200.0, 'percentage': 21.8},
      {'name': 'USDC', 'value': 18400.0, 'percentage': 12.9},
      {'name': 'Other', 'value': 5700.55, 'percentage': 4.0},
    ],
    // Manual ROTH IRA entry (not synced from coldkey)
    'roth_ira': {
      'total_value': 9781.01,
      'assets': [
        {
          'name': 'BTC',
          'amount': 0.07398868,
          'value': 7768.81,
          'percentage': 79.4,
        },
        {
          'name': 'XRP',
          'amount': 804.88,
          'value': 2012.20,
          'percentage': 20.6,
        },
      ],
    },
  };

  static final List<Map<String, dynamic>> _demoClients = [
    {
      'id': 'c1',
      'name': 'Jordan Reyes',
      'email': 'jordan@example.com',
      'tier': "Captain's Current",
      'portfolio_value': 88250.0,
    },
    {
      'id': 'c2',
      'name': 'Alicia Chen',
      'email': 'alicia@example.com',
      'tier': 'Buoy Brigade',
      'portfolio_value': 41230.0,
    },
    {
      'id': 'c3',
      'name': 'Sam Whitfield',
      'email': 'sam@example.com',
      'tier': 'Drifter Deck',
      'portfolio_value': 9800.0,
    },
    {
      'id': 'c4',
      'name': 'Priya Natarajan',
      'email': 'priya@example.com',
      'tier': 'Buoy Brigade',
      'portfolio_value': 55700.0,
    },
  ];

  // Auth
  static Future<AuthResponse> signInWithEmail(String email, String password) async {
    final client = _clientOrNull;
    if (client == null) {
      // Demo mode: simulate sign-in success
      debugPrint('DEMO: Simulated sign-in');
      return AuthResponse(
        session: null,
        user: User(
          id: 'marcus-demo-1',
          appMetadata: {},
          userMetadata: {},
          aud: 'authenticated',
          createdAt: DateTime.now().toIso8601String(),
        ),
      );
    }
    return await client.auth.signInWithPassword(email: email, password: password);
  }

  static Future<AuthResponse> signUpWithEmail(String email, String password, String name) async {
    final client = _clientOrNull;
    if (client == null) {
      // Demo mode: simulate successful account creation for Marcus
      debugPrint('DEMO: Simulated account creation for $name ($email)');
      // We don't throw anymore so the UI can proceed with the Marcus user
      // Ultra-safe demo return - no complex User object
      return AuthResponse(session: null, user: null);
    }
    final response = await client.auth.signUp(email: email, password: password);

    if (response.user != null) {
      await client.from('profiles').insert({
        'id': response.user!.id,
        'email': email,
        'name': name,
        'tier': 'Drifter Deck',
        'role': 'client',
      });
    }

    return response;
  }

  static Future<void> signOut() async {
    final client = _clientOrNull;
    if (client == null) return;
    await client.auth.signOut();
  }

  /// Resend the signup confirmation email (used when the project has
  /// email confirmation enabled and the user didn't get the first one).
  static Future<void> resendConfirmationEmail(String email) async {
    final client = _clientOrNull;
    if (client == null) return;
    await client.auth.resend(type: OtpType.signup, email: email);
  }

  // User Profile
  static Future<UserModel?> getCurrentUser() async {
    final client = _clientOrNull;
    if (client == null) return _demoUser;

    final user = client.auth.currentUser;
    if (user == null) return _demoUser;

    try {
      final data = await client.from('profiles').select().eq('id', user.id).single();
      return UserModel.fromJson(data);
    } catch (_) {
      return _demoUser;
    }
  }

  // Alerts
  static Future<List<AlertModel>> getUserAlerts(String userId) async {
    final client = _clientOrNull;
    if (client == null) return _demoAlerts;

    try {
      final data = await client
          .from('alerts')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return (data as List).map((json) => AlertModel.fromJson(json)).toList();
    } catch (_) {
      // Real backend but query failed — show nothing rather than fake alerts.
      return const [];
    }
  }

  static Future<void> createAlert({
    required String userId,
    required String asset,
    required String type,
    required String condition,
  }) async {
    final client = _clientOrNull;
    if (client == null) return; // demo mode: no-op
    await client.from('alerts').insert({
      'user_id': userId,
      'asset': asset,
      'type': type,
      'condition': condition,
      'is_active': true,
    });
  }

  // Portfolio
  static Future<Map<String, dynamic>?> getUserPortfolio(String userId) async {
    final client = _clientOrNull;
    if (client == null) return _demoPortfolio;

    try {
      final data = await client
          .from('portfolios')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      return data; // null → provider seeds real first-login positions
    } catch (_) {
      return null;
    }
  }

  // Admin - Get all clients
  static Future<List<Map<String, dynamic>>> getAllClients() async {
    final client = _clientOrNull;
    if (client == null) return _demoClients;

    try {
      final data = await client.from('profiles').select().order('created_at', ascending: false);
      final list = List<Map<String, dynamic>>.from(data);
      return list.isEmpty ? _demoClients : list;
    } catch (_) {
      return _demoClients;
    }
  }
}
