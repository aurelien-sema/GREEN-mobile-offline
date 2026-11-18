import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

import 'model_spec.dart';

/// Préparation d'une photo pour le modèle, sans dépendance au moteur
/// d'inférence (TFLite ou ONNX) : seule la [ModelSpec] décide de la taille,
/// du redimensionnement, de l'échelle des pixels et de la disposition.
///
/// Fonctions pures et statiques : elles tournent dans un isolate et sont
/// testées sans modèle.
class ImagePreprocessor {
  ImagePreprocessor._();

  static const List<double> imagenetMean = [0.485, 0.456, 0.406];
  static const List<double> imagenetStd = [0.229, 0.224, 0.225];

  /// Décode, oriente (EXIF) et prépare l'image. null si illisible.
  static Float32List? preprocess(Uint8List bytes, ModelSpec spec) {
    final rgb = decodeRgb(bytes);
    if (rgb == null) return null;
    final sized = switch (spec.resize) {
      ResizeMode.stretchBilinear => resizeStretch(rgb, spec.width, spec.height),
      ResizeMode.shorterSideCenterCrop => resizeAndCenterCrop(rgb, spec.shorterSide, spec.width, spec.height),
    };
    return toTensor(sized, spec);
  }

  /// Image RGB 8 bits orientée selon l'EXIF (photos prises en portrait).
  /// Les images 16 bits, en palette ou avec transparence sont converties.
  static img.Image? decodeRgb(Uint8List bytes) {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return null;
    final oriented = img.bakeOrientation(decoded);
    return oriented.format == img.Format.uint8 && oriented.numChannels == 3 && !oriented.hasPalette
        ? oriented
        : oriented.convert(format: img.Format.uint8, numChannels: 3);
  }

  /// Bilinéaire direct à w×h. Pour une forte réduction (photo de 12 Mpx →
  /// 224 px), un premier passage moyenneur à 2× la taille cible évite le
  /// crénelage : le résultat reste proche d'un redimensionnement bilinéaire
  /// avec anti-crénelage (PIL), mesuré sans écart de précision sur le jeu
  /// de contrôle (voir CHANGELOG, 2.1.0).
  static img.Image resizeStretch(img.Image image, int w, int h) {
    var source = image;
    if (image.width > w * 4 || image.height > h * 4) {
      source = img.copyResize(image, width: w * 2, height: h * 2, interpolation: img.Interpolation.average);
    }
    if (source.width == w && source.height == h) return source;
    return img.copyResize(source, width: w, height: h, interpolation: img.Interpolation.linear);
  }

  /// Petit côté à [shorterSide] puis recadrage central w×h (torchvision :
  /// `Resize(shorterSide)` + `CenterCrop`, recadrage arrondi).
  static img.Image resizeAndCenterCrop(img.Image image, int shorterSide, int w, int h) {
    final shortSide = math.min(image.width, image.height);
    final scale = shorterSide / shortSide;
    final rw = image.width <= image.height ? shorterSide : (image.width * scale).floor();
    final rh = image.height < image.width ? shorterSide : (image.height * scale).floor();

    var source = image;
    if (scale < 0.5) {
      source = img.copyResize(image, width: rw * 2, height: rh * 2, interpolation: img.Interpolation.average);
    }
    final resized = img.copyResize(source, width: rw, height: rh, interpolation: img.Interpolation.linear);
    final left = ((resized.width - w) / 2).round();
    final top = ((resized.height - h) / 2).round();
    return img.copyCrop(resized, x: math.max(0, left), y: math.max(0, top), width: w, height: h);
  }

  /// Image w×h → tenseur float32 dans la disposition et l'échelle du modèle.
  static Float32List toTensor(img.Image image, ModelSpec spec) {
    final w = spec.width;
    final h = spec.height;
    final plane = w * h;
    final data = Float32List(3 * plane);

    double scale(num v, int c) => switch (spec.pixels) {
          PixelScaling.raw0255 => v.toDouble(),
          PixelScaling.unit => v / 255.0,
          PixelScaling.imagenet => (v / 255.0 - imagenetMean[c]) / imagenetStd[c],
        };

    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        final p = image.getPixel(x, y);
        final i = y * w + x;
        if (spec.layout == TensorLayout.nhwc) {
          data[3 * i] = scale(p.r, 0);
          data[3 * i + 1] = scale(p.g, 1);
          data[3 * i + 2] = scale(p.b, 2);
        } else {
          data[i] = scale(p.r, 0);
          data[plane + i] = scale(p.g, 1);
          data[2 * plane + i] = scale(p.b, 2);
        }
      }
    }
    return data;
  }
}
