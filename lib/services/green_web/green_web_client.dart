import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// Client de l'API GREEN Web hébergée sur o2switch
/// (https://api-green.gitingeniering.com, voir GUIDE_INTEGRATION_O2SWITCH.md
/// du dépôt Greennew).
///
/// Ce que l'application web attend, sans aucune modification de son côté :
/// - un compte GREEN Web (téléphone ou e-mail + mot de passe) ouvert par
///   POST /api/auth/login, qui renvoie un jeton JWT valable 7 jours ;
/// - l'envoi de la photo en multipart (champ `file`, JPEG ≤ 8 Mo) sur
///   POST /api/camera/analyze-frame (photo prise) ou /api/camera/upload
///   (image de la galerie), avec l'en-tête `Authorization: Bearer <jeton>` ;
/// - le serveur réanalyse l'image, l'enregistre dans son dossier privé
///   (MEDIA_DIR = ~/green_media) et la référence en base : elle apparaît
///   alors dans l'historique web, la GREEN Map et la GREEN Data du même
///   compte, servie par GET /api/media/… (propriétaire uniquement) ;
/// - le consentement GREEN Data (réutilisation des images pour le jeu de
///   données) suit `dataset_consent` du compte ;
/// - une même photo (même SHA-256) envoyée deux fois par le même compte
///   n'est pas réanalysée : le serveur renvoie l'analyse existante avec
///   `duplicate: true`. Les renvois après une coupure réseau sont donc sans
///   effet de bord.
///
/// Depuis la v2.1, l'application utilise un compte GREEN Web unique, partagé
/// par tous les comptes du téléphone (voir SharedWebAccount).
class GreenWebClient {
  static const defaultBaseUrl = 'https://api-green.gitingeniering.com';
  static const _timeout = Duration(seconds: 30);
  static const _uploadTimeout = Duration(seconds: 90);

  final http.Client _http;
  final String baseUrl;

  GreenWebClient({http.Client? httpClient, String? baseUrl})
      : _http = httpClient ?? http.Client(),
        baseUrl = _cleanBase(baseUrl ?? _envBaseUrl());

  static String _envBaseUrl() {
    try {
      final v = dotenv.maybeGet('GREEN_API_BASE_URL');
      if (v != null && v.trim().isNotEmpty) return v.trim();
    } catch (_) {}
    return defaultBaseUrl;
  }

  static String _cleanBase(String url) => url.endsWith('/') ? url.substring(0, url.length - 1) : url;

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  Future<WebSession> login(String identifier, String password) async {
    final res = await _http
        .post(
          _uri('/api/auth/login'),
          headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
          body: jsonEncode({'identifier': identifier, 'password': password}),
        )
        .timeout(_timeout);
    return WebSession.fromJson(_decode(res));
  }

  Future<WebUser> me(String token) async {
    final res = await _http.get(_uri('/api/auth/me'), headers: _auth(token)).timeout(_timeout);
    return WebUser.fromJson(_decode(res));
  }

  /// Envoie une photo. [fromCamera] choisit l'endpoint (source « camera »
  /// ou « upload » dans la GREEN Data). Les octets envoyés sont exactement
  /// ceux dont l'empreinte a été vérifiée par l'appelant.
  Future<UploadReceipt> uploadPhoto({
    required String token,
    required Uint8List bytes,
    required bool fromCamera,
    required DateTime capturedAt,
    String? crop,
    String lang = 'fr',
  }) async {
    final path = fromCamera ? '/api/camera/analyze-frame' : '/api/camera/upload';
    final req = http.MultipartRequest('POST', _uri(path))
      ..headers.addAll({..._auth(token), 'Accept-Language': lang})
      ..fields['captured_at'] = capturedAt.toUtc().toIso8601String();
    if (fromCamera) req.fields['source'] = 'camera';
    // 2.2.0 : culture choisie avant la photo (Cassava, Corn ou Tomato) ; le
    // serveur applique alors la même règle (wrong_crop) que le téléphone.
    if (crop != null) req.fields['crop'] = crop;
    req.files.add(http.MultipartFile.fromBytes('file', bytes, filename: 'green_mobile.jpg'));
    final streamed = await _http.send(req).timeout(_uploadTimeout);
    final res = await http.Response.fromStream(streamed).timeout(_uploadTimeout);
    return UploadReceipt.fromJson(_decode(res));
  }

