package app.rork.sophia.ui.onboarding

import android.os.Build
import android.view.HapticFeedbackConstants
import android.view.View
import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.Spring
import androidx.compose.animation.core.animateDpAsState
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.spring
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsPressedAsState
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.Stable
import androidx.compose.runtime.derivedStateOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.blur
import androidx.compose.ui.draw.drawWithContent
import androidx.compose.ui.graphics.BlendMode
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.CompositingStrategy
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.platform.LocalView
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.rork.sophia.ui.theme.DS
import app.rork.sophia.ui.theme.PlusJakartaSans
import kotlinx.coroutines.delay

/**
 * Shared look and motion of the onboarding, ported from the iOS `OV2` kit: calm canvas,
 * navy ink, one blue accent, and reveals that land after the page transition instead of
 * fighting it.
 */
object OV2 {
    val bg = DS.canvas
    val ink = DS.ink
    val inkSecondary = DS.inkSecondary
    val inkTertiary = DS.inkTertiary
    val accent = DS.accent
    val accentSoft = DS.accentSoft
    val surface = DS.surface
    val hairline = DS.hairline
    val warm = Color(0xFFE6B233)
    val danger = Color(0xFFDB5A5C)
    val success = DS.success

    val title = TextStyle(
        fontFamily = PlusJakartaSans,
        fontWeight = FontWeight.ExtraBold,
        fontSize = 27.sp,
        lineHeight = 34.sp,
        color = DS.ink,
    )
    val titleLarge = TextStyle(
        fontFamily = PlusJakartaSans,
        fontWeight = FontWeight.ExtraBold,
        fontSize = 34.sp,
        lineHeight = 40.sp,
        color = DS.ink,
    )
    val headline = TextStyle(
        fontFamily = PlusJakartaSans,
        fontWeight = FontWeight.Bold,
        fontSize = 17.sp,
        lineHeight = 23.sp,
        color = DS.ink,
    )
    val body = TextStyle(
        fontFamily = PlusJakartaSans,
        fontWeight = FontWeight.Medium,
        fontSize = 16.sp,
        lineHeight = 23.sp,
        color = DS.inkSecondary,
    )
    val subheadline = TextStyle(
        fontFamily = PlusJakartaSans,
        fontWeight = FontWeight.Medium,
        fontSize = 15.sp,
        lineHeight = 21.sp,
        color = DS.inkSecondary,
    )
    val caption = TextStyle(
        fontFamily = PlusJakartaSans,
        fontWeight = FontWeight.SemiBold,
        fontSize = 13.sp,
        color = DS.inkSecondary,
    )
}

object OV2Shapes {
    val card = androidx.compose.foundation.shape.RoundedCornerShape(DS.Radius.card)
    val control = androidx.compose.foundation.shape.RoundedCornerShape(DS.Radius.control)
}

/**
 * The onboarding leans on haptics the way iOS does: a tick per revealed item, a firmer
 * bump on a primary tap. [View.performHapticFeedback] already honours the system setting.
 */
@Stable
class OnboardingHaptics(private val view: View?) {
    fun selection() = perform(HapticFeedbackConstants.CLOCK_TICK)

    fun primary() = perform(
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            HapticFeedbackConstants.CONFIRM
        } else {
            HapticFeedbackConstants.VIRTUAL_KEY
        },
    )

    fun commit() = perform(HapticFeedbackConstants.LONG_PRESS)

    private fun perform(constant: Int) {
        runCatching { view?.performHapticFeedback(constant) }
    }
}

@Composable
fun rememberOnboardingHaptics(): OnboardingHaptics {
    val view = LocalView.current
    return remember(view) { OnboardingHaptics(view) }
}

