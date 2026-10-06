import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Credentials live outside the repository and are provided only to release builds.
val uploadSigning = Properties()
val uploadSigningPath = System.getenv("TAP_ANDROID_SIGNING_PROPERTIES")
if (!uploadSigningPath.isNullOrBlank()) {
    file(uploadSigningPath).inputStream().use { uploadSigning.load(it) }
}

android {
    namespace = "com.tab2work.tab2work"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.tab2work.tab2work"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (!uploadSigningPath.isNullOrBlank()) {
            create("upload") {
                storeFile = file(requireNotNull(uploadSigning.getProperty("storeFile")))
                storePassword = requireNotNull(uploadSigning.getProperty("storePassword"))
                keyAlias = requireNotNull(uploadSigning.getProperty("keyAlias"))
                keyPassword = requireNotNull(uploadSigning.getProperty("keyPassword"))
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.findByName("upload")
        }
    }

}

flutter {
    source = "../.."
}
