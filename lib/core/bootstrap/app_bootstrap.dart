import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../providers/auth_provider.dart';
import '../../providers/diseases_provider.dart';
import '../../services/gemini/gemini_service.dart';
import '../../services/green_web/photo_sync_service.dart';
import '../../services/rag_service.dart';
import '../../services/vision/vision_model.dart';

/// Initialisations faites pendant l'écran de démarrage (et non plus avant
/// runApp, qui laissait l'écran vide plusieurs secondes, suivi d'une attente
/// artificielle de 3 s).
class AppBootstrap {
  AppBootstrap._();

  static bool _gemini = false;

  /// Charge les clés (assets/.env, puis --dart-define en repli).
  static Future<void> loadEnv() async {
    try {
      await dotenv.load(fileName: 'assets/.env');
    } catch (e) {
      debugPrint('assets/.env absent ou illisible : $e');
    }
  }

  static String? _env(String key) {
    String? v;
    try {
      v = dotenv.maybeGet(key);
    } catch (_) {}
    if (v == null || v.isEmpty) {
      v = switch (key) {
        'GEMINI_API_KEY' => const String.fromEnvironment('GEMINI_API_KEY'),
        'GEMINI_MODEL' => const String.fromEnvironment('GEMINI_MODEL'),
        'GEMINI_AUDIO_MODEL' => const String.fromEnvironment('GEMINI_AUDIO_MODEL'),
        _ => '',
      };
    }
    return v.isEmpty ? null : v;
  }

  static Future<void> run({
    required AuthProvider auth,
    required DiseasesProvider diseases,
    required PhotoSyncService sync,
  }) async {
    if (!_gemini) {
      final key = _env('GEMINI_API_KEY');
      if (key != null) {
        geminiService.initialize(key, chatModel: _env('GEMINI_MODEL'), audioModel: _env('GEMINI_AUDIO_MODEL'));
      }
      _gemini = true;
    }
    // restoreSession notifie AuthProvider : GreenApp relie alors l'envoi
    // GREEN Web au compte restauré.
    await Future.wait([
      auth.restoreSession(),
      diseases.load(),
    ]);
    // Préchargements non bloquants : index documentaire et modèle de vision.
    RagService.instance.initFromAssets();
    visionEngine.model().then<void>((_) {}, onError: (Object e) => debugPrint('Modèle de vision non préchargé : $e'));
    visionEngine.activeLabels().then(diseases.setActiveModelLabels, onError: (Object e) => debugPrint('Classes du modèle illisibles : $e'));
  }
}
