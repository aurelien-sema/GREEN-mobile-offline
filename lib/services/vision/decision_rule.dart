import '../../core/constants/app_constants.dart';
import '../../models/scan_result_model.dart';
import 'classification.dart';

export '../../models/scan_result_model.dart' show VisionDecision;

/// Règle de décision de classifier_v1, identique à celle du backend.
///
/// L'utilisateur choisit la culture **avant** la photo, puis :
/// 1. `best` = la classe la plus probable **parmi les 9** ; confiance = sa
///    probabilité ;
/// 2. culture de `best` ≠ culture choisie → [VisionDecision.wrongCrop] ;
/// 3. sinon confiance < [AppConstants.visionConfidenceThreshold] →
///    [VisionDecision.unknown] ;
/// 4. sinon → [VisionDecision.ok].
///
/// Interdit (décision d'équipe) : renormaliser sur les 3 classes de la
/// culture choisie ou n'y prendre le maximum. Cela gonfle la confiance,
/// surtout sur les images hors sujet (sol, mains, murs), rend le seuil
/// inopérant et masque le cas wrong_crop.
class DecisionRule {
  DecisionRule._();

  /// Premier mot de la classe du modèle → identifiant de culture de la base
  /// de maladies (assets/data/diseases.json).
  static const Map<String, String> modelCropToCatalog = {
    'Cassava': 'cassava',
    'Corn': 'maize',
    'Tomato': 'tomato',
  };

  /// Identifiant de culture → nom attendu par le backend (champ `crop` :
  /// Cassava, Corn, Tomato). null si inconnu.
  static String? modelCropOf(String? catalogCrop) {
    for (final e in modelCropToCatalog.entries) {
      if (e.value == catalogCrop) return e.key;
    }
    return null;
  }

  /// Cultures proposées à l'utilisateur avant la photo.
  static const List<String> selectableCrops = ['cassava', 'maize', 'tomato'];

  /// Culture d'une classe du modèle (« Corn leaf blight » → « maize »),
  /// null si le premier mot n'est pas une culture connue.
  static String? cropOf(String label) => modelCropToCatalog[label.trim().split(' ').first];

  static VisionDecision decide(
    ClassificationResult result, {
    required String chosenCrop,
    double threshold = AppConstants.visionConfidenceThreshold,
  }) {
    if (cropOf(result.label) != chosenCrop) return VisionDecision.wrongCrop;
    if (result.confidence < threshold) return VisionDecision.unknown;
    return VisionDecision.ok;
  }
}
