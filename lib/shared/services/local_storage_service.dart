import "package:hive_flutter/hive_flutter.dart";
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Simple local persistence for demo features (ROTH IRA, snapshots).
/// No real backend needed. Survives app restarts.
class LocalStorageService {
  static const String _rothKey = 'roth_ira_data';
  static const String _snapshotsKey = 'portfolio_snapshots';
  static const String _onboardedKey = 'has_completed_onboarding';

  /// Whether this device has already seen the onboarding flow.
  static Future<bool> hasCompletedOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardedKey) ?? false;
  }

  static Future<void> markOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardedKey, true);
  }

  static Future<Map<String, dynamic>?> loadRothIra() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_rothKey);
    if (jsonStr == null) return null;
    try {
      return jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveRothIra(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_rothKey, jsonEncode(data));
  }

  static Future<List<Map<String, dynamic>>> loadSnapshots() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_snapshotsKey);
    if (jsonStr == null) return [];
    try {
      final list = jsonDecode(jsonStr) as List;
      return list.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveSnapshot(Map<String, dynamic> snapshot) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = await loadSnapshots();
    existing.insert(0, {
      ...snapshot,
      'saved_at': DateTime.now().toIso8601String(),
    });
    // Keep only last 10
    final trimmed = existing.take(10).toList();
    await prefs.setString(_snapshotsKey, jsonEncode(trimmed));
  }


  static const String _aiAgentsKey = 'ai_agents_data';

  static Future<List<Map<String, dynamic>>> loadAIAgents() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_aiAgentsKey);
    if (jsonStr == null) return [];
    try {
      final list = jsonDecode(jsonStr) as List;
      return list.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveAIAgents(List<Map<String, dynamic>> agents) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_aiAgentsKey, jsonEncode(agents));
  }

  static Future<void> addOrUpdateAIAgent(Map<String, dynamic> agent) async {
    final existing = await loadAIAgents();
    final index = existing.indexWhere((a) => a['id'] == agent['id']);
    if (index >= 0) {
      existing[index] = agent;
    } else {
      existing.add(agent);
    }
    await saveAIAgents(existing);
  }


  // Hive for custom portfolio scopes (exchange imports etc.)
  static const String _customScopesBoxName = "custom_scopes";

  static Future<List<Map<String, dynamic>>> loadCustomScopes() async {
    final box = Hive.box(_customScopesBoxName);
    final data = box.get("scopes");
    if (data == null) return [];
    try {
      final list = List.from(data);
      return list.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveCustomScopes(List<Map<String, dynamic>> scopes) async {
    final box = Hive.box(_customScopesBoxName);
    await box.put("scopes", scopes);
  }

  static Future<void> removeAIAgent(String id) async {
    final existing = await loadAIAgents();
    final filtered = existing.where((a) => a['id'] != id).toList();
    await saveAIAgents(filtered);
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_rothKey);
    await prefs.remove(_snapshotsKey);
  }

  static const String _dailyHistoryKey = 'portfolio_daily_history';

  /// Load the daily portfolio value history (oldest first after sorting).
  static Future<List<Map<String, dynamic>>> loadDailyHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_dailyHistoryKey);
    if (jsonStr == null) return [];
    try {
      final list = jsonDecode(jsonStr) as List;
      final items = list.map((e) => Map<String, dynamic>.from(e)).toList();
      items.sort((a, b) => (a['date'] as String? ?? '').compareTo(b['date'] as String? ?? ''));
      return items;
    } catch (_) {
      return [];
    }
  }

  /// Record today's portfolio total. One entry per calendar day — calling
  /// again on the same day updates that day's value rather than duplicating.
  static Future<void> recordDailyValue(double totalValue) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await loadDailyHistory();
    final today = DateTime.now().toIso8601String().substring(0, 10); // yyyy-MM-dd
    final idx = history.indexWhere((e) => e['date'] == today);
    final entry = {
      'date': today,
      'total_value': totalValue,
      'recorded_at': DateTime.now().toIso8601String(),
    };
    if (idx >= 0) {
      history[idx] = entry;
    } else {
      history.add(entry);
    }
    // Keep a rolling year
    final trimmed = history.length > 365 ? history.sublist(history.length - 365) : history;
    await prefs.setString(_dailyHistoryKey, jsonEncode(trimmed));
  }

  static const String _coldkeyCacheKey = "coldkey_last_data";

  // Tracked EVM wallets (Base chain, read-only)
  static const String _evmWalletsKey = 'evm_tracked_wallets';
  static const String _evmWalletCacheKey = 'evm_wallet_data';

  static Future<List<Map<String, dynamic>>> loadEvmWallets() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_evmWalletsKey);
    if (jsonStr == null) return [];
    try {
      final list = jsonDecode(jsonStr) as List;
      return list.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveEvmWallets(List<Map<String, dynamic>> wallets) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_evmWalletsKey, jsonEncode(wallets));
  }

  static Future<Map<String, dynamic>?> loadEvmWalletCache() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_evmWalletCacheKey);
    if (jsonStr == null) return null;
    try {
      return jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveEvmWalletCache(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_evmWalletCacheKey, jsonEncode(data));
  }

  // Manual LOAN price override (protocol-internal token, no public Base market)
  static const String _loanPriceKey = 'loan_price_usd';

  static Future<double?> loadLoanPrice() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_loanPriceKey);
  }

  static Future<void> saveLoanPrice(double price) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_loanPriceKey, price);
  }

  static Future<Map<String, dynamic>?> loadColdkeyCache() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_coldkeyCacheKey);
    if (jsonStr == null) return null;
    try {
      return jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveColdkeyCache(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_coldkeyCacheKey, jsonEncode(data));
  }

  // Aliases for provider compatibility
  static Future<Map<String, dynamic>?> loadROTH() => loadRothIra();
  static Future<void> saveROTH(Map<String, dynamic> data) => saveRothIra(data);

  // Previous subnet positions snapshot (for yield alert comparisons)
  static const String _prevPositionsKey = 'previous_subnet_positions';

  static Future<List<Map<String, dynamic>>?> loadPreviousPositions() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_prevPositionsKey);
    if (jsonStr == null) return null;
    try {
      final list = jsonDecode(jsonStr) as List;
      return list.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (_) {
      return null;
    }
  }

  static Future<void> savePreviousPositions(List<Map<String, dynamic>> positions) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prevPositionsKey, jsonEncode(positions));
  }

  // Lead capture for Float Financial consulting
  static const String _leadsKey = 'consulting_leads';
  static const String _notificationsKey = 'app_notifications';

  static Future<List<Map<String, dynamic>>> loadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_notificationsKey);
    if (jsonStr == null) return [];
    try {
      final list = jsonDecode(jsonStr) as List;
      return list.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveNotifications(List<Map<String, dynamic>> notifications) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_notificationsKey, jsonEncode(notifications));
  }

  static Future<List<Map<String, dynamic>>> loadLeads() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_leadsKey);
    if (jsonStr == null) return [];
    try {
      final list = jsonDecode(jsonStr) as List;
      return list.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveLead(Map<String, dynamic> lead) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = await loadLeads();
    existing.insert(0, {
      ...lead,
      'saved_at': DateTime.now().toIso8601String(),
    });
    // Keep only last 50 leads
    final trimmed = existing.take(50).toList();
    await prefs.setString(_leadsKey, jsonEncode(trimmed));
  }

}
