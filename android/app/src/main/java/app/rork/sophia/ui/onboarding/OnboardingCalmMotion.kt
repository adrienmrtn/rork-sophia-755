package app.rork.sophia.ui.onboarding

import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.FiniteAnimationSpec
import androidx.compose.animation.core.LinearOutSlowInEasing
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.graphicsLayer
import kotlinx.coroutines.delay

/**
 * Les mouvements « posés » du début de l'onboarding : des courbes qui décélèrent et
 * s'arrêtent net, sans rebond. Elles remplacent, sur ces pages, les ressorts rebondissants
 * de `DSMotion` (`pop`, `snappy`, `press`), qui restent ceux du reste de l'app.
 */
internal object OV2Calm {
    /** Un élément qui se pose (carte, portrait, badge) : à la place de `DSMotion.pop()`. */
    fun <T> settle(): FiniteAnimationSpec<T> = tween(durationMillis = 280, easing = LinearOutSlowInEasing)

    /** Un changement d'état bref (sélection, pastille, glissement d'un rang) : à la place de `DSMotion.snappy()`. */
    fun <T> quick(): FiniteAnimationSpec<T> = tween(durationMillis = 200, easing = FastOutSlowInEasing)
}

/**
 * Apparition douce d'une illustration : un fondu et un léger grossissement (0,9 → 1), sans
 * rebond. Remplace `dsPopIn` sur ces pages.
 */
@Composable
internal fun Modifier.ov2CalmIn(delayMillis: Int = 0): Modifier {
    var shown by remember { mutableStateOf(false) }
    LaunchedEffect(Unit) {
        delay(delayMillis.toLong())
        shown = true
    }
    val progress by animateFloatAsState(if (shown) 1f else 0f, OV2Calm.settle(), label = "calmIn")
    return this.graphicsLayer {
        alpha = progress
        val scale = 0.9f + 0.1f * progress
        scaleX = scale
        scaleY = scale
    }
}
