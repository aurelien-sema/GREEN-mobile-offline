# 🎯 Green App - Roadmap des Modifications Complètes

## 📊 Vue d'ensemble des Changements

```
┌─────────────────────────────────────────────────────────────┐
│                   GREEN APP UPDATE v1.0.0                   │
│              "Naturellement Intelligent"                      │
└─────────────────────────────────────────────────────────────┘

├─ 🎨 DESIGN & INTERFACE
│  ├─ ✅ Thème clair/sombre cohérent
│  ├─ ✅ BottomNavBar animée (4 pages)
│  ├─ ✅ Drawer menu avec hamburger
│  ├─ ✅ Animations d'apparition (fadeIn, slideY, slideX)
│  └─ ✅ Tailles responsives dynamiques
│
├─ 🔐 AUTHENTIFICATION
│  ├─ ✅ Login avec "Mot de passe oublié?"
│  ├─ ✅ Register avec toggle Email/Téléphone
│  └─ ✅ Page de réinitialisation mot de passe
│
├─ 🤖 IA & CHAT
│  ├─ ✅ Intégration Gemini 1.5 Flash
│  ├─ ✅ Service pour réponses IA
│  ├─ ✅ Bot nommé "Green Bot"
│  └─ ⏳ Implémentation chat complète
│
├─ 📱 NAVIGATION
│  ├─ ✅ Home (Accueil)
│  ├─ ✅ Camera (Scanner)
│  ├─ ✅ Chat (Chat IA)
│  ├─ ✅ Profile (Profil) [remplace Maladies]
│  └─ ✅ Drawer pour options avancées
│
├─ ⚙️ CONFIGURATION
│  ├─ ✅ pubspec.yaml actualisé
│  ├─ ✅ Providers centralisés
│  ├─ ✅ Services Gemini
│  └─ ⏳ Clé API à configurer
│
└─ 📦 BRANDING
   ├─ ✅ Nom: "Green"
   ├─ ✅ Slogan: "Naturellement Intelligent"
   ├─ ✅ Splash screen 7s
   └─ ✅ Icône eco thème
```

## 🎬 Changements Majeurs Détaillés

### 1️⃣ **Branding Global**
| Avant | Après |
|-------|-------|
| "Green App" | "Green" |
| "Détection de maladies des plantes" | "Naturellement Intelligent" |
| 3 secondes splash | 7 secondes splash |

### 2️⃣ **Navigation Principale**
```
┌─────────────────────────────┐
│   BOTTOM NAVIGATION BAR      │
├─────────────────────────────┤
│ 🏠      📱      💬      👤   │
│Home   Scanner  Chat   Profile│
└─────────────────────────────┘
       + Drawer Menu (≡)
```

### 3️⃣ **Drawer Menu Structure**
```
┌──────────────────────────┐
│ 🌿 Green                 │
│ Naturellement Intelligent │
├──────────────────────────┤
│ 🏠 Accueil               │
│ 📱 Scanner               │
│ 💬 Chat IA               │
│ 👤 Profil                │
├──────────────────────────┤
│ PARAMÈTRES               │
│ 🌙 Thème sombre  [Toggle]│
│ 🌐 Langue                │
│ ⚙️  Préférences           │
│ 🔧 Paramètres            │
├──────────────────────────┤
│ SUPPORT                  │
│ ℹ️  À propos              │
│ ❓ Aide                   │
├──────────────────────────┤
│ 🚪 Déconnexion           │
└──────────────────────────┘
```

### 4️⃣ **Pages d'Authentification**
```
LOGIN SCREEN                REGISTER SCREEN
┌────────────────┐         ┌────────────────┐
│ Connexion      │         │ Inscription    │
├────────────────┤         ├────────────────┤
│ 📧 Email       │         │ Email|Téléphone│
│ 🔒 Mot de passe│         │ 👤 Nom         │
│ ❓ [Oublié?]   │◄───────►│ 📧/☎️ Contact  │
│ ✅ Se connecter│         │ 🔒 Mot de passe│
└────────────────┘         │ ✅ S'inscrire  │
                           └────────────────┘
```

