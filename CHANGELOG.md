# Journal des modifications — GREEN (application mobile)

Format : [Keep a Changelog](https://keepachangelog.com/fr/1.1.0/). Versions : `MAJEUR.MINEUR.CORRECTIF+code Android`.

## [2.1.0+3] — 2026-11-09

Nouveau modèle de vision (TFLite), envoi automatique de toutes les analyses vers GREEN Web avec file hors ligne, nouvelle clé Gemini et fiabilisation de GreenBot, interfaces plus aérées. L'application web n'a pas été modifiée. La clé de signature Android est inchangée.

### Modèle de vision : TFLite actif, ONNX conservé

- Nouveau classifieur `plant_classifier_float16.tflite` (9 classes : manioc taches brunes / sain / mosaïque, maïs sain / jaunissement / brûlure des feuilles, tomate taches brunes / mildiou / saine), intégré selon sa fiche `model_spec.json` : entrée `[1, 224, 224, 3]` float32, pixels RGB 0–255 non normalisés, redimensionnement bilinéaire direct, sortie en probabilités.
- Couche de vision réécrite et indépendante du format (`lib/services/vision/`) : `ModelSpec` (lu dans `assets/models/active_model.json`), `ImagePreprocessor` (NHWC/NCHW, 0–255 / 0–1 / ImageNet, étirement bilinéaire ou petit côté + recadrage central), `TfliteVisionModel` (tflite_flutter 0.12.1 / LiteRT 1.4, inférence dans un isolate, appels en file) et `OnnxVisionModel` (flutter_onnxruntime 1.9.0, ancien EfficientNet-B0 rebranchable par simple changement de configuration).
- Vérification au chargement : forme, type et nombre de sorties du modèle comparés à la configuration ; un modèle mal décrit est refusé avec un message clair.
- Seul le modèle actif est embarqué : le fichier ONNX (16 Mo) reste dans le dépôt (`assets/models/onnx/`) mais n'alourdit plus l'APK.
- Base de maladies (v3, 62 fiches) : nouvelle fiche **Cercosporiose brune du manioc** (classe « Cassava Brown Leaf Spot », absente jusqu'ici) ; « Cassava Healthy » reliée à la fiche manioc sain. Le badge « Reconnue par le scanner » ne s'affiche plus que pour les 9 classes du modèle actif.
- R8 : règles LiteRT ajoutées (`org.tensorflow.lite.**`, délégué GPU) pour éviter l'échec connu « Missing class …GpuDelegateFactory$Options » en release.

### Envoi automatique au serveur GREEN Web

- Compte GREEN Web par défaut, commun à tous les comptes du téléphone (`GREEN_WEB_EMAIL` / `GREEN_WEB_PHONE` / `GREEN_WEB_PASSWORD` dans `assets/.env`). Le bouton « Relier », la feuille de liaison et la création de compte web depuis le téléphone sont supprimés.
- « Envoi des analyses au serveur GREEN » toujours actif, verrouillé dans les Paramètres (icône cadenas) ; l'écran affiche l'état réel (tout envoyé / n en attente / hors ligne / refus du serveur) et un bouton « Envoyer » si des analyses attendent. Mention à l'inscription et dans « À propos ».
- File d'envoi persistante `upload_outbox.json` dans le stockage privé de l'application (pas le cache, qu'Android peut vider) ; écritures atomiques et sérialisées ; la photo n'est pas dupliquée (référence + SHA-256).
- Reprise automatique : après chaque analyse, au retour du réseau (connectivity_plus 7.3.2), au retour dans l'application, toutes les 15 min, ou à la demande. Un seul passage à la fois ; un appel pendant un passage en programme un second.
- Intégrité : empreinte SHA-256 revérifiée avant l'envoi (une photo altérée n'est jamais envoyée) ; le serveur dédoublonne par SHA-256, donc un renvoi après coupure ne crée pas de doublon.
- Erreurs : 401 → reconnexion automatique puis renvoi ; 408/429/5xx → nouvel essai à 30 s × 2ⁿ (plafond 6 h, sans abandon) ; 400/404/413/415/422 → retiré et marqué « échec » ; identifiants refusés → pas de nouvelle tentative pendant 1 h.
- Jeton JWT seul conservé (stockage chiffré Android), renouvelé 12 h avant expiration. Anciens jetons « par compte » de la 2.0 effacés à la mise à jour.
- Analyses d'avant la 2.1 jamais envoyées : mises en file à la connexion de leur compte. Analyse supprimée ou compte supprimé avant l'envoi : retiré de la file.
- Le diagnostic recalculé par le serveur (nom, confiance) est enregistré et affiché sous la confiance dans la fiche terrain.
- Limite, sans modification du web : le serveur n'accepte pas le résultat calculé par le téléphone ; il reçoit la photo et refait l'analyse avec son propre modèle.

### GreenBot

- Nouvelle clé API Gemini. Modèles vérifiés le 9 novembre 2026 (liste `GET /v1beta/models` + appels réels) ; ordre par défaut : `gemini-3.5-flash-lite` → `gemini-3.5-flash` → `gemini-3.8-flash` (souvent saturé : 503 ou plus de 60 s).
- **Corrigé : réponses bloquées à tort.** Avec les filtres de sécurité au seuil moyen, une réponse sur deux à « feuilles de manioc jaunes et déformées » était classée « harcèlement » ; la bibliothèque échouait alors sur la réponse vide. Seuil passé à « élevé seulement » ; les garde-fous métier restent dans la consigne système.
- **Corrigé : réponses coupées.** Les modèles 3.x comptent leur « réflexion » dans `maxOutputTokens` (mesuré : 284 jetons de réflexion pour 12 de réponse) ; plafond porté de 700 à 4096.
- Délai de 25 s par modèle, puis modèle suivant ; bascule aussi sur saturation, quota, modèle introuvable ou réponse filtrée. Nouveau message « GreenBot est très sollicité » quand tous sont saturés.
- Tests : 20 tests hors ligne avec les formats et messages d'erreur réels de l'API (`test/greenbot_test.dart`) et 6 tests en conditions réelles (`test/live/`, étiquette `live`), dont un message vocal réel (synthèse vocale Gemini → transcription → réponse).

### Interfaces

- Jetons d'espacement (`lib/core/theme/spacing.dart`) : marges latérales 20 dp, 16 à 24 dp entre blocs, cartes à 20 dp de marge intérieure, formulaires à 28 dp.
- Thème : fond vert-gris très clair, cartes blanches sans bordure ni ombre (rayon 18 dp), champs blancs à contour discret, lignes de liste plus hautes, titres de groupe en casse normale, filets adaptés aux lignes sans icône, interligne 1,45–1,5, boutons de 54 dp, barre de navigation de 72 dp.
- **Corrigé :** les titres des barres d'application s'affichaient en 14 sp au lieu de 22 sp (styles de thème créés sans géométrie typographique).
- Captures d'écran reproductibles sans téléphone : `GREEN_SNAPSHOTS=1 flutter test test/snapshots --tags snapshots`.

### Indicateurs mesurés (9 novembre 2026)

| Indicateur | Valeur | Méthode |
|---|---|---|
| `flutter analyze` | 0 problème | Flutter 3.47.8 |
| Tests hors ligne | 107 / 107 réussis (+ 11 ignorés : live et captures) | `flutter test` |
| Tests réels GreenBot + GREEN Web | 18 / 18 réussis (3 passages × 6) | `GREEN_LIVE=1 flutter test test/live --tags live` |
| Couverture des fichiers testés | 69,7 % des lignes (services : 71,8 %) | `flutter test --coverage` ; les moteurs TFLite/ONNX natifs ne s'exécutent que sur téléphone |
| Modèle : exactitude top-1 / top-3 | 88,3 % / 98,1 % (213 photos entières) ; 94,8 % sur la feuille recadrée | FieldPlant, échantillon de la partie *train* : contrôle du pipeline, **pas** une mesure de généralisation |
| Modèle : diagnostic affiché / précision | 87,3 % des photos ; 92,5 % justes (59,3 % parmi les « incertain ») | seuils 70 % de confiance et 15 points d'écart |
| Modèle : inférence | 10,5 ms (CPU x86, 4 fils) ; taille 8,1 Mo | LiteRT Python ; sur téléphone, attendre 50–200 ms |
| Prétraitement Dart vs référence | écart moyen 0,89 / 255 par pixel | `vision_pipeline_test.dart` |
| GreenBot, réponse texte | médiane 1,1 s, max 3,5 s, 12/12 au 1er modèle | 3 passages réels |
| GreenBot, transcription vocale | médiane 4,8 s, 3/3 justes | 3 passages réels |
| Connexion compte GREEN Web | 1,1–2,3 s (13,5 s à froid) | serveur o2switch |

## [2.0.0+2] — 2026-11-07

Refonte de l'application mobile : interfaces, fiabilité de la prédiction, sécurité des comptes, messages vocaux, envoi des photos vers GREEN Web. L'application web (dépôt Greennew) n'a pas été modifiée.

### Environnement de build (vérifié le 7 novembre 2026)

| Élément | Version | Remarque |
|---|---|---|
| Flutter | 3.47.8 (stable) | `environment.flutter: ">=3.47.0"` |
| Dart | 3.13.7 | `sdk: ^3.13.0` |
| Android Gradle Plugin | 8.11.1 | inchangé ; AGP 9 attendra que tous les plugins aient migré |
| Kotlin (plugin Gradle) | 2.2.20 | inchangé |
| Gradle | 8.14 → **8.14.3** | correctif |
| JDK | 17 minimum, 21 conseillé | chemin JDK retiré de `gradle.properties` (il pointait vers `/usr/lib/jvm/java-21-openjdk-amd64`, absent de la machine) |
| compileSdk / targetSdk / minSdk | valeurs Flutter (36 / 36 / 24) | |

Compatibilité des plugins natifs avec AGP 8 contrôlée dans leurs fichiers Gradle :
`record` reste en 6.2.1 (la 7.x exige AGP 9 et le Kotlin intégré), `geolocator` en 13.0.4 et `image_cropper` en 8.1.0 (versions déjà validées en release sur ce projet), `flutter_onnxruntime` 1.9.0 (ONNX Runtime 1.28) et `flutter_secure_storage` 11.2.0 compatibles AGP 8.

### Signature et configuration Android

- **La clé de signature ne change pas** : `android/keystore/green_app.jks`, alias `green_app_key`, empreinte SHA-256 `27:27:BB:98:60:54:7D:26:ED:57:F8:E4:49:73:E7:D2:67:26:5B:C5:E7:4B:FE:AC:92:61:E2:1D:DD:FC:48:DA`.
- Les mots de passe de la clé, écrits en clair dans `android/app/build.gradle.kts` (et donc dans l'historique git), sont déplacés dans `android/key.properties` (ignoré par git, modèle `key.properties.example`). Un build release sans ce fichier échoue avec un message clair au lieu de produire un APK mal signé.
- `build_apk.sh` ne régénère plus jamais la clé (il le faisait si le fichier manquait, ce qui aurait rendu les mises à jour impossibles) ; `generate_keystore.sh` refuse de s'exécuter sans option explicite.
- Manifeste : trafic HTTP en clair interdit ; permissions inutilisées retirées (écriture du stockage, notifications, démarrage, vibration) ; micro ajouté pour les vocaux ; lecture de la galerie limitée à Android 12 et antérieurs ; retour prédictif Android 13+ ; règles de sauvegarde Android excluant le stockage chiffré.
- `gradle.properties` : mémoire du démon Gradle 8 Go → 4 Go, propriétés inexistantes retirées.
- Règles R8 nettoyées (règles Dio/Retrofit inutiles, règle qui empêchait toute réduction du code).

### Dépendances

- Retirées (inutilisées ou remplacées) : `camera`, `dio`, `flutter_inappwebview`, `shimmer`, `lottie`, `file_picker`, `responsive_sizer`, `intl`, `geocoding`, `permission_handler`, `connectivity_plus`, `google_fonts`, `flutter_animate`.
- Ajoutées : `record` (vocaux), `flutter_secure_storage` (jeton GREEN Web chiffré), `path`, `flutter_localizations` (textes système en français).
- Mises à jour : `go_router` 18.1.3, `flutter_dotenv` 6.0.1, `image` 4.12.0, `flutter_onnxruntime` 1.9.0, `uuid` 4.6.0, `crypto` 3.0.8, `image_picker` 1.2.4, `shared_preferences` 2.5.6.
- La police Inter n'est plus téléchargée depuis Internet (Google Fonts) : police système, lisible hors ligne.
- Le fichier de vecteurs RAG (`embeddings_f32.bin`, 6 Mo) n'est plus embarqué (voir GreenBot).

### Prédiction (modèle EfficientNet-B0, 11 classes)

- Redimensionnement conforme à l'entraînement : la v1 utilisait le plus proche voisin (valeur par défaut de la bibliothèque `image`), ce qui créait du crénelage sur les photos de 12 Mpx ; désormais filtre moyenneur puis bilinéaire, proche du `Resize` de torchvision.
- Recadrage central arrondi comme torchvision ; images 16 bits, en palette ou transparentes converties en RGB 8 bits.
- Prétraitement dans un isolate : l'interface ne se fige plus pendant l'analyse.
- Résultat « incertain » si la confiance est inférieure à 70 % **ou** si les deux premières classes sont à moins de 15 points ; les trois possibilités sont alors présentées.
- **Gravité corrigée** : elle était égale à la confiance du modèle (une plante saine reconnue à 95 % affichait « gravité très élevée »). Elle vient maintenant de la fiche de la maladie.
- Rattachement à la fiche par correspondance exacte de classe (`modelLabels`) au lieu d'une ressemblance de nom.
- Photos d'analyse **copiées de façon permanente** dans l'application (1600 px, sans EXIF ni GPS, plus une miniature) : la v1 gardait le chemin du cache du sélecteur d'images, effacé par Android, d'où des photos disparues dans l'historique.

### Base de maladies hors ligne

- 39 entrées (dont des doublons, mélange français/anglais) → **61 fiches bilingues** français/anglais, sur 15 cultures (maïs, manioc, tomate, plantain, cacao, café, arachide, haricot, riz, igname, macabo/taro, piment, cucurbitacées, oignon, patate douce).
- Chaque fiche : type (champignon, mildiou, bactérie, virus, ravageur, nématode, carence), gravité, symptômes, cause, conditions favorables, actions immédiates, prévention, confusions possibles, quand demander de l'aide. Aucun dosage de produit chimique.
- Nouvel écran de détail, recherche insensible aux accents, filtres par culture et par type.

### Comptes et sécurité des données

- Registre JSON des comptes créés sur le téléphone (`account_registry.json`) : informations du compte, question de sécurité tirée au hasard parmi quatre (liées au champ et aux cultures) et réponse **hachée**.
- **Au plus 4 comptes par téléphone** : le 5e est refusé ; un compte supprimé continue de compter (sa ligne est anonymisée).
- Après **3 échecs de connexion**, la connexion demande le nom complet et la réponse à la question de sécurité ; si les deux sont justes, l'utilisateur choisit un nouveau mot de passe. Trois mauvaises réponses verrouillent le compte 15 minutes. L'ancien écran « mot de passe oublié », qui réinitialisait le mot de passe avec le seul numéro de téléphone, est supprimé.
- Les comptes créés avant la v2 sont repris tels quels ; une question de sécurité leur est demandée à la première connexion.
- Mots de passe et réponses : PBKDF2-SHA256, 40 000 itérations (10 000 en v1, toujours acceptés), calculés hors du fil de l'interface. Écritures de fichiers atomiques.
- Saisie automatique Android (gestionnaire de mots de passe) et « Se souvenir de moi » (identifiant seulement).
- Chaque champ n'accepte que son type de données et ouvre le clavier adapté (nom, téléphone, e-mail, mot de passe, texte).
- Confirmation du mot de passe enfin vérifiée à l'inscription.
- Changement du mot de passe et de la question de sécurité ; suppression du compte protégée par le mot de passe et effaçant historique, photos et conversations.

### Transfert des photos vers GREEN Web (o2switch)

- Liaison facultative à un compte GREEN Web (connexion ou création) dans Paramètres > Données et envoi.
- Envoi des photos (déjà réduites, sans position GPS) vers `POST /api/camera/analyze-frame` ou `/api/camera/upload`, dans le dossier privé `~/green_media` du serveur, sans modification de l'application web.
- File d'attente hors ligne, reprise au retour dans l'application, 5 tentatives au plus par photo, état visible sur chaque fiche.
- Jeton (JWT) conservé dans le stockage chiffré Android ; le mot de passe GREEN Web n'est jamais enregistré. Consentement GREEN Data réglable.

### GreenBot

- **Messages vocaux** : maintenir le micro pour parler (envoi au relâchement) ou glisser vers le haut pour verrouiller (arrêt et envoi au second appui) ; glisser vers la gauche pour annuler. Forme d'onde en direct, chronomètre, 2 minutes au maximum, retours haptiques.
- Gemini transcrit le vocal (et le traduit s'il est dans une autre langue), le texte s'affiche comme message de l'utilisateur, puis GreenBot répond.
- Modèles Gemini configurables (`GEMINI_MODEL`, `GEMINI_AUDIO_MODEL`) avec repli automatique ; la famille 2.5 est dépréciée par Google.
- Contexte : les 8 **derniers** messages (la v1 envoyait les 5 premiers).
- RAG : recherche BM25 hors ligne. La recherche vectorielle de la v1 ne fonctionnait pas (vecteurs USE 512 dimensions face à `text-embedding-004` en 768, modèle arrêté le 14 janvier 2026).
- Réponses dans la langue choisie ; messages d'erreur explicites (hors ligne, clé absente, quota).

### Interfaces et navigation

- Thème Material 3 refait : contrastes élevés, cibles tactiles de 48 dp, police système.
- Animations : suppression des entrées en cascade (fondus et glissements de chaque élément à l'ouverture des écrans), des rebonds élastiques de la barre d'onglets et de la physique de défilement personnalisée qui ralentissait les listes. À la place : transitions de page Android natives avec retour prédictif, transitions courtes (150 à 250 ms) là où elles aident à comprendre un changement d'état, et respect du réglage « Supprimer les animations ».
- Barre de navigation ancrée : l'ancienne barre flottante masquait la fin des listes et la saisie du chat.
- Retours : tous les écrans secondaires s'empilent (`push`) ; retour système et flèche ramènent à l'écran précédent ; quitter depuis l'Accueil ferme vraiment l'application (la v1 rouvrait la confirmation en boucle).
- Écran de démarrage sans attente artificielle de 3 secondes.
- **Fiche terrain** refaite (photo plein écran, statut, gravité, confiance, actions, prévention, envoi, suppression).
- **Historique** refait (recherche, filtres statut et culture, regroupement par jour, suppression par glissement avec annulation).
- **Profil** et **Paramètres** refaits ; « Préférences » fusionnées dans Paramètres. La taille du texte s'applique enfin à toute l'application ; le réglage « fréquence des conseils », sans effet, est retiré.
- **Photo de profil** : copie permanente dans l'application, conservée après déconnexion, supprimable.
- **Marketplace** : petites icônes décoratives retirées (emoji de catégorie, étoiles, pictogrammes) ; ajout au panier par bouton texte.
- **Météo** : plus aucune donnée inventée (la v1 affichait une météo fictive sans clé et une pression fixe de 1012 hPa) ; conseils de pulvérisation selon le vent et la pluie ; nouvelle clé OpenWeather.
- **À propos** : mention « étudiants du département de Génie Informatique et Sciences de Données et Intelligence Artificielle », sans niveau ; version lue dans `lib/core/app_info.dart`.

### Tests

Nouveaux tests unitaires et d'interface dans `test/` : version, hachage, comptes (registre, limite par téléphone, question après 3 échecs, verrouillage, comptes v1), validation et formateurs, prétraitement ONNX, règle de décision, base de maladies, modèle d'analyse (v1 et v2), historique et photos, BM25, météo, complétude des traductions, écran de connexion.

### Limites connues

- Les clés Gemini et OpenWeather sont embarquées dans l'APK (`assets/.env`) et peuvent en être extraites ; à restreindre dans leurs consoles respectives.
- La limite de 4 comptes repose sur un fichier local : une désinstallation sans sauvegarde Android la remet à zéro.
- `google_generative_ai` n'est plus maintenu par Google ; il fonctionne avec l'API actuelle, mais une migration vers le SDK officiel suivant sera à prévoir.
