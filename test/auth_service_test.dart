import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:green_app/core/constants/app_constants.dart';
import 'package:green_app/services/auth/password_hasher.dart';
import 'package:green_app/services/auth_service.dart';

void main() {
  late Directory dir;
  late DateTime now;
  AuthService service() => AuthService(directory: () async => dir, clock: () => now);

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('green_auth_');
    now = DateTime(2026, 11, 7, 10);
  });
  tearDown(() => dir.delete(recursive: true));

  Future<RegisterResult> register(AuthService s, String phone, {String name = 'Awa Ngono', String q = 'q1'}) {
    return s.register(
      name: name,
      email: '',
      phone: phone,
      password: 'Champ2026',
      securityQuestionId: q,
      securityAnswer: 'Maïs',
    );
  }

  test('inscription : numéro normalisé, secrets hachés, registre JSON complet', () async {
    final s = service();
    final r = await register(s, '699112233');
    expect(r.isSuccess, isTrue);
    expect(r.account!.phone, '+237699112233');

    final registry = jsonDecode(File('${dir.path}/account_registry.json').readAsStringSync()) as Map<String, dynamic>;
    final entry = (registry['accounts'] as List).single as Map<String, dynamic>;
    expect(entry['full_name'], 'Awa Ngono');
    expect(entry['security_question_id'], 'q1');
    expect(entry['security_question'], isNotEmpty);
    expect(entry['security_answer_hash'], startsWith('pbkdf2_sha256'));
    final raw = File('${dir.path}/account_registry.json').readAsStringSync() + File('${dir.path}/users.json').readAsStringSync();
    expect(raw.contains('Maïs'), isFalse, reason: 'la réponse ne doit jamais être stockée en clair');
    expect(raw.contains('Champ2026'), isFalse, reason: 'le mot de passe ne doit jamais être stocké en clair');
  });

  test('doublons de téléphone refusés, quelle que soit l\'écriture du numéro', () async {
    final s = service();
    await register(s, '+237 699 11 22 33');
    final r = await register(s, '00237699112233', name: 'Paul Ndi');
    expect(r.error, RegisterError.phoneTaken);
  });

  test('un téléphone ne peut pas créer un 5e compte, même après suppression', () async {
    final s = service();
    for (var i = 0; i < AppConstants.maxAccountsPerDevice; i++) {
      expect((await register(s, '69911223$i')).isSuccess, isTrue);
    }
    final first = await s.findByIdentifier('699112230');
    expect(await s.deleteAccount(first!.id, 'Champ2026'), isTrue);
    expect(await s.remainingAccountSlots(), 0);
    final fifth = await register(s, '699112239');
    expect(fifth.error, RegisterError.deviceLimitReached);

    // La ligne supprimée est conservée mais anonymisée.
    final registry = jsonDecode(File('${dir.path}/account_registry.json').readAsStringSync());
    final deleted = (registry['accounts'] as List).firstWhere((e) => e['account_id'] == first.id);
    expect(deleted['status'], 'deleted');
    expect(deleted['full_name'], '');
    expect(deleted['phone'], '');
  });

  test('3 échecs de connexion déclenchent la question de sécurité', () async {
    final s = service();
    await register(s, '699112233', q: 'q3');
    expect(await s.login('699112233', 'mauvais1'), isA<LoginInvalid>().having((r) => r.attemptsLeft, 'restants', 2));
    expect(await s.login('699112233', 'mauvais2'), isA<LoginInvalid>().having((r) => r.attemptsLeft, 'restants', 1));
    final third = await s.login('699112233', 'mauvais3');
    expect(third, isA<LoginChallengeRequired>().having((r) => r.questionId, 'question', 'q3'));
    // Même le bon mot de passe ne suffit plus tant que la vérification n'est pas faite.
    expect(await s.login('699112233', 'Champ2026'), isA<LoginChallengeRequired>());
  });

  test('vérification réussie : nom + réponse, puis nouveau mot de passe', () async {
    final s = service();
    await register(s, '699112233');
    for (var i = 0; i < 3; i++) {
      await s.login('699112233', 'x$i');
    }
    final ok = await s.answerChallenge(identifier: '699112233', fullName: 'awa  NGONO', answer: 'mais');
    expect(ok, isA<ChallengeSuccess>());
    final account = await s.completeRecovery((ok as ChallengeSuccess).accountId, 'Nouveau2026');
    expect(account, isNotNull);
    expect(await s.login('699112233', 'Nouveau2026'), isA<LoginSuccess>());
  });

  test('trois mauvaises réponses verrouillent le compte 15 minutes', () async {
    final s = service();
    await register(s, '699112233');
    for (var i = 0; i < 3; i++) {
      await s.login('699112233', 'x$i');
    }
    expect(await s.answerChallenge(identifier: '699112233', fullName: 'Awa Ngono', answer: 'manioc'), isA<ChallengeWrong>());
    expect(await s.answerChallenge(identifier: '699112233', fullName: 'Autre Nom', answer: 'mais'), isA<ChallengeWrong>());
    expect(await s.answerChallenge(identifier: '699112233', fullName: 'Awa Ngono', answer: 'tomate'), isA<ChallengeLocked>());
    expect(await s.answerChallenge(identifier: '699112233', fullName: 'Awa Ngono', answer: 'mais'), isA<ChallengeLocked>());
    now = now.add(const Duration(minutes: 16));
    expect(await s.answerChallenge(identifier: '699112233', fullName: 'Awa Ngono', answer: 'mais'), isA<ChallengeSuccess>());
  });

  test('la vérification n\'est pas proposée avant 3 échecs', () async {
    final s = service();
    await register(s, '699112233');
    expect(await s.answerChallenge(identifier: '699112233', fullName: 'Awa Ngono', answer: 'mais'), isA<ChallengeUnavailable>());
  });

  test('comptes v1 (sans question) : relus, verrouillés après 3 échecs', () async {
    final legacyHash = PasswordHasher.hashSync('Ancien123', rounds: 10000);
    File('${dir.path}/users.json').writeAsStringSync(jsonEncode([
      {'id': '1767225600000', 'name': 'Jean Fouda', 'email': '', 'phone': '+237677000000', 'password_hash': legacyHash},
    ]));
    final s = service();
    final ok = await s.login('677000000', 'Ancien123');
    expect(ok, isA<LoginSuccess>());
    expect((ok as LoginSuccess).account.hasSecurityQuestion, isFalse);
    for (var i = 0; i < 2; i++) {
      await s.login('677000000', 'faux$i');
    }
    expect(await s.login('677000000', 'faux3'), isA<LoginLocked>().having((r) => r.noSecurityQuestion, 'sans question', isTrue));
    // Le compte v1 compte dans la limite par téléphone.
    expect(await s.remainingAccountSlots(), AppConstants.maxAccountsPerDevice - 1);
  });
}
