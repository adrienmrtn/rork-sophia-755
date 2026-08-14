package app.rork.sophia.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.sp
/**
 * Cover placeholder only. Decoding 800+ JPEGs (even downsampled) OOMs Redmi-class devices
 * on every swipe. Color + initial is enough for the feed/library.
 */
@Composable
fun CourseImage(
    courseId: String,
    modifier: Modifier = Modifier,
    contentScale: ContentScale = ContentScale.Crop,
    maxEdgePx: Int = 1080,
) {
    val letter = courseId.substringAfterLast('_').firstOrNull()?.uppercaseChar()?.toString() ?: "S"
    val color = placeholderColor(courseId)
    Box(modifier = modifier.background(color), contentAlignment = Alignment.Center) {
        Text(
            text = letter,
            fontFamily = FontFamily.SansSerif,
            fontWeight = FontWeight.Bold,
            fontSize = 42.sp,
            color = Color.White.copy(alpha = 0.92f),
        )
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
    return Color(palette[kotlin.math.abs(hash) % palette.size])
}

/** Kept so startup/onboarding warm calls still compile; no-op (no bitmap decode). */
object CourseImageResolver {
    fun ensureMap(context: android.content.Context) = Unit
    fun decodeDownsampled(context: android.content.Context, courseId: String, maxEdgePx: Int = 1080) = null
}
