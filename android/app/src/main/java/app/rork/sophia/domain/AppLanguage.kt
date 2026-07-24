package app.rork.sophia.domain

enum class AppLanguage(val code: String, val displayName: String, val flag: String) {
    FRENCH("fr", "Français", "🇫🇷"),
    ENGLISH("en", "English", "🇬🇧"),
    SPANISH("es", "Español", "🇪🇸"),
    GERMAN("de", "Deutsch", "🇩🇪"),
    PORTUGUESE("pt", "Português", "🇵🇹"),
    ITALIAN("it", "Italiano", "🇮🇹");

    companion object {
        val DEFAULT = ENGLISH
        const val PREFS_KEY = "sophia_app_language"

        fun fromCode(code: String?): AppLanguage =
            entries.firstOrNull { it.code == code } ?: DEFAULT
    }
}
