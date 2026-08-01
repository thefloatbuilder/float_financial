import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class BittensorService {
  static const String _coldkey = '5EFcnuzBnLbxxzTL6MZ6W6KCDqPM31azTzoSptYEYJRBgeiY';
  static const String _taostatsKey = 'YOUR_TAOSTATS_API_KEY_HERE';

  Map<String, dynamic> _demoWithVariation() {
    final now = DateTime.now();
    final v = (now.millisecond % 10) * 0.15;
    return {
      'coldkey': _coldkey,
      'total_stake': 142.5 + v,
      'daily_yield_estimate_usd': 412.0 + (v * 1.8),
      'apy': 8.7,
      'monthly_change': 12.4 + (v / 8),
      'last_updated': now.toIso8601String(),
      'is_live': false,
      'source': 'demo',
    };
  }

  Future<Map<String, dynamic>> fetchColdkeyData() async {
    if (_taostatsKey == 'YOUR_TAOSTATS_API_KEY_HERE') {
      return _demoWithVariation();
    }
    try {
      final uri = Uri.parse('https://api.taostats.io/api/coldkey/');
      final resp = await http.get(uri, headers: {'Authorization': 'Bearer '});
      if (resp.statusCode == 200) {
        final d = jsonDecode(resp.body);
        return {
          'coldkey': _coldkey,
          'total_stake': (d['stake'] ?? d['total_stake'] ?? 0).toDouble(),
          'daily_yield_estimate_usd': (d['daily_yield'] ?? d['est_daily_yield'] ?? 0).toDouble(),
          'apy': (d['apy'] ?? 8.7).toDouble(),
          'monthly_change': (d['monthly_change'] ?? 12.4).toDouble(),
          'last_updated': DateTime.now().toIso8601String(),
          'is_live': true,
          'source': 'taostats',
        };
      }
    } catch (e) {
      debugPrint('Taostats fetch failed — demo fallback: $e');
    }
    return _demoWithVariation();
  }
}
