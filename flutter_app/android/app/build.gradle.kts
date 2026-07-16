import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release-Signatur: liegt eine android/key.properties (mit Keystore) vor, wird
// damit signiert – sonst fällt der Release-Build auf die Debug-Signatur zurück,
// damit der schnelle „android-latest"-APK-Build ohne Keystore weiter funktioniert.
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
val hasReleaseKeystore = keystorePropertiesFile.exists()
if (hasReleaseKeystore) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.kvmtrainer.kvm_trainer"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // Eindeutige Application ID. VOR der ersten Play-Veröffentlichung final
        // festlegen – sie lässt sich danach nicht mehr ändern. Siehe RELEASE.md.
        applicationId = "com.kvmtrainer.kvm_trainer"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        // Fester Debug-Keystore -> stabiler SHA-1 (nötig, damit Google-Login auf
        // der Sideload-APK zuverlässig funktioniert). Ein Debug-Keystore ist kein
        // Geheimnis (Standard-Passwort „android") und darf im Repo liegen.
        getByName("debug") {
            storeFile = file("kvm-debug.keystore")
            storePassword = "android"
            keyAlias = "androiddebugkey"
            keyPassword = "android"
        }
        if (hasReleaseKeystore) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = (keystoreProperties["storeFile"] as String?)?.let { file(it) }
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // Mit echtem Upload-Keystore (Play), sonst Debug-signiert (Sideload/Test).
            signingConfig = if (hasReleaseKeystore)
                signingConfigs.getByName("release")
            else
                signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
