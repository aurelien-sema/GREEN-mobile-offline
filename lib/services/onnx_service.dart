import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:flutter_onnxruntime/flutter_onnxruntime.dart';
import 'package:image/image.dart' as img;

class OnnxService {
  OrtSession? _session;
  List<String>? _labels;
  bool _isModelLoaded = false;

  static const String modelPath = 'assets/models/efficientnet_11classes.onnx';
  static const String labelsPath = 'assets/models/labels.txt';

  static const int inputSize = 224;
  static const int resizeShorterSide = 255;
  static const List<double> _imagenetMean = [0.485, 0.456, 0.406];
  static const List<double> _imagenetStd = [0.229, 0.224, 0.225];

  final OnnxRuntime _ort = OnnxRuntime();

  Future<void> loadModel() async {
    if (_isModelLoaded) return;

    _session = await _ort.createSessionFromAsset(modelPath);

    final labelData = await rootBundle.loadString(labelsPath);
    _labels = labelData
        .split('\n')
        .map((l) => l.trim().replaceAll(RegExp(r',+$'), ''))
        .where((l) => l.isNotEmpty)
        .toList();

    if (_session == null) {
      throw StateError('Impossible de charger la session ONNX.');
    }

    if (_labels == null || _labels!.isEmpty) {
      throw StateError('Le fichier de labels est vide ou introuvable.');
    }

    _isModelLoaded = true;
    print('ONNX model loaded successfully (${_labels!.length} classes)');
  }

  Future<Map<String, dynamic>?> classifyImage(File imageFile) async {
    if (!_isModelLoaded) {
      await loadModel();
    }
    if (_session == null || _labels == null) return null;

    final imageData = await imageFile.readAsBytes();
    final decodedImage = img.decodeImage(imageData);
    if (decodedImage == null) return null;

    final normalizedImage = img.bakeOrientation(decodedImage);
    final processedImage = _resizeAndCenterCrop(normalizedImage);
    final inputData = _createInputData(processedImage);

    final inputTensor = await OrtValue.fromList(inputData, [1, 3, inputSize, inputSize]);
    final inputs = {'input': inputTensor};

    final outputs = await _session!.run(inputs);
    final outputTensor = outputs['output'];
    if (outputTensor == null) {
      inputTensor.dispose();
      throw StateError('Le tenseur de sortie ONNX "output" est introuvable.');
    }

    final rawOutput = await outputTensor.asList();
    final flatOutput = _flattenOutput(rawOutput);
    final probabilities = _softmax(flatOutput);

    int topIndex = 0;
    double topScore = probabilities[0];
    for (var i = 1; i < probabilities.length; i++) {
      if (probabilities[i] > topScore) {
        topScore = probabilities[i];
        topIndex = i;
      }
    }

    final result = {
      'label': _labels![topIndex],
      'confidence': topScore.clamp(0.0, 1.0),
      'index': topIndex,
    };

    inputTensor.dispose();
    outputTensor.dispose();
    return result;
  }

  img.Image _resizeAndCenterCrop(img.Image image) {
    final shortSide = math.min(image.width, image.height);
    final scale = resizeShorterSide / shortSide;
    final resizedWidth = (image.width * scale).round();
    final resizedHeight = (image.height * scale).round();

    final resized = img.copyResize(
      image,
      width: resizedWidth,
      height: resizedHeight,
    );

    final cropX = math.max(0, (resized.width - inputSize) ~/ 2);
    final cropY = math.max(0, (resized.height - inputSize) ~/ 2);
    return img.copyCrop(
      resized,
      x: cropX,
      y: cropY,
      width: inputSize,
      height: inputSize,
    );
  }

  List<double> _createInputData(img.Image image) {
    final List<double> inputData = List<double>.filled(inputSize * inputSize * 3, 0.0);
    final int planeSize = inputSize * inputSize;

    for (var y = 0; y < inputSize; y++) {
      for (var x = 0; x < inputSize; x++) {
        final pixel = image.getPixel(x, y);
        final double r = (pixel.r / 255.0 - _imagenetMean[0]) / _imagenetStd[0];
        final double g = (pixel.g / 255.0 - _imagenetMean[1]) / _imagenetStd[1];
        final double b = (pixel.b / 255.0 - _imagenetMean[2]) / _imagenetStd[2];

        final int index = y * inputSize + x;
        inputData[index] = r;
        inputData[planeSize + index] = g;
        inputData[planeSize * 2 + index] = b;
      }
    }
    return inputData;
  }

  List<double> _flattenOutput(dynamic output) {
    if (output is List) {
      final flattened = <double>[];
      for (final element in output) {
        flattened.addAll(_flattenOutput(element));
      }
      return flattened;
    }
    return [output is num ? output.toDouble() : double.parse(output.toString())];
  }

  List<double> _softmax(List<double> logits) {
    final maxLogit = logits.reduce(math.max);
    final expValues = logits.map((value) => math.exp(value - maxLogit)).toList();
    final sumExp = expValues.fold(0.0, (sum, value) => sum + value);
    if (sumExp == 0.0) {
      return List<double>.filled(logits.length, 1.0 / logits.length);
    }
    return expValues.map((value) => value / sumExp).toList();
  }

  Future<void> dispose() async {
    _session?.close();
    _session = null;
    _isModelLoaded = false;
  }
}

final onnxService = OnnxService();
