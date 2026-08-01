/// Subnet Position model for Float Financial
/// Represents a staked position in a Bittensor subnet
library;

class SubnetPosition {
  final int subnetId;
  final String name;
  final double stakedTao;        // Original TAO staked
  final double alphaBalance;     // Current alpha token balance
  final double alphaPriceTao;    // Current alpha price in TAO
  final double currentValueTao;  // alphaBalance * alphaPriceTao
  final double monthlyYieldTao;  // Estimated monthly yield in TAO
  final double apy;              // Current APY percentage
  final double pnlTao;           // currentValueTao - stakedTao
  final double pnlPercent;       // (pnlTao / stakedTao) * 100

  const SubnetPosition({
    required this.subnetId,
    required this.name,
    required this.stakedTao,
    required this.alphaBalance,
    required this.alphaPriceTao,
    required this.currentValueTao,
    required this.monthlyYieldTao,
    required this.apy,
    required this.pnlTao,
    required this.pnlPercent,
  });

  /// Create from raw data
  factory SubnetPosition.fromData({
    required int subnetId,
    required String name,
    required double stakedTao,
    required double alphaBalance,
    required double alphaPriceTao,
    required double monthlyYieldTao,
  }) {
    final currentValue = alphaBalance * alphaPriceTao;
    final pnl = currentValue - stakedTao;
    final pnlPct = stakedTao > 0 ? (pnl / stakedTao) * 100 : 0.0;
    final apy = stakedTao > 0 ? (monthlyYieldTao * 12 / stakedTao) * 100 : 0.0;

    return SubnetPosition(
      subnetId: subnetId,
      name: name,
      stakedTao: stakedTao,
      alphaBalance: alphaBalance,
      alphaPriceTao: alphaPriceTao,
      currentValueTao: currentValue,
      monthlyYieldTao: monthlyYieldTao,
      apy: apy,
      pnlTao: pnl,
      pnlPercent: pnlPct,
    );
  }

  /// Copy with new values (for state updates)
  SubnetPosition copyWith({
    int? subnetId,
    String? name,
    double? stakedTao,
    double? alphaBalance,
    double? alphaPriceTao,
    double? currentValueTao,
    double? monthlyYieldTao,
    double? apy,
    double? pnlTao,
    double? pnlPercent,
  }) {
    return SubnetPosition(
      subnetId: subnetId ?? this.subnetId,
      name: name ?? this.name,
      stakedTao: stakedTao ?? this.stakedTao,
      alphaBalance: alphaBalance ?? this.alphaBalance,
      alphaPriceTao: alphaPriceTao ?? this.alphaPriceTao,
      currentValueTao: currentValueTao ?? this.currentValueTao,
      monthlyYieldTao: monthlyYieldTao ?? this.monthlyYieldTao,
      apy: apy ?? this.apy,
      pnlTao: pnlTao ?? this.pnlTao,
      pnlPercent: pnlPercent ?? this.pnlPercent,
    );
  }
}
