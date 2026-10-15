import java.util.Properties

plugins {
    id("com.android.application")
    // El plugin de Flutter se aplica despues de los plugins de Android y Kotlin.
    id("dev.flutter.flutter-gradle-plugin")
}

// Firma de release: android/key.properties (ignorado por Git) apunta al keystore de subida.
// Sin ese archivo, release se firma con la llave de debug (solo pruebas locales).
// NOTE (02-02): firma de subida para Google Play (prueba cerrada desde el 09-Nov-2026).
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
}

android {
    // applicationId definitivo confirmado por el equipo (01-01): no cambia despues de publicar.
    namespace = "com.musubi.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.musubi.app"
        minSdk = flutter.minSdkVersion
        // Flutter 3.47.7 fija targetSdk = 36 (requisito de Google Play para apps nuevas desde el 31-Ago-2026).
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (keystorePropertiesFile.exists()) {
            create("release") {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig =
                if (keystorePropertiesFile.exists()) {
                    signingConfigs.getByName("release")
                } else {
                    signingConfigs.getByName("debug")
                }
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
