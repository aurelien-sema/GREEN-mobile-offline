import 'dart:convert';
import 'dart:io';

import 'package:uuid/uuid.dart';

/// Une ligne du registre : un compte créé depuis ce téléphone.
class RegistryEntry {
  final String accountId;
  final String fullName;
  final String phone;
  final String email;
  final DateTime createdAt;
  final String? securityQuestionId;
  final String? securityQuestion;
  final String? securityAnswerHash;
  final String status; // 'active' | 'deleted'
  final DateTime? deletedAt;

  const RegistryEntry({
    required this.accountId,
    required this.fullName,
    required this.phone,
    required this.email,
    required this.createdAt,
    this.securityQuestionId,
    this.securityQuestion,
    this.securityAnswerHash,
    this.status = 'active',
    this.deletedAt,
  });

  bool get isActive => status == 'active';

  factory RegistryEntry.fromJson(Map<String, dynamic> j) => RegistryEntry(
        accountId: j['account_id'] as String,
        fullName: (j['full_name'] as String?) ?? '',
        phone: (j['phone'] as String?) ?? '',
        email: (j['email'] as String?) ?? '',
        createdAt: DateTime.tryParse((j['created_at'] as String?) ?? '') ?? DateTime(1970),
        securityQuestionId: j['security_question_id'] as String?,
        securityQuestion: j['security_question'] as String?,
        securityAnswerHash: j['security_answer_hash'] as String?,
        status: (j['status'] as String?) ?? 'active',
        deletedAt: DateTime.tryParse((j['deleted_at'] as String?) ?? ''),
      );

  Map<String, dynamic> toJson() => {
        'account_id': accountId,
        'full_name': fullName,
        'phone': phone,
        'email': email,
        'created_at': createdAt.toIso8601String(),
        'security_question_id': securityQuestionId,
        'security_question': securityQuestion,
        'security_answer_hash': securityAnswerHash,
        'status': status,
        'deleted_at': deletedAt?.toIso8601String(),
      };

  /// Compte supprimé : la ligne est conservée (elle compte toujours dans la
  /// limite de comptes par téléphone) mais ses données personnelles sont
  /// effacées.
  RegistryEntry anonymized(DateTime when) => RegistryEntry(
        accountId: accountId,
        fullName: '',
        phone: '',
        email: '',
        createdAt: createdAt,
        securityQuestionId: securityQuestionId,
        securityQuestion: securityQuestion,
        status: 'deleted',
        deletedAt: when,
      );
}

/// Registre JSON des comptes créés depuis ce téléphone :
/// `<documents de l'app>/account_registry.json`.
///
/// Il enregistre, pour chaque nouveau compte, ses informations, la question
/// de sécurité tirée au hasard et la réponse (hachée, jamais en clair). Il
/// sert aussi à appliquer la limite de comptes par téléphone : une ligne
/// n'est jamais retirée, même quand le compte est supprimé, pour qu'on ne
/// puisse pas contourner la limite en supprimant puis recréant des comptes.
///
/// Limite connue : le fichier vit dans le stockage privé de l'application.
/// Une désinstallation sans sauvegarde Android l'efface, comme le reste des
/// données locales. Seul un contrôle côté serveur rendrait la limite
/// infranchissable.
class AccountRegistry {
  static const fileName = 'account_registry.json';
  static const schemaVersion = 1;

  final Future<Directory> Function() _dir;
  String _installationId = '';
  List<RegistryEntry> _entries = [];
  bool _loaded = false;

  AccountRegistry(this._dir);

  String get installationId => _installationId;
  List<RegistryEntry> get entries => List.unmodifiable(_entries);
  int get createdCount => _entries.length;
  bool get isLoaded => _loaded;

  Future<File> _file() async => File('${(await _dir()).path}/$fileName');

  Future<void> load() async {
    if (_loaded) return;
    final f = await _file();
    if (await f.exists()) {
      try {
        final json = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
        _installationId = (json['installation_id'] as String?) ?? '';
        _entries = ((json['accounts'] as List?) ?? [])
            .map((e) => RegistryEntry.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {
        // Fichier illisible : on repart d'un registre vide plutôt que de
        // bloquer l'application ; l'ancien fichier est gardé pour analyse.
        await f.copy('${f.path}.corrupt');
        _entries = [];
      }
    }
    if (_installationId.isEmpty) _installationId = const Uuid().v4();
    _loaded = true;
  }

  Future<void> add(RegistryEntry entry) async {
    await load();
    _entries.add(entry);
    await _save();
  }

  /// Ajoute les comptes existants absents du registre (comptes créés avant
  /// la version 2) pour qu'ils comptent dans la limite.
  Future<void> backfill(Iterable<RegistryEntry> existing) async {
    await load();
    final known = _entries.map((e) => e.accountId).toSet();
    final missing = existing.where((e) => !known.contains(e.accountId)).toList();
    if (missing.isEmpty && await (await _file()).exists()) return;
    _entries.addAll(missing);
    await _save();
  }

  Future<void> update(String accountId, RegistryEntry Function(RegistryEntry) change) async {
    await load();
    final i = _entries.indexWhere((e) => e.accountId == accountId);
    if (i == -1) return;
    _entries[i] = change(_entries[i]);
    await _save();
  }

  Future<void> _save() async {
    final f = await _file();
    final tmp = File('${f.path}.tmp');
    await tmp.writeAsString(const JsonEncoder.withIndent('  ').convert({
      'schema': schemaVersion,
      'installation_id': _installationId,
      'updated_at': DateTime.now().toIso8601String(),
      'accounts': _entries.map((e) => e.toJson()).toList(),
    }));
    // Écriture atomique : un arrêt brutal pendant l'enregistrement ne peut
    // pas laisser un fichier à moitié écrit.
    await tmp.rename(f.path);
  }
}
