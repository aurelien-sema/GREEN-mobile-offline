import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../core/constants/app_constants.dart';
import 'auth/account_record.dart';
import 'auth/account_registry.dart';
import 'auth/password_hasher.dart';
import 'auth/security_questions.dart';

export 'auth/account_record.dart' show AccountRecord, normalizePhone;

enum RegisterError { none, emailTaken, phoneTaken, deviceLimitReached }

class RegisterResult {
  final AccountRecord? account;
  final RegisterError error;
  const RegisterResult.ok(AccountRecord this.account) : error = RegisterError.none;
  const RegisterResult.fail(this.error) : account = null;
  bool get isSuccess => error == RegisterError.none;
}

/// Issue d'une tentative de connexion.
sealed class LoginResult {
  const LoginResult();
}

class LoginSuccess extends LoginResult {
  final AccountRecord account;
  const LoginSuccess(this.account);
}

/// Identifiants refusés. [attemptsLeft] : essais restants avant la question
/// de sécurité (null si l'identifiant ne correspond à aucun compte).
class LoginInvalid extends LoginResult {
  final int? attemptsLeft;
  const LoginInvalid(this.attemptsLeft);
}

/// Trois échecs : il faut maintenant le nom complet et la réponse à la
/// question de sécurité du compte.
class LoginChallengeRequired extends LoginResult {
  final String accountId;
  final String questionId;
  const LoginChallengeRequired(this.accountId, this.questionId);
}

class LoginLocked extends LoginResult {
  final DateTime until;
  final bool noSecurityQuestion;
  const LoginLocked(this.until, {this.noSecurityQuestion = false});
}

sealed class ChallengeResult {
  const ChallengeResult();
}

class ChallengeSuccess extends ChallengeResult {
  final String accountId;
  const ChallengeSuccess(this.accountId);
}

class ChallengeWrong extends ChallengeResult {
  final int attemptsLeft;
  const ChallengeWrong(this.attemptsLeft);
}

class ChallengeLocked extends ChallengeResult {
  final DateTime until;
  const ChallengeLocked(this.until);
}

class ChallengeUnavailable extends ChallengeResult {
  const ChallengeUnavailable();
}

/// Comptes locaux de l'application (aucun serveur : tout reste sur le
/// téléphone, dans le dossier privé de l'application).
///
/// Fichiers :
/// - `users.json` : comptes (mots de passe et réponses hachés) ;
/// - `account_registry.json` : registre des comptes créés depuis ce
///   téléphone, voir [AccountRegistry].
class AuthService {
  static const _fileName = 'users.json';
  static const _recoveryGrantValidity = Duration(minutes: 10);

  final Future<Directory> Function() _dir;
  final DateTime Function() _now;
  late final AccountRegistry registry;

  List<AccountRecord> _accounts = [];
  bool _loaded = false;

  /// Échecs sur des identifiants inconnus (mémoire seulement).
  final Map<String, int> _unknownFailures = {};

  /// Compte autorisé à changer son mot de passe après une réponse correcte.
  String? _recoveryAccountId;
  DateTime? _recoveryGrantedAt;

  AuthService({Future<Directory> Function()? directory, DateTime Function()? clock})
      : _dir = directory ?? getApplicationDocumentsDirectory,
        _now = clock ?? DateTime.now {
    registry = AccountRegistry(_dir);
  }

  Future<File> _file() async => File('${(await _dir()).path}/$_fileName');

  Future<void> _load() async {
    if (_loaded) return;
    final f = await _file();
    if (await f.exists()) {
      try {
        final list = jsonDecode(await f.readAsString()) as List<dynamic>;
        _accounts = list.map((e) => AccountRecord.fromJson(e as Map<String, dynamic>)).toList();
      } catch (_) {
        await f.copy('${f.path}.corrupt');
        _accounts = [];
      }
    }
    // Normalise les numéros des comptes créés avant la v2.
    _accounts = _accounts
        .map((a) => a.phone.isEmpty ? a : a.copyWith(phone: normalizePhone(a.phone)))
        .toList();
    _loaded = true;
    await registry.load();
    await registry.backfill(_accounts.map((a) => RegistryEntry(
          accountId: a.id,
          fullName: a.name,
          phone: a.phone,
          email: a.email,
          createdAt: a.createdAt,
          securityQuestionId: a.securityQuestionId,
          securityQuestion: SecurityQuestions.referenceText[a.securityQuestionId],
          securityAnswerHash: a.securityAnswerHash,
        )));
  }

  Future<void> _save() async {
    final f = await _file();
    final tmp = File('${f.path}.tmp');
    await tmp.writeAsString(jsonEncode(_accounts.map((e) => e.toJson()).toList()));
    await tmp.rename(f.path);
  }

  void _replace(AccountRecord updated) {
    final i = _accounts.indexWhere((a) => a.id == updated.id);
    if (i != -1) _accounts[i] = updated;
  }

  // ---------------------------------------------------------------- lecture

