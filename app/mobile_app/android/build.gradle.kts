buildscript {
    val localProperties = java.util.Properties()
    val localPropertiesFile = file("local.properties")
    if (localPropertiesFile.exists()) {
        localPropertiesFile.inputStream().use { localProperties.load(it) }
    }

    val enableFcmProperty = findProperty("ENABLE_FCM") as String?
    val enableFcmLocal = localProperties.getProperty("ENABLE_FCM")
    val enableFcmEnv = System.getenv("ENABLE_FCM")
    val enableFcm =
        when {
            !enableFcmProperty.isNullOrBlank() -> enableFcmProperty.equals("true", ignoreCase = true)
            !enableFcmLocal.isNullOrBlank() -> enableFcmLocal.equals("true", ignoreCase = true)
            !enableFcmEnv.isNullOrBlank() -> enableFcmEnv.equals("true", ignoreCase = true)
            else -> file("app/google-services.json").exists()
        }

    repositories {
        google()
        mavenCentral()
    }
    if (enableFcm) {
        dependencies {
            classpath("com.google.gms:google-services:4.4.2")
        }
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
