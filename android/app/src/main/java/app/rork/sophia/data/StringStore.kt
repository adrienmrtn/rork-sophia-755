package app.rork.sophia.data

import android.content.Context
import android.icu.text.PluralRules
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.domain.locale
import kotlinx.serialization.json.Json
import java.util.concurrent.ConcurrentHashMap

object StringStore {
    private val json = Json { ignoreUnknownKeys = true }
    private val cache = ConcurrentHashMap<String, Map<String, String>>()
    private val pluralRules = ConcurrentHashMap<String, PluralRules>()

    /**
     * Looks up [key] in the user's language, falling back to English, and formats it.
     *
     * When the table carries plural variants for the key — `key.one`, `key.few`, `key.many`,
     * … — and the first argument is a whole number, the variant for that number is used
     * instead. That is what turns "1 courses completed" into "1 course completed", and what
     * gives Russian, Polish and Czech the three or four forms their grammar needs rather
     * than the one that happened to be written. Keys without variants are unaffected.
     */
    fun text(context: Context, key: String, language: AppLanguage, vararg formatArgs: Any): String {
        val primary = table(context, language.code)
        val english = table(context, AppLanguage.ENGLISH.code)
        val resolvedKey = pluralKey(key, language, primary, english, formatArgs)
        val template = primary[resolvedKey] ?: english[resolvedKey] ?: primary[key] ?: english[key] ?: key
        return if (formatArgs.isEmpty()) template else {
            try {
                val javaTemplate = template.replace("%@", "%s")
                // Formatted in the app's own locale: on an Arabic phone the default locale
                // rendered every count in Arabic-Indic digits, including for a French reader.
                String.format(language.locale, javaTemplate, *formatArgs)
            } catch (_: Exception) {
                template
            }
        }
    }

    /**
     * The variant key for a count, or [key] itself when the table has no plural forms for it.
     * Checked against the user's table first and English second, so a key that is pluralized
     * in only one of them still resolves.
     */
    private fun pluralKey(
        key: String,
        language: AppLanguage,
        primary: Map<String, String>,
        english: Map<String, String>,
        args: Array<out Any>,
    ): String {
        val count = args.firstOrNull() as? Int ?: return key
        if ("$key.other" !in primary && "$key.other" !in english) return key
        val category = runCatching {
            pluralRules.getOrPut(language.code) { PluralRules.forLocale(language.locale) }
                .select(count.toDouble())
        }.getOrDefault(PluralRules.KEYWORD_OTHER)
        val candidate = "$key.$category"
        return when {
            candidate in primary -> candidate
            "$key.other" in primary -> "$key.other"
            candidate in english -> candidate
            else -> "$key.other"
        }
    }

    fun preload(context: Context, language: AppLanguage) {
        table(context, language.code)
        table(context, AppLanguage.ENGLISH.code)
    }

    private fun table(context: Context, code: String): Map<String, String> {
        return cache.getOrPut(code) {
            try {
                val text = context.assets.open("strings/$code.json").bufferedReader().use { it.readText() }
                json.decodeFromString<Map<String, String>>(text)
            } catch (_: Exception) {
                emptyMap()
            }
        }
    }

    fun clearCache() {
        cache.clear()
        pluralRules.clear()
    }
}
