import java.util.Properties

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("org.jetbrains.kotlin.plugin.compose")
    id("org.jetbrains.kotlin.plugin.serialization")
}

/**
 * Keys come from `local.properties` (git-ignored), then a Gradle property, then an
 * environment variable, and only then the checked-in default. That way a store key can be
 * set on a laptop or in CI without editing this file or committing a secret.
 */
val localProperties = Properties().apply {
    val file = rootProject.file("local.properties")
    if (file.exists()) file.inputStream().use { load(it) }
}

fun secret(name: String, default: String): String =
    localProperties.getProperty(name)
        ?: (project.findProperty(name) as String?)
        ?: System.getenv(name)
        ?: default

android {
    namespace = "app.rork.sophia"
    compileSdk = 35

    defaultConfig {
        applicationId = "app.rork.sophia"
        minSdk = 26
        targetSdk = 35
        versionCode = 1
        versionName = "1.0.0"
        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"

        // Set REVENUECAT_API_KEY / REVENUECAT_TEST_API_KEY in local.properties to enable billing.
        buildConfigField(
            "String",
            "REVENUECAT_API_KEY",
            "\"${secret("REVENUECAT_API_KEY", "goog_REPLACE_ME")}\"",
        )
        buildConfigField(
            "String",
            "REVENUECAT_TEST_API_KEY",
            "\"${secret("REVENUECAT_TEST_API_KEY", "test_REPLACE_ME")}\"",
        )
        buildConfigField(
            "String",
            "MIXPANEL_TOKEN",
            "\"${secret("MIXPANEL_TOKEN", "d2e043bfcdd8f53a7ec613d378667519")}\"",
        )
        buildConfigField(
            "String",
            "SUPABASE_URL",
            "\"${secret("SUPABASE_URL", "https://afnmcoovdvbtkgohtdij.supabase.co")}\"",
        )
        buildConfigField(
            "String",
            "SUPABASE_ANON_KEY",
            "\"${secret("SUPABASE_ANON_KEY", "sb_publishable_eNzCyPFfEuKC0tKWr0Hjag_lJ_qsWRw")}\"",
        )
        buildConfigField(
            "String",
            "GOOGLE_WEB_CLIENT_ID",
            "\"${
                secret(
                    "GOOGLE_WEB_CLIENT_ID",
                    "716867958674-b9ql8ap6fna2lu9caublcjajdh7978q2.apps.googleusercontent.com",
                )
            }\"",
        )
        buildConfigField(
            "String",
            "FORMSPREE_ENDPOINT",
            "\"${secret("FORMSPREE_ENDPOINT", "https://formspree.io/f/xwvdybwb")}\"",
        )
        buildConfigField(
            "String",
            "FORMSPREE_AMBASSADOR_ENDPOINT",
            "\"${secret("FORMSPREE_AMBASSADOR_ENDPOINT", "https://formspree.io/f/xpqvqnwb")}\"",
        )
    }

    buildTypes {
        debug {
            buildConfigField("Boolean", "USE_RC_TEST_KEY", "true")
        }
        release {
            isMinifyEnabled = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
            buildConfigField("Boolean", "USE_RC_TEST_KEY", "false")
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions {
        jvmTarget = "17"
    }
    buildFeatures {
        compose = true
        buildConfig = true
    }
    packaging {
        resources {
            excludes += "/META-INF/{AL2.0,LGPL2.1}"
        }
    }
    // Cover JPEGs stay out of the APK (OOM on Android Go). Color placeholders in UI.
    androidResources {
        ignoreAssetsPattern = "!.svn:!.git:!.ds_store:!*.scc:.*:!CVS:!thumbs.db:!picasa.ini:!*~:images"
    }
}

dependencies {
    val composeBom = platform("androidx.compose:compose-bom:2024.12.01")
    implementation(composeBom)
    androidTestImplementation(composeBom)

    implementation("androidx.core:core-ktx:1.15.0")
    implementation("androidx.appcompat:appcompat:1.7.0")
    implementation("androidx.activity:activity-compose:1.9.3")
    implementation("androidx.lifecycle:lifecycle-runtime-ktx:2.8.7")
    implementation("androidx.lifecycle:lifecycle-viewmodel-compose:2.8.7")
    implementation("androidx.lifecycle:lifecycle-runtime-compose:2.8.7")
    implementation("androidx.navigation:navigation-compose:2.8.5")
    implementation("androidx.compose.ui:ui")
    implementation("androidx.compose.ui:ui-tooling-preview")
    implementation("androidx.compose.foundation:foundation")
    implementation("androidx.compose.material3:material3")
    implementation("androidx.compose.material:material-icons-extended")
    implementation("androidx.datastore:datastore-preferences:1.1.1")

    implementation("org.jetbrains.kotlinx:kotlinx-serialization-json:1.7.3")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.9.0")

    // RevenueCat
    implementation("com.revenuecat.purchases:purchases:9.26.1")

    // Supabase
    implementation(platform("io.github.jan-tennert.supabase:bom:3.1.1"))
    implementation("io.github.jan-tennert.supabase:auth-kt")
    implementation("io.github.jan-tennert.supabase:postgrest-kt")
    implementation("io.ktor:ktor-client-okhttp:3.0.3")

    // Mixpanel
    implementation("com.mixpanel.android:mixpanel-android:7.5.4")

    // Google Sign-In (Credential Manager)
    implementation("androidx.credentials:credentials:1.3.0")
    implementation("androidx.credentials:credentials-play-services-auth:1.3.0")
    implementation("com.google.android.libraries.identity.googleid:googleid:1.1.1")

    // Remote covers (Supabase Storage) — one image at a time, disk-cached
    implementation("io.coil-kt:coil-compose:2.7.0")

    // Play In-App Review
    implementation("com.google.android.play:review:2.0.2")
    implementation("com.google.android.play:review-ktx:2.0.2")

    debugImplementation("androidx.compose.ui:ui-tooling")
    debugImplementation("androidx.compose.ui:ui-test-manifest")
    testImplementation("junit:junit:4.13.2")
}
