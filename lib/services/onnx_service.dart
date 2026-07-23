import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:onnxruntime/onnxruntime.dart';

/// Service d'inférence basé sur ONNX Runtime.
///
/// Modèle : EfficientNet-B0 exporté depuis PyTorch (opset 13), une entrée
/// "input" de forme [1, 3, 224, 224] (NCHW, float32) et une sortie "output"
/// de forme [1, 11] contenant des LOGITS BRUTS (pas de softmax dans le graphe).
///
/// Le prétraitement reproduit EXACTEMENT celui de l'entraînement (voir
/// onnx_model_specifications.txt) : Resize(255) sur le plus petit côté,
/// CenterCrop(224), mise à l'échelle [0,1] puis normalisation ImageNet, et
/// réagencement HWC -> CHW. Toute divergence ici fausse les prédictions.
class OnnxService {
  OrtSession? _session;
  List<String>? _labels;
  bool _isModelLoaded = false;

  static const String modelPath = 'assets/models/efficientnet_11classes.onnx';
  static const String labelsPath = 'assets/models/labels.txt';

  static const String inputName = 'input';
  static const String outputName = 'output';

  /// Taille d'entrée attendue par le modèle (carré).
  static const int inputSize = 224;

  /// Plus petit côté visé par le redimensionnement avant le recadrage central
  /// (round(224 * 1.14) = 255, équivalent à torchvision Resize(255)).
  static const int resizeShortestSide = 255;

  /// Statistiques ImageNet (ordre R, G, B) utilisées à l'entraînement.
  static const List<double> _mean = [0.485, 0.456, 0.406];
  static const List<double> _std = [0.229, 0.224, 0.225];

  Future<void> loadModel() async {
    if (_isModelLoaded) return;
    try {
      OrtEnv.instance.init();

      final sessionOptions = OrtSessionOptions();
      final rawModel = await rootBundle.load(modelPath);
      final modelBytes = rawModel.buffer
          .asUint8List(rawModel.offsetInBytes, rawModel.lengthInBytes);
      _session = OrtSession.fromBuffer(modelBytes, sessionOptions);

      final labelData = await rootBundle.loadString(labelsPath);
      _labels = labelData
          .split('\n')
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .toList();

      if (_labels!.isEmpty) {
        throw StateError('labels.txt est vide ($labelsPath)');
      }

      _isModelLoaded = true;
      debugPrint('ONNX model loaded successfully (${_labels!.length} classes)');
    } catch (e) {
      debugPrint('Error loading ONNX model: $e');
      rethrow;
    }
  }

  /// Classe une image et renvoie la classe dominante.
  ///
  /// Retourne un map { 'label', 'confidence' (0..1), 'index', 'top3' } ou
  /// `null` si l'image ne peut pas être décodée.
  Future<Map<String, dynamic>?> classifyImage(File imageFile) async {
    if (!_isModelLoaded) {
      await loadModel();
    }
    final session = _session;
    final labels = _labels;
    if (session == null || labels == null) return null;

    OrtValueTensor? inputTensor;
    OrtRunOptions? runOptions;
    List<OrtValue?>? outputs;
    try {
      final input = await _preprocess(imageFile);
      if (input == null) return null;

      inputTensor = OrtValueTensor.createTensorWithDataList(
        input,
        [1, 3, inputSize, inputSize],
      );
      runOptions = OrtRunOptions();
      outputs = await session.runAsync(runOptions, {inputName: inputTensor});
      if (outputs == null) return null;

      final logits = _extractLogits(outputs);
      if (logits == null || logits.isEmpty) return null;

      // Garde-fou : le nombre de logits doit correspondre au nombre de labels.
      if (logits.length != labels.length) {
        debugPrint(
          'Incohérence modèle/labels : le modèle produit ${logits.length} '
          'classes mais labels.txt en contient ${labels.length}.',
        );
        return null;
      }

      final probabilities = _softmax(logits);

      var topIndex = 0;
      for (var i = 1; i < probabilities.length; i++) {
        if (probabilities[i] > probabilities[topIndex]) topIndex = i;
      }

      final top3 = _topK(probabilities, labels, 3);

      return {
        'label': labels[topIndex],
        'confidence': probabilities[topIndex],
        'index': topIndex,
        'top3': top3,
      };
    } catch (e) {
      debugPrint('Error during ONNX inference: $e');
      return null;
    } finally {
      inputTensor?.release();
      runOptions?.release();
      outputs?.forEach((o) => o?.release());
    }
  }

