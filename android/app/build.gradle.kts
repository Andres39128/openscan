plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.openscan.app"
    // 37: permission_handler_android lo exige (AGP lo tolera). minSdk sigue 26.
    compileSdk = 37
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.openscan.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 26 // PLAN §5: Play Services reciente para Doc Scanner
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    flavorDimensions += "env"

    productFlavors {
        create("dev") {
            dimension = "env"
            applicationIdSuffix = ".dev"
            versionNameSuffix = "-dev"
        }
        create("stg") {
            dimension = "env"
            applicationIdSuffix = ".stg"
            versionNameSuffix = "-stg"
        }
        create("prod") {
            dimension = "env"
        }
        create("oss") {
            dimension = "env"
            // Mismo ID que prod: F-Droid firma su propio build.
        }
    }

    sourceSets {
        // GMS solo en dev/stg/prod; oss compila su MainActivity sin GMS.
        getByName("dev") { java.srcDirs("src/gms/kotlin") }
        getByName("stg") { java.srcDirs("src/gms/kotlin") }
        getByName("prod") { java.srcDirs("src/gms/kotlin") }
        getByName("oss") { java.srcDirs("src/oss/kotlin") }
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

dependencies {
    // GMS solo en dev/stg/prod (oss es F-Droid sin Play Services).
    // ML Kit Document Scanner (PLAN §2, ADR-001). Solo JPEG (ADR-005).
    add("devImplementation", "com.google.android.gms:play-services-mlkit-document-scanner:16.0.0")
    add("stgImplementation", "com.google.android.gms:play-services-mlkit-document-scanner:16.0.0")
    add("prodImplementation", "com.google.android.gms:play-services-mlkit-document-scanner:16.0.0")
    // OCR latino on-device, modelo bundled (ADR-002).
    add("devImplementation", "com.google.android.gms:play-services-mlkit-text-recognition:19.0.1")
    add("stgImplementation", "com.google.android.gms:play-services-mlkit-text-recognition:19.0.1")
    add("prodImplementation", "com.google.android.gms:play-services-mlkit-text-recognition:19.0.1")
}

flutter {
    source = "../.."
}
