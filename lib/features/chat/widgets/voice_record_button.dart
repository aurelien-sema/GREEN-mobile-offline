import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../services/gemini/gemini_service.dart';
import '../../../services/voice/voice_recorder_service.dart';

enum VoicePhase { idle, holding, locked }

/// Bouton micro de GreenBot, au comportement de Telegram :
/// - maintenir : l'enregistrement dure tant que le doigt reste posé ; il
///   s'arrête au relâchement et le vocal part aussitôt ;
/// - glisser vers le HAUT pendant le maintien : l'enregistrement est
///   verrouillé, on peut lâcher ; il ne s'arrête (et ne part) que lorsqu'on
///   appuie de nouveau sur le bouton ;
/// - glisser vers la GAUCHE pendant le maintien, ou la corbeille en mode
///   verrouillé : annule sans rien envoyer.
///
/// [onPhaseChanged] et [levels] permettent à la barre de saisie d'afficher
/// la forme d'onde et le chronomètre pendant l'enregistrement.
class VoiceRecordController extends ChangeNotifier {
  final VoiceRecorderService recorder = VoiceRecorderService();
  VoicePhase phase = VoicePhase.idle;
  double dragDx = 0;
  double dragDy = 0;
  final List<double> levels = [];
  Duration elapsed = Duration.zero;
  Timer? _ticker;
  StreamSubscription<double>? _levelSub;

  static const lockThreshold = 70.0;
  static const cancelThreshold = 110.0;
  static const maxBars = 48;

  bool get isRecording => phase != VoicePhase.idle;

  /// Démarre l'enregistrement (l'autorisation micro doit déjà être accordée).
  Future<void> begin() async {
    await recorder.start();
    levels.clear();
    dragDx = 0;
    dragDy = 0;
    phase = VoicePhase.holding;
    _levelSub = recorder.levels.listen((v) {
      levels.add(v);
      if (levels.length > maxBars) levels.removeAt(0);
      notifyListeners();
    });
    _ticker = Timer.periodic(const Duration(milliseconds: 200), (_) {
      elapsed = recorder.elapsed;
      notifyListeners();
    });
    HapticFeedback.mediumImpact();
    notifyListeners();
  }

  void lock() {
    if (phase != VoicePhase.holding) return;
    phase = VoicePhase.locked;
    dragDx = 0;
    dragDy = 0;
    HapticFeedback.selectionClick();
    notifyListeners();
  }

  void drag(Offset delta) {
    if (phase != VoicePhase.holding) return;
    dragDx = (dragDx + delta.dx).clamp(-200, 0);
    dragDy = (dragDy + delta.dy).clamp(-120, 0);
    notifyListeners();
  }

  Future<Uint8List?> finish() async {
    _stopTimers();
    phase = VoicePhase.idle;
    notifyListeners();
    HapticFeedback.lightImpact();
    return recorder.stop();
  }

  Future<void> cancel() async {
    _stopTimers();
    phase = VoicePhase.idle;
    notifyListeners();
    HapticFeedback.heavyImpact();
    await recorder.cancel();
  }

  void _stopTimers() {
    _ticker?.cancel();
    _ticker = null;
    _levelSub?.cancel();
    _levelSub = null;
    elapsed = Duration.zero;
  }

  @override
  void dispose() {
    _stopTimers();
    recorder.dispose();
    super.dispose();
  }
}

class VoiceRecordButton extends StatefulWidget {
  final VoiceRecordController controller;
  final ValueChanged<Uint8List> onRecorded;
  final VoidCallback onPermissionDenied;

  /// Autorisation tout juste accordée : la boîte de dialogue système a
  /// interrompu l'appui, il faut maintenir à nouveau.
  final VoidCallback onPermissionGranted;
  final VoidCallback onTooShort;
  final bool enabled;
  final String tooltip;

  const VoiceRecordButton({
    super.key,
    required this.controller,
    required this.onRecorded,
    required this.onPermissionDenied,
    required this.onPermissionGranted,
    required this.onTooShort,
    required this.tooltip,
    this.enabled = true,
  });

  @override
  State<VoiceRecordButton> createState() => _VoiceRecordButtonState();
}

class _VoiceRecordButtonState extends State<VoiceRecordButton> {
  Timer? _limit;
  bool _starting = false;
  bool _pointerDown = false;

  VoiceRecordController get c => widget.controller;

  Future<void> _down(PointerDownEvent e) async {
    _pointerDown = true;
    if (!widget.enabled || _starting) return;
    if (c.phase == VoicePhase.locked) {
      await _send(); // 2e appui en mode verrouillé : arrêt et envoi
      return;
    }
    _starting = true;
    try {
      if (!await c.recorder.hasPermission(request: false)) {
        final granted = await c.recorder.hasPermission();
        granted ? widget.onPermissionGranted() : widget.onPermissionDenied();
        return;
      }
      await c.begin();
      if (!_pointerDown) {
        // Doigt relevé avant le démarrage effectif : simple appui.
        await c.cancel();
        widget.onTooShort();
        return;
      }
      _limit = Timer(GeminiService.maxVoiceDuration, _send);
    } catch (_) {
      widget.onPermissionDenied();
    } finally {
      _starting = false;
    }
  }

