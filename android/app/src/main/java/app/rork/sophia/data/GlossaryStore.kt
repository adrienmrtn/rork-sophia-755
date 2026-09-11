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

    /**
     * Entries are keyed `"{courseId}|{term}"` in every locale — French included,
     * which used to be looked up by course title and so never matched.
     *
     * Cache-only: the reader preloads the table off the main thread before it renders
     * a block, and a tap must never turn into an 0.8MB read on the UI thread.
     */
    fun entry(
        context: Context,
        language: AppLanguage,
        courseId: String,
        displayTerm: String,
    ): GlossaryEntry? = cache[language.code]?.let { lookup(it, courseId, displayTerm) }

    /**
     * Whether a term is worth rendering as a link. About 8% of the `[[terms]]` in the
     * content have no entry, and underlining those just invites a tap that does
     * nothing. Unknown when the table is not loaded yet, so links are kept.
     */
    fun hasEntry(language: AppLanguage, courseId: String, displayTerm: String): Boolean {
        val table = cache[language.code] ?: return true
        return lookup(table, courseId, displayTerm) != null
    }

    private fun lookup(table: GlossaryTable, courseId: String, displayTerm: String): GlossaryEntry? {
        table.exact["$courseId|$displayTerm"]?.let { return it }
        val needle = normalize(displayTerm)
        if (needle.isEmpty()) return null
        return table.normalized["$courseId|$needle"]
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
