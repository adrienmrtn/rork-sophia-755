package app.rork.sophia.data

import android.content.Context
import app.rork.sophia.domain.PathNodeState
import org.json.JSONObject

/**
 * Node states as the reader last saw them on this device, so the next visit can animate
 * exactly what changed in between (a course finished from the home, a level passed…).
 * Deliberately outside the synchronised progress: it is a display concern.
 */
class LearningPathSeenStore(context: Context) {
    private val prefs = context.getSharedPreferences("sophia_prefs", Context.MODE_PRIVATE)

    fun load(): Map<String, PathNodeState>? {
        val raw = prefs.getString(KEY, null) ?: return null
        return try {
            val json = JSONObject(raw)
            buildMap {
                json.keys().forEach { id ->
                    PathNodeState.fromStorageKey(json.optString(id))?.let { put(id, it) }
                }
            }
        } catch (_: Exception) {
            null
        }
    }

    fun save(states: Map<String, PathNodeState>) {
        val json = JSONObject()
        states.forEach { (id, state) -> json.put(id, state.storageKey) }
        prefs.edit().putString(KEY, json.toString()).apply()
    }

    private companion object {
        const val KEY = "sophia_path_seen_node_states"
    }
}
