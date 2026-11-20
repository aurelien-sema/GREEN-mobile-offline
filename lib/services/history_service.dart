import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/scan_result_model.dart';
import 'storage/scan_image_store.dart';
import 'user_scope.dart';

/// Historique des analyses du compte connecté :
/// `<documents>/scan_history_<compte>.json`, du plus récent au plus ancien.
class HistoryService {
  final Future<Directory> Function() _dir;
  final ScanImageStore _images;

  List<ScanResultModel> _cache = [];
  String? _loadedFor;
  bool _loaded = false;
  Future<void>? _loading;
  Future<void> _writes = Future.value();
  final StreamController<void> _changes = StreamController<void>.broadcast();

  HistoryService({Future<Directory> Function()? directory, ScanImageStore? images})
      : _dir = directory ?? getApplicationDocumentsDirectory,
        _images = images ?? scanImageStore;

  /// Émis à chaque ajout, modification ou suppression.
  Stream<void> get onChanged => _changes.stream;

  Future<File> _file() async =>
      File('${(await _dir()).path}/scan_history_${UserScope.userId ?? 'guest'}.json');

  Future<void> _ensureLoaded() {
    if (_loaded && _loadedFor == UserScope.userId) return Future.value();
    return _loading ??= _load().whenComplete(() => _loading = null);
  }

