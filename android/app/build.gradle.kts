//android/app/build.gradle.kts
//(app)👉 configure l'app
plugins {
    id("com.android.application")
    id("kotlin-android") 
    id("dev.flutter.flutter-gradle-plugin") //Connecte Flutter avec Android
}

android {
    namespace = "com.example.sunspace" 
    compileSdk = flutter.compileSdkVersion // version du SDK Android
    ndkVersion = flutter.ndkVersion // version du NDK

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17 //Version Android optimisée
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString() //Version Kotlin optimisée
    }

    defaultConfig {
        applicationId = "com.example.sunspace"
        minSdk = flutter.minSdkVersion //Version Android minimale
        targetSdk = flutter.targetSdkVersion //Version Android maximale
        versionCode = flutter.versionCode //version Code
        versionName = flutter.versionName //version Name
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}