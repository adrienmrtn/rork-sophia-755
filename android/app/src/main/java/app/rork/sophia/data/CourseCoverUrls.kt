package app.rork.sophia.data

import android.content.Context
import app.rork.sophia.AppConfig
import kotlinx.serialization.json.Json
import java.util.concurrent.ConcurrentHashMap

/**
 * Cover JPEGs live in Supabase Storage (`course-images` public bucket), not the APK.
 * URL: {SUPABASE_URL}/storage/v1/object/public/course-images/{slug}.jpg
 */
object CourseCoverUrls {
    const val BUCKET = "course-images"

    private val json = Json { ignoreUnknownKeys = true }
    private val slugByCourseId = ConcurrentHashMap<String, String>()
    @Volatile private var loaded = false

    fun ensureMap(context: Context) {
        if (loaded) return
        synchronized(this) {
            if (loaded) return
            runCatching {
                val text = context.assets.open("course_image_map.json")
                    .bufferedReader()
                    .use { it.readText() }
                json.decodeFromString<Map<String, String>>(text).forEach { (id, slug) ->
                    slugByCourseId[id] = slug
                }
            }
            loaded = true
        }
    }

    fun url(context: Context, courseId: String): String? {
        ensureMap(context)
        val slug = slugByCourseId[courseId] ?: return null
        val base = AppConfig.SUPABASE_URL.trimEnd('/')
        return "$base/storage/v1/object/public/$BUCKET/$slug.jpg"
    }
}
