package app.rork.sophia.domain

import java.util.Locale

enum class AppLanguage(val code: String, val displayName: String, val flag: String) {
    FRENCH("fr", "Français", "🇫🇷"),
    ENGLISH("en", "English", "🇬🇧"),
    SPANISH("es", "Español", "🇪🇸"),
    GERMAN("de", "Deutsch", "🇩🇪"),
    PORTUGUESE("pt", "Português", "🇵🇹"),
    ITALIAN("it", "Italiano", "🇮🇹"),
    TURKISH("tr", "Türkçe", "🇹🇷"),
    POLISH("pl", "Polski", "🇵🇱"),
    ROMANIAN("ro", "Română", "🇷🇴"),
    DUTCH("nl", "Nederlands", "🇳🇱"),
    GREEK("el", "Ελληνικά", "🇬🇷"),
    SWEDISH("sv", "Svenska", "🇸🇪"),
    HUNGARIAN("hu", "Magyar", "🇭🇺"),
    BULGARIAN("bg", "Български", "🇧🇬"),
    CZECH("cs", "Čeština", "🇨🇿");

    companion object {
        val DEFAULT = ENGLISH
        const val PREFS_KEY = "sophia_app_language"

        fun fromCode(code: String?): AppLanguage =
            entries.firstOrNull { it.code.equals(code, ignoreCase = true) } ?: DEFAULT

        /** Match device preferred languages to a supported app language. */
        fun preferredFromDevice(): AppLanguage {
            val locales = try {
                val configLocales = android.content.res.Resources.getSystem().configuration.locales
                (0 until configLocales.size()).map { configLocales[it] }
            } catch (_: Exception) {
                listOf(Locale.getDefault())
            }
            for (locale in locales) {
                val primary = locale.language.lowercase(Locale.ROOT)
                entries.firstOrNull { it.code == primary }?.let { return it }
                // Portuguese / Chinese-style region fallbacks if needed later.
                if (primary == "nb" || primary == "nn") {
                    // no Norwegian pack — skip
                }
            }
            return DEFAULT
        }
    }
}
