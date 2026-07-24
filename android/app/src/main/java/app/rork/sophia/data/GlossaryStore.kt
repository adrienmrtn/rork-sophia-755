package app.rork.sophia.data

import android.content.Context
import app.rork.sophia.domain.AppLanguage
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json
import java.util.concurrent.ConcurrentHashMap

@Serializable
data class GlossaryEntry(
    val displayTerm: String,
    val classification: String = "",
    val explanation: String = "",
)

object GlossaryStore {
    private val json = Json { ignoreUnknownKeys = true; isLenient = true }
    private val cache = ConcurrentHashMap<String, Map<String, GlossaryEntry>>()

    fun entry(
        context: Context,
        language: AppLanguage,
        courseId: String,
        courseTitle: String,
        displayTerm: String,
    ): GlossaryEntry? {
        val table = table(context, language)
        val primaryKey = if (language == AppLanguage.FRENCH) {
            "$courseTitle|$displayTerm"
        } else {
            "$courseId|$displayTerm"
        }
        table[primaryKey]?.let { return it }

        val needle = normalize(displayTerm)
        if (needle.length < 4) return null
        val prefix = if (language == AppLanguage.FRENCH) "$courseTitle|" else "$courseId|"
        for ((key, entry) in table) {
            if (!key.startsWith(prefix)) continue
            val termPart = key.substringAfter('|')
            val norm = normalize(termPart)
            if (norm == needle) return entry
            if (needle.length >= 4 && norm.length >= 8) {
                val longer = maxOf(needle.length, norm.length).toDouble()
                val shorter = minOf(needle.length, norm.length).toDouble()
                if (shorter / longer >= 0.45 && (norm.contains(needle) || needle.contains(norm))) {
                    return entry
                }
            }
        }
        return null
    }

    private fun table(context: Context, language: AppLanguage): Map<String, GlossaryEntry> {
        return cache.getOrPut(language.code) {
            try {
                val path = "locales/glossary.${language.code}.json"
                val text = context.assets.open(path).bufferedReader().use { it.readText() }
                json.decodeFromString<Map<String, GlossaryEntry>>(text)
            } catch (_: Exception) {
                emptyMap()
            }
        }
    }

    private fun normalize(s: String): String =
        s.lowercase().replace(Regex("[^a-z0-9àâäéèêëïîôùûüç]+"), "")
}
