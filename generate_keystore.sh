#!/bin/bash

# Script pour générer une clé de signature pour l'application Green App

KEYSTORE_DIR="./android/keystore"
KEYSTORE_FILE="$KEYSTORE_DIR/green_app.jks"

# Créer le répertoire keystore s'il n'existe pas
mkdir -p "$KEYSTORE_DIR"

# Générer la clé si elle n'existe pas
if [ ! -f "$KEYSTORE_FILE" ]; then
    echo "Génération de la clé de signature..."
    
    keytool -genkey -v \
        -keystore "$KEYSTORE_FILE" \
        -keyalias green_app_key \
        -keyalg RSA \
        -keysize 4096 \
        -validity 10000 \
        -storepass Green@App2025 \
        -keypass Green@App2025 \
        -dname "CN=Green App Developer, OU=Green App, O=Green App, L=France, C=FR"
    
    echo "Clé de signature créée avec succès!"
else
    echo "La clé de signature existe déjà à: $KEYSTORE_FILE"
fi

# Afficher les informations du keystore
echo ""
echo "Informations du keystore:"
keytool -list -v -keystore "$KEYSTORE_FILE" -storepass Green@App2025

echo ""
echo "Pour générer l'APK en release, exécutez:"
echo "flutter build apk --release"
