import 'dart:math';

/// Les quatre questions de sécurité, simples et liées à l'exploitant et à son
/// activité agricole. Une question est tirée au hasard à chaque création de
/// compte ; l'utilisateur y répond et la réponse (hachée) est enregistrée
/// avec l'identifiant de la question.
///
/// Les identifiants (`q1`…`q4`) sont stockés : ne jamais les renuméroter.
/// Le texte affiché vient des clés de traduction `secQ1`…`secQ4`.
class SecurityQuestions {
  SecurityQuestions._();

  static const List<String> ids = ['q1', 'q2', 'q3', 'q4'];

  /// Texte français de référence, enregistré dans le registre des comptes
  /// pour qu'il reste lisible même hors de l'application.
  static const Map<String, String> referenceText = {
    'q1': 'Quelle est la culture principale de votre champ ?',
    'q2': 'Dans quel village ou quelle localité se trouve votre champ ?',
    'q3': 'Quelle a été la toute première culture que vous avez plantée ?',
    'q4': 'Quel est le prénom de la personne qui vous a appris à cultiver ?',
  };

  static String translationKey(String id) => 'secQ${id.substring(1)}';

  static String randomId([Random? random]) {
    final rnd = random ?? Random.secure();
    return ids[rnd.nextInt(ids.length)];
  }

  static bool isValid(String? id) => id != null && ids.contains(id);
}
