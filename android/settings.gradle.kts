pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        // Google Maven is unreachable from this network (404). Myket mirrors it.
        maven { url = uri("https://maven.myket.ir") }
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "9.1.0" apply false
    id("org.jetbrains.kotlin.android") version "2.4.0" apply false
}

include(":app")

// Flutter plugins resolve their own AGP from a buildscript classpath that only
// lists Google Maven. That host 404s on this network, so the lookup fails
// before the Android plugin is applied. Register the mirror before those
// buildscripts run.
gradle.projectsLoaded {
    rootProject.allprojects {
        buildscript.repositories {
            maven { url = uri("https://maven.myket.ir") }
        }
    }
}