### 5️⃣ **Hiérarchie des Tailles**
```
┌─────────────────────────────────────┐
│    RESPONSIVE SIZING SYSTEM         │
├─────────────────────────────────────┤
│ Small Screen (<600px)               │
│   • Padding: 16dp                   │
│   • Border Radius: 12dp             │
│   • Font: -10%                      │
├─────────────────────────────────────┤
│ Medium Screen (600-900px)           │
│   • Padding: 20dp                   │
│   • Border Radius: 16dp             │
│   • Font: 100%                      │
├─────────────────────────────────────┤
│ Large Screen (>900px)               │
│   • Padding: 24dp                   │
│   • Border Radius: 20dp             │
│   • Font: +10%                      │
└─────────────────────────────────────┘
```

## 📋 Checklist d'Intégration

```
PRIORITÉ HAUTE - À faire immédiatement:
☐ Installer les packages: flutter pub get
☐ Obtenir clé API Gemini
☐ Configurer clé dans main.dart
☐ Tester le build apk --release
☐ Vérifier les animations sur device

PRIORITÉ MOYENNE - À faire bientôt:
☐ Intégrer chat complètement avec Gemini
☐ Ajouter tailles responsives à home_screen.dart
☐ Ajouter toggle thème page profil
☐ Ajouter animations toutes les pages
☐ Tester sur différents appareils

PRIORITÉ BASSE - Futur:
☐ Ajouter page "Maladies" au drawer
☐ Historique chat persistant
☐ Préférences utilisateur sauvegardées
☐ Support multilingue complet
☐ Analytics
```

## 🔑 Configuration Requise

### 1. Clé API Gemini
```dart
// lib/main.dart - ligne 17
geminiService.initialize('paste_your_key_here');
```

Obtenir la clé: https://makersuite.google.com/app/apikey

### 2. Packages à Installer
```bash
flutter pub add google_generative_ai
flutter pub get
flutter pub upgrade
```

### 3. Vérifier la Configuration
```bash
flutter doctor
flutter analyze
```

## 📱 Structure de Fichiers Finale

```
lib/
├── main.dart ✅ (Mis à jour)
├── config/
│   └── constants.dart (Optionnel - à créer)
├── core/
│   ├── constants/
│   │   └── app_colors.dart ✅
│   ├── helpers/
│   │   └── responsive_helper.dart ✅ (NOUVEAU)
│   ├── routing/
│   │   └── app_router.dart ✅ (Mis à jour)
│   └── theme/
│       └── app_theme.dart ✅ (Mis à jour)
├── features/
│   ├── auth/
│   │   └── screens/
│   │       ├── splash_screen.dart ✅ (Mis à jour)
│   │       ├── login_screen.dart ✅ (Mis à jour)
│   │       ├── register_screen.dart ✅ (Mis à jour)
│   │       └── forgot_password_screen.dart ✅ (NOUVEAU)
│   ├── home/screens/home_screen.dart (À améliorer)
│   ├── camera/screens/camera_screen.dart (À améliorer)
│   ├── chat/screens/chat_screen.dart (À améliorer)
│   ├── profile/screens/profile_screen.dart (À améliorer)
│   └── diseases/screens/diseases_screen.dart (Optionnel)
├── providers/
│   ├── theme_provider.dart ✅ (Mis à jour)
│   └── app_settings_provider.dart ✅ (NOUVEAU)
├── services/
│   ├── gemini/
│   │   └── gemini_service.dart ✅ (NOUVEAU)
│   └── storage/
│       └── storage_service.dart ✅
└── shared/
    └── widgets/
        ├── app_drawer.dart ✅ (NOUVEAU)
        ├── main_navigation_shell.dart ✅ (Mis à jour)
        └── ...
```

## 🎨 Animations Implémentées

```dart
// Pattern d'animation utilisé:
Widget.animate()
  .fadeIn(duration: Duration(milliseconds: 300))  // Apparition
  .slideX(begin: -20, end: 0)                     // Glissement horizontal
  .slideY(begin: 20, end: 0)                      // Glissement vertical
  .scale()                                         // Zoom
```

Appliqué à:
- ✅ Splash screen
- ✅ Login/Register/Forgot password
- ✅ Drawer menu
- ⏳ À ajouter: Home, Camera, Chat, Profile

## 🚀 Prochains Déploiements

### Phase 1 (Immédiat)
- Configuration Gemini
- Build APK release
- Tests sur devices

### Phase 2 (Cette semaine)
- Intégration complète Chat
- Animations toutes pages
- Tests utilisateur

### Phase 3 (Cette semaine+)
- Google Play Store publication
- Analytics & monitoring
- Feature updates

---

**Status**: 80% complet - Prêt pour phase de test
**Dernière mise à jour**: 21 Janvier 2026
**Version**: 1.0.0 Alpha

