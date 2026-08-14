package app.rork.sophia.data

import android.content.Context
import app.rork.sophia.domain.AppLanguage
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json
import java.util.concurrent.ConcurrentHashMap

@Serializable
data class GlossaryEntry(
    val displayTerm: String,
    val classification: String = "",
    val explanation: String = "",
)

private class GlossaryTable(
    val exact: Map<String, GlossaryEntry>,
    val normalized: Map<String, GlossaryEntry>,
)

object GlossaryStore {
    private val json = Json { ignoreUnknownKeys = true; isLenient = true }
    private val cache = ConcurrentHashMap<String, GlossaryTable>()

    /** Warm glossary JSON (~0.8MB) off the main thread before first lesson render. */
    suspend fun preload(context: Context, language: AppLanguage) {
        withContext(Dispatchers.IO) { table(context, language) }
    }

    fun entry(
        context: Context,
        language: AppLanguage,
        courseId: String,
        courseTitle: String,
        displayTerm: String,
    ): GlossaryEntry? {
        val table = cache[language.code] ?: return null
        val prefix = if (language == AppLanguage.FRENCH) courseTitle else courseId
        val primaryKey = "$prefix|$displayTerm"
        table.exact[primaryKey]?.let { return it }
        val needle = normalize(displayTerm)
        if (needle.isEmpty()) return null
        return table.normalized["$prefix|$needle"]
    }

    private fun table(context: Context, language: AppLanguage): GlossaryTable {
        return cache.getOrPut(language.code) {
            try {
                val path = "locales/glossary.${language.code}.json"
                val text = context.assets.open(path).bufferedReader().use { it.readText() }
                val exact = json.decodeFromString<Map<String, GlossaryEntry>>(text)
                val normalized = HashMap<String, GlossaryEntry>(exact.size)
                for ((key, entry) in exact) {
                    val bar = key.indexOf('|')
                    if (bar < 0) continue
                    val prefix = key.substring(0, bar)
                    val term = key.substring(bar + 1)
                    normalized["$prefix|${normalize(term)}"] = entry
                }
                GlossaryTable(exact, normalized)
            } catch (_: Exception) {
                GlossaryTable(emptyMap(), emptyMap())
            }
        }
    }

    private fun normalize(s: String): String =
        s.lowercase().filter { it.isLetterOrDigit() }

    fun clearCache() {
        cache.clear()
    }
}
