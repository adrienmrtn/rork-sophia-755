package app.rork.sophia.ui.theme

import android.app.Activity
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.ColorScheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Typography
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.ReadOnlyComposable
import androidx.compose.runtime.SideEffect
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.platform.LocalView
import androidx.core.view.WindowCompat
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.TextStyle
import app.rork.sophia.domain.AppLanguage

private fun sophiaColorScheme(dark: Boolean): ColorScheme {
    val p = if (dark) DSPalette.Dark else DSPalette.Light
    return if (dark) {
        darkColorScheme(
            primary = p.accent,
            onPrimary = Color.White,
            secondary = p.accentSoft,
            background = p.canvas,
            surface = p.surface,
            onBackground = p.ink,
            onSurface = p.ink,
            outline = p.hairline,
        )
    } else {
        lightColorScheme(
            primary = p.accent,
            onPrimary = Color.White,
            secondary = p.accentSoft,
            background = p.canvas,
            surface = p.surface,
            onBackground = p.ink,
            onSurface = p.ink,
            outline = p.hairline,
        )
    }
}

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
    // Automatic follows the phone: its mode is mirrored into the appearance state.
    val systemDark = isSystemInDarkTheme()
    SideEffect { SophiaAppearance.systemDark = systemDark }
    val dark = SophiaAppearance.isDark

    // Status- and navigation-bar icons: dark on the light canvas, light on the night one
    // and on a screen's dark backdrop.
    val lightBars = !dark && !SophiaAppearance.darkBackdropBehindBars
    val view = LocalView.current
    if (!view.isInEditMode) {
        SideEffect {
            val window = (view.context as? Activity)?.window ?: return@SideEffect
            val controller = WindowCompat.getInsetsController(window, view)
            controller.isAppearanceLightStatusBars = lightBars
            controller.isAppearanceLightNavigationBars = lightBars
            val canvas = if (dark) DSPalette.Dark.canvas else DSPalette.Light.canvas
            window.decorView.setBackgroundColor(canvas.toArgb())
        }
    }

    CompositionLocalProvider(
        LocalSophiaFontFamily provides fontFamilyFor(language),
        LocalAppLanguage provides language,
    ) {
        MaterialTheme(
            colorScheme = sophiaColorScheme(dark),
            typography = componentTypography(),
            content = content,
        )
    }
}