  Future<void> _load() async {
    _loadedFor = UserScope.userId;
    _cache = [];
    try {
      final f = await _file();
      if (await f.exists()) {
        final list = jsonDecode(await f.readAsString()) as List<dynamic>;
        _cache = list.map((e) => ScanResultModel.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (_) {
      _cache = [];
    }
    _cache.sort((a, b) => b.scannedAt.compareTo(a.scannedAt));
    _loaded = true;
    await _migrateLegacyImages();
  }

  /// Entrées v1 : la photo pointait vers le cache temporaire du sélecteur.
  /// Si le fichier existe encore, on en fait une copie permanente.
  Future<void> _migrateLegacyImages() async {
    var changed = false;
    for (var i = 0; i < _cache.length; i++) {
      final s = _cache[i];
      if (s.thumbPath != null || s.imagePath.isEmpty) continue;
      final f = File(s.imagePath);
      if (!await f.exists() || s.imagePath.contains('/scans/')) continue;
      try {
        final (photo, thumb) = await _images.persist(f, s.id);
        _cache[i] = s.copyWith(imagePath: photo, thumbPath: thumb);
        changed = true;
      } catch (_) {}
    }
    if (changed) await _save();
  }

  Future<void> _save() async {
    final f = await _file();
    await _writeAtomic(f, _cache);
    _changes.add(null);
  }

  /// Écritures sérialisées (deux mises à jour simultanées ne peuvent pas se
  /// croiser sur le même fichier temporaire) et atomiques.
  Future<void> _writeAtomic(File f, List<ScanResultModel> scans) {
    final json = jsonEncode(scans.map((e) => e.toJson()).toList());
    return _writes = _writes.then((_) async {
      final tmp = File('${f.path}.tmp');
      await tmp.writeAsString(json, flush: true);
      await tmp.rename(f.path);
    });
  }

  File _fileFor(Directory dir, String userId) => File('${dir.path}/scan_history_$userId.json');

  /// Analyses d'un compte précis, connecté ou non (file d'envoi).
  Future<List<ScanResultModel>> scansFor(String userId) async {
    if (userId == UserScope.userId) return getAllScans();
    try {
      final f = _fileFor(await _dir(), userId);
      if (!await f.exists()) return const [];
      final list = jsonDecode(await f.readAsString()) as List<dynamic>;
      return list.map((e) => ScanResultModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return const [];
    }
  }

  /// Met à jour l'état d'envoi d'une analyse, même si son compte n'est pas
  /// celui qui est connecté (la file d'envoi est commune au téléphone).
  Future<void> updateSyncFor(String userId, String scanId, SyncState sync) async {
    if (userId == UserScope.userId) {
      final scan = await findById(scanId);
      if (scan != null) await updateScan(scan.copyWith(sync: sync));
      return;
    }
    final scans = (await scansFor(userId)).toList();
    final i = scans.indexWhere((s) => s.id == scanId);
    if (i == -1) return;
    scans[i] = scans[i].copyWith(sync: sync);
    await _writeAtomic(_fileFor(await _dir(), userId), scans);
  }

  Future<List<ScanResultModel>> getAllScans() async {
    await _ensureLoaded();
    return List.unmodifiable(_cache);
  }

  Future<List<ScanResultModel>> getRecentScans([int limit = 5]) async {
    await _ensureLoaded();
    return _cache.take(limit).toList();
  }

  Future<ScanResultModel?> findById(String id) async {
    await _ensureLoaded();
    for (final s in _cache) {
      if (s.id == id) return s;
    }
    return null;
  }

  Future<void> addScan(ScanResultModel scan) async {
    await _ensureLoaded();
    _cache.insert(0, scan);
    await _save();
  }

  Future<void> updateScan(ScanResultModel scan) async {
    await _ensureLoaded();
    final i = _cache.indexWhere((s) => s.id == scan.id);
    if (i == -1) return;
    _cache[i] = scan;
    await _save();
  }

  /// Retire l'analyse de l'historique. Les fichiers ne sont supprimés que
  /// par [purgeFiles], pour permettre l'annulation (« Annuler » du SnackBar).
  Future<ScanResultModel?> removeScan(String id) async {
    await _ensureLoaded();
    final i = _cache.indexWhere((s) => s.id == id);
    if (i == -1) return null;
    final removed = _cache.removeAt(i);
    await _save();
    return removed;
  }

  Future<void> restoreScan(ScanResultModel scan) async {
    await _ensureLoaded();
    _cache.add(scan);
    _cache.sort((a, b) => b.scannedAt.compareTo(a.scannedAt));
    await _save();
  }

  Future<void> purgeFiles(ScanResultModel scan) => _images.delete(scan.imagePath, scan.thumbPath);

  Future<void> clearAll() async {
    await _ensureLoaded();
    final old = List<ScanResultModel>.from(_cache);
    _cache = [];
    await _save();
    for (final s in old) {
      await purgeFiles(s);
    }
  }

  /// Statistiques simples pour le profil.
  Future<HistoryStats> statistics() async {
    await _ensureLoaded();
    final analysed = _cache.where((s) => !s.isError).toList();
    final diseased = analysed.where((s) => s.isDiseased).toList();
    final freq = <String, int>{};
    for (final s in diseased) {
      final key = s.diseaseId ?? s.label;
      freq[key] = (freq[key] ?? 0) + 1;
    }
    String? top;
    var best = 0;
    freq.forEach((k, v) {
      if (v > best) {
        best = v;
        top = k;
      }
    });
    return HistoryStats(
      total: analysed.length,
      healthy: analysed.where((s) => s.isHealthy).length,
      diseased: diseased.length,
      // 2.2.0 : « sans diagnostic » compte aussi les cultures non cohérentes.
      uncertain: analysed.where((s) => s.isUncertain || s.isWrongCrop).length,
      mostFrequentDiseaseId: top,
    );
  }

  /// Suppression complète des données d'un compte (fichier + photos).
  Future<void> deleteAllFor(String userId) async {
    final f = File('${(await _dir()).path}/scan_history_$userId.json');
    if (await f.exists()) await f.delete();
    await _images.deleteAllFor(userId);
    if (_loadedFor == userId) {
      _cache = [];
      _loaded = false;
    }
  }
}

class HistoryStats {
  final int total;
  final int healthy;
  final int diseased;
  final int uncertain;
  final String? mostFrequentDiseaseId;

  const HistoryStats({
    required this.total,
    required this.healthy,
    required this.diseased,
    required this.uncertain,
    this.mostFrequentDiseaseId,
  });
}

final historyService = HistoryService();
