package app.rork.sophia.ui.theme

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Typography
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.ReadOnlyComposable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.TextStyle
import app.rork.sophia.domain.AppLanguage

private val SophiaColorScheme = lightColorScheme(
    primary = DS.accent,
    onPrimary = Color.White,
    secondary = DS.accentSoft,
    background = DS.canvas,
    surface = DS.surface,
    onBackground = DS.ink,
    onSurface = DS.ink,
    outline = DS.hairline,
)

/**
 * [SophiaTypography] bakes a colour into every style, which is fine where a screen
 * asks for it explicitly but wrong as a theme default: Material resolves a text
 * style before `LocalContentColor`, so a baked-in [DS.ink] beat a Button's
 * `contentColor` and painted near-black labels on the dark blue accent buttons.
 * Components get the same type scale with the colour left to the caller.
 */
@Composable
@ReadOnlyComposable
private fun componentTypography(): Typography {
    val sophia = SophiaTypography
    return Typography(
        displayLarge = sophia.displayLarge.uncolored(),
        titleLarge = sophia.titleLarge.uncolored(),
        titleMedium = sophia.titleMedium.uncolored(),
        bodyLarge = sophia.bodyLarge.uncolored(),
        bodyMedium = sophia.bodyMedium.uncolored(),
        labelLarge = sophia.labelLarge.uncolored(),
        labelMedium = sophia.labelMedium.uncolored(),
    )
}

private fun TextStyle.uncolored() = copy(color = Color.Unspecified)

@Composable
fun SophiaTheme(language: AppLanguage, content: @Composable () -> Unit) {
    CompositionLocalProvider(
        LocalSophiaFontFamily provides fontFamilyFor(language),
        LocalAppLanguage provides language,
    ) {
        MaterialTheme(
            colorScheme = SophiaColorScheme,
            typography = componentTypography(),
            content = content,
        )
    }
}
