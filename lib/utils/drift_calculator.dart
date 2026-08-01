/// Portfolio Drift Calculator
///
/// Compares current asset allocations against target allocations and computes
/// the total drift, the asset with the largest individual drift, and whether
/// the portfolio needs rebalancing.
///
/// - [currentAllocations]: Map of asset ticker/name -> current weight (0.0 - 1.0)
/// - [targetAllocations]:  Map of asset ticker/name -> target weight (0.0 - 1.0)
///
/// Returns a Map with:
///   'totalDrift'      (double) — sum of absolute differences divided by 2
///   'maxDriftAsset'   (String) — asset with the largest absolute drift
///   'needsRebalance'  (bool)   — true if totalDrift > 0.05 (5%)
Map<String, dynamic> calculatePortfolioDrift(
  Map<String, double> currentAllocations,
  Map<String, double> targetAllocations,
) {
  final Set<String> allAssets = <String>{
    ...currentAllocations.keys,
    ...targetAllocations.keys,
  };

  double totalDrift = 0.0;
  double maxDrift = -1.0;
  String maxDriftAsset = '';

  for (final asset in allAssets) {
    final double current = currentAllocations[asset] ?? 0.0;
    final double target = targetAllocations[asset] ?? 0.0;
    final double drift = (current - target).abs();

    totalDrift += drift;

    if (drift > maxDrift) {
      maxDrift = drift;
      maxDriftAsset = asset;
    }
  }

  totalDrift /= 2.0;

  return <String, dynamic>{
    'totalDrift': totalDrift,
    'maxDriftAsset': maxDriftAsset,
    'needsRebalance': totalDrift > 0.05,
  };
}
