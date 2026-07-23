#!/bin/bash

# Script pour générer une clé de signature pour l'application Green App

KEYSTORE_DIR="./android/keystore"
KEYSTORE_FILE="$KEYSTORE_DIR/green_app.jks"

# Les mots de passe NE DOIVENT PAS être codés en dur dans ce fichier versionné.
# Fournissez-les via des variables d'environnement avant de lancer le script :
#   export GREEN_KEYSTORE_PASSWORD='...'
#   export GREEN_KEY_PASSWORD='...'   # optionnel, défaut = GREEN_KEYSTORE_PASSWORD
# Reportez ensuite ces mêmes valeurs dans android/key.properties (ignoré par git).
if [ -z "$GREEN_KEYSTORE_PASSWORD" ]; then
    echo "Erreur: la variable d'environnement GREEN_KEYSTORE_PASSWORD n'est pas définie."
    echo "       export GREEN_KEYSTORE_PASSWORD='votre_mot_de_passe' puis relancez."
    exit 1
fi
GREEN_KEY_PASSWORD="${GREEN_KEY_PASSWORD:-$GREEN_KEYSTORE_PASSWORD}"

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
        -storepass "$GREEN_KEYSTORE_PASSWORD" \
        -keypass "$GREEN_KEY_PASSWORD" \
        -dname "CN=Green App Developer, OU=Green App, O=Green App, L=France, C=FR"
    
    echo "Clé de signature créée avec succès!"
else
    echo "La clé de signature existe déjà à: $KEYSTORE_FILE"
fi

# Afficher les informations du keystore
echo ""
echo "Informations du keystore:"
keytool -list -v -keystore "$KEYSTORE_FILE" -storepass "$GREEN_KEYSTORE_PASSWORD"

echo ""
echo "Pour générer l'APK en release, exécutez:"
echo "flutter build apk --release"
