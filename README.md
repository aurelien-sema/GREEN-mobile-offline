# GREEN — application mobile

Détection hors ligne des maladies du maïs, du manioc et de la tomate à partir d'une photo, fiche terrain, base de maladies, assistant GreenBot (texte et vocal), météo du champ et marketplace d'intrants.

Version : **2.2.0 (4)** — voir [CHANGELOG.md](CHANGELOG.md). Construire l'APK : [BUILD_RELEASE.md](BUILD_RELEASE.md).

## Fonctionnement

| Fonction | Où | Réseau |
|---|---|---|
| Analyse d'une feuille (classifier_v1, TFLite float16, 9 classes ; culture choisie avant la photo) | Scanner | non |
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
├── services/        auth (comptes, registre, hachage), vision (TFLite, règle de décision), historique et photos,
│                    gemini, voice, rag, green_web (envoi o2switch), weather
└── shared/          composants d'interface communs
assets/
├── models/active_model.json   modèle utilisé par l'application (format, fichier, prétraitement)
├── models/tflite/   plant_classifier_float16.tflite, labels.txt, model_spec.json (fournis avec le modèle)
├── data/diseases.json   base de maladies v2 (modelLabels relie chaque classe à sa fiche)
└── rag/chunks.json      extraits de documents agronomiques pour GreenBot
```

## Données et confidentialité

Stockage privé de l'application : comptes (`users.json`, secrets hachés en PBKDF2), registre des comptes du téléphone (`account_registry.json`), historique et photos par compte, file d'envoi (`upload_outbox.json`).

Depuis la 2.1, chaque analyse (photo réduite à 1600 px, sans EXIF ni GPS, + date de prise) est envoyée automatiquement, en HTTPS, au compte GREEN Web par défaut défini dans `assets/.env` (`GREEN_WEB_EMAIL`/`GREEN_WEB_PHONE`/`GREEN_WEB_PASSWORD`). L'envoi n'est pas désactivable ; l'inscription l'annonce. Hors ligne, l'analyse attend dans la file (stockage privé, pas le cache) et part au retour du réseau. Seul le jeton JWT est conservé (stockage chiffré Android) ; le mot de passe reste dans l'APK.

## Modèle de vision : classifier_v1 (depuis la 2.2.0)

Modèle `assets/models/tflite/plant_classifier_float16.tflite` (projet FieldPlant_9classes, poids float16, entrée et sortie float32), décrit par `assets/models/active_model.json` (id `classifier_v1`, enregistré avec chaque analyse). L'ancien modèle ONNX à 11 classes et son moteur ont été supprimés.

- **Prétraitement** (`lib/services/vision/image_preprocessor.dart`), identique à l'entraînement : pixels RGB ; redimensionnement à 224×224 bilinéaire **avec anti-crénelage** (même algorithme que `tf.image.resize(..., antialias=True)`), image étirée sans recadrage ; valeurs float32 brutes 0–255 (ni division par 255, ni moyenne), NHWC `[1, 224, 224, 3]`.
- **Sortie** : `[1, 9]` probabilités, utilisées telles quelles (pas de softmax).
- **Règle de décision** (`lib/services/vision/decision_rule.dart`), identique au backend : l'utilisateur choisit la culture avant la photo ; `best` = classe la plus probable **parmi les 9** ; culture de `best` ≠ culture choisie → `wrong_crop` ; sinon confiance < seuil → `unknown` ; sinon `ok`. Jamais de renormalisation ni de maximum limité aux 3 classes de la culture choisie.
- **Seuil** : `AppConstants.visionConfidenceThreshold = 0.70`, unique et global, **provisoire**, même valeur que le backend.
- **Scanner** : choix de la culture, puis cadre carré (une seule feuille qui remplit le cadre) ; seule la zone cadrée est analysée.
- **Moteur** : interpréteur TFLite chargé une fois, inférence dans un isolate dédié (jamais sur le fil de l'interface).

Pour changer de modèle : déposer le `.tflite` et son `labels.txt` (classes commençant par `Cassava`, `Corn` ou `Tomato`), mettre à jour `active_model.json`, ajouter les classes dans `modelLabels` de `assets/data/diseases.json`, puis relancer le test d'acceptation. Un modèle dont l'entrée ou la sortie ne correspond pas est refusé au chargement.

## Tests

```bash
flutter test                                              # tests hors ligne (118)
flutter test integration_test/classifier_v1_acceptance_test.dart -d <appareil>   # vrai modèle, sur téléphone Android (12 cas)
GREEN_LIVE=1 flutter test test/live --tags live           # vraie clé Gemini + vrai serveur GREEN Web
GREEN_SNAPSHOTS=1 flutter test test/snapshots --tags snapshots   # captures d'écran → build/snapshots/
```
