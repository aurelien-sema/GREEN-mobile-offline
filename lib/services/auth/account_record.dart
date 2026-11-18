/// Compte local stocké dans `users.json` (dossier privé de l'application).
///
/// Ne contient jamais de secret en clair : le mot de passe et la réponse de
/// sécurité sont hachés (PBKDF2, voir PasswordHasher).
class AccountRecord {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String passwordHash;
  final DateTime createdAt;
  final String? securityQuestionId;
  final String? securityAnswerHash;

  /// Copie permanente de la photo de profil, dans le dossier de l'application.
  /// Conservée après déconnexion ; supprimée seulement à la demande.
  final String? avatarPath;

  final int failedLogins;
  final int failedAnswers;
  final DateTime? lockedUntil;

  const AccountRecord({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.passwordHash,
    required this.createdAt,
    this.securityQuestionId,
    this.securityAnswerHash,
    this.avatarPath,
    this.failedLogins = 0,
    this.failedAnswers = 0,
    this.lockedUntil,
  });

  bool get hasSecurityQuestion =>
      (securityQuestionId ?? '').isNotEmpty && (securityAnswerHash ?? '').isNotEmpty;

  bool isLocked(DateTime now) => lockedUntil != null && lockedUntil!.isAfter(now);

  factory AccountRecord.fromJson(Map<String, dynamic> json) {
    DateTime? parse(Object? v) => v is String ? DateTime.tryParse(v) : null;
    return AccountRecord(
      id: json['id'] as String,
      name: (json['name'] as String?) ?? '',
      email: (json['email'] as String?) ?? '',
      phone: (json['phone'] as String?) ?? '',
      passwordHash: (json['password_hash'] as String?) ?? '',
      // Comptes créés avant la v2 : l'identifiant est un horodatage en ms.
      createdAt: parse(json['created_at']) ??
          DateTime.fromMillisecondsSinceEpoch(int.tryParse(json['id'] as String) ?? 0),
      securityQuestionId: json['security_question_id'] as String?,
      securityAnswerHash: json['security_answer_hash'] as String?,
      avatarPath: json['avatar_path'] as String?,
      failedLogins: (json['failed_logins'] as num?)?.toInt() ?? 0,
      failedAnswers: (json['failed_answers'] as num?)?.toInt() ?? 0,
      lockedUntil: parse(json['locked_until']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'password_hash': passwordHash,
        'created_at': createdAt.toIso8601String(),
        'security_question_id': securityQuestionId,
        'security_answer_hash': securityAnswerHash,
        'avatar_path': avatarPath,
        'failed_logins': failedLogins,
        'failed_answers': failedAnswers,
        'locked_until': lockedUntil?.toIso8601String(),
      };

  AccountRecord copyWith({
    String? name,
    String? email,
    String? phone,
    String? passwordHash,
    String? securityQuestionId,
    String? securityAnswerHash,
    String? avatarPath,
    bool clearAvatar = false,
    int? failedLogins,
    int? failedAnswers,
    DateTime? lockedUntil,
    bool clearLock = false,
  }) {
    return AccountRecord(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      passwordHash: passwordHash ?? this.passwordHash,
      createdAt: createdAt,
      securityQuestionId: securityQuestionId ?? this.securityQuestionId,
      securityAnswerHash: securityAnswerHash ?? this.securityAnswerHash,
      avatarPath: clearAvatar ? null : (avatarPath ?? this.avatarPath),
      failedLogins: failedLogins ?? this.failedLogins,
      failedAnswers: failedAnswers ?? this.failedAnswers,
      lockedUntil: clearLock ? null : (lockedUntil ?? this.lockedUntil),
    );
  }
}

/// Numéro de téléphone sous une forme unique (+237XXXXXXXXX pour le
/// Cameroun), identique à la normalisation du backend GREEN Web
/// (schemas.normalize_phone) pour que le même numéro y désigne le même compte.
String normalizePhone(String raw) {
  var v = raw.replaceAll(RegExp(r'[\s.\-()]'), '');
  if (v.startsWith('00')) v = '+${v.substring(2)}';
  if (RegExp(r'^[26]\d{8}$').hasMatch(v)) {
    v = '+237$v';
  } else if (RegExp(r'^237[26]\d{8}$').hasMatch(v)) {
    v = '+$v';
  }
  return v;
}
