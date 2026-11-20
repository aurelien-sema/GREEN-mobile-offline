import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:path_provider/path_provider.dart';

/// Une analyse en attente d'envoi au serveur.
class OutboxItem {
  final String scanId;
  final String userId;
  final String imagePath;

  /// SHA-256 de la photo au moment de l'analyse : vérifié avant l'envoi
  /// (une photo modifiée ou corrompue n'est jamais envoyée) ; c'est aussi
  /// la clé de dédoublonnage du serveur.
  final String sha256;
  final DateTime capturedAt;
  final String source;

  /// Culture choisie avant la photo (cassava, maize, tomato), envoyée au
  /// serveur pour qu'il applique la même règle wrong_crop (2.2.0). null
  /// pour les analyses plus anciennes.
  final String? chosenCrop;
  final DateTime queuedAt;
  final int attempts;
  final DateTime? nextAttemptAt;
  final String? lastError;

  const OutboxItem({
    required this.scanId,
    required this.userId,
    required this.imagePath,
    required this.sha256,
    required this.capturedAt,
    required this.source,
    this.chosenCrop,
    required this.queuedAt,
    this.attempts = 0,
    this.nextAttemptAt,
    this.lastError,
  });

  bool isDue(DateTime now) => nextAttemptAt == null || !now.isBefore(nextAttemptAt!);

  /// Échec temporaire (serveur indisponible, 429…) : nouvel essai après un
  /// délai exponentiel de 30 s × 2^n, plafonné à 6 h. Pas de limite du
  /// nombre d'essais : une analyse n'est jamais abandonnée pour une panne.
  OutboxItem failedTemporarily(String error, DateTime now) {
    final n = attempts + 1;
    final seconds = math.min(30 * math.pow(2, n - 1).toInt(), backoffCap.inSeconds);
    return copyWith(attempts: n, nextAttemptAt: now.add(Duration(seconds: seconds)), lastError: error);
  }

  static const backoffCap = Duration(hours: 6);

  OutboxItem copyWith({int? attempts, DateTime? nextAttemptAt, String? lastError}) => OutboxItem(
        scanId: scanId,
        userId: userId,
        imagePath: imagePath,
        sha256: sha256,
        capturedAt: capturedAt,
        source: source,
        chosenCrop: chosenCrop,
        queuedAt: queuedAt,
        attempts: attempts ?? this.attempts,
        nextAttemptAt: nextAttemptAt ?? this.nextAttemptAt,
        lastError: lastError ?? this.lastError,
      );

  factory OutboxItem.fromJson(Map<String, dynamic> j) => OutboxItem(
        scanId: j['scan_id'] as String,
        userId: j['user_id'] as String,
        imagePath: j['image_path'] as String,
        sha256: j['sha256'] as String,
        capturedAt: DateTime.parse(j['captured_at'] as String),
        source: (j['source'] as String?) ?? 'camera',
        chosenCrop: j['chosen_crop'] as String?,
        queuedAt: DateTime.parse(j['queued_at'] as String),
        attempts: (j['attempts'] as num?)?.toInt() ?? 0,
        nextAttemptAt: DateTime.tryParse((j['next_attempt_at'] as String?) ?? ''),
        lastError: j['last_error'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'scan_id': scanId,
        'user_id': userId,
        'image_path': imagePath,
        'sha256': sha256,
        'captured_at': capturedAt.toIso8601String(),
        'source': source,
        'chosen_crop': chosenCrop,
        'queued_at': queuedAt.toIso8601String(),
        'attempts': attempts,
        'next_attempt_at': nextAttemptAt?.toIso8601String(),
        'last_error': lastError,
      };
}

/// File d'envoi persistante : `<documents>/upload_outbox.json`.
///
/// Pourquoi ici et pas dans le cache : Android peut vider le cache d'une
/// application à tout moment quand la mémoire manque ; une analyse en
/// attente y serait perdue. Le dossier documents de l'application est privé
/// (inaccessible aux autres applications) et chiffré par le système
/// (chiffrement des fichiers d'Android). La photo elle-même est déjà
/// conservée à part (`scans/<compte>/<analyse>.jpg`) : la file ne stocke que
/// sa référence et son empreinte, pas une deuxième copie.
///
/// Écritures atomiques (fichier temporaire puis renommage) et sérialisées :
/// une coupure pendant l'écriture laisse l'ancienne file intacte.
class UploadOutbox {
  static const fileName = 'upload_outbox.json';

  final Future<Directory> Function() _dir;
  final List<OutboxItem> _items = [];
  bool _loaded = false;
  Future<void>? _loading;
  Future<void> _writes = Future.value();

  UploadOutbox({Future<Directory> Function()? directory}) : _dir = directory ?? getApplicationDocumentsDirectory;

  Future<File> _file() async => File('${(await _dir()).path}/$fileName');

  Future<void> _ensureLoaded() => _loaded ? Future.value() : (_loading ??= _load());

  Future<void> _load() async {
    try {
      final f = await _file();
      if (await f.exists()) {
        final data = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
        for (final e in (data['items'] as List<dynamic>? ?? const [])) {
          try {
            _items.add(OutboxItem.fromJson(e as Map<String, dynamic>));
          } catch (_) {}
        }
      }
    } catch (_) {
      // Fichier illisible : la file repart vide, les analyses restent dans
      // l'historique avec leur statut et sont remises en file (backfill).
    }
    _loaded = true;
  }

  Future<void> _save() {
    final snapshot = jsonEncode({'schema': 1, 'items': _items.map((e) => e.toJson()).toList()});
    return _writes = _writes.then((_) async {
      final f = await _file();
      final tmp = File('${f.path}.tmp');
      await tmp.writeAsString(snapshot, flush: true);
      await tmp.rename(f.path);
    });
  }

  Future<List<OutboxItem>> items() async {
    await _ensureLoaded();
    return List.unmodifiable(_items);
  }

  Future<int> count() async => (await items()).length;

  Future<bool> contains(String scanId) async => (await items()).any((e) => e.scanId == scanId);

  /// Ajoute (ou remplace) l'analyse.
  Future<void> put(OutboxItem item) async {
    await _ensureLoaded();
    _items.removeWhere((e) => e.scanId == item.scanId);
    _items.add(item);
    await _save();
  }

  Future<void> remove(String scanId) async {
    await _ensureLoaded();
    final before = _items.length;
    _items.removeWhere((e) => e.scanId == scanId);
    if (_items.length != before) await _save();
  }

  Future<void> removeUser(String userId) async {
    await _ensureLoaded();
    final before = _items.length;
    _items.removeWhere((e) => e.userId == userId);
    if (_items.length != before) await _save();
  }

  /// Analyses à envoyer maintenant, de la plus ancienne à la plus récente.
  Future<List<OutboxItem>> due(DateTime now) async {
    await _ensureLoaded();
    return (_items.where((e) => e.isDue(now)).toList()..sort((a, b) => a.queuedAt.compareTo(b.queuedAt)));
  }

  Future<void> flush() => _writes;
}
