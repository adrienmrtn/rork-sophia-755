package app.rork.sophia.data

import android.content.Context
import org.json.JSONObject

/**
 * Cards swiped past without being opened, the « fatigue » of the home deck. Same rules as
 * iOS's `DeckSkipStore`: local on purpose and never synced (a browsing habit, not progress),
 * capped per course and in size, and cleared for a course once it is opened.
 */
class DeckSkipStore(context: Context) {
    private val prefs = context.getSharedPreferences("sophia_prefs", Context.MODE_PRIVATE)

    fun counts(): Map<String, Int> {
        val raw = prefs.getString(KEY, null) ?: return emptyMap()
        return try {
            val json = JSONObject(raw)
            buildMap { json.keys().forEach { put(it, json.optInt(it)) } }
        } catch (_: Exception) {
            emptyMap()
        }
    }

    /** Records that [courseId] was dealt and swiped past. */
    fun registerSkip(courseId: String) {
        val counts = counts().toMutableMap()
        counts[courseId] = minOf((counts[courseId] ?: 0) + 1, MAX_PER_COURSE)
        // The least-skipped go first: they are the ones the deck barely penalises anyway.
        val kept = if (counts.size > MAX_ENTRIES) {
            counts.entries.sortedByDescending { it.value }.take(MAX_ENTRIES).associate { it.key to it.value }
        } else {
            counts
        }
        save(kept)
    }

    /** A course the reader finally opened is no longer held against itself. */
    fun clear(courseId: String) {
        val counts = counts().toMutableMap()
        if (counts.remove(courseId) != null) save(counts)
    }

    private fun save(counts: Map<String, Int>) {
        val json = JSONObject()
        counts.forEach { (id, count) -> json.put(id, count) }
        prefs.edit().putString(KEY, json.toString()).apply()
    }

    private companion object {
        const val KEY = "sophia_deck_skip_counts"
        const val MAX_PER_COURSE = 8
        const val MAX_ENTRIES = 120
    }
}
