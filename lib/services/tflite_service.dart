import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class TFLiteService {
  Interpreter? _interpreter;
  List<String>? _labels;
  bool _isModelLoaded = false;

  static const String modelPath = 'assets/models/best_efficientnet.tflite';
  static const String labelsPath = 'assets/models/labels.txt';
  
  // Input size for MobileNetV2 (usually 224x224)
  static const int inputSize = 224;

  Future<void> loadModel() async {
    if (_isModelLoaded) return;
    try {
      final options = InterpreterOptions();
      // Use XNNPACK delegate or GPU delegate if needed/available, keeping it simple for now
      _interpreter = await Interpreter.fromAsset(modelPath, options: options);
      
      final labelData = await rootBundle.loadString(labelsPath);
      _labels = labelData.split('\n').where((l) => l.isNotEmpty).map((l) => l.trim()).toList();

      _isModelLoaded = true;
      print('TFLite Model loaded successfully');
    } catch (e) {
      print('Error loading TFLite model: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> classifyImage(File imageFile) async {
    if (!_isModelLoaded) {
      await loadModel();
    }
    if (_interpreter == null || _labels == null) return null;

    try {
      // 1. Read and Resize Image
      final imageData = await imageFile.readAsBytes();
      final image = img.decodeImage(imageData);
      if (image == null) return null;

      final resizedImage = img.copyResize(
        image, 
        width: inputSize, 
        height: inputSize,
      );

      // 2. Preprocess (Normalize)
      // DenseNet/ImageNet standard: 
      // typically values [0,1] or [-1, 1] or [0, 255]. 
      // Since it's a quantized model (.tfliteQuant), it likely expects uint8 [0, 255] or int8 [-128, 127].
      // HOWEVER, without knowing the exact quantization parameter, we often try standard uint8 input for quantized models
      // OR float input if the interpreter handles dequantization.
      
      // Let's inspect input tensor type
      final inputTensor = _interpreter!.getInputTensor(0);
      final inputType = inputTensor.type; // e.g. TifLiteType.uint8 or float32

      // Preparing input buffer
      var inputBuffer;
      
      if (inputType == TensorType.uint8) {
         // Quantized input [0, 255]
         final inputBytes = Uint8List(1 * inputSize * inputSize * 3);
         int pixelIndex = 0;
         for (var y = 0; y < inputSize; y++) {
           for (var x = 0; x < inputSize; x++) {
             final pixel = resizedImage.getPixel(x, y);
             inputBytes[pixelIndex++] = pixel.r.toInt();
             inputBytes[pixelIndex++] = pixel.g.toInt();
             inputBytes[pixelIndex++] = pixel.b.toInt();
           }
         }
         inputBuffer = inputBytes.reshape([1, inputSize, inputSize, 3]);
      } else {
         // Float input (usually normalized 0-1 or -1 to 1)
         // Assuming 0-1 for now unless specified otherwise, or standard ImageNet 
         // mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225]
         // For many simple TFLite conversions, standard 0-1 float32 is common if not quantized.
         // Let's stick to simple 0-255 float normalized to 0-1 for now if float.
         
         final inputFloats = Float32List(1 * inputSize * inputSize * 3);
         int pixelIndex = 0;
         for (var y = 0; y < inputSize; y++) {
           for (var x = 0; x < inputSize; x++) {
             final pixel = resizedImage.getPixel(x, y);
             // Normalize to [0, 1]
             inputFloats[pixelIndex++] = pixel.r / 255.0;
             inputFloats[pixelIndex++] = pixel.g / 255.0;
             inputFloats[pixelIndex++] = pixel.b / 255.0;
           }
         }
         inputBuffer = inputFloats.reshape([1, inputSize, inputSize, 3]);
      }

      // 3. Output Buffer
      final outputTensor = _interpreter!.getOutputTensor(0);
      final outputShape = outputTensor.shape; 
      final outputType = outputTensor.type;
      final numClasses = outputShape.last; 

      // Support for batch size 1
      var outputBuffer;
      if (outputType == TensorType.uint8) {
         outputBuffer = Uint8List(numClasses).reshape([1, numClasses]);
      } else {
         outputBuffer = Float32List(numClasses).reshape([1, numClasses]);
      }

      // 4. Run Inference
      _interpreter!.run(inputBuffer, outputBuffer);

      // 5. Parse Results
      final outputList = outputBuffer[0] as List;
      
      // Find top confidence
      int topIndex = 0;
      num maxScore = 0;
      
      for (int i = 0; i < outputList.length; i++) {
        final score = outputList[i];
        if (score > maxScore) {
           maxScore = score;
           topIndex = i;
        }
      }
      
      // Calculate confidence (softmax if needed, or raw)
      // If quantized uint8, usually 0-255.
      double confidence;
      if (outputType == TensorType.uint8) {
         confidence = maxScore / 255.0;
      } else {
         confidence = maxScore.toDouble(); // Assuming softmax output or logits (if logits, softmax needed, but usually tflite output is prob)
      }

      if (topIndex < _labels!.length) {
        final label = _labels![topIndex];
        
        // Label format: Plant___Disease
        return {
           'label': label,
           'confidence': confidence,
           'index': topIndex,
        };
      }
      
      return null;

    } catch (e) {
      print('Error during inference: $e');
      return null;
    }
  }

  void dispose() {
    _interpreter?.close();
    _isModelLoaded = false;
  }
}

final tfliteService = TFLiteService();
