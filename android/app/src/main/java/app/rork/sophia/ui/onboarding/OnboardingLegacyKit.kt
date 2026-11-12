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
import androidx.compose.foundation.ScrollState
import androidx.compose.foundation.background
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsPressedAsState
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.ReadOnlyComposable
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
import androidx.compose.ui.unit.TextUnit
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.rork.sophia.ui.theme.DS
import app.rork.sophia.ui.theme.DSLegacy
import app.rork.sophia.ui.theme.DSPalette
import app.rork.sophia.ui.theme.PlusJakartaSans
import kotlinx.coroutines.delay

/**
 * The onboarding kit as it was before « Elevate arrondi » (navy capsule CTA, extra-bold
 * titles), frozen for the steps that keep their old look: strengths, trial steps, reminder.
 * Do not use anywhere else; the current kit is [OV2] / [OnboardingCta].
 */
object OV2Legacy {
    // The light tokens, pinned: the onboarding is light-only (see `ForceLightAppearance`),
    // and these are read once, whenever the object first loads.
    val bg = DSPalette.Legacy.canvas
    val ink = DSPalette.Legacy.ink
    val inkSecondary = DSPalette.Legacy.inkSecondary
    val inkTertiary = DSPalette.Legacy.inkTertiary
    val accent = DSPalette.Legacy.accent
    val accentSoft = DSPalette.Legacy.accentSoft
    val surface = DSPalette.Legacy.surface
    val hairline = DSPalette.Legacy.hairline
    val warm = Color(0xFFE6B233)
    val danger = Color(0xFFDB5A5C)
    val success = DSPalette.Legacy.success

    // Composable getters: the family is resolved from the composition, so a Russian, Greek
    // or Hebrew reader gets one consistent typeface rather than Jakarta punctuation around
    // system-fallback letters.
    val title: TextStyle
        @Composable @ReadOnlyComposable
        get() = ov2LegacyStyle(FontWeight.ExtraBold, 27.sp, 34.sp, DSLegacy.ink)

    val titleLarge: TextStyle
        @Composable @ReadOnlyComposable
        get() = ov2LegacyStyle(FontWeight.ExtraBold, 34.sp, 40.sp, DSLegacy.ink)

    val headline: TextStyle
        @Composable @ReadOnlyComposable
        get() = ov2LegacyStyle(FontWeight.Bold, 17.sp, 23.sp, DSLegacy.ink)

    val body: TextStyle
        @Composable @ReadOnlyComposable
        get() = ov2LegacyStyle(FontWeight.Medium, 16.sp, 23.sp, DSLegacy.inkSecondary)

    val subheadline: TextStyle
        @Composable @ReadOnlyComposable
        get() = ov2LegacyStyle(FontWeight.Medium, 15.sp, 21.sp, DSLegacy.inkSecondary)

    val caption: TextStyle
        @Composable @ReadOnlyComposable
        get() = ov2LegacyStyle(FontWeight.SemiBold, 13.sp, TextUnit.Unspecified, DSLegacy.inkSecondary)
}

@Composable
@ReadOnlyComposable
private fun ov2LegacyStyle(
    weight: FontWeight,
    size: TextUnit,
    lineHeight: TextUnit,
    color: Color,
) = TextStyle(
    fontFamily = PlusJakartaSans,
    fontWeight = weight,
    fontSize = size,
    lineHeight = lineHeight,
    color = color,
)

object OV2LegacyShapes {
    val card = androidx.compose.foundation.shape.RoundedCornerShape(DSLegacy.Radius.card)
    val control = androidx.compose.foundation.shape.RoundedCornerShape(DSLegacy.Radius.control)
}


/** The capsule CTA of the onboarding before « Elevate arrondi », for the frozen steps. */
@Composable
fun OnboardingLegacyCta(
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
        animationSpec = OnboardingMotion.press(),
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
            containerColor = OV2Legacy.accent,
            contentColor = Color.White,
            disabledContainerColor = OV2Legacy.accent.copy(alpha = 0.35f),
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

