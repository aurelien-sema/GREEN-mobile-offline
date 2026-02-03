import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import '../models/scan_result_model.dart';

class HistoryService {
  static const _fileName = 'scan_history.json';
  List<ScanResultModel> _cache = [];
  final StreamController<void> _onChanged = StreamController<void>.broadcast();

  /// Stream that emits whenever history changes (add/remove)
  Stream<void> get onChanged => _onChanged.stream;

  Future<File> _getLocalFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  Future<void> _ensureLoaded() async {
    if (_cache.isNotEmpty) return;
    try {
      final file = await _getLocalFile();
      if (!await file.exists()) {
        _cache = [];
        return;
      }
      final content = await file.readAsString();
      final List<dynamic> jsonList = jsonDecode(content);
      _cache = jsonList.map((e) => ScanResultModel.fromJson(e)).toList();
    } catch (_) {
      _cache = [];
    }
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
    try {
      _onChanged.add(null);
    } catch (_) {}
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
}

final historyService = HistoryService();
