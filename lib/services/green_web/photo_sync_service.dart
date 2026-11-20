import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/scan_result_model.dart';
import '../history_service.dart';
import '../user_scope.dart';
import '../vision/decision_rule.dart';
import 'green_web_client.dart';
import 'shared_web_account.dart';
import 'upload_outbox.dart';

/// Envoi automatique des analyses (photo + résultat) au serveur GREEN Web.
///
/// Toujours actif depuis la v2.1, sans réglage utilisateur : toutes les
/// analyses de tous les comptes du téléphone partent vers le compte GREEN
/// Web par défaut (SharedWebAccount).
///
/// Déroulement :
/// 1. Analyse terminée → la photo (déjà réduite à 1600 px, JPEG, sans EXIF
///    ni GPS) est mise en file avec son empreinte SHA-256 (UploadOutbox,
///    stockage privé de l'application, pas le cache).
/// 2. Envoi immédiat si le réseau est là. Sinon l'analyse attend, et l'envoi
///    reprend tout seul : retour du réseau (connectivity_plus), retour dans
///    l'application, toutes les 15 min tant qu'elle est ouverte, ou bouton
///    « Envoyer maintenant ».
/// 3. Avant l'envoi, l'empreinte est revérifiée : une photo modifiée ou
///    corrompue n'est jamais envoyée.
/// 4. Le serveur réanalyse la photo et la classe dans la GREEN Data. Il
///    reconnaît une photo déjà reçue (même SHA-256) : un renvoi après une
///    coupure ne crée pas de doublon.
/// 5. Échec temporaire (serveur indisponible, 429, 5xx) : nouvel essai avec
///    un délai croissant (30 s → 6 h), sans limite. Refus définitif (photo
///    invalide, 4xx) : retirée de la file et marquée « échec ».
class PhotoSyncService extends ChangeNotifier {
  static const periodicInterval = Duration(minutes: 15);

  final GreenWebClient _client;
  final HistoryService _history;
  final UploadOutbox _outbox;
  final SharedWebAccount _account;
  final Stream<bool> Function()? _connectivity;
  final DateTime Function() _now;

  bool _started = false;
  bool _running = false;
  bool _online = true;
  int _pending = 0;
  String? _lastError;
  DateTime? _lastSentAt;
  StreamSubscription<bool>? _connSub;
  Timer? _timer;

  factory PhotoSyncService({
    GreenWebClient? client,
    HistoryService? history,
    UploadOutbox? outbox,
    SharedWebAccount? account,
    FlutterSecureStorage? secure,
    Stream<bool> Function()? connectivity,
    DateTime Function()? clock,
  }) {
    final c = client ?? GreenWebClient();
    return PhotoSyncService._(
      c,
      history ?? historyService,
      outbox ?? UploadOutbox(),
      account ?? SharedWebAccount(client: c, secure: secure, clock: clock),
      connectivity,
      clock ?? DateTime.now,
    );
  }

  PhotoSyncService._(this._client, this._history, this._outbox, this._account, this._connectivity, this._now);

  /// L'envoi n'est pas désactivable (exigence produit v2.1).
  bool get isEnabled => true;
  bool get isRunning => _running;
  bool get isOnline => _online;
  bool get isConfigured => _account.isConfigured;
  int get pendingCount => _pending;
  DateTime? get lastSentAt => _lastSentAt;
  String get serverUrl => _client.baseUrl;

  /// Code de la dernière erreur : offline, server, rejected, disabled,
  /// not-configured, integrity, missing-file, ou null.
  String? get lastError => _lastError;

  /// À appeler une fois au démarrage de l'application.
  Future<void> start() async {
    if (_started) return;
    _started = true;
    await _migrateFromV20();
    final stream = _connectivity?.call() ?? _defaultConnectivity();
    _connSub = stream.listen((online) {
      final cameBack = online && !_online;
      _online = online;
      notifyListeners();
      if (cameBack) unawaited(syncNow());
    }, onError: (Object e) => debugPrint('Suivi du réseau indisponible : $e'));
    _timer = Timer.periodic(periodicInterval, (_) => unawaited(syncNow()));
    await _refreshCount();
    unawaited(syncNow());
  }

