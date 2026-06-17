import java.util.Properties
import java.io.FileInputStream
import org.jetbrains.kotlin.gradle.dsl.JvmTarget

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

val localProperties = Properties()
val localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    localProperties.load(FileInputStream(localPropertiesFile))
}

val googleServicesFile = project.file("google-services.json")
val enableFcm =
    providers.gradleProperty("ENABLE_FCM")
        .orElse(localProperties.getProperty("ENABLE_FCM") ?: "")
        .orElse(providers.environmentVariable("ENABLE_FCM"))
        .map { value -> value.equals("true", ignoreCase = true) }
        .orElse(googleServicesFile.exists())
        .get()

val jpushAppKey = providers.gradleProperty("JPUSH_APPKEY")
    .orElse(localProperties.getProperty("JPUSH_APPKEY") ?: "")
    .orElse(providers.environmentVariable("JPUSH_APPKEY"))
    .orElse("")
val jpushChannel = providers.gradleProperty("JPUSH_CHANNEL")
    .orElse(localProperties.getProperty("JPUSH_CHANNEL") ?: "")
    .orElse(providers.environmentVariable("JPUSH_CHANNEL"))
    .orElse("developer-default")
val androidApplicationId = "com.luckyfish.lumalis"

android {
    namespace = androidApplicationId
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties.getProperty("keyAlias")
            keyPassword = keystoreProperties.getProperty("keyPassword")
            storeFile = keystoreProperties.getProperty("storeFile")?.let { rootProject.file(it) }
            storePassword = keystoreProperties.getProperty("storePassword")
        }
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = androidApplicationId
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["JPUSH_PKGNAME"] = androidApplicationId
        manifestPlaceholders["JPUSH_APPKEY"] = jpushAppKey.get()
        manifestPlaceholders["JPUSH_CHANNEL"] = jpushChannel.get()
        manifestPlaceholders["FCM_NOTIFICATION_ICON"] = "@drawable/ic_stat_marketours_notification"
    }

    buildTypes {
        getByName("release") {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

if (!enableFcm) {
    logger.lifecycle(
        "FCM channel is disabled for ${project.path}. Add android/app/google-services.json or set ENABLE_FCM=true to enable it.",
    )
}

kotlin {
    compilerOptions {
        jvmTarget.set(JvmTarget.JVM_17)
    }
}

flutter {
    source = "../.."
}

if (enableFcm) {
    apply(plugin = "com.google.gms.google-services")
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    if (enableFcm) {
        implementation("cn.jiguang.sdk.plugin:fcm:4.8.6")
        implementation("com.google.firebase:firebase-messaging:24.1.2")
    }
}
