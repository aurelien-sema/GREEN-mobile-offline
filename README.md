# GREEN — application mobile

Détection hors ligne des maladies du maïs, du manioc et de la tomate à partir d'une photo, fiche terrain, base de maladies, assistant GreenBot (texte et vocal), météo du champ et marketplace d'intrants.

Version : **2.1.0 (3)** — voir [CHANGELOG.md](CHANGELOG.md). Construire l'APK : [BUILD_RELEASE.md](BUILD_RELEASE.md).

## Fonctionnement

| Fonction | Où | Réseau |
|---|---|---|
| Analyse d'une photo (classifieur TFLite float16, 9 classes ; moteur ONNX conservé) | Scanner | non |
| Fiche terrain, historique, base de 62 fiches bilingues | Fiche, Historique, Base des maladies | non |
| GreenBot (Gemini) avec documents agronomiques (BM25) et messages vocaux | GreenBot | oui |
| Météo (OpenWeatherMap) | Accueil, Météo | oui |
| Envoi automatique des analyses (photo + résultat) vers GREEN Web (o2switch), file hors ligne | automatique ; état dans Paramètres > Données et envoi | oui, reprise automatique |

## Structure

```
lib/
├── core/            thème, routage, constantes, validation, démarrage, version (app_info.dart)
├── features/        écrans : auth, home, camera (scanner + fiche terrain), history, chat,
│                    diseases, weather, profile (profil, paramètres, à propos), marketplace
├── l10n/            textes FR / EN / Pidgin (app_strings.dart + app_strings_v2.dart)
├── models/          analyses, fiches maladies, utilisateur, produits
├── providers/       état partagé (session, langue, thème, taille du texte, météo…)
├── services/        auth (comptes, registre, hachage), vision (TFLite + ONNX), historique et photos,
│                    gemini, voice, rag, green_web (envoi o2switch), weather
└── shared/          composants d'interface communs
assets/
├── models/active_model.json   modèle utilisé par l'application (format, fichier, prétraitement)
├── models/tflite/   plant_classifier_float16.tflite, labels.txt, model_spec.json (fournis avec le modèle)
├── models/onnx/     efficientnet_11classes.onnx + onnx_model.json (conservé, non embarqué dans l'APK)
├── data/diseases.json   base de maladies v2 (modelLabels relie chaque classe à sa fiche)
└── rag/chunks.json      extraits de documents agronomiques pour GreenBot
```

## Données et confidentialité

Stockage privé de l'application : comptes (`users.json`, secrets hachés en PBKDF2), registre des comptes du téléphone (`account_registry.json`), historique et photos par compte, file d'envoi (`upload_outbox.json`).

Depuis la 2.1, chaque analyse (photo réduite à 1600 px, sans EXIF ni GPS, + date de prise) est envoyée automatiquement, en HTTPS, au compte GREEN Web par défaut défini dans `assets/.env` (`GREEN_WEB_EMAIL`/`GREEN_WEB_PHONE`/`GREEN_WEB_PASSWORD`). L'envoi n'est pas désactivable ; l'inscription l'annonce. Hors ligne, l'analyse attend dans la file (stockage privé, pas le cache) et part au retour du réseau. Seul le jeton JWT est conservé (stockage chiffré Android) ; le mot de passe reste dans l'APK.

## Changer de modèle de vision

Le code ne contient aucune constante propre à un modèle : tout est dans `assets/models/active_model.json`.

- **Modèle actif (2.1)** : `plant_classifier_float16.tflite`, entrée `[1, 224, 224, 3]` float32 en pixels bruts 0–255 (RGB), redimensionnement bilinéaire direct, sortie = 9 probabilités dans l'ordre de `labels.txt`.
- **Repasser au modèle ONNX** : copier le contenu de `assets/models/onnx/onnx_model.json` dans `assets/models/active_model.json`, remplacer `- assets/models/tflite/` par `- assets/models/onnx/` dans `pubspec.yaml`, puis `flutter pub get`.
- **Nouveau modèle** : déposer le fichier et son `labels.txt`, décrire l'entrée (`layout` nhwc/nchw, `width`, `height`, `pixels` raw_0_255/unit_0_1/imagenet, `resize` stretch_bilinear/shorter_side_center_crop) et la sortie (`probabilities`/`logits`), ajouter les classes dans `modelLabels` de `assets/data/diseases.json`. Au chargement, la forme des tenseurs est vérifiée contre ce fichier : un modèle mal décrit est refusé au lieu de donner de fausses prédictions. Les tests `vision_pipeline_test.dart` et `diseases_catalog_test.dart` signalent une classe sans fiche.

## Tests

```bash
flutter test                                              # tests hors ligne (107)
GREEN_LIVE=1 flutter test test/live --tags live           # vraie clé Gemini + vrai serveur GREEN Web
GREEN_SNAPSHOTS=1 flutter test test/snapshots --tags snapshots   # captures d'écran → build/snapshots/
```
