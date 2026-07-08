/// Identifiant de l'utilisateur actuellement connecté sur cet appareil.
///
/// L'authentification permet plusieurs comptes locaux sur le même appareil
/// (users.json dans AuthService), mais l'historique de scans, les
/// conversations et les conseils mis en cache n'étaient rattachés à aucun
/// compte : un nouveau compte voyait les données du précédent. UserScope
/// donne aux services concernés (HistoryService, ChatHistoryService,
/// GeminiService) un identifiant courant sur lequel baser leurs fichiers/clés
/// de stockage, sans les coupler directement à AuthProvider.
class UserScope {
  UserScope._();

  static String? _userId;

  /// null tant qu'aucun utilisateur n'est connecté (ou après déconnexion).
  static String? get userId => _userId;

  /// À appeler après une connexion/inscription réussie, après restauration de
  /// session au démarrage, et avec `null` à la déconnexion.
  static void setUserId(String? id) {
    _userId = id;
  }
}
