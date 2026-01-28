# 🌿 Green App - Détection de Maladies des Plantes avec IA

<div align="center">

**Application Flutter Professionnelle & Moderne**

[![Flutter](https://img.shields.io/badge/Flutter-3.10+-blue.svg)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.10+-blue.svg)](https://dart.dev)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

[📖 Documentation](#-documentation) • [🚀 Démarrage Rapide](#-démarrage-rapide) • [🤝 Contribution](#-contribution)

</div>

---

## 🎯 Aperçu

**Green App** est une application mobile de pointe pour diagnostiquer les maladies des plantes en temps réel grâce à :
- 🤖 **Vision par Ordinateur (IA)** - Détection automatique des maladies
- 💬 **Chatbot Intelligent** - Conseils personnalisés et assistance
- 📚 **Base de Données Complète** - Catalogue des maladies et traitements
- 🎨 **Design Premium** - Thème clair/sombre avec animations fluides

## ✨ Fonctionnalités Principales

| Fonctionnalité | Description |
|---|---|
| **📸 Scanner Intelligent** | Capture d'images via caméra ou galerie avec analyse IA instantanée |
| **🔍 Détection Précise** | Identification des maladies avec taux de confiance |
| **💡 Conseils IA** | Assistant conversationnel pour recommandations personnalisées |
| **📖 Base de Maladies** | Catalogue complet avec descriptions et traitements |
| **👤 Profil Utilisateur** | Historique des scans et statistiques |
| **🌓 Thème Dual** | Basculement dynamique clair/sombre |
| **✨ Animations** | Transitions fluides et expérience utilisateur premium |
| **📱 Responsive** | Adaptatif pour tous les appareils Android/iOS |

## 🏗️ Architecture Professionnelle

**Clean Architecture avec Séparation des Responsabilités:**

```
lib/
├── core/
│   ├── constants/          # Couleurs, constantes, tailles
│   ├── theme/              # Thèmes clair/sombre
│   ├── routing/            # Navigation GoRouter
│   └── extensions/         # Extensions utiles
├── features/               # Fonctionnalités métier
│   ├── auth/              # Authentification & Splash
│   ├── home/              # Accueil
│   ├── camera/            # Scanner de plantes
│   ├── chat/              # Chat IA
│   ├── diseases/          # Base de maladies
│   └── profile/           # Profil & Paramètres
├── services/              # Services externes
│   ├── api/               # Vision & Chatbot APIs
│   └── storage/           # Stockage local
├── shared/                # Widgets & Modèles partagés
└── main.dart              # Point d'entrée
```

## 🔌 Intégration Python

### Prérequis

- Flutter SDK (>=3.10.1)
- Dart SDK
- Android Studio / Xcode (pour émulateurs)

### Installation

1. Cloner le projet
```bash
cd green_app
```

2. Installer les dépendances
```bash
flutter pub get
```

3. Configurer les APIs Python (optionnel)

Modifier `lib/config/api_config.dart` avec vos URLs d'API :

```dart
static const String visionBaseUrl = 'http://votre-api-vision:8001';
static const String chatbotBaseUrl = 'http://votre-api-chatbot:8002';
```

### Lancement

```bash
flutter run
```

## 🎨 Thèmes

L'application supporte deux thèmes :

- **Thème Clair** : Fond blanc avec accents verts
- **Thème Sombre** : Fond vert foncé avec accents verts clairs

Le changement de thème est accessible via le bouton dans l'AppBar.

## 🔌 Intégration Python

L'application communique avec deux services Python indépendants :

### 1️⃣ Vision Service (Détection de Maladies)
```python
POST http://localhost:8000/api/vision/detect
- Request: multipart/form-data (image)
- Response: { diseaseId, diseaseName, confidence, treatments, severity }
```

### 2️⃣ Chatbot Service (Assistant IA)
```python
POST http://localhost:8000/api/chat/message
- Request: { message, context, image_url }
- Response: { id, response, image_url }
```

📚 **[Documentation Backend →](./PYTHON_BACKEND.md)**
📚 **[Exemple Backend →](./backend_example.py)**

## 🚀 Démarrage Rapide

### Prérequis
- **Flutter**: 3.10.1+
- **Dart**: 3.10.1+
- **Python**: 3.8+ (pour le backend)
- **Android Studio** ou **Xcode** (optionnel)

### Installation

```bash
# 1. Cloner le projet
cd green_app

# 2. Installer les dépendances Flutter
flutter pub get

# 3. Lancer l'application
flutter run

# 4. (Optionnel) Générer les fichiers GoRouter
dart run build_runner build
```

### Lancer le Backend

```bash
# 1. Installer les dépendances Python
pip install -r requirements.txt  # ou voir backend_example.py

# 2. Lancer le serveur
python3 backend_example.py

# 3. Tester sur http://localhost:8000/docs
```

## 🎨 Design & Thèmes

### Palette de Couleurs

| Thème | Primaire | Secondaire | Surface |
|-------|----------|-----------|---------|
| **Clair** | #2E8B57 | #90EE90 | #FFFFFF |
| **Sombre** | #4CAF50 | #66BB6A | #1E1E1E |

### Typography
- **Police**: Google Fonts (Poppins)
- **Tailles**: 12px - 28px avec hiérarchie cohérente

## 📲 Écrans

| Écran | Description | Route |
|-------|-------------|-------|
| **Splash** | Démarrage avec animation | `/` |
| **Login** | Connexion utilisateur | `/login` |
| **Register** | Inscription | `/register` |
| **Home** | Tableau de bord & accueil | `/home` |
| **Camera** | Scanner de plantes | `/camera` |
| **Chat** | Assistant IA | `/chat` |
| **Diseases** | Base de maladies | `/diseases` |
| **Profile** | Profil utilisateur | `/profile` |
| **Settings** | Paramètres | `/settings` |
| **Notifications** | Notifications | `/notifications` |
| **Preferences** | Préférences | `/preferences` |

## 🎯 Bonnes Pratiques Implémentées

✅ **Architecture Clean** - Séparation des responsabilités  
✅ **State Management** - Provider Pattern efficace  
✅ **Responsive Design** - Adaptive pour tous les appareils  
✅ **Animations Fluides** - flutter_animate pour transitions  
✅ **Navigation Moderne** - GoRouter avec routes typées  
✅ **Thème Dual** - Clair/Sombre persistant  
✅ **API Integration** - Services découplés et testables  
✅ **Code Modulaire** - Fichiers réutilisables et maintenables  

📖 **[Lire les Bonnes Pratiques →](./BEST_PRACTICES.md)**

## 🔧 Configuration

### Variables d'Environnement (.env)
```env
API_BASE_URL=http://localhost:8000
API_TIMEOUT=30000
ENABLE_ANALYTICS=true
```

Copier `.env.example` en `.env` et adapter.

## 🧪 Tests

```bash
# Tests unitaires
flutter test

# Tests d'intégration
flutter test integration_test/

# Tests avec couverture
flutter test --coverage
```

## 📦 Build Production

### Android
```bash
flutter build apk --release
flutter build appbundle --release  # Pour Google Play
```

### iOS
```bash
flutter build ios --release
```

## 🤝 Contribution

Les contributions sont bienvenues! 

```bash
# 1. Fork le projet
# 2. Créer une branche feature
git checkout -b feature/amazing-feature

# 3. Commit les changements
git commit -m 'Add amazing feature'

# 4. Push vers la branche
git push origin feature/amazing-feature

# 5. Ouvrir une Pull Request
```

## 📚 Documentation

- **[🏗️ Architecture Détaillée](./ARCHITECTURE.md)** - Guide complet de la structure
- **[🐍 Backend Python](./PYTHON_BACKEND.md)** - Intégration des APIs
- **[✨ Bonnes Pratiques](./BEST_PRACTICES.md)** - Conventions et patterns

## 🐛 Troubleshooting

### "Android Gradle Error"
```bash
flutter clean
flutter pub get
flutter run
```

### "iOS Pods Error"
```bash
cd ios
rm -rf Pods
rm -rf Podfile.lock
cd ..
flutter pub get
flutter run
```

### "API Connexion Timeout"
- Vérifier que le backend Python est lancé
- Vérifier l'adresse IP: `http://localhost:8000` ou `http://192.168.x.x:8000`
- Vérifier les logs: `flutter run --verbose`

## 📊 Statistiques du Projet

| Métrique | Valeur |
|----------|--------|
| **Écrans** | 11 |
| **Widgets Personnalisés** | 8+ |
| **Fichiers Dart** | 30+ |
| **Lignes de Code** | 3000+ |
| **Architecture** | Clean + MVVM |
| **State Management** | Provider |

## 🌟 Fonctionnalités Futures

- [ ] Notifications push
- [ ] Synchronisation cloud
- [ ] Authentification OAuth
- [ ] Localisation multilingue
- [ ] Offline mode amélioré
- [ ] Widget iOS
- [ ] Apple Watch app

## 📞 Support & Contact

Pour toute question ou problème:
- 📧 Email: support@greenapp.dev
- 🐛 Issues: [GitHub Issues](https://github.com/greenapp/issues)
- 💬 Discussions: [GitHub Discussions](https://github.com/greenapp/discussions)

## 👨‍💻 À Propos

**Green App** a été développée avec passion par une équipe d'experts Flutter pour offrir la meilleure expérience utilisateur dans la détection et le traitement des maladies des plantes.

Construit avec ❤️ en utilisant **Flutter** et **Python**.

## 📄 Licence

MIT License - Voir [LICENSE](LICENSE) pour plus de détails.

---

<div align="center">

**Dernière mise à jour**: 19 janvier 2026  
**Version**: 1.0.0  
**Status**: ✅ Production Ready

[⬆ Retour au haut](#-green-app---détection-de-maladies-des-plantes-avec-ia)

</div>
