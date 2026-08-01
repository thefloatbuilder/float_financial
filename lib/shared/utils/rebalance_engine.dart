/// Rebalance Engine - Suggests portfolio rebalancing based on drift from targets
/// Pure Dart, no Flutter dependencies
library;

enum RebalanceAction { trim, add }

class RebalanceSuggestion {
  final int subnetId;
  final double currentPct;      // Current allocation %
  final double targetPct;       // Target allocation %
  final double driftPct;        // currentPct - targetPct
  final RebalanceAction action; // 'trim' or 'add'
  final double amountTao;       // TAO amount to move

  const RebalanceSuggestion({
    required this.subnetId,
    required this.currentPct,
    required this.targetPct,
    required this.driftPct,
    required this.action,
    required this.amountTao,
  });
}

class RebalanceEngine {
  /// Calculate rebalance suggestions based on current positions vs target allocations
  /// Only suggests when drift exceeds threshold (default 5%)
  static List<RebalanceSuggestion> calculateRebalance({
    required List<dynamic> positions,           // List of SubnetPosition-like objects
    required Map<int, double> targetAllocations, // subnetId -> target % (0-100)
    double driftThreshold = 5.0,                 // Minimum drift to suggest action
  }) {
    final suggestions = <RebalanceSuggestion>[];
    
    // Calculate total portfolio value
    final totalValue = positions.fold<double>(
      0.0,
      (sum, p) => sum + (p.currentValueTao ?? 0.0),
    );
    
    if (totalValue <= 0) return suggestions;

    for (final position in positions) {
      final subnetId = position.subnetId as int;
      final currentValue = position.currentValueTao as double? ?? 0.0;
      final targetPct = targetAllocations[subnetId];
      
      // Skip if no target set for this subnet
      if (targetPct == null) continue;
      
      final currentPct = (currentValue / totalValue) * 100;
      final driftPct = currentPct - targetPct;
      
      // Only suggest if drift exceeds threshold
      if (driftPct.abs() < driftThreshold) continue;
      
      // Calculate amount to move (in TAO)
      // For trim: how much to sell. For add: how much to buy.
      final targetValue = (targetPct / 100) * totalValue;
      final amountTao = (targetValue - currentValue).abs();
      
      suggestions.add(RebalanceSuggestion(
        subnetId: subnetId,
        currentPct: currentPct,
        targetPct: targetPct,
        driftPct: driftPct,
        action: driftPct > 0 ? RebalanceAction.trim : RebalanceAction.add,
        amountTao: amountTao,
      ));
    }
    
    // Sort by absolute drift (largest first)
    suggestions.sort((a, b) => b.driftPct.abs().compareTo(a.driftPct.abs()));
    return suggestions;
  }
  
  /// Check if portfolio needs rebalancing
  static bool needsRebalance({
    required List<dynamic> positions,
    required Map<int, double> targetAllocations,
    double driftThreshold = 5.0,
  }) {
    final suggestions = calculateRebalance(
      positions: positions,
      targetAllocations: targetAllocations,
      driftThreshold: driftThreshold,
    );
    return suggestions.isNotEmpty;
  }
}
