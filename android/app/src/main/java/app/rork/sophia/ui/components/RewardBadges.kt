package app.rork.sophia.ui.components

import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.requiredSize
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.MenuBook
import androidx.compose.material.icons.filled.Bolt
import androidx.compose.material.icons.filled.EmojiEvents
import androidx.compose.material.icons.filled.LocalFireDepartment
import androidx.compose.material.icons.filled.Star
import androidx.compose.material.icons.filled.TrackChanges
import androidx.compose.material.icons.filled.Verified
import androidx.compose.material3.Icon
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.drawWithCache
import androidx.compose.ui.graphics.BlendMode
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.CompositingStrategy
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp

/** The streak colours: pink at the base of the flame, orange, yellow at the tip (iOS). */
object StreakColors {
    val pink = Color(red = 0.96f, green = 0.30f, blue = 0.56f)
    val orange = Color(red = 1.0f, green = 0.55f, blue = 0.18f)
    val yellow = Color(red = 1.0f, green = 0.84f, blue = 0.35f)
}

/**
 * The « emotes » of the gamification, one family treated like the streak flame: a warm
 * gradient glyph, a halo, a soft beat. Same kinds and colours as iOS's `AnimatedRewardBadge`.
 * [colors] run from the bottom of the glyph to its top.
 */
enum class RewardBadgeKind(val icon: ImageVector, val colors: List<Color>) {
    /** Experience points: a golden star. */
    Xp(Icons.Filled.Star, GOLD),

    /** A finished quiz, a ranking: a golden trophy. */
    Trophy(Icons.Filled.EmojiEvents, GOLD),

    /** A level gained: a violet-pink bolt. */
    LevelUp(
        Icons.Filled.Bolt,
        listOf(Color(0.55f, 0.30f, 0.95f), Color(0.85f, 0.35f, 0.80f), Color(0.98f, 0.55f, 0.70f)),
    ),

    /** A collection or a session completed: a mint seal. */
    Seal(
        Icons.Filled.Verified,
        listOf(Color(0.16f, 0.60f, 0.42f), Color(0.30f, 0.80f, 0.58f), Color(0.62f, 0.94f, 0.78f)),
    ),

    /** Courses read: blue-turquoise books. */
    Courses(
        Icons.AutoMirrored.Filled.MenuBook,
        listOf(Color(0.18f, 0.40f, 0.90f), Color(0.25f, 0.65f, 0.95f), Color(0.45f, 0.88f, 0.90f)),
    ),

    /** Quiz accuracy: a pink-orange target. */
    Target(
        Icons.Filled.TrackChanges,
        listOf(Color(0.96f, 0.30f, 0.56f), Color(1.0f, 0.55f, 0.30f), Color(1.0f, 0.78f, 0.40f)),
    );

    /** Halo and shadow: the middle tone. */
    val glow: Color get() = colors[1]
}

private val GOLD = listOf(Color(0.98f, 0.60f, 0.10f), Color(1.0f, 0.82f, 0.22f), Color(1.0f, 0.93f, 0.55f))

/**
 * A reward glyph in its gradient. [animated] false keeps the colours but not the beat (the
 * home header, where moving badges would compete with the course cards).
 */
@Composable
fun AnimatedRewardBadge(
    kind: RewardBadgeKind,
    modifier: Modifier = Modifier,
    size: Dp = 24.dp,
    showGlow: Boolean = true,
    animated: Boolean = true,
) {
    val pulse = if (animated) {
        rememberInfiniteTransition(label = "rewardBadge").animateFloat(
            initialValue = 0f,
            targetValue = 1f,
            animationSpec = infiniteRepeatable(tween(1100, easing = FastOutSlowInEasing), RepeatMode.Reverse),
            label = "pulse",
        ).value
    } else {
        0f
    }
    BadgeFrame(modifier = modifier, size = size, glow = kind.glow, showGlow = showGlow, glowAlpha = 0.28f + 0.17f * pulse) {
        GradientIcon(
            icon = kind.icon,
            colors = kind.colors,
            size = size,
            modifier = Modifier.graphicsLayer {
                val scale = 1f + 0.08f * pulse
                scaleX = scale
                scaleY = scale
            },
        )
    }
}

/** The streak flame: pink → orange → yellow, a pink halo and a lively beat (iOS). */
@Composable
fun AnimatedFlameBadge(
    modifier: Modifier = Modifier,
    size: Dp = 24.dp,
    showGlow: Boolean = true,
    animated: Boolean = true,
) {
    val transition = rememberInfiniteTransition(label = "flame")
    val beat = if (animated) {
        transition.animateFloat(
            initialValue = 1f,
            targetValue = 1.12f,
            animationSpec = infiniteRepeatable(tween(900, easing = FastOutSlowInEasing), RepeatMode.Reverse),
            label = "beat",
        ).value
    } else {
        1f
    }
    val sway = if (animated) {
        transition.animateFloat(
            initialValue = 0f,
            targetValue = 5f,
            animationSpec = infiniteRepeatable(tween(750, easing = FastOutSlowInEasing), RepeatMode.Reverse),
            label = "sway",
        ).value
    } else {
        0f
    }
    BadgeFrame(modifier = modifier, size = size, glow = StreakColors.pink, showGlow = showGlow, glowAlpha = 0.35f) {
        GradientIcon(
            icon = Icons.Filled.LocalFireDepartment,
            colors = listOf(StreakColors.pink, StreakColors.orange, StreakColors.yellow),
            size = size,
            modifier = Modifier.graphicsLayer {
                scaleX = beat
                scaleY = beat
                rotationZ = sway
            },
        )
    }
}

/** The glyph centred in a box 1.4 × its size, over a soft halo that may spill out of it. */
@Composable
private fun BadgeFrame(
    modifier: Modifier,
    size: Dp,
    glow: Color,
    showGlow: Boolean,
    glowAlpha: Float,
    content: @Composable () -> Unit,
) {
    Box(modifier = modifier.size(size * 1.4f), contentAlignment = Alignment.Center) {
        if (showGlow) {
            // iOS blurs a filled circle; a radial gradient gives the same soft edge on every
            // API level (blur needs Android 12).
            Box(
                modifier = Modifier
                    .requiredSize(size * 1.9f)
                    .background(
                        Brush.radialGradient(
                            0f to glow.copy(alpha = glowAlpha),
                            0.55f to glow.copy(alpha = glowAlpha * 0.8f),
                            1f to glow.copy(alpha = 0f),
                        ),
                        CircleShape,
                    ),
            )
        }
        content()
    }
}

/** [icon] painted with a vertical gradient, [colors] from bottom to top. */
@Composable
fun GradientIcon(
    icon: ImageVector,
    colors: List<Color>,
    size: Dp,
    modifier: Modifier = Modifier,
) {
    Icon(
        imageVector = icon,
        contentDescription = null,
        tint = Color.White,
        modifier = modifier
            .size(size)
            .graphicsLayer(compositingStrategy = CompositingStrategy.Offscreen)
            .drawWithCache {
                val brush = Brush.verticalGradient(colors.reversed())
                onDrawWithContent {
                    drawContent()
                    drawRect(brush, blendMode = BlendMode.SrcIn)
                }
            },
    )
}
