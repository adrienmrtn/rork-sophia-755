package app.rork.sophia.data

import android.content.Context
import app.rork.sophia.domain.CourseAffinity
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.serialization.json.Json

/**
 * `assets/course_affinity.json`, written by `scripts/build_course_affinity.py` together with
 * the iOS `CourseAffinity.swift`. Read once; a missing or broken file leaves the deck to the
 * base weights alone rather than failing the home.
 */
object CourseAffinityStore {
    private val json = Json { ignoreUnknownKeys = true }

    @Volatile
    private var cached: CourseAffinity? = null

    fun cached(): CourseAffinity? = cached

    suspend fun load(context: Context): CourseAffinity {
        cached?.let { return it }
        return withContext(Dispatchers.IO) {
            val loaded = try {
                context.assets.open("course_affinity.json").bufferedReader().use {
                    json.decodeFromString(CourseAffinity.serializer(), it.readText())
                }
            } catch (_: Exception) {
                CourseAffinity.NONE
            }
            cached = loaded
            loaded
        }
    }
}
