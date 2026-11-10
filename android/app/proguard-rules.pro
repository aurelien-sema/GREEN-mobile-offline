# Règles R8 de l'APK release (minification + suppression des ressources).
# Les plugins Flutter fournissent leurs propres règles « consumer » ; seules
# les bibliothèques chargées par réflexion ou JNI sont protégées ici.

# Moteur Flutter
-keep class io.flutter.** { *; }
-dontwarn io.flutter.embedding.**

# ONNX Runtime : classes appelées depuis le code natif (JNI)
-keep class ai.onnxruntime.** { *; }

# TensorFlow Lite / LiteRT (tflite_flutter) : bibliothèque C chargée par
# FFI et classes du délégué GPU référencées sans être toujours présentes
# (erreur R8 connue « Missing class …GpuDelegateFactory$Options »).
-keep class org.tensorflow.lite.** { *; }
-keep class com.google.ai.edge.litert.** { *; }
-dontwarn org.tensorflow.lite.gpu.**
-dontwarn com.google.ai.edge.litert.**

# uCrop (recadrage de la photo de profil)
-keep class com.yalantis.ucrop.** { *; }
-dontwarn com.yalantis.ucrop.**

# Tink (chiffrement de flutter_secure_storage) : annotations optionnelles
-dontwarn com.google.errorprone.annotations.**
-dontwarn javax.annotation.**

# Play Core n'est pas embarqué (pas de modules dynamiques)
-dontwarn com.google.android.play.core.**

-keepattributes *Annotation*,InnerClasses,Signature
