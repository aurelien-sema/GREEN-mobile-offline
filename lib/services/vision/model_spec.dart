import 'dart:convert';

/// Format du fichier de modèle.
enum ModelFormat { tflite, onnx }

/// Disposition du tenseur d'entrée : [1, H, W, 3] (TensorFlow/Keras) ou
/// [1, 3, H, W] (PyTorch).
enum TensorLayout { nhwc, nchw }

/// Mise à l'échelle des pixels attendue par le modèle.
enum PixelScaling {
  /// Valeurs brutes 0–255 en float32 (le modèle se normalise lui-même).
  raw0255('raw_0_255'),

  /// 0–1 (pixel / 255).
  unit('unit_0_1'),

  /// 0–1 puis normalisation ImageNet (moyenne / écart-type par canal).
  imagenet('imagenet');

  final String json;
  const PixelScaling(this.json);
}

/// Redimensionnement vers la taille d'entrée.
enum ResizeMode {
  /// Redimensionnement bilinéaire direct à W×H (proportions non conservées),
  /// comme `tf.image.resize` / `image_dataset_from_directory`.
  stretchBilinear('stretch_bilinear'),

  /// Petit côté à [ModelSpec.shorterSide] puis recadrage central W×H, comme
  /// `Resize` + `CenterCrop` de torchvision.
  shorterSideCenterCrop('shorter_side_center_crop');

  final String json;
  const ResizeMode(this.json);
}

/// Sortie du modèle : probabilités (softmax déjà appliqué) ou logits.
enum OutputKind { probabilities, logits }

/// Description d'un modèle de vision, lue dans assets/models/active_model.json.
///
/// Le code d'inférence ne contient plus aucune constante propre à un modèle :
/// changer de modèle (ou de format TFLite ↔ ONNX) revient à changer ce
/// fichier et les fichiers qu'il désigne.
class ModelSpec {
  final String id;
  final ModelFormat format;
  final String modelAsset;
  final String labelsAsset;
  final TensorLayout layout;
  final int width;
  final int height;
  final PixelScaling pixels;
  final ResizeMode resize;
  final int shorterSide;
  final OutputKind output;
  final int threads;

  /// Noms des tenseurs (utilisés par ONNX Runtime ; ignorés en TFLite).
  final String inputName;
  final String outputName;

  const ModelSpec({
    required this.id,
    required this.format,
    required this.modelAsset,
    required this.labelsAsset,
    required this.layout,
    required this.width,
    required this.height,
    required this.pixels,
    required this.resize,
    this.shorterSide = 0,
    required this.output,
    this.threads = 4,
    this.inputName = 'input',
    this.outputName = 'output',
  });

  factory ModelSpec.fromJson(Map<String, dynamic> j) {
    final input = (j['input'] as Map<String, dynamic>?) ?? const {};
    final output = (j['output'] as Map<String, dynamic>?) ?? const {};
    T pick<T extends Enum>(List<T> values, String? raw, String field, String Function(T) name) {
      for (final v in values) {
        if (name(v) == raw) return v;
      }
      throw FormatException('active_model.json : valeur « $raw » invalide pour $field.');
    }

    final width = (input['width'] as num?)?.toInt() ?? 0;
    final height = (input['height'] as num?)?.toInt() ?? 0;
    if (width <= 0 || height <= 0) {
      throw const FormatException('active_model.json : input.width et input.height sont obligatoires.');
    }
    final resize = pick(ResizeMode.values, input['resize'] as String? ?? 'stretch_bilinear', 'input.resize', (v) => v.json);
    final shorter = (input['shorterSide'] as num?)?.toInt() ?? 0;
    if (resize == ResizeMode.shorterSideCenterCrop && shorter < width) {
      throw const FormatException('active_model.json : input.shorterSide doit être ≥ input.width.');
    }
    final model = j['model'] as String?;
    final labels = j['labels'] as String?;
    if (model == null || labels == null) {
      throw const FormatException('active_model.json : « model » et « labels » sont obligatoires.');
    }

    return ModelSpec(
      id: (j['id'] as String?) ?? model.split('/').last,
      format: pick(ModelFormat.values, j['format'] as String?, 'format', (v) => v.name),
      modelAsset: model,
      labelsAsset: labels,
      layout: pick(TensorLayout.values, input['layout'] as String? ?? 'nhwc', 'input.layout', (v) => v.name),
      width: width,
      height: height,
      pixels: pick(PixelScaling.values, input['pixels'] as String?, 'input.pixels', (v) => v.json),
      resize: resize,
      shorterSide: shorter,
      output: pick(OutputKind.values, output['kind'] as String? ?? 'probabilities', 'output.kind', (v) => v.name),
      threads: ((j['threads'] as num?)?.toInt() ?? 4).clamp(1, 8),
      inputName: (input['name'] as String?) ?? 'input',
      outputName: (output['name'] as String?) ?? 'output',
    );
  }

  factory ModelSpec.parse(String raw) => ModelSpec.fromJson(jsonDecode(raw) as Map<String, dynamic>);

  /// Forme du tenseur d'entrée.
  List<int> get inputShape => layout == TensorLayout.nhwc ? [1, height, width, 3] : [1, 3, height, width];

  /// labels.txt : une classe par ligne, dans l'ordre des sorties du modèle.
  /// Les virgules finales et les lignes vides sont ignorées.
  static List<String> parseLabels(String raw) => raw
      .split('\n')
      .map((l) => l.trim().replaceAll(RegExp(r',+$'), ''))
      .where((l) => l.isNotEmpty)
      .toList();
}