  Map<String, String> _auth(String token) => {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      };

  Map<String, dynamic> _decode(http.Response res) {
    Map<String, dynamic>? body;
    try {
      final decoded = jsonDecode(utf8.decode(res.bodyBytes));
      if (decoded is Map<String, dynamic>) body = decoded;
    } catch (_) {}
    if (res.statusCode >= 200 && res.statusCode < 300 && body != null) return body;
    final detail = body?['detail'];
    throw GreenWebException(
      res.statusCode,
      detail is String ? detail : (detail == null ? 'HTTP ${res.statusCode}' : jsonEncode(detail)),
    );
  }

  void close() => _http.close();
}

class GreenWebException implements Exception {
  final int statusCode;
  final String message;
  const GreenWebException(this.statusCode, this.message);

  bool get isUnauthorized => statusCode == 401 || statusCode == 403;
  bool get isConflict => statusCode == 409;
  bool get isTooLarge => statusCode == 413;

  /// Erreur définitive pour cette image (inutile de réessayer) : requête
  /// refusée sur le fond. 408, 429 et 5xx sont temporaires.
  bool get isPermanent =>
      statusCode == 400 || statusCode == 404 || statusCode == 413 || statusCode == 415 || statusCode == 422;

  @override
  String toString() => 'GreenWebException($statusCode): $message';
}

class WebUser {
  final int id;
  final String firstName;
  final String lastName;
  final String phone;
  final bool datasetConsent;

  const WebUser({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.datasetConsent,
  });

  factory WebUser.fromJson(Map<String, dynamic> j) => WebUser(
        id: (j['id'] as num).toInt(),
        firstName: (j['first_name'] as String?) ?? '',
        lastName: (j['last_name'] as String?) ?? '',
        phone: (j['phone'] as String?) ?? '',
        datasetConsent: (j['dataset_consent'] as bool?) ?? false,
      );

  String get displayName => '$firstName $lastName'.trim();
}

class WebSession {
  final String token;
  final WebUser user;
  const WebSession(this.token, this.user);

  factory WebSession.fromJson(Map<String, dynamic> j) =>
      WebSession(j['access_token'] as String, WebUser.fromJson(j['user'] as Map<String, dynamic>));
}

class UploadReceipt {
  final int? analysisId;
  final String? imagePath;
  final bool duplicate;

  /// Bloc `disease` de la réponse : diagnostic du modèle serveur.
  final String? diseaseName;
  final double? confidence;

  /// Statut de la règle côté serveur (ok, unknown, wrong_crop), null pour
  /// un ancien serveur (2.2.0).
  final String? status;

  const UploadReceipt({
    this.analysisId,
    this.imagePath,
    this.duplicate = false,
    this.status,
    this.diseaseName,
    this.confidence,
  });

  /// Deux formats de réponse :
  /// - serveur classifier_v1 (2.2.0) : `status` (ok / unknown / wrong_crop),
  ///   `disease` = nom de la classe ou null si le statut n'est pas « ok »,
  ///   `confidence` (0–1) au premier niveau ; sans réponse, pas
  ///   d'`analysis_id` ;
  /// - ancien serveur : bloc `disease` { disease_name, confidence }.
  factory UploadReceipt.fromJson(Map<String, dynamic> j) {
    final raw = j['disease'];
    final block = raw is Map<String, dynamic> ? raw : const <String, dynamic>{};
    final name = raw is String ? raw : (block['disease_name'] ?? block['detected_disease']) as String?;
    final conf = ((raw is Map ? block['confidence'] : j['confidence']) as num?)?.toDouble();
    return UploadReceipt(
      analysisId: (j['analysis_id'] as num?)?.toInt(),
      imagePath: j['image_path'] as String?,
      duplicate: (j['duplicate'] as bool?) ?? false,
      status: j['status'] as String?,
      diseaseName: name,
      // Confiance gardée seulement avec un diagnostic. Le serveur l'exprime en
      // 0–1 ou en pourcentage selon les versions.
      confidence: name == null || conf == null ? null : (conf > 1 ? conf / 100 : conf),
    );
  }
}
