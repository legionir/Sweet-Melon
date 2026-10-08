plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.sweet_melon"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // Placeholder Application ID from the Flutter template. Replace it with
        // your own unique ID before publishing (see README, "Before release").
        applicationId = "com.example.sweet_melon"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Release signing is read from environment variables (CI secrets or a
    // local shell). The debug key is never used for release builds (SEC-006).
    // Without a release keystore the release APK is left unsigned.
    val releaseKeystorePath: String? = System.getenv("SWEETMELON_KEYSTORE_PATH")
    signingConfigs {
        if (releaseKeystorePath != null) {
            create("release") {
                storeFile = file(releaseKeystorePath)
                storePassword = System.getenv("SWEETMELON_KEYSTORE_PASSWORD")
                keyAlias = System.getenv("SWEETMELON_KEY_ALIAS")
                keyPassword = System.getenv("SWEETMELON_KEY_PASSWORD")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (releaseKeystorePath != null) {
                signingConfigs.getByName("release")
            } else {
                null
            }
        }
    }
}

flutter {
    source = "../.."
}
