plugins {
    // API 36 needs AGP 8.9.1+; 8.13.x is the last 8.x line and requires Gradle 8.13+
    // (AGP 8.x is broken by Gradle 9.6+, so the wrapper stays on 8.x).
    id("com.android.application") version "8.13.2" apply false
    id("org.jetbrains.kotlin.android") version "2.1.0" apply false
    id("org.jetbrains.kotlin.plugin.compose") version "2.1.0" apply false
    id("org.jetbrains.kotlin.plugin.serialization") version "2.1.0" apply false
}
