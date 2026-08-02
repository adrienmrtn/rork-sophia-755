package app.rork.sophia.ui.course

import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material3.Icon
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.blur
import androidx.compose.ui.draw.scale
import androidx.compose.ui.unit.dp
import app.rork.sophia.ui.theme.DS

/**
 * Central lock on progressively-blurred lesson pages for free users.
 * A single calm padlock medallion — no CTA copy. Tapping opens the paywall.
 */
@Composable
fun CourseLessonLockOverlay(onUnlock: () -> Unit) {
    val infinite = rememberInfiniteTransition(label = "lockPulse")
    val pulse by infinite.animateFloat(
        initialValue = 0.94f,
        targetValue = 1.08f,
        animationSpec = infiniteRepeatable(tween(1600), RepeatMode.Reverse),
        label = "pulse",
    )
    val ring by infinite.animateFloat(
        initialValue = 1f,
        targetValue = 1.8f,
        animationSpec = infiniteRepeatable(tween(2200), RepeatMode.Restart),
        label = "ring",
    )
    val ringAlpha by infinite.animateFloat(
        initialValue = 0.55f,
        targetValue = 0f,
        animationSpec = infiniteRepeatable(tween(2200), RepeatMode.Restart),
        label = "ringAlpha",
    )

    Box(
        modifier = Modifier
            .fillMaxSize()
            .clickable(
                indication = null,
                interactionSource = remember { MutableInteractionSource() },
                onClick = onUnlock,
            ),
        contentAlignment = Alignment.Center,
    ) {
        // Soft scrim so the teaser page stays readable underneath.
        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(DS.canvas.copy(alpha = 0.35f)),
        )

        Box(contentAlignment = Alignment.Center) {
            Box(
                modifier = Modifier
                    .size(92.dp)
                    .scale(ring)
                    .border(2.dp, DS.accent.copy(alpha = ringAlpha), CircleShape),
            )
            Box(
                modifier = Modifier
                    .size(120.dp)
                    .scale(pulse)
                    .background(DS.accent.copy(alpha = 0.10f), CircleShape)
                    .blur(20.dp),
            )
            Box(
                modifier = Modifier
                    .size(88.dp)
                    .background(DS.surface, CircleShape)
                    .border(1.dp, DS.hairline, CircleShape),
                contentAlignment = Alignment.Center,
            ) {
                Box(
                    modifier = Modifier
                        .size(62.dp)
                        .background(DS.accentTint, CircleShape),
                    contentAlignment = Alignment.Center,
                ) {
                    Icon(
                        imageVector = Icons.Filled.Lock,
                        contentDescription = null,
                        tint = DS.accent,
                        modifier = Modifier
                            .size(28.dp)
                            .scale(if (pulse > 1f) 1.04f else 1f),
                    )
                }
            }
        }
    }
}