  static Stream<bool> _defaultConnectivity() async* {
    final c = Connectivity();
    bool up(List<ConnectivityResult> r) => r.any((e) => e != ConnectivityResult.none);
    try {
      yield up(await c.checkConnectivity());
    } catch (_) {
      yield true;
    }
    yield* c.onConnectivityChanged.map(up);
  }

  /// Un compte vient de se connecter : ses analyses jamais envoyées (y
  /// compris celles d'avant la v2.1) sont mises en file.
  Future<void> onUserChanged(String? userId) async {
    if (userId == null) return;
    await backfill(userId);
    unawaited(syncNow());
  }

  /// Met en file les analyses non envoyées d'un compte. Renvoie leur nombre.
  Future<int> backfill(String userId) async {
    var n = 0;
    for (final s in await _history.scansFor(userId)) {
      if (s.isError || s.sync.status == SyncStatus.sent || s.sync.status == SyncStatus.failed) continue;
      if (await _outbox.contains(s.id)) continue;
      final f = File(s.imagePath);
      if (s.imagePath.isEmpty || !await f.exists()) continue;
      await _outbox.put(await _itemFor(s, userId, await f.readAsBytes()));
      await _history.updateSyncFor(userId, s.id, s.sync.status == SyncStatus.pending ? s.sync : SyncState(status: SyncStatus.pending, attempts: s.sync.attempts));
      n++;
    }
    if (n > 0) await _refreshCount();
    return n;
  }

  Future<OutboxItem> _itemFor(ScanResultModel s, String userId, Uint8List bytes) async => OutboxItem(
        scanId: s.id,
        userId: userId,
        imagePath: s.imagePath,
        sha256: sha256.convert(bytes).toString(),
        capturedAt: s.scannedAt,
        source: s.source,
        chosenCrop: s.chosenCropId,
        queuedAt: _now(),
      );

  /// Nouvelle analyse : mise en file puis envoi immédiat si possible (sans
  /// faire attendre l'écran de résultat).
  Future<ScanResultModel> enqueue(ScanResultModel scan, {String? userId}) async {
    if (scan.isError || scan.imagePath.isEmpty) return scan;
    final uid = userId ?? UserScope.userId ?? 'guest';
    final f = File(scan.imagePath);
    if (!await f.exists()) return scan;
    await _outbox.put(await _itemFor(scan, uid, await f.readAsBytes()));
    final queued = scan.copyWith(sync: SyncState(status: SyncStatus.pending, attempts: scan.sync.attempts));
    await _history.updateSyncFor(uid, scan.id, queued.sync);
    await _refreshCount();
    notifyListeners();
    unawaited(syncNow());
    return queued;
  }

  /// Nom conservé pour les appels existants (retour dans l'application).
  Future<int> syncPending({String lang = 'fr'}) => syncNow(lang: lang);

  /// Envoie les analyses dues. Renvoie le nombre d'envois réussis.
  ///
  /// Un seul passage à la fois : un appel reçu pendant un passage (nouvelle
  /// analyse, retour du réseau) en programme un second juste après, et
  /// renvoie le même résultat ; rien n'est donc oublié ni envoyé deux fois.
  Future<int> syncNow({String lang = 'fr'}) {
    final running = _current;
    if (running != null) {
      _again = true;
      return running;
    }
    final run = _loop(lang);
    _current = run;
    return run;
  }

  Future<int>? _current;
  bool _again = false;

  Future<int> _loop(String lang) async {
    var total = 0;
    try {
      do {
        _again = false;
        total += await _pass(lang);
      } while (_again);
    } finally {
      _current = null;
    }
    return total;
  }

