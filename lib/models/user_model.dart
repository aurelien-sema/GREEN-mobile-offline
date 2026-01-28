/// Modèle utilisateur
class UserModel {
  final String id;
  final String name;
  final String username;
  final String email;
  final String? phone;
  final String? profession;
  final String? avatarUrl;
  final DateTime memberSince;

  UserModel({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    this.phone,
    this.profession,
    this.avatarUrl,
    required this.memberSince,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      profession: json['profession'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      memberSince: DateTime.parse(json['member_since'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'username': username,
      'email': email,
      'phone': phone,
      'profession': profession,
      'avatar_url': avatarUrl,
      'member_since': memberSince.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? username,
    String? email,
    String? phone,
    String? profession,
    String? avatarUrl,
    DateTime? memberSince,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      username: username ?? this.username,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      profession: profession ?? this.profession,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      memberSince: memberSince ?? this.memberSince,
    );
  }
}
