package app.rork.sophia.ui.theme

import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Typography
import androidx.compose.runtime.Composable
import androidx.compose.runtime.Immutable
import androidx.compose.runtime.ReadOnlyComposable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
/** One set of the design tokens. iOS resolves the same pairs from its trait collection. */
@Immutable
class DSPalette(
    val canvas: Color,
    val surface: Color,
    val surfaceMuted: Color,
    val ink: Color,
    val inkSecondary: Color,
    val inkTertiary: Color,
    val accent: Color,
    val accentSoft: Color,
    val accentTint: Color,
    val hairline: Color,
    val success: Color,
    val successTint: Color,
    val danger: Color,
    val dangerTint: Color,
    val warm: Color,
) {
    companion object {
        val Light = DSPalette(
            canvas = Color(0xFFF7F8FA),
            surface = Color.White,
            surfaceMuted = Color(0xFFE9EFF8),
            ink = Color(0xFF16263D),
            inkSecondary = Color(0xFF55637A),
            inkTertiary = Color(0xFF9AA4B2),
            accent = Color(0xFF1A3A6B),
            accentSoft = Color(0xFF2E62C4),
            accentTint = Color(0xFFE9EFF8),
            hairline = Color(0xFFE4E7EC),
            success = Color(0xFF387D5A),
            successTint = Color(0xFFE0EDED),
            danger = Color(0xFFB14F42),
            dangerTint = Color(0xFFF6E7E4),
            warm = Color(0xFFE6B233),
        )

        /** The iOS Night palette (`DesignSystem.swift`), value for value. */
        val Dark = DSPalette(
            canvas = Color(0xFF121721),
            surface = Color(0xFF1E2531),
            surfaceMuted = Color(0xFF252F3F),
            ink = Color(0xFFECEFF4),
            inkSecondary = Color(0xFFA7B2C1),
            inkTertiary = Color(0xFF798596),
            accent = Color(0xFF4F7DDA),
            accentSoft = Color(0xFF7AA7F5),
            accentTint = Color(0xFF25324C),
            hairline = Color(0xFF363F4F),
            success = Color(0xFF61B082),
            successTint = Color(0xFF21372D),
            danger = Color(0xFFE37466),
            dangerTint = Color(0xFF422624),
            warm = Color(0xFFF2C252),
        )
    }
}

/**
 * Design tokens. The colours follow [SophiaAppearance]: each read picks the light or the
 * night value, and is observed, so a screen redraws when the appearance changes.
 */
object DS {
    val palette: DSPalette get() = if (SophiaAppearance.isDark) DSPalette.Dark else DSPalette.Light

    val canvas: Color get() = palette.canvas
    val surface: Color get() = palette.surface
    val surfaceMuted: Color get() = palette.surfaceMuted

    val ink: Color get() = palette.ink
    val inkSecondary: Color get() = palette.inkSecondary
    val inkTertiary: Color get() = palette.inkTertiary

    val accent: Color get() = palette.accent
    val accentSoft: Color get() = palette.accentSoft
    val accentTint: Color get() = palette.accentTint

    val hairline: Color get() = palette.hairline

    val success: Color get() = palette.success
    val successTint: Color get() = palette.successTint
    val danger: Color get() = palette.danger
    val dangerTint: Color get() = palette.dangerTint
    val warm: Color get() = palette.warm

    object Radius {
        val card = 22.dp
        val control = 16.dp
        val small = 12.dp
    }

    object Space {
        val xs = 6.dp
        val s = 12.dp
        val m = 16.dp
        val l = 20.dp
        val xl = 28.dp
    }

    val cardShape = RoundedCornerShape(Radius.card)
    val controlShape = RoundedCornerShape(Radius.control)
}

/**
 * Reads the font family from the composition rather than naming it, so a language whose
 * script Plus Jakarta Sans cannot render gets one consistent typeface instead of a mixture.
 * Cheap to re-read: `Typography` is a value type and the family is a static local.
 */
val SophiaTypography: Typography
    @Composable
    @ReadOnlyComposable
    get() = typographyFor(LocalSophiaFontFamily.current)

private fun typographyFor(family: androidx.compose.ui.text.font.FontFamily) = Typography(
    displayLarge = TextStyle(
        fontFamily = family,
        fontWeight = FontWeight.ExtraBold,
        fontSize = 34.sp,
        color = DS.ink,
    ),
    titleLarge = TextStyle(
        fontFamily = family,
        fontWeight = FontWeight.ExtraBold,
        fontSize = 22.sp,
        color = DS.ink,
    ),
    titleMedium = TextStyle(
        fontFamily = family,
        fontWeight = FontWeight.Bold,
        fontSize = 18.sp,
        color = DS.ink,
    ),
    bodyLarge = TextStyle(
        fontFamily = family,
        fontWeight = FontWeight.Normal,
        fontSize = 17.sp,
        color = DS.ink,
        lineHeight = 24.sp,
    ),
    bodyMedium = TextStyle(
        fontFamily = family,
        fontWeight = FontWeight.Normal,
        fontSize = 15.sp,
        color = DS.inkSecondary,
        lineHeight = 22.sp,
    ),
    labelLarge = TextStyle(
        fontFamily = family,
        fontWeight = FontWeight.SemiBold,
        fontSize = 16.sp,
        color = DS.ink,
    ),
    labelMedium = TextStyle(
        fontFamily = family,
        fontWeight = FontWeight.Medium,
        fontSize = 13.sp,
        color = DS.inkSecondary,
    ),
)
