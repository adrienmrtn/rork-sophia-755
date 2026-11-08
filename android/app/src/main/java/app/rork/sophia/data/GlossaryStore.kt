package app.rork.sophia.data

import android.content.Context
import app.rork.sophia.data.catalog.CatalogSnapshot
import app.rork.sophia.data.catalog.CatalogStore
import app.rork.sophia.domain.AppLanguage
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.serialization.Serializable
import java.util.concurrent.ConcurrentHashMap

@Serializable
data class GlossaryEntry(
    val displayTerm: String,
    val classification: String = "",
    val explanation: String = "",
)

/**
 * Le glossaire d'une langue indexé pour la recherche : clés exactes `"<courseId>|<terme>"` et
 * clés normalisées (minuscules, lettres et chiffres). Rattaché au snapshot qui l'a produit.
 */
private class GlossaryTable(
    val snapshot: CatalogSnapshot,
    val exact: Map<String, GlossaryEntry>,
    val normalized: Map<String, GlossaryEntry>,
)

/** Un terme trouvé par la recherche de l'onglet Explorer, avec le cours qui le définit. */
data class GlossaryHit(val courseId: String, val entry: GlossaryEntry)

/**
 * Les définitions des termes `[[…]]`, lues dans le catalogue en ligne ([CatalogStore]) : le
 * fichier `glossary.json` de la langue (téléchargé, clé `"<courseId>|<terme>"` dans toutes les
 * langues), complété par le glossaire du paquet de chaque cours (pack de départ ou téléchargé),
 * qui définit les termes d'un cours avant même que le fichier de la langue soit arrivé.
 */
object GlossaryStore {
    private val cache = ConcurrentHashMap<String, GlossaryTable>()

    /** Indexe le glossaire de la langue hors du fil principal, avant le premier rendu d'une leçon. */
    suspend fun preload(context: Context, language: AppLanguage) {
        withContext(Dispatchers.IO) { table(language) }
    }

    /**
     * Entries are keyed `"{courseId}|{term}"` in every locale — French included.
     *
     * Cache-only: the reader preloads the table off the main thread before it renders
     * a block, and a tap must never turn into a file read on the UI thread. Le glossaire du
     * paquet du cours, déjà décodé pour afficher le texte, est consulté aussi.
     */
    fun entry(
        context: Context,
        language: AppLanguage,
        courseId: String,
        displayTerm: String,
    ): GlossaryEntry? = lookup(cachedTable(language), CatalogStore.cachedBundle(courseId, language)?.glossary, courseId, displayTerm)

    /**
     * Whether a term is worth rendering as a link. About 8% of the `[[terms]]` in the
     * content have no entry, and underlining those just invites a tap that does
     * nothing. Unknown when nothing is loaded yet, so links are kept.
     */
    fun hasEntry(language: AppLanguage, courseId: String, displayTerm: String): Boolean {
        val table = cachedTable(language)
        val bundleGlossary = CatalogStore.cachedBundle(courseId, language)?.glossary
        if (table == null && bundleGlossary == null) return true
        return lookup(table, bundleGlossary, courseId, displayTerm) != null
    }

    private fun lookup(
        table: GlossaryTable?,
        bundleGlossary: Map<String, GlossaryEntry>?,
        courseId: String,
        displayTerm: String,
    ): GlossaryEntry? {
        table?.exact?.get("$courseId|$displayTerm")?.let { return it }
        val needle = normalize(displayTerm)
        if (table != null && needle.isNotEmpty()) {
            table.normalized["$courseId|$needle"]?.let { return it }
        }
        if (bundleGlossary.isNullOrEmpty()) return null
        bundleGlossary[displayTerm]?.let { return it }
        if (needle.isEmpty()) return null
        for ((term, entry) in bundleGlossary) {
            if (normalize(term) == needle) return entry
        }
        return null
    }

    /** La table en mémoire si elle correspond encore au snapshot courant ; null sinon (sans rien lire). */
    private fun cachedTable(language: AppLanguage): GlossaryTable? {
        val snapshot = CatalogStore.cachedSnapshot(language) ?: return null
        return cache[language.code]?.takeIf { it.snapshot === snapshot }
    }

    /** La table de la langue, indexée depuis le snapshot (décode `glossary.json` si besoin : disque). */
    private fun table(language: AppLanguage): GlossaryTable {
        val snapshot = CatalogStore.snapshot(language)
        cache[language.code]?.takeIf { it.snapshot === snapshot }?.let { return it }
        val exact = snapshot.glossary
        val normalized = HashMap<String, GlossaryEntry>(exact.size * 2)
        for ((key, entry) in exact) {
            val bar = key.indexOf('|')
            if (bar < 0) continue
            val prefix = key.substring(0, bar)
            val term = key.substring(bar + 1)
            normalized["$prefix|${normalize(term)}"] = entry
        }
        return GlossaryTable(snapshot, exact, normalized).also { cache[language.code] = it }
    }

    /**
     * Les termes dont le nom contient [query] (sans accents ni casse), un par couple
     * terme/cours, triés par terme, au plus [limit]. Charge la table de la langue si besoin :
     * à appeler depuis une coroutine, jamais pendant la composition.
     */
    suspend fun search(context: Context, language: AppLanguage, query: String, limit: Int): List<GlossaryHit> {
        val needle = searchKey(query)
        if (needle.length < 2) return emptyList()
        return withContext(Dispatchers.IO) {
            val table = table(language)
            val seen = HashSet<String>()
            val hits = ArrayList<GlossaryHit>()
            for ((key, entry) in table.exact) {
                if (!searchKey(entry.displayTerm).contains(needle)) continue
                val bar = key.indexOf('|')
                val courseId = if (bar >= 0) key.substring(0, bar) else ""
                if (!seen.add(searchKey(entry.displayTerm) + "|" + courseId)) continue
                hits += GlossaryHit(courseId, entry)
            }
            hits.sortBy { it.entry.displayTerm }
            hits.take(limit)
        }
    }

    /** Minuscules sans diacritiques, pour une recherche tolérante (« medecin » trouve « médecin »). */
    fun searchKey(s: String): String =
        java.text.Normalizer.normalize(s, java.text.Normalizer.Form.NFD)
            .replace(Regex("\\p{Mn}+"), "")
            .lowercase(java.util.Locale.ROOT)
            .trim()

    private fun normalize(s: String): String =
        // Locale.ROOT: a Turkish phone lowercases "I" to a dotless "ı", which would
        // stop every glossary term containing an I from ever matching.
        s.lowercase(java.util.Locale.ROOT).filter { it.isLetterOrDigit() }

    fun clearCache() {
        cache.clear()
    }
}