/** Fade + lift that starts after [delayMillis], so it reads as a reveal, not a jump. */
@Composable
fun Modifier.ov2Reveal(delayMillis: Int = 120, yOffset: Dp = 16.dp): Modifier {
    var shown by remember { mutableStateOf(false) }
    LaunchedEffect(Unit) {
        delay(delayMillis.toLong())
        shown = true
    }
    val progress by animateFloatAsState(
        targetValue = if (shown) 1f else 0f,
        animationSpec = spring(dampingRatio = 0.82f, stiffness = Spring.StiffnessMediumLow),
        label = "ov2Reveal",
    )
    val offsetPx = with(LocalDensity.current) { yOffset.toPx() }
    return this.graphicsLayer {
        alpha = progress
        translationY = (1f - progress) * offsetPx
    }
}

/** Full-width capsule CTA with the soft press feedback used across the iOS flow. */
@Composable
fun OnboardingCta(
    text: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
    horizontalInset: Dp = 24.dp,
    bottomInset: Dp = 20.dp,
) {
    val haptics = rememberOnboardingHaptics()
    val interaction = remember { MutableInteractionSource() }
    val pressed by interaction.collectIsPressedAsState()
    val scale by animateFloatAsState(
        targetValue = if (pressed) 0.98f else 1f,
        animationSpec = spring(dampingRatio = 0.8f, stiffness = Spring.StiffnessMedium),
        label = "ctaScale",
    )
    androidx.compose.material3.Button(
        onClick = {
            haptics.primary()
            onClick()
        },
        enabled = enabled,
        interactionSource = interaction,
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = horizontalInset)
            .padding(bottom = bottomInset)
            .graphicsLayer {
                scaleX = scale
                scaleY = scale
            }
            .height(56.dp),
        shape = CircleShape,
        colors = androidx.compose.material3.ButtonDefaults.buttonColors(
            containerColor = OV2.accent,
            contentColor = Color.White,
            disabledContainerColor = OV2.accent.copy(alpha = 0.35f),
            disabledContentColor = Color.White.copy(alpha = 0.9f),
        ),
        contentPadding = androidx.compose.foundation.layout.PaddingValues(horizontal = 12.dp),
    ) {
        Text(
            text = text,
            fontFamily = PlusJakartaSans,
            fontWeight = FontWeight.SemiBold,
            fontSize = 16.sp,
            maxLines = 2,
            textAlign = TextAlign.Center,
        )
    }
}

