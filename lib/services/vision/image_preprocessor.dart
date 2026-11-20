import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

import 'model_spec.dart';

/// Préparation d'une photo pour classifier_v1, identique à l'entraînement
/// (train_classifier.ipynb du projet FieldPlant_9classes) :
///
/// ```python
/// image = tf.cast(tf.io.decode_jpeg(..., channels=3), tf.float32)   # RGB 0–255
/// image = tf.image.resize(image, (224, 224), method="bilinear", antialias=True)
/// ```
///
/// 1. pixels **RGB** (alpha retiré, pas de BGR) ;
/// 2. redimensionnement à 224×224 **bilinéaire avec anti-crénelage**, en
///    étirant l'image (proportions non conservées, pas de recadrage central) ;
/// 3. tenseur NHWC float32 en **valeurs brutes 0–255** : ni division par 255,
///    ni moyenne / écart-type (le modèle se normalise lui-même).
///
/// Modifié en 2.2.0 : l'ancien redimensionnement (moyenne à 2× la cible puis
/// bilinéaire simple) et les options de l'ancien modèle ONNX (NCHW,
/// ImageNet, recadrage central) sont supprimés. Le redimensionnement
/// reproduit maintenant exactement l'algorithme de TensorFlow
/// (`ScaleAndTranslate`, noyau triangle, centres de pixels à +0,5, noyau
/// élargi d'un facteur max(1, réduction)), ce qui évite le crénelage des
/// photos de téléphone (~4000 px) sans étape intermédiaire.
///
/// Fonctions pures et statiques : elles tournent dans un isolate et sont
/// testées sans modèle.
class ImagePreprocessor {
  ImagePreprocessor._();

  /// Décode et prépare l'image. null si illisible.
  static Float32List? preprocess(Uint8List bytes, ModelSpec spec) {
    final rgb = decodeRgb(bytes);
    if (rgb == null) return null;
    return resizeAntialiased(rgbBytes(rgb), rgb.width, rgb.height, spec.width, spec.height);
  }

  /// Image RGB 8 bits. Les images 16 bits, en palette ou avec transparence
  /// sont converties (le canal alpha est retiré, sans composition). L'EXIF
  /// d'orientation est appliqué pour rester cohérent avec la photo affichée,
  /// même si le modèle, entraîné avec des rotations, n'y est pas sensible.
  static img.Image? decodeRgb(Uint8List bytes) {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return null;
    final oriented = img.bakeOrientation(decoded);
    return oriented.format == img.Format.uint8 && oriented.numChannels == 3 && !oriented.hasPalette
        ? oriented
        : oriented.convert(format: img.Format.uint8, numChannels: 3);
  }

  /// Octets R, G, B entrelacés (largeur × hauteur × 3), dans cet ordre.
  static Uint8List rgbBytes(img.Image image) => image.getBytes(order: img.ChannelOrder.rgb);

  /// Redimensionnement bilinéaire avec anti-crénelage de [rgb] (w×h×3,
  /// RGB) vers outW×outH, résultat NHWC float32 sur 0–255 (non arrondi).
  ///
  /// Équivalent de `tf.image.resize(method="bilinear", antialias=True)` :
  /// filtre séparable (lignes puis colonnes), noyau triangle de rayon
  /// max(1, entrée/sortie) ; les poids sortant de l'image sont ignorés puis
  /// renormalisés. En agrandissement, c'est le bilinéaire classique.
  static Float32List resizeAntialiased(Uint8List rgb, int w, int h, int outW, int outH) {
    if (rgb.length != w * h * 3) {
      throw ArgumentError('Tampon RGB de ${rgb.length} octets pour une image $w×$h.');
    }
    final cols = _Spans.compute(w, outW);
    final rows = _Spans.compute(h, outH);

    // 1er passage : largeur w → outW, pour chaque ligne de la source.
    final tmp = Float32List(h * outW * 3);
    for (var y = 0; y < h; y++) {
      final srcRow = y * w * 3;
      final dstRow = y * outW * 3;
      for (var x = 0; x < outW; x++) {
        final start = cols.starts[x];
        final size = cols.sizes[x];
        final wBase = x * cols.maxSize;
        var r = 0.0, g = 0.0, b = 0.0;
        for (var k = 0; k < size; k++) {
          final weight = cols.weights[wBase + k];
          final p = srcRow + (start + k) * 3;
          r += rgb[p] * weight;
          g += rgb[p + 1] * weight;
          b += rgb[p + 2] * weight;
        }
        final d = dstRow + x * 3;
        tmp[d] = r;
        tmp[d + 1] = g;
        tmp[d + 2] = b;
      }
    }

    // 2e passage : hauteur h → outH.
    final out = Float32List(outH * outW * 3);
    final stride = outW * 3;
    for (var y = 0; y < outH; y++) {
      final start = rows.starts[y];
      final size = rows.sizes[y];
      final wBase = y * rows.maxSize;
      final dstRow = y * stride;
      for (var k = 0; k < size; k++) {
        final weight = rows.weights[wBase + k];
        final srcRow = (start + k) * stride;
        for (var i = 0; i < stride; i++) {
          out[dstRow + i] += tmp[srcRow + i] * weight;
        }
      }
    }
    return out;
  }
}

/// Poids du filtre pour un axe (port de `ComputeSpansCore`, TensorFlow
/// scale_and_translate_op.cc, noyau triangle, translation nulle).
class _Spans {
  final Int32List starts;
  final Int32List sizes;
  final Float64List weights;
  final int maxSize;

  _Spans(this.starts, this.sizes, this.weights, this.maxSize);

  factory _Spans.compute(int inSize, int outSize) {
    final invScale = inSize / outSize;
    final kernelScale = math.max(invScale, 1.0);
    final radius = kernelScale; // rayon du noyau triangle = 1, élargi
    final maxSize = math.min(2 * radius.ceil() + 1, inSize);
    final starts = Int32List(outSize);
    final sizes = Int32List(outSize);
    final weights = Float64List(outSize * maxSize);

    for (var x = 0; x < outSize; x++) {
      final sample = (x + 0.5) * invScale;
      final start = (sample - radius - 0.5).ceil().clamp(0, inSize - 1);
      final end = (sample + radius - 0.5).floor().clamp(0, inSize - 1) + 1;
      var total = 0.0;
      final base = x * maxSize;
      for (var s = start; s < end; s++) {
        final t = ((s + 0.5 - sample) / kernelScale).abs();
        final weight = t < 1 ? 1 - t : 0.0;
        weights[base + s - start] = weight;
        total += weight;
      }
      if (total > 0) {
        for (var k = 0; k < end - start; k++) {
          weights[base + k] /= total;
        }
      }
      starts[x] = start;
      sizes[x] = end - start;
    }
    return _Spans(starts, sizes, weights, maxSize);
  }
}
