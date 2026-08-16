package app.rork.sophia.ui.components

import android.os.Build
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.blur
import androidx.compose.ui.draw.drawWithContent
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.unit.dp
import app.rork.sophia.ui.theme.DS

/**
 * Blurs premium lesson content the way iOS does: the text stays visible enough to be
 * enticing, but unreadable.
 *
 * `Modifier.blur` only does anything from Android 12 (API 31); below that it is silently
 * ignored, which would leave the paid content perfectly legible. Older phones therefore
 * get a fade plus a canvas wash, which is less pretty but actually hides the text.
 */
@Composable
fun Modifier.lockedContentBlur(locked: Boolean, radius: androidx.compose.ui.unit.Dp = 7.dp): Modifier {
    val progress by animateFloatAsState(
        targetValue = if (locked) 1f else 0f,
        animationSpec = tween(260),
        label = "lockBlur",
    )
    if (progress <= 0.01f) return this
    val supportsBlur = Build.VERSION.SDK_INT >= Build.VERSION_CODES.S
    return if (supportsBlur) {
        this.blur(radius * progress)
    } else {
        this
            .graphicsLayer { alpha = 1f - 0.55f * progress }
            .drawWithContent {
                drawContent()
                drawRect(
                    brush = Brush.verticalGradient(
                        listOf(
                            DS.canvas.copy(alpha = 0.55f * progress),
                            DS.canvas.copy(alpha = 0.8f * progress),
                        ),
                    ),
                )
                // A few horizontal bands break up the remaining word shapes.
                val bandHeight = size.height / 26f
                var y = 0f
                while (y < size.height) {
                    drawRect(
                        color = Color.White.copy(alpha = 0.35f * progress),
                        topLeft = androidx.compose.ui.geometry.Offset(0f, y),
                        size = androidx.compose.ui.geometry.Size(size.width, bandHeight * 0.45f),
                    )
                    y += bandHeight
                }
            }
    }
}
