class AlertModel {
  final String id;
  final String userId;
  final String asset;
  final String type; // Price, APY, Pool
  final String condition;
  final bool isActive;
  final DateTime createdAt;

  AlertModel({
    required this.id,
    required this.userId,
    required this.asset,
    required this.type,
    required this.condition,
    required this.isActive,
    required this.createdAt,
  });

  factory AlertModel.fromJson(Map<String, dynamic> json) {
    return AlertModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      asset: json['asset'] ?? '',
      type: json['type'] ?? '',
      condition: json['condition'] ?? '',
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }
}