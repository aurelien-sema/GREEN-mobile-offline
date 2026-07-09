/// Détermine si un nom de maladie/résultat correspond à une plante saine.
///
/// Centralisé ici car utilisé à la fois par l'écran Maladies et l'historique
/// de l'Accueil pour dériver les mêmes couleurs de statut (vert/ambre) — avant
/// ce partage, l'heuristique ('sain') était dupliquée indépendamment dans les
/// deux écrans et risquait de diverger silencieusement.
bool isHealthyDiseaseName(String name) => name.toLowerCase().contains('sain');
