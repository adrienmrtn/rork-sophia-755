package app.rork.sophia.data

import android.content.Context
import app.rork.sophia.AppConfig
import app.rork.sophia.data.catalog.CatalogStore
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
    private val objectBySlug = ConcurrentHashMap<String, String>()
    @Volatile private var loaded = false
    @Volatile private var blocksLoaded = false

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

    /**
     * Inline `image` block slugs do not always match the object names in the bucket
     * (accents encoded as `_u0301`, aliases, casing), so the mapping is resolved
     * offline by `scripts/build_block_image_map.py`.
     */
    fun ensureBlockMap(context: Context) {
        if (blocksLoaded) return
        synchronized(this) {
            if (blocksLoaded) return
            runCatching {
                val text = context.assets.open("course_block_images.json")
                    .bufferedReader()
                    .use { it.readText() }
                json.decodeFromString<Map<String, String>>(text).forEach { (slug, obj) ->
                    objectBySlug[slug] = obj
                }
            }
            blocksLoaded = true
        }
    }

    /**
     * La couverture d'un cours : la carte embarquée d'abord, sinon le `cover` du catalogue en
     * ligne (un cours publié après ce build). Le catalogue n'est consulté qu'en mémoire : cette
     * méthode est appelée pendant la composition.
     */
    fun url(context: Context, courseId: String): String? {
        ensureMap(context)
        val slug = slugByCourseId[courseId]
            ?: CatalogStore.coverSlug(courseId, LanguageManager.persisted(context))
            ?: return null
        return publicUrl(slug)
    }

    /** Cover for an inline `image` block, or null when the slug has no object. */
    fun blockUrl(context: Context, asset: String): String? {
        ensureBlockMap(context)
        return publicUrl(objectBySlug[asset] ?: return null)
    }

    private fun publicUrl(objectName: String): String {
        val base = AppConfig.SUPABASE_URL.trimEnd('/')
        return "$base/storage/v1/object/public/$BUCKET/$objectName.jpg"
    }
}
