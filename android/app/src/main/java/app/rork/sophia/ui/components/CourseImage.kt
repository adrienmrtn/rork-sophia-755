package app.rork.sophia.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.sp
import app.rork.sophia.data.CourseCoverUrls
import app.rork.sophia.data.DeviceCapabilities
import coil.compose.AsyncImage
import coil.request.ImageRequest
import kotlinx.coroutines.yield

/**
 * One remote cover at a time (Coil disk cache). Never ships JPEGs in the APK.
 * Falls back to a color tile if the network/cache miss.
 */
@Composable
fun CourseImage(
    courseId: String,
    modifier: Modifier = Modifier,
    contentScale: ContentScale = ContentScale.Crop,
    maxEdgePx: Int = 720,
) {
    val context = LocalContext.current
    val url = remember(courseId) { CourseCoverUrls.url(context, courseId) }
    val color = remember(courseId) { placeholderColor(courseId) }
    val letter = remember(courseId) {
        courseId.substringAfterLast('_').firstOrNull()?.uppercaseChar()?.toString() ?: "S"
    }
    // Low-RAM phones get a smaller decode, not a blank tile.
    val targetPx = remember(maxEdgePx) {
        if (DeviceCapabilities.isLowRam(context)) minOf(maxEdgePx, 480) else maxEdgePx
    }
    var loadRemote by remember(courseId) { mutableStateOf(false) }
    LaunchedEffect(courseId) {
        yield()
        loadRemote = true
    }
    Box(modifier = modifier.background(color), contentAlignment = Alignment.Center) {
        Text(
            text = letter,
            fontFamily = FontFamily.SansSerif,
            fontWeight = FontWeight.Bold,
            fontSize = 42.sp,
            color = Color.White.copy(alpha = 0.92f),
        )
        if (loadRemote && url != null) {
            AsyncImage(
                model = ImageRequest.Builder(context)
                    .data(url)
                    .size(targetPx)
                    .allowHardware(false)
                    .crossfade(false)
                    .memoryCacheKey(courseId)
                    .diskCacheKey(courseId)
                    .build(),
                contentDescription = null,
                modifier = Modifier.fillMaxSize(),
                contentScale = contentScale,
            )
        }
    }
}

private fun placeholderColor(courseId: String): Color {
    var hash = 0
    for (ch in courseId) hash = hash * 31 + ch.code
    val palette = intArrayOf(
        0xFF1A3A6B.toInt(),
        0xFF2E62C4.toInt(),
        0xFF387D5A.toInt(),
        0xFF8F66EB.toInt(),
        0xFFB14F42.toInt(),
        0xFF55637A.toInt(),
    )
    return Color(palette[(hash and 0x7FFFFFFF) % palette.size])
}

object CourseImageResolver {
    fun ensureMap(context: android.content.Context) = CourseCoverUrls.ensureMap(context)
    fun decodeDownsampled(context: android.content.Context, courseId: String, maxEdgePx: Int = 1080) = null
}
