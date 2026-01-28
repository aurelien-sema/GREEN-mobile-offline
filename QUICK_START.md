# 🚀 Instructions de Configuration - Green App

## ✅ Configuration Rapide (5 minutes)

### Étape 1: Cloner/Mettre à jour le projet

```bash
cd /home/neo-space-corp/Bureau/green_app
flutter clean
flutter pub get
```

### Étape 2: Obtenir une clé API Gemini

1. Aller sur https://makersuite.google.com/app/apikey
2. Cliquer sur "Create API Key"
3. Sélectionner "In new Google Cloud project"
4. Copier la clé

### Étape 3: Configurer la clé API

Ouvrir `lib/main.dart` et remplacer la ligne 18:

```dart
// AVANT:
geminiService.initialize('YOUR_GEMINI_API_KEY');

// APRÈS:
geminiService.initialize('AIzaSyD...'); // Votre clé réelle
```

### Étape 4: Tester l'app

```bash
flutter run -d chrome  # Ou votre device
```

## 🔧 Configuration Détaillée

### Configuration Gemini Avancée

**Option 1: Depuis le code (Rapide - Développement)**
```dart
// lib/main.dart
geminiService.initialize('YOUR_API_KEY_HERE');
```

**Option 2: Depuis les variables d'environnement (Sécurisé - Production)**

Créer `.env` à la racine du projet:
```
GEMINI_API_KEY=AIzaSyD...
```

Installer le package:
```bash
flutter pub add flutter_dotenv
```

Utiliser dans `lib/main.dart`:
```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  await dotenv.load();
  String apiKey = dotenv.env['GEMINI_API_KEY']!;
  geminiService.initialize(apiKey);
  // ...
}
```

Ajouter dans `pubspec.yaml`:
```yaml
flutter:
  assets:
    - assets/images/
    - .env
```

### Configuration pour Android

Aucune configuration supplémentaire requise. Les permissions sont déjà dans `AndroidManifest.xml`:
- ✅ INTERNET
- ✅ CAMERA
- ✅ READ/WRITE_EXTERNAL_STORAGE

## 📱 Tester sur Device

### Android Physique

```bash
# Connecter le device via USB
# Activer le débogage USB dans les paramètres développeur

flutter devices  # Vérifier que le device est reconnu
flutter run -d <device_id>
```

### Android Émulateur

```bash
flutter emulators --launch <emulator_id>
flutter run
```

### Web (Pour tester rapidement)

```bash
flutter run -d chrome
```

## 🎨 Tester les Features

### 1. Tester le Thème

```
1. Ouvrir l'app → Drawer (≡)
2. Cliquer sur "Thème sombre" toggle
3. Vérifier les couleurs changent partout
```

### 2. Tester le Chat avec Gemini

```
1. Aller à Chat (💬) dans la bottom nav
2. Taper un message: "Quels soins pour un monstera?"
3. Le bot devrait répondre avec l'API Gemini
```

### 3. Tester la Responsivité

```dart
// Dans responsive_helper.dart, logs:
print(ResponsiveHelper.getScreenWidth(context));
print(ResponsiveHelper.isSmallScreen(context));

// Utiliser Chrome DevTools pour tester différentes résolutions
```

### 4. Tester la Navigation

```
1. Cliquer sur chaque onglet (Home, Scanner, Chat, Profil)
2. Vérifier que l'animation de surbrillance fonctionne
3. Ouvrir le Drawer et naviguer
4. Vérifier que les animations apparaissent
```

## 🐛 Troubleshooting

### Erreur: "Invalid API Key"

```
Solution: Vérifier que la clé est correctement copiée
- Pas d'espaces au début/fin
- Pas de quotes supplémentaires
- Clé active sur makersuite.google.com
```

### Erreur: "google_generative_ai not found"

```bash
flutter pub get
flutter pub add google_generative_ai
flutter clean
flutter pub get
```

### L'app ne réagit pas au toggle thème

```dart
// Vérifier que MultiProvider est bien configuré dans main.dart:
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => ThemeProvider()),
    ChangeNotifierProvider(create: (_) => AppSettingsProvider()),
  ],
  // ...
)
```

### Les animations n'apparaissent pas

```dart
// Vérifier les imports dans la page:
import 'package:flutter_animate/flutter_animate.dart';

// Vérifier que le widget a .animate():
Widget.animate().fadeIn()...
```

## 📊 Vérifier la Configuration

### Commande Diagnostique

```bash
flutter doctor -v
flutter analyze
flutter pub outdated
```

### Vérifier l'installation des packages

```bash
flutter pub list
```

Doit contenir:
- ✅ google_generative_ai
- ✅ provider
- ✅ go_router
- ✅ flutter_animate
- ✅ google_fonts

## 🏗️ Build pour Production

### Build APK Release

```bash
./build_apk.sh
```

Ou manuellement:

```bash
flutter build apk --release
```

Le fichier sera à:
```
build/app/outputs/flutter-apk/app-release.apk
```

### Build App Bundle (Pour Google Play)

```bash
flutter build appbundle --release
```

Output:
```
build/app/outputs/bundle/release/app-release.aab
```

## 📝 Fichiers de Configuration

### pubspec.yaml

```yaml
name: green_app
description: "Application mobile de détection de maladies des plantes avec IA - Naturellement Intelligent"
version: 1.0.0+1

dependencies:
  flutter: sdk: flutter
  # Thème et UI
  google_fonts: ^6.1.0
  flutter_animate: ^4.5.0
  # État et routing
  provider: ^6.1.1
  go_router: ^14.2.0
  # IA
  google_generative_ai: ^0.4.5
  # Autre
  shared_preferences: ^2.2.2
  image_picker: ^1.0.7
```

### AndroidManifest.xml

```xml
<!-- Permissions requises -->
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />

<!-- Features optionnelles -->
<uses-feature android:name="android.hardware.camera" android:required="false" />
<uses-feature android:name="android.hardware.camera.autofocus" android:required="false" />
```

## 🔐 Sécurité

### Pour la Production

1. **Ne jamais commiter la clé API**
   ```
   Ajouter à .gitignore:
   .env
   lib/config/secrets.dart
   ```

2. **Utiliser Firebase Remote Config (Optionnel)**
   ```dart
   // Récupérer la clé depuis Firebase au lieu de la hardcoder
   ```

3. **Limiter la clé API**
   - Aller sur Google Cloud Console
   - Restreindre à Android app
   - Ajouter SHA-1 de votre certificat de signature

## 📚 Ressources

- **Gemini AI Docs**: https://ai.google.dev/docs
- **Flutter Docs**: https://flutter.dev/docs
- **Material Design 3**: https://m3.material.io/

## ✨ Commandes Utiles

```bash
# Nettoyer le projet
flutter clean
flutter pub get

# Vérifier les erreurs
flutter analyze

# Format le code
dart format lib/

# Exécuter un test
flutter test

# Hot reload (pendant flutter run)
r

# Hot restart
R

# Quitter
q
```

## 🎯 Prochaines Étapes

1. ✅ Configuration complétée
2. ⏳ Intégration Gemini dans chat_screen.dart
3. ⏳ Ajouter animations à toutes les pages
4. ⏳ Tester sur device physique
5. ⏳ Build APK release
6. ⏳ Publication Google Play Store

---

**Aide Rapide**: Pour toute erreur, consultez les logs:
```bash
flutter run -v  # Logs verbeux
```

**Support**: Consulter la documentation à:
- `APK_BUILD_GUIDE.md`
- `BUILD_CONFIG.md`
- `MODIFICATIONS_SUMMARY.md`

