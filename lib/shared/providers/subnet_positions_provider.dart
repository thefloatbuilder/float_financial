import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../models/subnet_position.dart';
import '../services/local_storage_service.dart';
import '../services/notification_service.dart';
import '../utils/subnet_apy.dart';
import '../utils/yield_alerts.dart';
import '../utils/rebalance_engine.dart';

/// Taostats API configuration
const String _taostatsApiKey = 'tao-cc2d66d0-626c-4091-b9e5-6fa2749a8e8b:4993e936';
const String _walletAddress = '5EFQqbzyd2usEvoqre2HNgcsV1PbonmLAGzGV1eijh9xVgyC';
const String _taostatsBaseUrl = 'https://api.taostats.io';

/// Live subnet positions from taostats API
final subnetPositionsProvider = FutureProvider<List<SubnetPosition>>((ref) async {
  try {
    final response = await http.get(
      Uri.parse('$_taostatsBaseUrl/api/account/latest/v1?address=$_walletAddress&network=finney'),
      headers: {'Authorization': _taostatsApiKey},
    );

    if (response.statusCode != 200) {
      // Fallback to demo data if API fails
      return _getDemoPositions();
    }

    final json = jsonDecode(response.body);
    final data = json['data'] as List;
    if (data.isEmpty) return _getDemoPositions();

    final account = data[0];
    final alphaBalances = account['alpha_balances'] as List? ?? [];

    final positions = <SubnetPosition>[];
    for (final alpha in alphaBalances) {
      final netuid = alpha['netuid'] as int;
      final balance = int.tryParse(alpha['balance']?.toString() ?? '0') ?? 0;
      final balanceAsTao = int.tryParse(alpha['balance_as_tao']?.toString() ?? '0') ?? 0;
      
      // Convert rao to TAO (1 TAO = 1e9 rao)
      final alphaBalance = balance / 1e9;
      final currentValue = balanceAsTao / 1e9;
      
      // Get subnet name
      final name = _getSubnetName(netuid);
      
      // Estimate monthly yield based on current APY
      final monthlyYield = _estimateMonthlyYield(netuid, currentValue);
      
      positions.add(SubnetPosition.fromData(
        subnetId: netuid,
        name: name,
        stakedTao: currentValue, // Use current value as staked amount
        alphaBalance: alphaBalance,
        alphaPriceTao: alphaBalance > 0 ? currentValue / alphaBalance : 1.0,
        monthlyYieldTao: monthlyYield,
      ));
    }

    // Sort by value (highest first)
    positions.sort((a, b) => b.currentValueTao.compareTo(a.currentValueTao));
    
    return positions.isNotEmpty ? positions : _getDemoPositions();
  } catch (e) {
    // Fallback to demo data on error
    return _getDemoPositions();
  }
});

String _getSubnetName(int netuid) {
  switch (netuid) {
    case 0: return 'Root';
    case 4: return 'Targon';
    case 53: return 'Engy';
    case 64: return 'Chutes';
    default: return 'SN$netuid';
  }
}

double _estimateMonthlyYield(int netuid, double stakedTao) {
  // APY rates live in SubnetApy (single source of truth).
  return (stakedTao * SubnetApy.getApy(netuid) / 100.0) / 12;
}

List<SubnetPosition> _getDemoPositions() {
  return [
    SubnetPosition.fromData(
      subnetId: 64, name: 'Chutes', stakedTao: 30.0,
      alphaBalance: 1.887, alphaPriceTao: 15.90, monthlyYieldTao: 0.4375,
    ),
    SubnetPosition.fromData(
      subnetId: 4, name: 'Targon', stakedTao: 25.0,
      alphaBalance: 2.244, alphaPriceTao: 11.14, monthlyYieldTao: 0.4479,
    ),
    SubnetPosition.fromData(
      subnetId: 53, name: 'Engy', stakedTao: 25.0,
      alphaBalance: 4.363, alphaPriceTao: 5.73, monthlyYieldTao: 0.6771,
    ),
    SubnetPosition.fromData(
      subnetId: 0, name: 'Root', stakedTao: 20.0,
      alphaBalance: 20.0, alphaPriceTao: 1.0, monthlyYieldTao: 0.2083,
    ),
  ];
}

/// Summary stats derived from positions
final subnetSummaryProvider = Provider<Map<String, dynamic>>((ref) {
  final positionsAsync = ref.watch(subnetPositionsProvider);
  
  return positionsAsync.when(
    data: (positions) {
      final totalStaked = positions.fold<double>(0, (sum, p) => sum + p.stakedTao);
      final totalValue = positions.fold<double>(0, (sum, p) => sum + p.currentValueTao);
      final totalYield = positions.fold<double>(0, (sum, p) => sum + p.monthlyYieldTao);
      final totalPnl = totalValue - totalStaked;
      
      return {
        'totalStaked': totalStaked,
        'totalValue': totalValue,
        'totalYield': totalYield,
        'totalPnl': totalPnl,
        'totalPnlPercent': totalStaked > 0 ? (totalPnl / totalStaked) * 100 : 0.0,
        'positionCount': positions.length,
      };
    },
    loading: () => {
      'totalStaked': 0.0,
      'totalValue': 0.0,
      'totalYield': 0.0,
      'totalPnl': 0.0,
      'totalPnlPercent': 0.0,
      'positionCount': 0,
    },
    error: (_, __) => {
      'totalStaked': 0.0,
      'totalValue': 0.0,
      'totalYield': 0.0,
      'totalPnl': 0.0,
      'totalPnlPercent': 0.0,
      'positionCount': 0,
    },
  );
});

