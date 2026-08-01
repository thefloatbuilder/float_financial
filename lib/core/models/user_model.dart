class UserModel {
  final String id;
  final String email;
  final String name;
  final String tier; // Drifter Deck, Buoy Brigade, Captain's Current
  final String role; // client or admin

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.tier,
    required this.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      tier: json['tier'] ?? 'Drifter Deck',
      role: json['role'] ?? 'client',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'tier': tier,
      'role': role,
    };
  }
}