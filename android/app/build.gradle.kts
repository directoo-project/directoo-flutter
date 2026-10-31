import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

val storeProperties = Properties()
val storePropertiesFile = rootProject.file("store.properties")
if (storePropertiesFile.exists()) {
    storeProperties.load(FileInputStream(storePropertiesFile))
}

val dotenv = Properties()
val dotenvFile = rootProject.file("../.env")
if (dotenvFile.exists()) {
    dotenvFile.forEachLine { line ->
        val trimmed = line.trim()
        if (trimmed.isEmpty() || trimmed.startsWith("#")) return@forEachLine
        val separator = trimmed.indexOf('=')
        if (separator <= 0) return@forEachLine
        dotenv.setProperty(trimmed.substring(0, separator).trim(), trimmed.substring(separator + 1).trim())
    }
}

fun configured(primary: String?, fallback: String?): String? =
    primary?.trim()?.takeIf { it.isNotEmpty() } ?: fallback?.trim()?.takeIf { it.isNotEmpty() }

fun javaStringLiteral(value: String?): String {
    val escaped = (value ?: "")
        .replace("\\", "\\\\")
        .replace("\"", "\\\"")
        .replace("\r", "")
        .replace("\n", "")
    return "\"$escaped\""
}

android {
    namespace = "ir.directoo.directoo"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "ir.directoo.directoo"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            keyAlias = configured(dotenv.getProperty("KEY_ALIAS"), keystoreProperties.getProperty("keyAlias"))
            keyPassword = configured(dotenv.getProperty("KEY_PASSWORD"), keystoreProperties.getProperty("keyPassword"))
            storeFile = configured(dotenv.getProperty("STORE_FILE"), keystoreProperties.getProperty("storeFile"))?.let { file(it) }
            storePassword = configured(dotenv.getProperty("STORE_PASSWORD"), keystoreProperties.getProperty("storePassword"))
        }
    }

    buildFeatures {
        buildConfig = true
    }

    flavorDimensions += "store"
    productFlavors {
        create("bazaar") {
            dimension = "store"
            buildConfigField("String", "STORE", "\"bazaar\"")
            buildConfigField("String", "STORE_RSA_KEY", javaStringLiteral(configured(dotenv.getProperty("BAZAAR_RSA_PUBLIC_KEY"), storeProperties.getProperty("bazaarRsaKey"))))
            buildConfigField("String", "DYNAMIC_PRICE_SECRET", javaStringLiteral(dotenv.getProperty("BAZAAR_DYNAMIC_PRICE_SECRET")))
            buildConfigField("String", "WALLET_SKU", javaStringLiteral(configured(dotenv.getProperty("BAZAAR_WALLET_SKU"), "directoo_wallet")))
            // Myket's billing AAR reads these placeholders. Point them at Cafe Bazaar
            // in this flavor so the merged manifest does not request Myket billing.
            manifestPlaceholders["marketApplicationId"] = "com.farsitel.bazaar"
            manifestPlaceholders["marketBindAddress"] = "ir.cafebazaar.pardakht.InAppBillingService.BIND"
            manifestPlaceholders["marketPermission"] = "com.farsitel.bazaar.permission.PAY_THROUGH_BAZAAR"
        }
        create("myket") {
            dimension = "store"
            buildConfigField("String", "STORE", "\"myket\"")
            buildConfigField("String", "STORE_RSA_KEY", javaStringLiteral(configured(dotenv.getProperty("MYKET_RSA_PUBLIC_KEY"), storeProperties.getProperty("myketRsaKey"))))
            buildConfigField("String", "DYNAMIC_PRICE_SECRET", "\"\"")
            buildConfigField("String", "WALLET_SKU", "\"\"")
            manifestPlaceholders["marketApplicationId"] = "ir.mservices.market"
            manifestPlaceholders["marketBindAddress"] = "ir.mservices.market.InAppBillingService.BIND"
            manifestPlaceholders["marketPermission"] = "ir.mservices.market.BILLING"
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Each store output links only its own billing SDK. Both AARs ship the same
    // IInAppBillingService class, so they cannot be packaged together.
    "bazaarImplementation"("com.github.cafebazaar.Poolakey:poolakey:2.2.0")
    "myketImplementation"("ir.myket:billing:2.2")
}
