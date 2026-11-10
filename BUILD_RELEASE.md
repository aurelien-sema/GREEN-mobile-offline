# Construire l'APK release de GREEN

## Prérequis (vérifiés le 7 novembre 2026 sur la machine de développement)

| Outil | Version | Vérifier avec |
|---|---|---|
| Flutter | 3.47.8 stable (Dart 3.13.7) | `flutter --version` |
| JDK | 21 (17 minimum) | `java -version` |
| Android SDK | plateforme 36, build-tools récents | `flutter doctor -v` |

Si `flutter` (installé par snap) répond « cannot run snap applications », appelez directement
`~/snap/flutter/common/flutter/bin/flutter`.

Le JDK n'est plus fixé dans `android/gradle.properties` (le chemin écrit ne correspondait à aucun JDK
installé). Indiquez-le une fois à Flutter :

```bash
flutter config --jdk-dir=/usr/lib/jvm/jdk-21.0.11-oracle-x64
flutter doctor -v   # la section « Android toolchain » doit citer ce JDK
```

## Fichiers locaux obligatoires (jamais dans git)

1. `android/keystore/green_app.jks` — **la clé existante, à ne jamais régénérer.**
2. `android/key.properties` — mots de passe de la clé (modèle : `android/key.properties.example`).
3. `assets/.env` — clé Gemini, clé OpenWeather, URL et identifiants du compte GREEN Web par défaut (modèle : `.env.example`). Il doit exister ; `build_apk.sh` signale les valeurs vides.

À vérifier aussi (versionné, mais indispensable) : `assets/models/tflite/plant_classifier_float16.tflite`, le modèle de vision actif (8,1 Mo). `build_apk.sh` s'arrête s'il manque.

## Construire

```bash
cd green_app
flutter pub get
flutter analyze
flutter test

# Un APK par architecture (≈ 3 fois plus léger) :
flutter build apk --release --split-per-abi
#   → build/app/outputs/flutter-apk/app-arm64-v8a-release.apk (la plupart des téléphones récents)
#   → app-armeabi-v7a-release.apk (anciens téléphones 32 bits)

# Ou un APK unique pour tous les téléphones (plus lourd, pratique à partager) :
flutter build apk --release
#   → build/app/outputs/flutter-apk/app-release.apk
```

`./build_apk.sh` enchaîne ces étapes avec les contrôles (clé, key.properties, .env).

## Vérifier que la clé n'a pas changé

```bash
$ANDROID_HOME/build-tools/<version>/apksigner verify --print-certs build/app/outputs/flutter-apk/app-release.apk
```

L'empreinte SHA-256 doit être :

```
27:27:BB:98:60:54:7D:26:ED:57:F8:E4:49:73:E7:D2:67:26:5B:C5:E7:4B:FE:AC:92:61:E2:1D:DD:FC:48:DA
```

Si elle diffère, n'envoyez pas l'APK : il ne pourrait pas mettre à jour l'application installée.

## Installer sur un téléphone

```bash
adb install -r build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

`-r` remplace la version précédente en gardant les données (comptes, historique), ce qui n'est
possible qu'avec la même clé et un code de version supérieur (`+2` dans `pubspec.yaml`).

## Problèmes fréquents

| Message | Cause | Solution |
|---|---|---|
| `android/key.properties introuvable` | fichier absent | le créer depuis `key.properties.example` |
| `Unable to load asset: assets/.env` | fichier absent | `cp .env.example assets/.env` |
| `Inconsistent JVM-target compatibility` | plugin compilé en Java 11 | déjà corrigé pour `flutter_onnxruntime` dans `android/build.gradle.kts` |
| Gradle manque de mémoire | ordinateur chargé | fermer le navigateur ; `org.gradle.jvmargs` est réglé à 4 Go |
| `INSTALL_FAILED_UPDATE_INCOMPATIBLE` | APK signé avec une autre clé | vérifier l'empreinte ci-dessus |