  Future<AccountRecord?> findById(String id) async {
    await _load();
    for (final a in _accounts) {
      if (a.id == id) return a;
    }
    return null;
  }

  /// Recherche par e-mail (si l'identifiant contient « @ ») ou par téléphone.
  Future<AccountRecord?> findByIdentifier(String identifier) async {
    await _load();
    final id = identifier.trim();
    if (id.isEmpty) return null;
    if (id.contains('@')) {
      final lower = id.toLowerCase();
      for (final a in _accounts) {
        if (a.email.toLowerCase() == lower) return a;
      }
      return null;
    }
    final phone = normalizePhone(id);
    for (final a in _accounts) {
      if (a.phone.isNotEmpty && a.phone == phone) return a;
    }
    return null;
  }

  /// Nombre de comptes encore créables depuis ce téléphone.
  Future<int> remainingAccountSlots() async {
    await _load();
    final left = AppConstants.maxAccountsPerDevice - registry.createdCount;
    return left < 0 ? 0 : left;
  }

  // ------------------------------------------------------------- inscription

  Future<RegisterResult> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String securityQuestionId,
    required String securityAnswer,
  }) async {
    await _load();
    if (registry.createdCount >= AppConstants.maxAccountsPerDevice) {
      return const RegisterResult.fail(RegisterError.deviceLimitReached);
    }
    final emailLower = email.trim().toLowerCase();
    final phoneNorm = phone.trim().isEmpty ? '' : normalizePhone(phone);
    if (emailLower.isNotEmpty && _accounts.any((a) => a.email.toLowerCase() == emailLower)) {
      return const RegisterResult.fail(RegisterError.emailTaken);
    }
    if (phoneNorm.isNotEmpty && _accounts.any((a) => a.phone == phoneNorm)) {
      return const RegisterResult.fail(RegisterError.phoneTaken);
    }
    if (!SecurityQuestions.isValid(securityQuestionId)) {
      throw ArgumentError.value(securityQuestionId, 'securityQuestionId');
    }

    final passwordHash = await PasswordHasher.hash(password);
    final answerHash = await PasswordHasher.hash(normalizeSecret(securityAnswer));
    final account = AccountRecord(
      id: const Uuid().v4(),
      name: name.trim().replaceAll(RegExp(r'\s+'), ' '),
      email: emailLower,
      phone: phoneNorm,
      passwordHash: passwordHash,
      createdAt: _now(),
      securityQuestionId: securityQuestionId,
      securityAnswerHash: answerHash,
    );
    _accounts.add(account);
    await _save();
    await registry.add(RegistryEntry(
      accountId: account.id,
      fullName: account.name,
      phone: account.phone,
      email: account.email,
      createdAt: account.createdAt,
      securityQuestionId: securityQuestionId,
      securityQuestion: SecurityQuestions.referenceText[securityQuestionId],
      securityAnswerHash: answerHash,
    ));
    return RegisterResult.ok(account);
  }

  // --------------------------------------------------------------- connexion

  Future<LoginResult> login(String identifier, String password) async {
    await _load();
    final now = _now();
    var account = await findByIdentifier(identifier);
    final max = AppConstants.maxFailedLoginsBeforeChallenge;

    if (account == null) {
      final key = identifier.trim().toLowerCase();
      final count = (_unknownFailures[key] ?? 0) + 1;
      _unknownFailures[key] = count;
      return const LoginInvalid(null);
    }

    if (account.isLocked(now)) {
      return LoginLocked(account.lockedUntil!, noSecurityQuestion: !account.hasSecurityQuestion);
    }
    // Verrou expiré d'un compte sans question : nouvelle série d'essais.
    if (account.lockedUntil != null && !account.hasSecurityQuestion) {
      account = account.copyWith(failedLogins: 0, clearLock: true);
      _replace(account);
      await _save();
    }

    if (account.failedLogins >= max && account.hasSecurityQuestion) {
      return LoginChallengeRequired(account.id, account.securityQuestionId!);
    }

    if (await PasswordHasher.verify(password, account.passwordHash)) {
      final reset = account.copyWith(failedLogins: 0, failedAnswers: 0, clearLock: true);
      _replace(reset);
      await _save();
      return LoginSuccess(reset);
    }

    final failures = account.failedLogins + 1;
    if (failures >= max) {
      if (account.hasSecurityQuestion) {
        _replace(account.copyWith(failedLogins: failures));
        await _save();
        return LoginChallengeRequired(account.id, account.securityQuestionId!);
      }
      final until = now.add(AppConstants.securityLockDuration);
      _replace(account.copyWith(failedLogins: failures, lockedUntil: until));
      await _save();
      return LoginLocked(until, noSecurityQuestion: true);
    }
    _replace(account.copyWith(failedLogins: failures));
    await _save();
    return LoginInvalid(max - failures);
  }

  /// Vérification d'identité après trois échecs : nom complet + réponse à
  /// la question de sécurité. Le message d'erreur ne dit pas lequel des
  /// deux est faux.
  Future<ChallengeResult> answerChallenge({
    required String identifier,
    required String fullName,
    required String answer,
  }) async {
    await _load();
    final now = _now();
    final account = await findByIdentifier(identifier);
    if (account == null || !account.hasSecurityQuestion) return const ChallengeUnavailable();
    if (account.failedLogins < AppConstants.maxFailedLoginsBeforeChallenge) {
      return const ChallengeUnavailable();
    }
    if (account.isLocked(now)) return ChallengeLocked(account.lockedUntil!);

    final nameOk = normalizeSecret(fullName) == normalizeSecret(account.name);
    final answerOk = await PasswordHasher.verify(normalizeSecret(answer), account.securityAnswerHash!);
    if (nameOk && answerOk) {
      _replace(account.copyWith(failedAnswers: 0, clearLock: true));
      await _save();
      _recoveryAccountId = account.id;
      _recoveryGrantedAt = now;
      return ChallengeSuccess(account.id);
    }

    final failures = account.failedAnswers + 1;
    if (failures >= AppConstants.maxFailedSecurityAnswers) {
      final until = now.add(AppConstants.securityLockDuration);
      _replace(account.copyWith(failedAnswers: 0, lockedUntil: until));
      await _save();
      return ChallengeLocked(until);
    }
    _replace(account.copyWith(failedAnswers: failures));
    await _save();
    return ChallengeWrong(AppConstants.maxFailedSecurityAnswers - failures);
  }

  /// Nouveau mot de passe après une réponse correcte (valable 10 minutes).
  Future<AccountRecord?> completeRecovery(String accountId, String newPassword) async {
    await _load();
    final granted = _recoveryGrantedAt;
    if (_recoveryAccountId != accountId ||
        granted == null ||
        _now().difference(granted) > _recoveryGrantValidity) {
      return null;
    }
    final account = await findById(accountId);
    if (account == null) return null;
    final updated = account.copyWith(
      passwordHash: await PasswordHasher.hash(newPassword),
      failedLogins: 0,
      failedAnswers: 0,
      clearLock: true,
    );
    _replace(updated);
    await _save();
    _recoveryAccountId = null;
    _recoveryGrantedAt = null;
    return updated;
  }

  // ------------------------------------------------------- gestion du compte

  Future<bool> verifyPassword(String accountId, String password) async {
    final account = await findById(accountId);
    if (account == null) return false;
    return PasswordHasher.verify(password, account.passwordHash);
  }

  Future<bool> changePassword(String accountId, String current, String next) async {
    final account = await findById(accountId);
    if (account == null || !await PasswordHasher.verify(current, account.passwordHash)) {
      return false;
    }
    _replace(account.copyWith(passwordHash: await PasswordHasher.hash(next)));
    await _save();
    return true;
  }

  /// Définit (ou change) la question de sécurité. [currentPassword] est exigé
  /// sauf juste après une connexion réussie d'un ancien compte qui n'en avait
  /// pas ([trustedSession] = true).
  Future<bool> setSecurityQuestion(
    String accountId,
    String questionId,
    String answer, {
    String? currentPassword,
    bool trustedSession = false,
  }) async {
    final account = await findById(accountId);
    if (account == null || !SecurityQuestions.isValid(questionId)) return false;
    if (!trustedSession) {
      if (currentPassword == null ||
          !await PasswordHasher.verify(currentPassword, account.passwordHash)) {
        return false;
      }
    }
    final answerHash = await PasswordHasher.hash(normalizeSecret(answer));
    _replace(account.copyWith(securityQuestionId: questionId, securityAnswerHash: answerHash));
    await _save();
    await registry.update(
      accountId,
      (e) => RegistryEntry(
        accountId: e.accountId,
        fullName: e.fullName,
        phone: e.phone,
        email: e.email,
        createdAt: e.createdAt,
        securityQuestionId: questionId,
        securityQuestion: SecurityQuestions.referenceText[questionId],
        securityAnswerHash: answerHash,
        status: e.status,
        deletedAt: e.deletedAt,
      ),
    );
    return true;
  }

  Future<AccountRecord?> setAvatarPath(String accountId, String? path) async {
    final account = await findById(accountId);
    if (account == null) return null;
    final updated = path == null ? account.copyWith(clearAvatar: true) : account.copyWith(avatarPath: path);
    _replace(updated);
    await _save();
    return updated;
  }

  /// Supprime le compte après vérification du mot de passe. La ligne du
  /// registre est conservée mais anonymisée.
  Future<bool> deleteAccount(String accountId, String password) async {
    final account = await findById(accountId);
    if (account == null || !await PasswordHasher.verify(password, account.passwordHash)) {
      return false;
    }
    _accounts.removeWhere((a) => a.id == accountId);
    await _save();
    await registry.update(accountId, (e) => e.anonymized(_now()));
    return true;
  }

  /// Pour les tests : oublie l'état chargé en mémoire.
  void resetCache() {
    _loaded = false;
    _accounts = [];
    _unknownFailures.clear();
  }
}

final authService = AuthService();
