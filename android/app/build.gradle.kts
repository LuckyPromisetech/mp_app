plugins {
    id("com.android.application")
    id("kotlin-android")
    id("com.google.gms.google-services")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.mp_app"
    compileSdk = 36 // or flutter.compileSdkVersion

    ndkVersion = "29.0.13846066"

    defaultConfig {
        applicationId = "com.example.mp_app"
        minSdk = flutter.minSdkVersion
        targetSdk = 36 // or flutter.targetSdkVersion
        versionCode = 1
        versionName = "1.0"
    }

buildFeatures {
    prefab = false
}

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    buildTypes {
        release {
            // Disable code shrinking and resource shrinking
            isMinifyEnabled = false
            isShrinkResources = false
            signingConfig = signingConfigs.getByName("debug") // for testing release
        }
    }

    // ❌ Remove ndkVersion entirely
}

flutter {
    source = "../.."
}