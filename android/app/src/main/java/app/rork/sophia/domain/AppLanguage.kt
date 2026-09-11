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
    CZECH("cs", "Čeština", "🇨🇿"),
    DANISH("da", "Dansk", "🇩🇰"),
    NORWEGIAN("nb", "Norsk", "🇳🇴"),
    RUSSIAN("ru", "Русский", "🇷🇺"),
    CROATIAN("hr", "Hrvatski", "🇭🇷"),
    SLOVENIAN("sl", "Slovenščina", "🇸🇮"),
    SLOVAK("sk", "Slovenčina", "🇸🇰"),
    SERBIAN("sr", "Srpski", "🇷🇸"),
    ARABIC("ar", "العربية", "🇸🇦"),
    HEBREW("he", "עברית", "🇮🇱"),
    FINNISH("fi", "Suomi", "🇫🇮"),
    ESTONIAN("et", "Eesti", "🇪🇪");

    /**
     * Writing direction of the language. The app reads its language from its own
     * preferences rather than the device configuration, so `LocalLayoutDirection`
     * still follows the phone and would leave an Arabic or Hebrew reader with a
     * left-to-right screen. `SophiaRoot` puts this into the composition instead.
     */
    val isRtl: Boolean get() = this == ARABIC || this == HEBREW

    companion object {
        val DEFAULT = ENGLISH
        const val PREFS_KEY = "sophia_app_language"

        /**
         * Device language codes that are not our own but map onto one. Android
         * reports Norwegian as `nb`, `nn` or the `no` macrolanguage depending on
         * the device. Bosnian and Montenegrin have no table of their own, so
         * their speakers read the Croatian one. `iw` matters more here than on
         * iOS: `Locale.getLanguage()` still returns the retired code for Hebrew.
         */
        private val DEVICE_ALIASES = mapOf(
            "no" to "nb",
            "nn" to "nb",
            "bs" to "hr",
            "sh" to "hr",
            "cnr" to "hr",
            "iw" to "he",
            "arb" to "ar",
        )

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
                val normalized = DEVICE_ALIASES[primary] ?: primary
                entries.firstOrNull { it.code == normalized }?.let { return it }
            }
            return DEFAULT
        }
    }
}