  /// Prétraitement conforme à onnx_model_specifications.txt.
  Future<Float32List?> _preprocess(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return null;

    // 1. Corriger l'orientation EXIF (le pipeline d'entraînement travaille sur
    //    des images déjà correctement orientées).
    var image = img.bakeOrientation(decoded);

    // 2. Resize : le plus petit côté ramené à 255 px, ratio conservé.
    if (image.width < image.height) {
      final newHeight = (image.height * resizeShortestSide / image.width).round();
      image = img.copyResize(
        image,
        width: resizeShortestSide,
        height: newHeight,
        interpolation: img.Interpolation.linear,
      );
    } else {
      final newWidth = (image.width * resizeShortestSide / image.height).round();
      image = img.copyResize(
        image,
        width: newWidth,
        height: resizeShortestSide,
        interpolation: img.Interpolation.linear,
      );
    }

    // 3. CenterCrop 224x224.
    final left = ((image.width - inputSize) / 2).round();
    final top = ((image.height - inputSize) / 2).round();
    final cropped = img.copyCrop(
      image,
      x: left,
      y: top,
      width: inputSize,
      height: inputSize,
    );

    // 4 -> 6. [0,1], normalisation ImageNet, réagencement HWC -> CHW.
    final buffer = Float32List(3 * inputSize * inputSize);
    const int channelStride = inputSize * inputSize;
    for (var y = 0; y < inputSize; y++) {
      for (var x = 0; x < inputSize; x++) {
        final pixel = cropped.getPixel(x, y);
        final pos = y * inputSize + x;
        buffer[pos] = (pixel.r / 255.0 - _mean[0]) / _std[0];
        buffer[channelStride + pos] = (pixel.g / 255.0 - _mean[1]) / _std[1];
        buffer[2 * channelStride + pos] = (pixel.b / 255.0 - _mean[2]) / _std[2];
      }
    }
    return buffer;
  }

  /// Extrait le vecteur de logits [11] de la sortie ONNX (forme [1, 11]).
  List<double>? _extractLogits(List<OrtValue?> outputs) {
    if (outputs.isEmpty) return null;
    final raw = outputs.first?.value;
    if (raw is List) {
      final flat = raw.expand((e) => e is List ? e : [e]).toList();
      return flat.map((e) => (e as num).toDouble()).toList();
    }
    return null;
  }

  /// Softmax numériquement stable.
  List<double> _softmax(List<double> logits) {
    final maxLogit = logits.reduce(math.max);
    final exps = logits.map((l) => math.exp(l - maxLogit)).toList();
    final sum = exps.fold<double>(0.0, (a, b) => a + b);
    if (sum == 0.0) return List<double>.filled(logits.length, 0.0);
    return exps.map((e) => e / sum).toList();
  }

  List<Map<String, dynamic>> _topK(
    List<double> probabilities,
    List<String> labels,
    int k,
  ) {
    final indexed = List<int>.generate(probabilities.length, (i) => i);
    indexed.sort((a, b) => probabilities[b].compareTo(probabilities[a]));
    return indexed
        .take(k)
        .map((i) => {
              'label': labels[i],
              'confidence': probabilities[i],
              'index': i,
            })
        .toList();
  }

  void dispose() {
    _session?.release();
    _session = null;
    _isModelLoaded = false;
    OrtEnv.instance.release();
  }
}

final onnxService = OnnxService();
