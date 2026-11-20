import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:green_app/models/scan_result_model.dart';
import 'package:green_app/services/green_web/green_web_client.dart';
import 'package:green_app/services/green_web/photo_sync_service.dart';
import 'package:green_app/services/green_web/shared_web_account.dart';
import 'package:green_app/services/green_web/upload_outbox.dart';
import 'package:green_app/services/history_service.dart';
import 'package:green_app/services/user_scope.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Envoi automatique au serveur GREEN Web : file hors ligne, reprise au
/// retour du réseau, intégrité, jeton expiré, délais, plusieurs comptes.
/// Le serveur est simulé avec les formats de réponse de Greennew
/// (rover_common.analysis_response).

String _jwt(DateTime exp) {
  String enc(Map<String, Object> m) => base64Url.encode(utf8.encode(jsonEncode(m))).replaceAll('=', '');
  return '${enc({'alg': 'HS256'})}.${enc({'sub': '1', 'exp': exp.millisecondsSinceEpoch ~/ 1000})}.sig';
}

http.Response _json(Object body, int code) =>
    http.Response.bytes(utf8.encode(jsonEncode(body)), code, headers: {'content-type': 'application/json; charset=utf-8'});

class _Server {
  int logins = 0;
  final uploads = <http.Request>[];
  final List<int> uploadStatus = []; // statuts imposés aux prochains envois
  bool offline = false;
  int loginStatus = 200;
  DateTime now;
  _Server(this.now);

  MockClient get client => MockClient((r) async {
        if (offline) throw const SocketException('Network is unreachable');
        if (r.url.path == '/api/auth/login') {
          logins++;
          if (loginStatus != 200) {
            return _json({'detail': 'Incorrect phone/email or password.'}, loginStatus);
          }
          return _json({
            'access_token': _jwt(now.add(const Duration(days: 7))),
            'token_type': 'bearer',
            'user': {'id': 1, 'first_name': 'Compte', 'last_name': 'GREEN', 'phone': '+237600000000', 'dataset_consent': true},
          }, 200);
        }
        if (r.url.path.startsWith('/api/camera/')) {
          uploads.add(r);
          final status = uploadStatus.isEmpty ? 200 : uploadStatus.removeAt(0);
          if (status != 200) return _json({'detail': 'HTTP $status'}, status);
          return _json({
            'success': true,
            'analysis_id': 40 + uploads.length,
            'duplicate': false,
            'image_path': '/api/media/x.jpg?sig=1',
            'disease': {'disease_name': 'Mosaïque du manioc', 'confidence': 0.93, 'class_raw': 'Cassava Mosaic'},
          }, 200);
        }
        return http.Response('{"detail":"Not Found"}', 404);
      });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory dir;
  late _Server server;
  late HistoryService history;
  late UploadOutbox outbox;
  late StreamController<bool> network;
  late PhotoSyncService sync;
  late DateTime now;

  PhotoSyncService build({Map<String, String>? env}) {
    final client = GreenWebClient(httpClient: server.client, baseUrl: 'https://api.test');
    final account = SharedWebAccount(
      client: client,
      credentials: () => SharedAccountCredentials.fromEnv(env ??
          const {'GREEN_WEB_EMAIL': 'compte@green.test', 'GREEN_WEB_PHONE': '+237600000000', 'GREEN_WEB_PASSWORD': 'secret'}),
      clock: () => now,
    );
    return PhotoSyncService(
      client: client,
      history: history,
      outbox: outbox,
      account: account,
      connectivity: () => network.stream,
      clock: () => now,
    );
  }

