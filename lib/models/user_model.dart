import '../services/auth/account_record.dart';

/// Profil de l'utilisateur connecté, tel qu'affiché par l'interface.
class UserModel {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? avatarPath;
  final DateTime memberSince;
  final bool hasSecurityQuestion;
  final String? securityQuestionId;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.avatarPath,
    required this.memberSince,
    this.hasSecurityQuestion = false,
    this.securityQuestionId,
  });

  factory UserModel.fromAccount(AccountRecord a) => UserModel(
        id: a.id,
        name: a.name,
        email: a.email,
        phone: a.phone.isEmpty ? null : a.phone,
        avatarPath: a.avatarPath,
        memberSince: a.createdAt,
        hasSecurityQuestion: a.hasSecurityQuestion,
        securityQuestionId: a.securityQuestionId,
      );

  /// Identifiant de connexion principal à afficher.
  String get contact => (phone ?? '').isNotEmpty ? phone! : email;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }
}
