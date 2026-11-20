import 'dart:convert';

/// Description du modèle de vision embarqué (assets/models/active_model.json).
///
/// classifier_v1 (2.2.0) : un seul format est pris en charge, celui du
/// modèle entraîné dans le projet FieldPlant_9classes :
/// - TensorFlow Lite, poids float16, entrée et sortie float32 ;
/// - entrée NHWC `[1, height, width, 3]`, pixels **RGB bruts 0–255** (le
///   modèle se normalise lui-même : ni division par 255, ni moyenne) ;
/// - redimensionnement bilinéaire **avec anti-crénelage**, sans conserver
///   les proportions ni recadrer (voir ImagePreprocessor) ;
/// - sortie `[1, classes]` en **probabilités** (somme = 1, pas de softmax).
///
/// Ce contrat est fixé dans le code ; le JSON ne décrit que les fichiers,
/// l'identifiant et la taille d'entrée. Les options de l'ancien modèle ONNX
/// à 11 classes (NCHW, normalisation ImageNet, recadrage central, logits)
/// ont été retirées : un JSON qui les demande est refusé.
class ModelSpec {
  /// Identifiant enregistré avec chaque analyse (ex. « classifier_v1 »).
  final String id;
  final String modelAsset;
  final String labelsAsset;
  final int width;
  final int height;
  final int threads;

  const ModelSpec({
    required this.id,
    required this.modelAsset,
    required this.labelsAsset,
    required this.width,
    required this.height,
    this.threads = 4,
  });

  /// Forme attendue du tenseur d'entrée (NHWC).
  List<int> get inputShape => [1, height, width, 3];

  factory ModelSpec.fromJson(Map<String, dynamic> j) {
    final format = j['format'] as String?;
    if (format != 'tflite') {
      throw FormatException('active_model.json : format « $format » non pris en charge (seul « tflite » est accepté).');
    }
    final input = (j['input'] as Map<String, dynamic>?) ?? const {};
    // Garde-fou : refuse une configuration héritée de l'ancien modèle ONNX
    // plutôt que de l'ignorer en silence.
    const legacy = {'layout': 'nhwc', 'pixels': 'raw_0_255'};
    for (final e in legacy.entries) {
      final v = input[e.key];
      if (v != null && v != e.value) {
        throw FormatException('active_model.json : input.${e.key} = « $v » n\'est plus pris en charge (attendu « ${e.value} »).');
      }
    }
    final outputKind = (j['output'] as Map<String, dynamic>?)?['kind'];
    if (outputKind != null && outputKind != 'probabilities') {
      throw FormatException('active_model.json : output.kind = « $outputKind » n\'est plus pris en charge (attendu « probabilities »).');
    }

    final width = (input['width'] as num?)?.toInt() ?? 0;
    final height = (input['height'] as num?)?.toInt() ?? 0;
    if (width <= 0 || height <= 0) {
      throw const FormatException('active_model.json : input.width et input.height sont obligatoires.');
    }
    final model = j['model'] as String?;
    final labels = j['labels'] as String?;
    if (model == null || labels == null) {
      throw const FormatException('active_model.json : « model » et « labels » sont obligatoires.');
    }
    return ModelSpec(
      id: (j['id'] as String?) ?? model.split('/').last,
      modelAsset: model,
      labelsAsset: labels,
      width: width,
      height: height,
      threads: ((j['threads'] as num?)?.toInt() ?? 4).clamp(1, 8),
    );
  }

  factory ModelSpec.parse(String raw) => ModelSpec.fromJson(jsonDecode(raw) as Map<String, dynamic>);

  /// labels.txt : une classe par ligne, dans l'ordre de sortie du modèle.
  /// Les virgules finales et les lignes vides sont ignorées.
  static List<String> parseLabels(String raw) => raw
      .split('\n')
      .map((l) => l.trim().replaceAll(RegExp(r',+$'), ''))
      .where((l) => l.isNotEmpty)
      .toList();
}
