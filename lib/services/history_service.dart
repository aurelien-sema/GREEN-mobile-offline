import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/scan_result_model.dart';
import 'user_scope.dart';

class HistoryService {
  List<ScanResultModel> _cache = [];
  // Compte pour lequel _cache a été chargé — comparé à UserScope.userId à
  // chaque accès pour recharger depuis le bon fichier si l'utilisateur a
  // changé (nouvelle connexion, changement de compte sur le même appareil).
  String? _loadedForUserId;
  bool _loaded = false;
  final StreamController<void> _onChanged = StreamController<void>.broadcast();

  /// Stream that emits whenever history changes (add/remove)
  Stream<void> get onChanged => _onChanged.stream;

  String get _fileName => 'scan_history_${UserScope.userId ?? 'guest'}.json';

  Future<File> _getLocalFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  Future<void> _ensureLoaded() async {
    if (_loaded && _loadedForUserId == UserScope.userId) return;
    _loadedForUserId = UserScope.userId;
    _loaded = true;
    try {
      final file = await _getLocalFile();
      if (!await file.exists()) {
        _cache = [];
        return;
      }
      final content = await file.readAsString();
      final List<dynamic> jsonList = jsonDecode(content);
      _cache = jsonList.map((e) => ScanResultModel.fromJson(e)).toList();
    } catch (e, st) {
      // Historique corrompu : on repart sur une liste vide plutôt que de
      // planter, mais on trace l'erreur pour pouvoir diagnostiquer un
      // fichier illisible plutôt que de la masquer silencieusement.
      debugPrint('HistoryService: échec du chargement de $_fileName, historique vidé: $e');
      debugPrint('$st');
      _cache = [];
    }
  }

  /// Notifie les abonnés d'un changement. Le [StreamController] ne lève que
  /// s'il a déjà été fermé ; on garde donc ce cas sous contrôle explicitement
  /// au lieu d'avaler toutes les exceptions.
  void _notifyChanged() {
    if (_onChanged.isClosed) {
      debugPrint('HistoryService: notification ignorée, le stream est fermé.');
      return;
    }
    _onChanged.add(null);
  }

  Future<List<ScanResultModel>> getAllScans() async {
    await _ensureLoaded();
    return List.unmodifiable(_cache);
  }

  Future<List<ScanResultModel>> getRecentScans([int limit = 5]) async {
    await _ensureLoaded();
    final list = List<ScanResultModel>.from(_cache);
    list.sort((a, b) => b.scannedAt.compareTo(a.scannedAt));
    return list.take(limit).toList();
  }

  Future<void> addScan(ScanResultModel scan) async {
    await _ensureLoaded();
    _cache.add(scan);
    await _save();
    _notifyChanged();
  }

  Future<void> _save() async {
    final file = await _getLocalFile();
    final jsonList = _cache.map((e) => e.toJson()).toList();
    await file.writeAsString(jsonEncode(jsonList));
  }

  /// Simple statistics computed from history
  Future<Map<String, dynamic>> getStatistics() async {
    await _ensureLoaded();
    final total = _cache.length;
    double avgConfidence = 0;
    if (total > 0) {
      avgConfidence =
          _cache.map((e) => e.confidence).reduce((a, b) => a + b) / total;
    }
    final Map<String, int> freq = {};
    for (final s in _cache) {
      freq[s.diseaseName] = (freq[s.diseaseName] ?? 0) + 1;
    }
    final List<MapEntry<String, int>> sorted = freq.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final mostCommon = sorted.isNotEmpty ? sorted.first.key : null;
    return {
      'total': total,
      'avgConfidence': avgConfidence,
      'mostCommon': mostCommon,
      'freq': freq,
    };
  }
  Future<List<Map<String, String>>> getUniqueDiseases() async {
    await _ensureLoaded();
    final unique = <String, ScanResultModel>{};
    for (final scan in _cache) {
      if (!unique.containsKey(scan.diseaseName) && 
          !scan.diseaseName.toLowerCase().contains('healthy') && 
          !scan.diseaseName.toLowerCase().contains('saine')) {
        unique[scan.diseaseName] = scan;
      }
    }
    
    return unique.values.map((scan) {
      // Improve this by possibly fetching descriptions from a static map or AI
      return {
        'name': scan.diseaseName,
        'scientificName': scan.diseaseId.split('___').last.replaceAll('_', ' '),
        'description': 'Maladie identifiée sur ${scan.affectedPlants.join(", ")}.',
        'treatment': scan.treatment,
      };
    }).toList();
  }

  /// Remove a scan from history by ID
  Future<void> removeScan(String scanId) async {
    await _ensureLoaded();
    _cache.removeWhere((scan) => scan.id == scanId);
    await _save();
    _notifyChanged();
  }

  /// Clear all scans from history
  Future<void> clearAll() async {
    _cache = [];
    await _save();
    _notifyChanged();
  }
}

final historyService = HistoryService();
