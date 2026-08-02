package app.rork.sophia.ui.components

import android.content.Context
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.sp
import app.rork.sophia.ui.theme.DS
import app.rork.sophia.ui.theme.PlusJakartaSans
import android.graphics.BitmapFactory
import androidx.compose.foundation.Image
import androidx.compose.ui.graphics.asImageBitmap
import kotlinx.serialization.json.Json
import java.util.concurrent.ConcurrentHashMap

object CourseImageResolver {
    private val cache = ConcurrentHashMap<String, String?>()
    private var map: Map<String, String>? = null

    private fun ensureMap(context: Context) {
        if (map != null) return
        map = try {
            val text = context.assets.open("course_image_map.json").bufferedReader().use { it.readText() }
            Json.decodeFromString<Map<String, String>>(text)
        } catch (_: Exception) {
            emptyMap()
        }
    }

    fun assetPath(context: Context, courseId: String): String? {
        cache[courseId]?.let { return it }
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
        cache[courseId] = found
        return found
    }
}

@Composable
fun CourseImage(
    courseId: String,
    modifier: Modifier = Modifier,
    contentScale: ContentScale = ContentScale.Crop,
) {
    val context = LocalContext.current
    val bitmap = remember(courseId) {
        CourseImageResolver.assetPath(context, courseId)?.let { path ->
            runCatching {
                context.assets.open(path).use { BitmapFactory.decodeStream(it) }
            }.getOrNull()
        }
    }
    if (bitmap == null) {
        Box(modifier = modifier.background(DS.surfaceMuted), contentAlignment = Alignment.Center) {
            Text("S", fontFamily = PlusJakartaSans, fontSize = 42.sp, color = DS.accent)
        }
    } else {
        Image(
            bitmap = bitmap.asImageBitmap(),
            contentDescription = null,
            modifier = modifier,
            contentScale = contentScale,
        )
    }
}
