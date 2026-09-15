plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.fluttter_web_skripsi"
    compileSdk = flutter.compileSdkVersion
    // Dinaikkan dari `flutter.ndkVersion` (26.3.11579264) atas instruksi
    // langsung `flutter build apk`: app_links, package_info_plus,
    // path_provider_android, shared_preferences_android, dan
    // url_launcher_android semuanya minta 27.0.12077973. Versi NDK bersifat
    // backward compatible, jadi dipakai yang tertinggi.
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // Identitas permanen aplikasi di perangkat dan di Play Store.
        // `namespace` di atas sengaja dibiarkan `com.example.*` supaya
        // MainActivity.kt tidak perlu dipindahkan; keduanya boleh berbeda.
        applicationId = "com.klinik.emr_psikiatri"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
