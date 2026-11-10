import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

/// Enregistrement des messages vocaux de GreenBot (WAV PCM 16 bits, 16 kHz,
/// mono : format accepté tel quel par Gemini, sans conversion).
///
/// [levels] émet le niveau sonore normalisé (0 à 1) toutes les 60 ms pour
/// dessiner la forme d'onde en direct. Le fichier est supprimé dès que les
/// octets ont été lus.
class VoiceRecorderService {
  static const sampleRate = 16000;
  static const _tick = Duration(milliseconds: 60);

  AudioRecorder? _recorder;
  StreamSubscription<Amplitude>? _ampSub;
  final _levels = StreamController<double>.broadcast();
  String? _path;
  DateTime? _startedAt;

  Stream<double> get levels => _levels.stream;
  bool get isRecording => _startedAt != null;
  Duration get elapsed => _startedAt == null ? Duration.zero : DateTime.now().difference(_startedAt!);

  /// [request] = false : vérifie sans afficher la demande d'autorisation.
  Future<bool> hasPermission({bool request = true}) async {
    _recorder ??= AudioRecorder();
    return _recorder!.hasPermission(request: request);
  }

  Future<void> start() async {
    _recorder ??= AudioRecorder();
    final dir = await getTemporaryDirectory();
    _path = '${dir.path}/greenbot_${DateTime.now().millisecondsSinceEpoch}.wav';
    await _recorder!.start(
      const RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: sampleRate,
        numChannels: 1,
        autoGain: true,
        noiseSuppress: true,
      ),
      path: _path!,
    );
    _startedAt = DateTime.now();
    _ampSub = _recorder!.onAmplitudeChanged(_tick).listen((a) {
      _levels.add(normalizeDb(a.current));
    });
  }

  /// Arrête et renvoie l'audio (null si trop court ou en cas d'échec).
  Future<Uint8List?> stop({Duration minDuration = const Duration(milliseconds: 700)}) async {
    final duration = elapsed;
    await _ampSub?.cancel();
    _ampSub = null;
    _startedAt = null;
    final path = await _recorder?.stop() ?? _path;
    if (path == null) return null;
    final file = File(path);
    try {
      if (duration < minDuration || !await file.exists()) return null;
      return await file.readAsBytes();
    } finally {
      if (await file.exists()) await file.delete();
    }
  }

  Future<void> cancel() async {
    await _ampSub?.cancel();
    _ampSub = null;
    _startedAt = null;
    await _recorder?.cancel();
  }

  Future<void> dispose() async {
    await cancel();
    await _recorder?.dispose();
    _recorder = null;
    await _levels.close();
  }

  /// dBFS (-160 à 0) → 0..1, avec une courbe adaptée à la voix (-50 dB ≈ 0).
  static double normalizeDb(double db) {
    if (db.isNaN || db.isInfinite) return 0;
    final v = ((db + 50) / 50).clamp(0.0, 1.0);
    return math.pow(v, 1.6).toDouble();
  }
}
