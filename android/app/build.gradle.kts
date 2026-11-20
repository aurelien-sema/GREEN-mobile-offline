import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// ---------------------------------------------------------------------------
// Signature release
// La clé ne change PAS : même fichier android/keystore/green_app.jks, même
// alias. Seuls les mots de passe quittent ce fichier (ils étaient écrits en
// clair et versionnés) pour android/key.properties, ignoré par git.
// Modèle : android/key.properties.example.
// ---------------------------------------------------------------------------
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val hasReleaseKey = keystorePropertiesFile.exists()
if (hasReleaseKey) {
    keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
}

android {
    namespace = "com.green.green"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    signingConfigs {
        if (hasReleaseKey) {
            create("release") {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = rootProject.file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    defaultConfig {
        applicationId = "com.green.green"
        // API 24 = minimum de Flutter 3.47 ; record et flutter_secure_storage
        // l'acceptent aussi.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // 2.2.0 (classifier_v1) : le modèle .tflite est stocké non compressé
    // dans l'APK, pour pouvoir être mappé en mémoire.
    androidResources {
        noCompress += "tflite"
    }

    buildTypes {
        release {
            // Sans key.properties, la configuration reste valide (flutter run,
            // build debug) ; c'est la tâche release qui échoue, plus bas.
            signingConfig = if (hasReleaseKey) signingConfigs.getByName("release") else null
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
        debug {
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    lint {
        checkReleaseBuilds = false
    }
}

flutter {
    source = "../.."
}

// Échec explicite au moment d'assembler un APK/AAB release sans la clé, plutôt
// qu'un fichier non signé (ou signé en debug) incapable de mettre à jour
// l'application déjà installée chez les utilisateurs.
tasks.configureEach {
    if (!hasReleaseKey && (name == "assembleRelease" || name == "bundleRelease")) {
        doFirst {
            throw GradleException(
                "android/key.properties introuvable : signature release impossible. " +
                    "Copiez android/key.properties.example en android/key.properties " +
                    "et renseignez les mots de passe de android/keystore/green_app.jks."
            )
        }
    }
}
