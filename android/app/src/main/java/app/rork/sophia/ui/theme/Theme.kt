package app.rork.sophia.ui.theme

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color

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

@Composable
fun SophiaTheme(content: @Composable () -> Unit) {
    MaterialTheme(
        colorScheme = SophiaColorScheme,
        typography = SophiaTypography,
        content = content,
    )
}
