plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.ivfmate.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // 프로덕션용 Application ID
        applicationId = "com.ivfmate.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // release 서명 설정 (keystore 파일 필요)
    signingConfigs {
        create("release") {
            // key.properties 파일에서 읽어오도록 설정 필요
            // storeFile = file("upload-keystore.jks")
            // storePassword = "YOUR_STORE_PASSWORD"
            // keyAlias = "upload"
            // keyPassword = "YOUR_KEY_PASSWORD"
        }
    }

    buildTypes {
        release {
            // TODO: release 서명 설정 후 아래 줄의 주석을 해제하세요
            // signingConfig = signingConfigs.getByName("release")
            signingConfig = signingConfigs.getByName("debug") // 임시: 테스트용
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
