#!/usr/bin/env bash
# Construit l'APK release de GREEN, signé avec la clé EXISTANTE.
# Ce script ne crée JAMAIS de nouvelle clé : une autre clé empêcherait la mise
# à jour de l'application déjà installée sur les téléphones.
set -euo pipefail
cd "$(dirname "$0")"

FLUTTER="${FLUTTER:-flutter}"
command -v "$FLUTTER" >/dev/null || { echo "Flutter introuvable (variable FLUTTER ou PATH)."; exit 1; }

[ -f android/keystore/green_app.jks ] || { echo "Clé absente : android/keystore/green_app.jks (ne pas la régénérer, la restaurer)."; exit 1; }
[ -f android/key.properties ] || { echo "android/key.properties absent : copiez android/key.properties.example et complétez-le."; exit 1; }
[ -f assets/.env ] || { echo "assets/.env absent : copiez .env.example en assets/.env et renseignez les clés."; exit 1; }
for k in GEMINI_API_KEY OPENWEATHER_API_KEY GREEN_WEB_PASSWORD; do
  grep -Eq "^$k=.+" assets/.env || echo "ATTENTION : $k vide dans assets/.env (fonction correspondante inactive dans l'APK)."
done
[ -f assets/models/tflite/plant_classifier_float16.tflite ] || { echo "Modèle absent : assets/models/tflite/plant_classifier_float16.tflite"; exit 1; }

echo "Empreinte SHA-256 attendue de la clé : 27:27:BB:98:60:54:7D:26:ED:57:F8:E4:49:73:E7:D2:67:26:5B:C5:E7:4B:FE:AC:92:61:E2:1D:DD:FC:48:DA"

"$FLUTTER" pub get
"$FLUTTER" analyze
"$FLUTTER" test
"$FLUTTER" build apk --release --split-per-abi --obfuscate --split-debug-info=build/symbols

echo
echo "APK générés :"
ls -lh build/app/outputs/flutter-apk/*-release.apk
echo "Vérifier la signature : apksigner verify --print-certs build/app/outputs/flutter-apk/app-arm64-v8a-release.apk"
