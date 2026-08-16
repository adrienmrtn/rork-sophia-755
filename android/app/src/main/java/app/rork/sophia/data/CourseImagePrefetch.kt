package app.rork.sophia.data

import android.content.Context
import app.rork.sophia.domain.AppLanguage
import coil.imageLoader
import coil.request.ImageRequest
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

/**
 * Inline course images are fetched from Supabase, so the first one is still in
 * flight when the reader appears. Warming them through the very same request the
 * reader will build means the composable hits Coil's cache instead of the network.
 *
 * Enqueuing is fire-and-forget: it never blocks the caller and never blocks the
 * reader from showing.
 */
object CourseImagePrefetch {
    /** Matches only `image` blocks — no other block in `courses_v2` has an `asset`. */
    private val assetPattern = Regex("\"asset\"\\s*:\\s*\"([^\"]+)\"")

    fun targetPx(context: Context): Int =
        if (DeviceCapabilities.isLowRam(context)) 480 else 720

    /** The single definition of an inline-image request; cache keys must not diverge. */
    fun request(context: Context, asset: String, url: String): ImageRequest =
        ImageRequest.Builder(context)
            .data(url)
            .size(targetPx(context))
            .crossfade(false)
            .memoryCacheKey(asset)
            .diskCacheKey(asset)
            .build()

    fun warmAssets(context: Context, assets: List<String>) {
        if (assets.isEmpty()) return
        val app = context.applicationContext
        CourseCoverUrls.ensureBlockMap(app)
        assets.forEach { asset ->
            val url = CourseCoverUrls.blockUrl(app, asset) ?: return@forEach
            app.imageLoader.enqueue(request(app, asset, url))
        }
    }

    /**
     * Warms the first [limit] images of a course straight from its JSON, for callers
     * that have not parsed it — the home feed giving the reader a head start.
     */
    suspend fun warmCourse(
        context: Context,
        language: AppLanguage,
        courseId: String,
        limit: Int = 2,
    ) {
        val app = context.applicationContext
        val assets = withContext(Dispatchers.IO) {
            val raw = ContentCatalog.structuredContentJson(app, language, courseId)
                ?: return@withContext emptyList()
            assetPattern.findAll(raw)
                .mapNotNull { it.groupValues.getOrNull(1).takeIf { s -> !s.isNullOrBlank() } }
                .distinct()
                .take(limit)
                .toList()
        }
        warmAssets(app, assets)
    }
}