@Composable
fun OnboardingProgressDots(current: Int, total: Int, modifier: Modifier = Modifier) {
    if (total <= 1) return
    Row(
        modifier = modifier,
        horizontalArrangement = Arrangement.spacedBy(6.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        repeat(total) { i ->
            val width by animateDpAsState(
                targetValue = if (i == current) 22.dp else 7.dp,
                animationSpec = spring(dampingRatio = 0.8f, stiffness = Spring.StiffnessMediumLow),
                label = "dot",
            )
            Box(
                modifier = Modifier
                    .width(width)
                    .height(6.dp)
                    .background(
                        if (i <= current) OV2.accent else OV2.accent.copy(alpha = 0.15f),
                        CircleShape,
                    ),
            )
        }
    }
}

/**
 * A word whose slot is as wide as its bold rendering, so turning it bold does not reflow
 * the sentence around it — the iOS screens rely on that stillness.
 */
@Composable
fun WordCell(
    word: String,
    bold: Boolean,
    modifier: Modifier = Modifier,
    style: TextStyle = OV2.title,
    boldColor: Color = OV2.ink,
    dimColor: Color = OV2.inkTertiary,
) {
    val color by androidx.compose.animation.animateColorAsState(
        targetValue = if (bold) boldColor else dimColor,
        animationSpec = tween(300),
        label = "wordColor",
    )
    Box(modifier = modifier, contentAlignment = Alignment.Center) {
        Text(text = word, style = style.copy(fontWeight = FontWeight.ExtraBold), modifier = Modifier.alpha(0f))
        Text(
            text = word,
            style = style.copy(
                fontWeight = if (bold) FontWeight.ExtraBold else FontWeight.Normal,
                color = color,
            ),
        )
    }
}

/** Sentence that turns bold one word at a time, centred and wrapping like the iOS flow layout. */
@OptIn(ExperimentalLayoutApi::class)
@Composable
fun ProgressiveWords(
    words: List<String>,
    boldCount: Int,
    modifier: Modifier = Modifier,
    style: TextStyle = OV2.title,
    lastCell: (@Composable (bold: Boolean) -> Unit)? = null,
) {
    FlowRow(
        modifier = modifier,
        horizontalArrangement = Arrangement.spacedBy(7.dp, Alignment.CenterHorizontally),
        verticalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        words.forEachIndexed { index, word ->
            if (lastCell != null && index == words.lastIndex) {
                lastCell(boldCount > index)
            } else {
                WordCell(word = word, bold = index < boldCount, style = style)
            }
        }
    }
}

/**
 * Vertical carousel: the centred item is sharp, its neighbours shrink, fade and blur.
 * [blurEnabled] is off on constrained phones, where the scale and fade carry the effect
 * on their own (and `Modifier.blur` is a no-op below Android 12 anyway).
 */
@Composable
fun <T> OnboardingRoulette(
    items: List<T>,
    slotSpacing: Dp,
    tickMillis: Long,
    modifier: Modifier = Modifier,
    running: Boolean = true,
    blurEnabled: Boolean = true,
    content: @Composable (item: T, focused: Boolean) -> Unit,
) {
    if (items.isEmpty()) return
    val position = remember { Animatable(0f) }
    LaunchedEffect(running, items.size) {
        if (!running) return@LaunchedEffect
        while (true) {
            delay(tickMillis)
            position.animateTo(position.value + 1f, tween(950, easing = FastOutSlowInEasing))
        }
    }
    val spacingPx = with(LocalDensity.current) { slotSpacing.toPx() }
    // Only the slot window is read during composition; the per-frame offset, scale and
    // fade are read inside graphicsLayer, so a turn does not recompose the cards.
    val base by remember { derivedStateOf { kotlin.math.floor(position.value).toInt() } }
    Box(
        modifier = modifier
            .graphicsLayer { compositingStrategy = CompositingStrategy.Offscreen }
            .drawWithContent {
                drawContent()
                drawRect(
                    brush = Brush.verticalGradient(
                        0f to Color.Transparent,
                        0.27f to Color.Black,
                        0.73f to Color.Black,
                        1f to Color.Transparent,
                    ),
                    blendMode = BlendMode.DstIn,
                )
            },
        contentAlignment = Alignment.Center,
    ) {
        for (slot in (base - 1)..(base + 2)) {
            val item = items[((slot % items.size) + items.size) % items.size]
            val settledDistance = kotlin.math.abs(slot - base)
            val focused = settledDistance == 0
            // Blur cannot be animated per frame the way a layer transform can, so it is
            // stepped once per turn on the settled distance.
            val blurRadius = if (focused) 0.dp else minOf(7, settledDistance * 5).dp
            Box(
                modifier = Modifier
                    .graphicsLayer {
                        val distance = slot - position.value
                        val magnitude = kotlin.math.abs(distance)
                        translationY = distance * spacingPx
                        val s = 1f - 0.16f * minOf(magnitude, 1f)
                        scaleX = s
                        scaleY = s
                        alpha = if (magnitude < 0.5f) {
                            1f
                        } else {
                            (0.42f - (magnitude - 0.5f) * 0.42f).coerceAtLeast(0f)
                        }
                    }
                    .let { if (blurEnabled && blurRadius > 0.dp) it.blur(blurRadius) else it },
            ) {
                content(item, focused)
            }
        }
    }
}

/** Circle badge used for icons and emoji throughout the flow. */
@Composable
fun OnboardingCircleBadge(
    size: Dp,
    background: Color,
    modifier: Modifier = Modifier,
    content: @Composable () -> Unit,
) {
    Box(
        modifier = modifier.size(size).background(background, CircleShape),
        contentAlignment = Alignment.Center,
    ) {
        content()
    }
}
