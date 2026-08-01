class ClientModel {
  final String id;
  final String name;
  final String email;
  final String tier;
  final double portfolioValue;
  final String lastActive;
  final double changePercent;

  ClientModel({
    required this.id,
    required this.name,
    required this.email,
    required this.tier,
    required this.portfolioValue,
    required this.lastActive,
    required this.changePercent,
  });
}