  Future<int> _pass(String lang) async {
    final due = await _outbox.due(_now());
    if (due.isEmpty) {
      await _refreshCount();
      return 0;
    }
    _running = true;
    notifyListeners();
    var sent = 0;
    try {
      String token;
      try {
        token = await _account.token();
      } on SharedAccountException catch (e) {
        _lastError = e.code;
        return 0;
      } catch (e) {
        _lastError = _isNetwork(e) ? 'offline' : 'server';
        return 0;
      }

      var reauthenticated = false;
      for (var i = 0; i < due.length; i++) {
        final item = due[i];
        final file = File(item.imagePath);
        if (!await file.exists()) {
          await _drop(item, 'missing-file');
          continue;
        }
        final bytes = await file.readAsBytes();
        if (sha256.convert(bytes).toString() != item.sha256) {
          await _drop(item, 'integrity');
          continue;
        }
        try {
          final receipt = await _client.uploadPhoto(
            token: token,
            bytes: bytes,
            fromCamera: item.source == 'camera',
            capturedAt: item.capturedAt,
            crop: DecisionRule.modelCropOf(item.chosenCrop),
            lang: lang,
          );
          await _outbox.remove(item.scanId);
          await _history.updateSyncFor(
            item.userId,
            item.scanId,
            SyncState(
              status: SyncStatus.sent,
              remoteAnalysisId: receipt.analysisId,
              remoteImagePath: receipt.imagePath,
              sentAt: _now(),
              attempts: item.attempts + 1,
              serverDiagnosis: receipt.diseaseName,
              serverConfidence: receipt.confidence,
            ),
          );
          sent++;
          _lastSentAt = _now();
          _lastError = null;
        } on GreenWebException catch (e) {
          if (e.isUnauthorized) {
            // Jeton expiré ou révoqué : une seule réouverture par passage.
            await _account.invalidate();
            if (reauthenticated) {
              _lastError = 'rejected';
              break;
            }
            reauthenticated = true;
            try {
              token = await _account.token();
            } on SharedAccountException catch (se) {
              _lastError = se.code;
              break;
            }
            i--; // renvoyer la même analyse avec le nouveau jeton
            continue;
          }
          if (e.isPermanent) {
            await _drop(item, 'http-${e.statusCode}', attempts: item.attempts + 1);
            continue;
          }
          await _postpone(item, 'http-${e.statusCode}');
          _lastError = 'server';
        } catch (e) {
          if (_isNetwork(e)) {
            _lastError = 'offline';
            break; // pas de réseau : inutile de parcourir la file
          }
          await _postpone(item, '$e');
          _lastError = 'server';
        }
      }
    } finally {
      _running = false;
      await _refreshCount();
      notifyListeners();
    }
    return sent;
  }

  static bool _isNetwork(Object e) =>
      e is SocketException || e is TimeoutException || e is http.ClientException || e is HandshakeException;

  Future<void> _postpone(OutboxItem item, String error) async {
    final next = item.failedTemporarily(error, _now());
    await _outbox.put(next);
    await _history.updateSyncFor(
      item.userId,
      item.scanId,
      SyncState(status: SyncStatus.pending, attempts: next.attempts, lastError: error),
    );
  }

  Future<void> _drop(OutboxItem item, String error, {int? attempts}) async {
    await _outbox.remove(item.scanId);
    await _history.updateSyncFor(
      item.userId,
      item.scanId,
      SyncState(status: SyncStatus.failed, attempts: attempts ?? item.attempts, lastError: error),
    );
    _lastError = error;
  }

  Future<void> _refreshCount() async {
    _pending = await _outbox.count();
  }

  /// Analyse supprimée par l'utilisateur avant son envoi.
  Future<void> cancel(String scanId) async {
    await _outbox.remove(scanId);
    await _refreshCount();
    notifyListeners();
  }

  /// Suppression d'un compte local : ses analyses en attente ne partent plus.
  Future<void> forget(String userId) async {
    await _outbox.removeUser(userId);
    await _refreshCount();
    notifyListeners();
  }

  /// v2.0 → v2.1 : les jetons « par compte » (bouton Relier) et l'option
  /// d'envoi par compte n'existent plus.
  Future<void> _migrateFromV20() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool('greenweb_v21_migrated') ?? false) return;
      for (final k in prefs.getKeys().where((k) => k.startsWith('greenweb_upload_enabled_')).toList()) {
        await prefs.remove(k);
      }
      const secure = FlutterSecureStorage();
      final all = await secure.readAll();
      for (final k in all.keys.where((k) => k.startsWith('greenweb_token_'))) {
        await secure.delete(key: k);
      }
      await prefs.setBool('greenweb_v21_migrated', true);
    } catch (e) {
      debugPrint('Migration GREEN Web v2.0 → v2.1 : $e');
    }
  }

  @override
  void dispose() {
    _connSub?.cancel();
    _timer?.cancel();
    super.dispose();
  }
}
