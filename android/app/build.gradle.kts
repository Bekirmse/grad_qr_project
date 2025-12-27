plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.grad_qr_project"
    
    // UYARI DÜZELTMESİ: mobile_scanner için 36 yapıldı
    compileSdk = 36 
    
    // UYARI DÜZELTMESİ: Firebase ve scanner paketleri için NDK güncellendi
    ndkVersion = "27.0.12077973" 

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.grad_qr_project"
        
        // ÖNCEKİ DÜZELTME: mobile_scanner paketi için en az 23 olmalı
        minSdk = 23

        // YAZIM HATASI DÜZELTMESİ: targetSdkVersion olarak güncellendi
        targetSdk = flutter.targetSdkVersion
        
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}