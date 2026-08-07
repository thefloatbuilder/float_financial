import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class BittensorService {
  static const String _coldkey = '5EFcnuzBnLbxxzTL6MZ6W6KCDqPM31azTzoSptYEYJRBgeiY';
  static const String _wallet = '5EFQqbzyd2usEvoqre2HNgcsV1PbonmLAGzGV1eijh9xVgyC';
  static const String _taostatsKey = 'tao-cc2d66d0-626c-4091-b9e5-6fa2749a8e8b:4993e936';
  static const String _base = 'https://api.taostats.io';

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

  /// Live staked TAO (sum of balance_as_tao across alpha positions), plus the
  /// current TAO/USD price when we can get it.
  Future<Map<String, dynamic>> fetchColdkeyData() async {
    try {
      final resp = await http.get(
        Uri.parse('$_base/api/account/latest/v1?address=$_wallet&network=finney'),
        headers: {'Authorization': _taostatsKey},
      ).timeout(const Duration(seconds: 12));
      if (resp.statusCode == 200) {
        final d = jsonDecode(resp.body);
        final data = d['data'] as List? ?? [];
        if (data.isNotEmpty) {
          final account = data[0] as Map<String, dynamic>;
          final alphas = account['alpha_balances'] as List? ?? [];
          double totalTao = 0.0;
          for (final a in alphas) {
            totalTao += (int.tryParse('${a['balance_as_tao']}') ?? 0) / 1e9;
          }
          // Free balance (unstaked) is in rao too
          totalTao += (int.tryParse('${account['balance']}') ?? 0) / 1e9;

          final price = await _fetchTaoPrice();
          final usd = price != null ? totalTao * price : null;
          return {
            'coldkey': _coldkey,
            'total_stake': totalTao,
            'tao_price_usd': price,
            'daily_yield_estimate_usd': usd != null ? usd * 0.087 / 365 : 0.0,
            'apy': 8.7,
            'monthly_change': 12.4,
            'last_updated': DateTime.now().toIso8601String(),
            'is_live': true,
            'source': 'taostats',
          };
        }
      }
    } catch (e) {
      debugPrint('Taostats fetch failed — demo fallback: $e');
    }
    return _demoWithVariation();
  }

  Future<double?> _fetchTaoPrice() async {
    try {
      final r = await http.get(Uri.parse(
        'https://api.coingecko.com/api/v3/simple/price?ids=bittensor&vs_currencies=usd',
      )).timeout(const Duration(seconds: 8));
      if (r.statusCode == 200) {
        final j = jsonDecode(r.body);
        return (j['bittensor']?['usd'] as num?)?.toDouble();
      }
    } catch (_) {}
    return null;
  }
}

/// Live subnet positions for Paul's wallet — used by the portfolio notifier to
/// mirror real staked TAO into holdings. Returns null on any failure.
Future<List<Map<String, dynamic>>?> fetchLiveSubnetPositions() async {
  const key = 'tao-cc2d66d0-626c-4091-b9e5-6fa2749a8e8b:4993e936';
  const wallet = '5EFQqbzyd2usEvoqre2HNgcsV1PbonmLAGzGV1eijh9xVgyC';
  try {
    final resp = await http.get(
      Uri.parse('https://api.taostats.io/api/account/latest/v1?address=$wallet&network=finney'),
      headers: {'Authorization': key},
    ).timeout(const Duration(seconds: 12));
    if (resp.statusCode != 200) return null;
    final d = jsonDecode(resp.body);
    final data = d['data'] as List? ?? [];
    if (data.isEmpty) return null;
    final alphas = (data[0] as Map<String, dynamic>)['alpha_balances'] as List? ?? [];
    const names = {0: 'Root', 4: 'Targon', 53: 'Engy', 64: 'Chutes'};
    final out = <Map<String, dynamic>>[];
    for (final a in alphas) {
      final netuid = a['netuid'] as int? ?? -1;
      final valueTao = (int.tryParse('${a['balance_as_tao']}') ?? 0) / 1e9;
      if (valueTao <= 0) continue;
      out.add({
        'netuid': netuid,
        'name': names[netuid] ?? 'SN$netuid',
        'current_value_tao': valueTao,
      });
    }
    out.sort((x, y) => (y['current_value_tao'] as double).compareTo(x['current_value_tao'] as double));
    return out;
  } catch (e) {
    debugPrint('Live subnet positions fetch failed: $e');
    return null;
  }
}
