class PortfolioModel {
  final String userId;
  final double totalValue;
  final double monthlyYield;
  final double avgApy;
  final List<AssetModel> assets;

  PortfolioModel({
    required this.userId,
    required this.totalValue,
    required this.monthlyYield,
    required this.avgApy,
    required this.assets,
  });
}

class AssetModel {
  final String symbol;
  final String name;
  final double amount;
  final double valueUsd;
  final double percentage;
  final double change24h;

  AssetModel({
    required this.symbol,
    required this.name,
    required this.amount,
    required this.valueUsd,
    required this.percentage,
    required this.change24h,
  });
}