package app.rork.sophia.ui.components

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.util.LruCache
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.produceState
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.sp
import app.rork.sophia.ui.theme.DS
import app.rork.sophia.ui.theme.PlusJakartaSans
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.serialization.json.Json
import java.util.concurrent.ConcurrentHashMap

object CourseImageResolver {
    private val pathCache = ConcurrentHashMap<String, String?>()
    private var map: Map<String, String>? = null

    /** ~1/8 of typical heap; enough for ~15–25 downsampled covers. */
    private val bitmapCache = object : LruCache<String, Bitmap>(
        (Runtime.getRuntime().maxMemory() / 1024 / 8).toInt().coerceIn(8_192, 48_576),
    ) {
        override fun sizeOf(key: String, value: Bitmap): Int = value.byteCount / 1024
    }

    @Synchronized
    fun ensureMap(context: Context) {
        if (map != null) return
        map = try {
            val text = context.assets.open("course_image_map.json").bufferedReader().use { it.readText() }
            Json.decodeFromString<Map<String, String>>(text)
        } catch (_: Exception) {
            emptyMap()
        }
    }

    fun assetPath(context: Context, courseId: String): String? {
        pathCache[courseId]?.let { return it }
        ensureMap(context)
        val stem = map?.get(courseId)
            ?: courseId.replace(Regex("^course_\\d+_"), "")
        val candidates = listOf(
            "images/$stem.jpg",
            "images/$stem.jpeg",
            "images/$stem.png",
            "images/$courseId.jpg",
        )
        val found = candidates.firstOrNull { path ->
            try {
                context.assets.open(path).close()
                true
            } catch (_: Exception) {
                false
            }
        }
        pathCache[courseId] = found
        return found
    }

    /**
     * Decode a course cover off the caller's thread expectations — always call from IO.
     * Downsamples to [maxEdgePx] so TikTok swipes don't allocate 4–9MB full-res bitmaps.
     */
    fun decodeDownsampled(context: Context, courseId: String, maxEdgePx: Int = 1080): Bitmap? {
        val cacheKey = "$courseId@$maxEdgePx"
        synchronized(bitmapCache) {
            bitmapCache.get(cacheKey)?.let { return it }
        }
        val path = assetPath(context, courseId) ?: return null
        val decoded = runCatching {
            val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
            context.assets.open(path).use { BitmapFactory.decodeStream(it, null, bounds) }
            val sample = calculateInSampleSize(bounds.outWidth, bounds.outHeight, maxEdgePx)
            val opts = BitmapFactory.Options().apply {
                inSampleSize = sample
                inPreferredConfig = Bitmap.Config.RGB_565
            }
            context.assets.open(path).use { BitmapFactory.decodeStream(it, null, opts) }
        }.getOrNull() ?: return null
        synchronized(bitmapCache) {
            bitmapCache.put(cacheKey, decoded)
        }
        return decoded
    }

    private fun calculateInSampleSize(width: Int, height: Int, maxEdgePx: Int): Int {
        if (width <= 0 || height <= 0) return 1
        var sample = 1
        var w = width
        var h = height
        while (w / 2 >= maxEdgePx || h / 2 >= maxEdgePx) {
            w /= 2
            h /= 2
            sample *= 2
        }
        return sample.coerceAtLeast(1)
    }
}

@Composable
fun CourseImage(
    courseId: String,
    modifier: Modifier = Modifier,
    contentScale: ContentScale = ContentScale.Crop,
    maxEdgePx: Int = 1080,
) {
    val context = LocalContext.current
    val bitmap by produceState<Bitmap?>(initialValue = null, courseId, maxEdgePx) {
        value = withContext(Dispatchers.IO) {
            CourseImageResolver.decodeDownsampled(context.applicationContext, courseId, maxEdgePx)
        }
    }
    if (bitmap == null) {
        Box(modifier = modifier.background(DS.surfaceMuted), contentAlignment = Alignment.Center) {
            Text("S", fontFamily = PlusJakartaSans, fontSize = 42.sp, color = DS.accent)
        }
    } else {
        Image(
            bitmap = bitmap!!.asImageBitmap(),
            contentDescription = null,
            modifier = modifier,
            contentScale = contentScale,
        )
    }
}
