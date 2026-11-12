package app.rork.sophia.ui.onboarding

import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.spring
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.size
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.drawWithContent
import androidx.compose.ui.graphics.TransformOrigin
import androidx.compose.ui.graphics.drawscope.clipRect
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalLayoutDirection
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.unit.LayoutDirection
import androidx.compose.ui.unit.dp
import app.rork.sophia.R
import app.rork.sophia.ui.components.DSMotion
import app.rork.sophia.ui.components.rememberHaptics
import app.rork.sophia.ui.theme.DS
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

/** How long the animated logo plays before its veil starts to lift, in milliseconds. */
internal const val ONBOARDING_SPLASH_MILLIS = 1500

/** Proportions of the `sophia_mark` picture (1192 × 334). */
private const val LOGO_ASPECT = 1192f / 334f

/** Share of the width taken by the symbol, on the left of the word. */
private const val MARK_FRACTION = 0.247f

/**
 * Screen 0 — the animated logo, played once over the welcome page when the onboarding opens
 * on it (iOS `OnboardingV2Splash`): the symbol appears in the middle with a small bounce,
 * slides to the left, and the word « Sophia » unrolls on its right. [onFinished] is called
 * once; the coordinator then lifts the veil.
 */
@Composable
internal fun OnboardingSplash(onFinished: () -> Unit, modifier: Modifier = Modifier) {
    val reduceMotion = rememberOnboardingReduceMotion()
    val haptics = rememberHaptics()
    val finished = rememberUpdatedState(onFinished)
    val markScale = remember { Animatable(if (reduceMotion) 1f else 0.86f) }
    // 1 while the symbol sits alone in the middle, 0 once the whole logo is laid out.
    val centered = remember { Animatable(if (reduceMotion) 0f else 1f) }

    LaunchedEffect(Unit) {
        if (reduceMotion) {
            // No movement: the whole logo, for a short moment.
            delay(700)
            finished.value()
            return@LaunchedEffect
        }
        launch { markScale.animateTo(1f, DSMotion.pop()) }
        delay(550)
        launch { centered.animateTo(0f, spring(dampingRatio = 0.82f, stiffness = 110f)) }
        haptics.soft()
        delay((ONBOARDING_SPLASH_MILLIS - 550).toLong())
        finished.value()
    }

    val logoWidth = 212.dp
    val logoHeight = logoWidth / LOGO_ASPECT
    val painter = painterResource(R.drawable.sophia_mark)
    Box(
        modifier = modifier
            .fillMaxSize()
            .background(DS.canvas)
            // The veil keeps the taps: nothing under it can be pressed before it lifts.
            .pointerInput(Unit) { detectTapGestures { } }
            .clearAndSetSemantics { contentDescription = "Sophia" },
        contentAlignment = Alignment.Center,
    ) {
        // The logo is a drawing: it does not flip in a right-to-left language.
        CompositionLocalProvider(LocalLayoutDirection provides LayoutDirection.Ltr) {
            Box(modifier = Modifier.size(width = logoWidth, height = logoHeight)) {
                // The word: the logo masked to its right part, uncovered from left to right.
                Image(
                    painter = painter,
                    contentDescription = null,
                    contentScale = ContentScale.Fit,
                    modifier = Modifier
                        .fillMaxSize()
                        .graphicsLayer {
                            val shown = 1f - centered.value
                            alpha = shown.coerceIn(0f, 1f)
                            translationX = -18.dp.toPx() * centered.value
                        }
                        .drawWithContent {
                            val markWidth = size.width * MARK_FRACTION
                            val reveal = (1f - centered.value).coerceIn(0f, 1f)
                            clipRect(left = markWidth, right = markWidth + (size.width - markWidth) * reveal) {
                                this@drawWithContent.drawContent()
                            }
                        },
                )
                // The symbol alone: the logo masked to its left part, first centred in the frame.
                Image(
                    painter = painter,
                    contentDescription = null,
                    contentScale = ContentScale.Fit,
                    modifier = Modifier
                        .fillMaxSize()
                        .graphicsLayer {
                            transformOrigin = TransformOrigin(MARK_FRACTION / 2f, 0.5f)
                            scaleX = markScale.value
                            scaleY = markScale.value
                            translationX = size.width * (1f - MARK_FRACTION) / 2f * centered.value
                        }
                        .drawWithContent {
                            clipRect(right = size.width * MARK_FRACTION) {
                                this@drawWithContent.drawContent()
                            }
                        },
                )
            }
        }
    }
}