  void _move(PointerMoveEvent e) {
    if (c.phase != VoicePhase.holding) return;
    c.drag(e.delta);
    if (-c.dragDy > VoiceRecordController.lockThreshold) {
      c.lock();
    } else if (-c.dragDx > VoiceRecordController.cancelThreshold) {
      _cancel();
    }
  }

  Future<void> _up(PointerUpEvent e) async {
    _pointerDown = false;
    if (c.phase == VoicePhase.holding) await _send();
  }

  Future<void> _send() async {
    _limit?.cancel();
    if (!c.isRecording) return;
    final audio = await c.finish();
    if (audio == null) {
      widget.onTooShort();
    } else {
      widget.onRecorded(audio);
    }
  }

  Future<void> _cancel() async {
    _limit?.cancel();
    await c.cancel();
  }

  @override
  void dispose() {
    _limit?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListenableBuilder(
      listenable: c,
      builder: (context, _) {
        final recording = c.isRecording;
        final locked = c.phase == VoicePhase.locked;
        return Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            // Repère de verrouillage au-dessus du bouton pendant le maintien.
            if (c.phase == VoicePhase.holding)
              Positioned(
                bottom: 64 + (-c.dragDy * 0.4),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: scheme.outlineVariant),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock_outline_rounded, size: 20, color: scheme.primary),
                      Icon(Icons.keyboard_arrow_up_rounded, size: 20, color: scheme.onSurfaceVariant),
                    ],
                  ),
                ),
              ),
            Semantics(
              button: true,
              label: widget.tooltip,
              child: Listener(
                onPointerDown: _down,
                onPointerMove: _move,
                onPointerUp: _up,
                onPointerCancel: (_) {
                  _pointerDown = false;
                  if (c.phase == VoicePhase.holding) _cancel();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  curve: Easing.standard,
                  width: recording && !locked ? 60 : 48,
                  height: recording && !locked ? 60 : 48,
                  transform: Matrix4.translationValues(c.phase == VoicePhase.holding ? c.dragDx * 0.3 : 0, 0, 0),
                  decoration: BoxDecoration(
                    color: !widget.enabled
                        ? scheme.surfaceContainerHighest
                        : recording
                            ? scheme.error
                            : scheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    locked ? Icons.send_rounded : Icons.mic_rounded,
                    color: widget.enabled ? scheme.onPrimary : scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Barre affichée à la place du champ de saisie pendant l'enregistrement :
/// point rouge, durée, forme d'onde en direct, consigne ou corbeille.
class RecordingBar extends StatelessWidget {
  final VoiceRecordController controller;
  final String slideToCancel;
  final String cancelTooltip;
  const RecordingBar({super.key, required this.controller, required this.slideToCancel, required this.cancelTooltip});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final locked = controller.phase == VoicePhase.locked;
        final secs = controller.elapsed.inSeconds;
        final time = '${(secs ~/ 60).toString().padLeft(1, '0')}:${(secs % 60).toString().padLeft(2, '0')}';
        return Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(26),
          ),
          child: Row(
            children: [
              if (locked)
                IconButton(
                  tooltip: cancelTooltip,
                  onPressed: controller.cancel,
                  icon: Icon(Icons.delete_outline_rounded, color: scheme.error),
                )
              else
                Container(width: 10, height: 10, decoration: BoxDecoration(color: scheme.error, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text(time, style: const TextStyle(fontFeatures: [FontFeature.tabularFigures()], fontWeight: FontWeight.w600)),
              const SizedBox(width: 12),
              Expanded(
                child: CustomPaint(
                  size: const Size(double.infinity, 32),
                  painter: WaveformPainter(controller.levels, scheme.primary),
                ),
              ),
              if (!locked) ...[
                const SizedBox(width: 8),
                Opacity(
                  opacity: (1 - controller.dragDx.abs() / VoiceRecordController.cancelThreshold).clamp(0.3, 1.0),
                  child: Text('‹ $slideToCancel', style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// Barres verticales proportionnelles au niveau sonore, les plus récentes à
/// droite (défilement continu pendant la prise de son).
class WaveformPainter extends CustomPainter {
  final List<double> levels;
  final Color color;
  WaveformPainter(List<double> source, this.color) : levels = List.of(source);

  @override
  void paint(Canvas canvas, Size size) {
    const barWidth = 3.0;
    const gap = 2.0;
    final count = (size.width / (barWidth + gap)).floor();
    final paint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeWidth = barWidth;
    final data = levels.length > count ? levels.sublist(levels.length - count) : levels;
    final startX = size.width - data.length * (barWidth + gap);
    for (var i = 0; i < data.length; i++) {
      final h = 3 + data[i] * (size.height - 3);
      final x = startX + i * (barWidth + gap) + barWidth / 2;
      final y1 = (size.height - h) / 2;
      canvas.drawLine(Offset(x, y1), Offset(x, y1 + h), paint);
    }
  }

  @override
  bool shouldRepaint(WaveformPainter old) => true;
}
