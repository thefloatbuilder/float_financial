/// Utility for looking up Bittensor subnet APY rates and estimating yield.
library;

/// Static APY rates for known subnets, keyed by netuid.
class SubnetApy {
  SubnetApy._();

  /// APY rates (as percentages) for known subnets.
  static const Map<int, double> apyRates = {
    0: 12.5, // SN0 Root
    4: 21.5, // SN4 Targon
    53: 32.5, // SN53 Engy
    64: 17.5, // SN64 Chutes
  };

  /// Fallback APY for subnets not present in [apyRates].
  static const double defaultApy = 15.0;

  /// Human-readable names for known subnets.
  static const Map<int, String> subnetNames = {
    0: 'Root',
    4: 'Targon',
    53: 'Engy',
    64: 'Chutes',
  };

  /// Returns the APY (percent) for [netuid], or [defaultApy] if unknown.
  static double getApy(int netuid) => apyRates[netuid] ?? defaultApy;

  /// Estimates the monthly yield in TAO for [stakedTao] staked on [netuid].
  ///
  /// Calculation: stakedTao * (APY / 100) / 12.
  static double estimateMonthlyYield(double stakedTao, int netuid) {
    return stakedTao * (getApy(netuid) / 100.0) / 12.0;
  }

  /// Estimates the annual yield in TAO for [stakedTao] staked on [netuid].
  static double estimateAnnualYield(double stakedTao, int netuid) {
    return stakedTao * (getApy(netuid) / 100.0);
  }
}