  Future<ScanResultModel> addScan(String id, {String user = 'u1', String bytes = 'jpeg-bytes', String? chosenCrop}) async {
    final img = File('${dir.path}/scans/$user/$id.jpg')..createSync(recursive: true);
    img.writeAsStringSync('$bytes-$id');
    final scan = ScanResultModel(
      id: id,
      label: 'Cassava Mosaic',
      diseaseId: 'cassava-mosaic',
      plantName: 'Manioc',
      diseaseName: 'Mosaïque',
      confidence: 0.91,
      status: ScanStatus.diseased,
      chosenCropId: chosenCrop,
      imagePath: img.path,
      thumbPath: img.path,
      scannedAt: now,
    );
    UserScope.setUserId(user);
    await history.addScan(scan);
    return scan;
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    dir = await Directory.systemTemp.createTemp('green_sync_');
    now = DateTime.utc(2026, 11, 9, 10);
    server = _Server(now);
    history = HistoryService(directory: () async => dir);
    outbox = UploadOutbox(directory: () async => dir);
    network = StreamController<bool>.broadcast();
    UserScope.setUserId('u1');
    sync = build();
  });

  tearDown(() async {
    sync.dispose();
    await network.close();
    await outbox.flush();
    await dir.delete(recursive: true);
  });

  test('en ligne : analyse envoyée tout de suite avec sa photo et sa date', () async {
    await sync.start();
    final scan = await addScan('s1');
    final queued = await sync.enqueue(scan);
    expect(queued.sync.status, SyncStatus.pending);
    await sync.syncNow();

    expect(server.uploads, hasLength(1));
    final r = server.uploads.single;
    expect(r.url.path, '/api/camera/analyze-frame');
    expect(r.headers['authorization'], startsWith('Bearer '));
    expect(utf8.decode(r.bodyBytes), contains('jpeg-bytes-s1'));
    expect(utf8.decode(r.bodyBytes), contains('name="captured_at"'));

    final saved = (await history.findById('s1'))!;
    expect(saved.sync.status, SyncStatus.sent);
    expect(saved.sync.remoteAnalysisId, 41);
    expect(saved.sync.serverDiagnosis, 'Mosaïque du manioc');
    expect(saved.sync.serverConfidence, closeTo(0.93, 1e-9));
    expect(await outbox.count(), 0);
    expect(sync.pendingCount, 0);
  });

  test('2.2.0 : la culture choisie est envoyée (champ crop = Cassava / Corn / Tomato)', () async {
    await sync.start();
    await sync.enqueue(await addScan('s1', chosenCrop: 'maize'));
    await sync.syncNow();
    final body = utf8.decode(server.uploads.single.bodyBytes);
    expect(body, contains('name="crop"'));
    expect(body, contains('Corn'));
  });

  test('2.2.0 : réponse du serveur classifier_v1 (disease = nom ou null, confidence au premier niveau)', () {
    final ok = UploadReceipt.fromJson({'status': 'ok', 'disease': 'Cassava Mosaic', 'confidence': 0.97, 'analysis_id': 7});
    expect((ok.status, ok.diseaseName, ok.confidence, ok.analysisId), ('ok', 'Cassava Mosaic', 0.97, 7));
    final wrong = UploadReceipt.fromJson({'status': 'wrong_crop', 'disease': null, 'confidence': 0.974, 'analysis_id': null});
    expect((wrong.status, wrong.diseaseName, wrong.confidence, wrong.analysisId), ('wrong_crop', null, null, null));
  });

  test('hors ligne : rien n\'est perdu, envoi automatique au retour du réseau', () async {
    await sync.start();
    network.add(false);
    server.offline = true;
    await sync.enqueue(await addScan('s1'));
    await sync.enqueue(await addScan('s2'));
    await sync.syncNow();
    expect(sync.lastError, 'offline');
    expect(sync.pendingCount, 2);
    expect((await history.findById('s1'))!.sync.status, SyncStatus.pending);

    // Redémarrage de l'application : la file est relue depuis le disque.
    final reopened = UploadOutbox(directory: () async => dir);
    expect((await reopened.items()).map((e) => e.scanId), ['s1', 's2']);

    server.offline = false;
    network.add(true);
    await pumpEventQueue(times: 50);
    await sync.syncNow(); // attend la fin d'un envoi éventuellement en cours
    expect(server.uploads, hasLength(2));
    expect((await history.findById('s2'))!.sync.status, SyncStatus.sent);
    expect(sync.pendingCount, 0);
  });

  test('intégrité : une photo modifiée après l\'analyse n\'est jamais envoyée', () async {
    server.offline = true;
    final scan = await addScan('s1');
    await sync.enqueue(scan);
    await sync.syncNow();
    File(scan.imagePath).writeAsStringSync('photo modifiée');
    server.offline = false;
    await sync.syncNow();
    expect(server.uploads, isEmpty);
    final saved = (await history.findById('s1'))!;
    expect(saved.sync.status, SyncStatus.failed);
    expect(saved.sync.lastError, 'integrity');
    expect(await outbox.count(), 0);
  });

  test('jeton refusé (401) : reconnexion automatique puis renvoi', () async {
    server.uploadStatus.addAll([401]);
    await sync.enqueue(await addScan('s1'));
    await sync.syncNow();
    expect(server.logins, 2);
    expect(server.uploads, hasLength(2));
    expect((await history.findById('s1'))!.sync.status, SyncStatus.sent);
  });

  test('serveur saturé (503) : nouvel essai après un délai croissant', () async {
    server.uploadStatus.add(503);
    await sync.enqueue(await addScan('s1'));
    await sync.syncNow();
    expect(server.uploads, hasLength(1));
    var item = (await outbox.items()).single;
    expect(item.attempts, 1);
    expect(item.nextAttemptAt, now.add(const Duration(seconds: 30)));

    await sync.syncNow(); // trop tôt : pas de nouvel envoi
    expect(server.uploads, hasLength(1));

    now = now.add(const Duration(seconds: 31));
    await sync.syncNow();
    expect(server.uploads, hasLength(2));
    expect((await history.findById('s1'))!.sync.status, SyncStatus.sent);

    item = OutboxItem.fromJson(item.toJson()).copyWith(attempts: 20);
    expect(item.failedTemporarily('x', now).nextAttemptAt, now.add(OutboxItem.backoffCap));
  });

  test('refus définitif (422) : retiré de la file et marqué en échec', () async {
    server.uploadStatus.add(422);
    await sync.enqueue(await addScan('s1'));
    await sync.syncNow();
    expect(await outbox.count(), 0);
    expect((await history.findById('s1'))!.sync.status, SyncStatus.failed);
  });

  test('plusieurs comptes sur le téléphone : un seul compte serveur, historiques séparés', () async {
    await sync.enqueue(await addScan('a1', user: 'alice'), userId: 'alice');
    await sync.enqueue(await addScan('b1', user: 'bob'), userId: 'bob');
    await sync.syncNow();
    expect(server.uploads, hasLength(2));
    expect(server.logins, 1, reason: 'un seul compte GREEN Web partagé');
    final alice = await history.scansFor('alice');
    expect(alice.single.sync.status, SyncStatus.sent);
    expect((await history.findById('b1'))!.sync.status, SyncStatus.sent);
  });

  test('analyses d\'avant la v2.1 remises en file à la connexion du compte', () async {
    await addScan('old1');
    await addScan('old2');
    server.offline = true;
    await sync.onUserChanged('u1');
    expect(await outbox.count(), 2);
    server.offline = false;
    await sync.syncNow();
    expect(server.uploads, hasLength(2));
  });

  test('analyse supprimée par l\'utilisateur avant l\'envoi : annulée', () async {
    server.offline = true;
    await sync.enqueue(await addScan('s1'));
    await sync.cancel('s1');
    server.offline = false;
    await sync.syncNow();
    expect(server.uploads, isEmpty);
  });

  test('identifiants refusés : pas de rafale de connexions, analyses gardées', () async {
    server.loginStatus = 401;
    await sync.enqueue(await addScan('s1'));
    await sync.syncNow();
    await sync.syncNow();
    expect(sync.lastError, 'rejected');
    expect(server.logins, 2, reason: 'e-mail puis téléphone, une seule fois par heure');
    expect(await outbox.count(), 1);
  });

  test('sans identifiants configurés : file conservée, aucune requête', () async {
    sync.dispose();
    sync = build(env: const {});
    await sync.enqueue(await addScan('s1'));
    await sync.syncNow();
    expect(sync.isConfigured, isFalse);
    expect(sync.lastError, 'not-configured');
    expect(server.logins, 0);
    expect(await outbox.count(), 1);
  });

  test('l\'envoi ne se désactive pas', () {
    expect(sync.isEnabled, isTrue);
  });

  test('expiration lue dans le jeton JWT', () {
    final exp = DateTime.utc(2026, 11, 16, 10);
    expect(SharedWebAccount.jwtExpiry(_jwt(exp)), exp);
    expect(SharedWebAccount.jwtExpiry('pas-un-jwt'), isNull);
  });
}
