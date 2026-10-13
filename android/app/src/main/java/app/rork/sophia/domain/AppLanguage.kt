package app.rork.sophia.domain

import java.util.Locale

enum class AppLanguage(val code: String, val displayName: String, val flag: String) {
    FRENCH("fr", "Français", "🇫🇷"),
    ENGLISH("en", "English", "🇬🇧"),
    SPANISH("es", "Español", "🇪🇸"),
    GERMAN("de", "Deutsch", "🇩🇪"),
    /** Brazilian Portuguese. A bare `pt` is Brazilian, as it is for Apple and Google. */
    PORTUGUESE("pt", "Português (Brasil)", "🇧🇷"),
    PORTUGUESE_PORTUGAL("pt-PT", "Português (Portugal)", "🇵🇹"),
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

        /**
         * Set once a stored `pt` has been read under its current meaning. Until the Brazilian
         * and European editions were split, `pt` was the only Portuguese and readers in
         * Portugal chose it too; on the first launch after the split, a stored `pt` on a phone
         * that asks for European Portuguese becomes `pt-PT`. After that it is never revisited.
         */
        const val PORTUGUESE_SPLIT_KEY = "sophia_pt_variant_resolved"

        /** Regions whose Portuguese follows the European norm: CLDR's `pt_*` other than Brazil. */
        private val EUROPEAN_PORTUGUESE_REGIONS =
            setOf("PT", "AO", "MZ", "CV", "GW", "ST", "TL", "MO", "GQ", "LU", "CH")

        fun fromCode(code: String?): AppLanguage =
            entries.firstOrNull { it.code.equals(code, ignoreCase = true) } ?: DEFAULT

        /** The app language for one device locale, or null when Sophia does not speak it. */
        fun match(locale: Locale): AppLanguage? {
            val primary = locale.language.lowercase(Locale.ROOT)
            if (primary == "pt") {
                val region = locale.country.uppercase(Locale.ROOT)
                return if (region in EUROPEAN_PORTUGUESE_REGIONS) PORTUGUESE_PORTUGAL else PORTUGUESE
            }
            val normalized = DEVICE_ALIASES[primary] ?: primary
            return entries.firstOrNull { it.code == normalized }
        }

        private fun deviceLocales(): List<Locale> = try {
            val configLocales = android.content.res.Resources.getSystem().configuration.locales
            (0 until configLocales.size()).map { configLocales[it] }
        } catch (_: Exception) {
            listOf(Locale.getDefault())
        }

        /** Match device preferred languages to a supported app language. */
        fun preferredFromDevice(): AppLanguage =
            deviceLocales().firstNotNullOfOrNull { match(it) } ?: DEFAULT

        /**
         * Whether the phone asks for European Portuguese: the first Portuguese in its language
         * list is a European one or, with no Portuguese listed, the phone sits in a
         * European-norm region.
         */
        fun deviceWantsEuropeanPortuguese(): Boolean {
            val locales = deviceLocales()
            for (locale in locales) {
                when (match(locale)) {
                    PORTUGUESE_PORTUGAL -> return true
                    PORTUGUESE -> return false
                    else -> Unit
                }
            }
            val region = locales.firstOrNull()?.country ?: Locale.getDefault().country
            return region.uppercase(Locale.ROOT) in EUROPEAN_PORTUGUESE_REGIONS
        }
    }
}
