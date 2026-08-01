import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/subnet_position.dart';
import '../utils/yield_alerts.dart';
import '../utils/rebalance_engine.dart';

/// Demo subnet positions provider
/// Shows Paul's staking plan: SN64, SN4, SN53, SN0
/// Replace with real taostats API calls when live
final subnetPositionsProvider = FutureProvider<List<SubnetPosition>>((ref) async {
  // Simulate API delay
  await Future.delayed(const Duration(milliseconds: 500));

  // Demo data matching Paul's staking plan
  // 100 TAO total: 30% Chutes, 25% Targon, 25% Engy, 20% Root
  return [
    SubnetPosition.fromData(
      subnetId: 64,
      name: 'Chutes',
      stakedTao: 30.0,
      alphaBalance: 1.887,
      alphaPriceTao: 15.90,
      monthlyYieldTao: 0.4375,
    ),
    SubnetPosition.fromData(
      subnetId: 4,
      name: 'Targon',
      stakedTao: 25.0,
      alphaBalance: 2.244,
      alphaPriceTao: 11.14,
      monthlyYieldTao: 0.4479,
    ),
    SubnetPosition.fromData(
      subnetId: 53,
      name: 'Engy',
      stakedTao: 25.0,
      alphaBalance: 4.363,
      alphaPriceTao: 5.73,
      monthlyYieldTao: 0.6771,
    ),
    SubnetPosition.fromData(
      subnetId: 0,
      name: 'Root',
      stakedTao: 20.0,
      alphaBalance: 20.0,
      alphaPriceTao: 1.0,
      monthlyYieldTao: 0.2083,
    ),
  ];
});

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

/// Previous positions for alert comparison (simulated)
final previousPositionsProvider = FutureProvider<List<SubnetPosition>>((ref) async {
  await Future.delayed(const Duration(milliseconds: 300));
  
  // Simulate slightly different previous state for alert demo
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

/// Yield alerts provider
final yieldAlertsProvider = FutureProvider<List<YieldAlert>>((ref) async {
  final current = await ref.watch(subnetPositionsProvider.future);
  final previous = await ref.watch(previousPositionsProvider.future);
  
  final engine = YieldAlertEngine();
  return engine.checkAlerts(current, previous);
});

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