/// Previous positions for alert comparison — real snapshot persisted from the
/// last fetch. Falls back to simulated previous state on first-ever run so the
/// alerts UI still has something to show in demo mode.
final previousPositionsProvider = FutureProvider<List<SubnetPosition>>((ref) async {
  final saved = await LocalStorageService.loadPreviousPositions();
  if (saved != null && saved.isNotEmpty) {
    try {
      return saved.map(SubnetPosition.fromJson).toList();
    } catch (_) {
      // Corrupted cache — fall through to demo
    }
  }

  // First run: simulate slightly different previous state for alert demo
  return [
    SubnetPosition.fromData(
      subnetId: 64,
      name: 'Chutes',
      stakedTao: 30.0,
      alphaBalance: 1.887,
      alphaPriceTao: 15.20,  // was lower
      monthlyYieldTao: 0.42,
    ),
    SubnetPosition.fromData(
      subnetId: 4,
      name: 'Targon',
      stakedTao: 25.0,
      alphaBalance: 2.244,
      alphaPriceTao: 11.80,  // was higher
      monthlyYieldTao: 0.46,
    ),
    SubnetPosition.fromData(
      subnetId: 53,
      name: 'Engy',
      stakedTao: 25.0,
      alphaBalance: 4.363,
      alphaPriceTao: 5.20,  // was lower
      monthlyYieldTao: 0.52,  // APY was lower
    ),
    SubnetPosition.fromData(
      subnetId: 0,
      name: 'Root',
      stakedTao: 20.0,
      alphaBalance: 20.0,
      alphaPriceTao: 1.0,
      monthlyYieldTao: 0.20,
    ),
  ];
});

/// Yield alerts provider — compares current live positions against the last
/// persisted snapshot, fires local notifications for fresh alerts, logs them
/// to the in-app inbox, then saves current as the new previous snapshot.
final yieldAlertsProvider = FutureProvider<List<YieldAlert>>((ref) async {
  final current = await ref.watch(subnetPositionsProvider.future);
  final previous = await ref.watch(previousPositionsProvider.future);

  final engine = YieldAlertEngine();
  final alerts = engine.checkAlerts(current, previous);

  if (alerts.isNotEmpty) {
    // Dedup: only notify once per (subnetId, type) per 24h cooldown window,
    // so a sustained move doesn't spam on every refresh but a new move
    // tomorrow still alerts.
    final inbox = await LocalStorageService.loadNotifications();
    final cooldown = DateTime.now().subtract(const Duration(hours: 24));
    final recentlyNotified = inbox
        .where((n) =>
            n['kind'] == 'yield_alert' &&
            (DateTime.tryParse('${n['saved_at']}') ?? DateTime(2000)).isAfter(cooldown))
        .map((n) => '${n['alert_key']}')
        .toSet();

    final fresh = alerts
        .where((a) => !recentlyNotified.contains('${a.subnetId}:${a.type}'))
        .toList();

    if (fresh.isNotEmpty) {
      // Fire local push notifications (Android); no-op failures are swallowed
      // by the service on platforms without notification support (web).
      for (final alert in fresh) {
        try {
          await NotificationService.showNotification(
            title: _alertTitle(alert),
            body: alert.message,
          );
        } catch (_) {}
      }

      // Log to in-app notification inbox
      for (final alert in fresh) {
        inbox.insert(0, {
          'kind': 'yield_alert',
          'alert_key': '${alert.subnetId}:${alert.type}',
          'title': _alertTitle(alert),
          'message': alert.message,
          'severity': alert.severity.name,
          'saved_at': alert.timestamp.toIso8601String(),
        });
      }
      await LocalStorageService.saveNotifications(inbox.take(50).toList());
    }

    // Persist current positions as the baseline for the next comparison
    await LocalStorageService.savePreviousPositions(
      current.map((p) => p.toJson()).toList(),
    );
  }

  return alerts;
});

String _alertTitle(YieldAlert alert) {
  switch (alert.type) {
    case 'apy_drop':
      return '📉 Yield Alert: APY Drop';
    case 'apy_spike':
      return '📈 Yield Alert: APY Spike';
    case 'alpha_price_drop':
      return '🔴 Alpha Price Drop';
    case 'alpha_price_spike':
      return '🟢 Alpha Price Spike';
    default:
      return '🌊 Float Yield Alert';
  }
}

/// Target allocations for rebalancing (Paul's plan)
final targetAllocationsProvider = Provider<Map<int, double>>((ref) {
  return {
    64: 30.0,  // Chutes 30%
    4: 25.0,   // Targon 25%
    53: 25.0,  // Engy 25%
    0: 20.0,   // Root 20%
  };
});

/// Rebalance suggestions provider
final rebalanceSuggestionsProvider = FutureProvider<List<RebalanceSuggestion>>((ref) async {
  final positions = await ref.watch(subnetPositionsProvider.future);
  final targets = ref.watch(targetAllocationsProvider);
  
  return RebalanceEngine.calculateRebalance(
    positions: positions,
    targetAllocations: targets,
  );
});

/// Check if rebalancing is needed
final needsRebalanceProvider = FutureProvider<bool>((ref) async {
  final suggestions = await ref.watch(rebalanceSuggestionsProvider.future);
  return suggestions.isNotEmpty;
});
