package app.rork.sophia.ui.newgen

import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.Spring
import androidx.compose.animation.core.spring
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.size
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material.icons.filled.FavoriteBorder
import androidx.compose.material3.Icon
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.scale
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import app.rork.sophia.ui.theme.DS
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlin.math.cos
import kotlin.math.sin

/**
 * Le cœur d'un bouton « j'aime » : il rebondit quand il s'allume et lâche un éclat de petites
 * particules. [burst] est incrémenté par le parent à chaque nouveau « j'aime » pour rejouer
 * l'éclat (jamais au retrait). Même geste que `LikeHeartIcon` sur iOS.
 */
@Composable
fun LikeHeartIcon(
    liked: Boolean,
    burst: Int,
    modifier: Modifier = Modifier,
    size: Dp = 15.dp,
    idleTint: Color = DS.inkSecondary,
) {
    val scale = remember { Animatable(1f) }
    val progress = remember { Animatable(0f) }
    LaunchedEffect(burst) {
        if (burst == 0) return@LaunchedEffect
        launch {
            scale.snapTo(1f)
            scale.animateTo(1.5f, spring(dampingRatio = 0.45f, stiffness = Spring.StiffnessMedium))
            scale.animateTo(1f, spring(dampingRatio = 0.6f, stiffness = Spring.StiffnessMediumLow))
        }
        launch {
            progress.snapTo(0f)
            progress.animateTo(1f, tween(durationMillis = 600))
            progress.snapTo(0f)
        }
    }
    Box(modifier = modifier.size(size + 4.dp), contentAlignment = Alignment.Center) {
        HeartBurst(progress = progress.value, modifier = Modifier.size(size * 3.4f))
        Icon(
            imageVector = if (liked) Icons.Filled.Favorite else Icons.Filled.FavoriteBorder,
            contentDescription = null,
            tint = if (liked) LikedTint else idleTint,
            modifier = Modifier.size(size).scale(scale.value),
        )
    }
}

/**
 * Huit particules qui partent du centre, rose et or en alternance, et s'éteignent en route.
 * [progress] va de 0 (rien n'est visible) à 1 (éclat terminé).
 */
@Composable
fun HeartBurst(progress: Float, modifier: Modifier = Modifier) {
    val warm = DS.warm
    Canvas(modifier = modifier) {
        if (progress <= 0f) return@Canvas
        val radius = size.minDimension / 2f
        val travel = 0.25f + 0.75f * progress
        val dot = 2.5.dp.toPx() * (1f - 0.6f * progress)
        val alpha = (1f - progress).coerceIn(0f, 1f)
        for (index in 0 until 8) {
            val angle = index / 8.0 * 2 * Math.PI
            val color = if (index % 2 == 0) LikedTint else warm
            drawCircle(
                color = color.copy(alpha = alpha),
                radius = dot,
                center = Offset(
                    center.x + (cos(angle) * radius * travel).toFloat(),
                    center.y + (sin(angle) * radius * travel).toFloat(),
                ),
            )
        }
    }
}

/** Le grand cœur blanc du double-tap, au centre de la carte : il surgit, puis s'efface. */
@Composable
fun BigHeartOverlay(trigger: Int, modifier: Modifier = Modifier) {
    val scale = remember { Animatable(0.5f) }
    val alpha = remember { Animatable(0f) }
    LaunchedEffect(trigger) {
        if (trigger == 0) return@LaunchedEffect
        scale.snapTo(0.5f)
        alpha.snapTo(1f)
        scale.animateTo(1.1f, spring(dampingRatio = 0.55f, stiffness = Spring.StiffnessMedium))
        delay(250)
        launch { scale.animateTo(1.3f, tween(durationMillis = 300)) }
        alpha.animateTo(0f, tween(durationMillis = 300))
    }
    if (alpha.value > 0f) {
        Icon(
            imageVector = Icons.Filled.Favorite,
            contentDescription = null,
            tint = Color.White,
            modifier = modifier
                .size(96.dp)
                .scale(scale.value)
                .alpha(alpha.value),
        )
    }
}
