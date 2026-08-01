import "package:hive_flutter/hive_flutter.dart";
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Simple local persistence for demo features (ROTH IRA, snapshots).
/// No real backend needed. Survives app restarts.
class LocalStorageService {
  static const String _rothKey = 'roth_ira_data';
  static const String _snapshotsKey = 'portfolio_snapshots';

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

  static const String _coldkeyCacheKey = "coldkey_last_data";

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
