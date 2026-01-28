#!/bin/bash

# Script pour construire l'APK release de Green App

echo "========================================="
echo "Green App - APK Release Builder"
echo "========================================="
echo ""

# Vérifier si Flutter est installé
if ! command -v flutter &> /dev/null; then
    echo "Erreur: Flutter n'est pas installé ou non trouvé dans le PATH"
    exit 1
fi

echo "1. Nettoyage des fichiers de build précédents..."
flutter clean

echo ""
echo "2. Récupération des dépendances..."
flutter pub get

echo ""
echo "3. Génération des fichiers de configuration..."
flutter pub run build_runner build --delete-conflicting-outputs 2>/dev/null || true

echo ""
echo "4. Vérification de la clé de signature..."
if [ ! -f "./android/keystore/green_app.jks" ]; then
    echo "La clé de signature n'existe pas. Création..."
    bash ./generate_keystore.sh
    if [ $? -ne 0 ]; then
        echo "Erreur: Impossible de créer la clé de signature"
        exit 1
    fi
fi

echo ""
echo "5. Construction de l'APK en mode release..."
echo "(Cela peut prendre quelques minutes...)"
flutter build apk --release

if [ $? -eq 0 ]; then
    echo ""
    echo "========================================="
    echo "✓ APK généré avec succès!"
    echo "========================================="
    echo ""
    echo "Localisation du fichier APK:"
    echo "build/app/outputs/flutter-apk/app-release.apk"
    echo ""
    echo "Pour installer sur un appareil Android:"
    echo "adb install build/app/outputs/flutter-apk/app-release.apk"
else
    echo ""
    echo "========================================="
    echo "✗ Erreur lors de la génération de l'APK"
    echo "========================================="
    exit 1
fi
