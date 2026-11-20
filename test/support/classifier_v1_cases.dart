/// Tableau d'acceptation de classifier_v1 (GREEN mobile 2.2.0), fourni avec
/// le modèle : résultats du pipeline de référence (Python, même fichier
/// float16) sur des feuilles de crops_v1/test jamais vues à l'entraînement.
///
/// Utilisé par integration_test/classifier_v1_acceptance_test.dart (vrai
/// modèle, sur téléphone). Statut et classe doivent être identiques ; la
/// confiance à ±[confidenceTolerance] près (petites différences de
/// décodage JPEG / redimensionnement). Un écart plus grand signale un
/// prétraitement différent de l'entraînement (BGR, division par 255,
/// normalisation, recadrage central, redimensionnement sans anti-crénelage).
library;

const double confidenceTolerance = 0.03;

class AcceptanceCase {
  /// Nom du fichier dans test/fixtures/classifier_v1/.
  final String fixture;

  /// Culture choisie par l'utilisateur (identifiant de diseases.json).
  final String chosenCrop;

  /// Statut attendu, mêmes noms que le backend : ok, unknown, wrong_crop.
  final String status;

  /// Classe la plus probable parmi les 9.
  final String label;
  final double confidence;
  final String? note;

  const AcceptanceCase(this.fixture, this.chosenCrop, this.status, this.label, this.confidence, {this.note});
}

const List<AcceptanceCase> classifierV1Cases = [
  AcceptanceCase('0_02327_0.jpg', 'cassava', 'ok', 'Cassava Brown Leaf Spot', 0.963),
  AcceptanceCase('1_01361_0.jpg', 'cassava', 'ok', 'Cassava Healthy', 0.946),
  AcceptanceCase('2_01760_0.jpg', 'cassava', 'ok', 'Cassava Mosaic', 0.974),
  AcceptanceCase('3_00458_3.jpg', 'maize', 'ok', 'Corn Healthy', 0.996),
  AcceptanceCase('4_00961_0.jpg', 'maize', 'ok', 'Corn Yellowing', 0.948),
  AcceptanceCase('5_03227_0.jpg', 'maize', 'ok', 'Corn leaf blight', 0.941),
  AcceptanceCase('6_03832_1.jpg', 'tomato', 'ok', 'Tomato Brown Spots', 0.925),
  AcceptanceCase('7_00340_0.jpg', 'tomato', 'ok', 'Tomato blight leaf', 0.963),
  AcceptanceCase('8_00205_1.jpg', 'tomato', 'ok', 'Tomato healthy', 0.954),
  AcceptanceCase('5_00060_0.jpg', 'maize', 'unknown', 'Corn leaf blight', 0.580),
  AcceptanceCase('6_00417_0.jpg', 'tomato', 'ok', 'Tomato blight leaf', 0.852,
      note: 'vraie erreur du modèle : la vraie classe est Tomato Brown Spots'),
  AcceptanceCase('2_01760_0.jpg', 'tomato', 'wrong_crop', 'Cassava Mosaic', 0.974),
];
