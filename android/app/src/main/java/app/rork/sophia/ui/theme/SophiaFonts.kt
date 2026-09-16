package app.rork.sophia.ui.theme

import androidx.compose.runtime.Composable
import androidx.compose.runtime.ReadOnlyComposable
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.text.ExperimentalTextApi
import androidx.compose.ui.text.font.DeviceFontFamilyName
import androidx.compose.ui.text.font.Font
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontVariation
import androidx.compose.ui.text.font.FontWeight
import app.rork.sophia.R
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.domain.uppercaseIn

/**
 * Plus Jakarta Sans, at the weights it actually ships.
 *
 * The file is a variable font with a `wght` axis from 200 to 800, but it was registered as a
 * single Normal face. Everything heavier was therefore *synthesised*: Compose smeared the
 * regular outlines, which is why bold titles looked muddy and slightly too wide next to the
 * same text on iOS. Naming each weight against the axis hands Compose the real design
 * instances instead. Variable-font settings on a resource font need API 26, which is the
 * app's minimum.
 */
private val JakartaSans = FontFamily(
    jakarta(FontWeight.ExtraLight, 200),
    jakarta(FontWeight.Light, 300),
    jakarta(FontWeight.Normal, 400),
    jakarta(FontWeight.Medium, 500),
    jakarta(FontWeight.SemiBold, 600),
    jakarta(FontWeight.Bold, 700),
    jakarta(FontWeight.ExtraBold, 800),
)

@OptIn(ExperimentalTextApi::class)
private fun jakarta(weight: FontWeight, axis: Int) = Font(
    resId = R.font.plus_jakarta_sans,
    weight = weight,
    variationSettings = FontVariation.Settings(FontVariation.weight(axis)),
)

/**
 * The platform's own sans, at the same weights.
 *
 * Plus Jakarta Sans covers Latin and nothing else: the file carries zero Cyrillic, zero
 * Hebrew and zero Arabic glyphs, and three Greek ones. Russian, Bulgarian, Greek and Hebrew
 * therefore rendered every letter through Android's per-glyph fallback while punctuation,
 * digits and any Latin word stayed in Jakarta — two typefaces in the same sentence, with two
 * different x-heights. One consistent face reads far better than a mixture, and the system
 * font covers all four scripts properly and in real weights.
 */
private val SystemSans = FontFamily(
    system(FontWeight.Light),
    system(FontWeight.Normal),
    system(FontWeight.Medium),
    system(FontWeight.SemiBold),
    system(FontWeight.Bold),
    system(FontWeight.ExtraBold),
)

@OptIn(ExperimentalTextApi::class)
private fun system(weight: FontWeight) = Font(
    familyName = DeviceFontFamilyName("sans-serif"),
    weight = weight,
)

/**
 * Languages whose script the bundled font cannot render at all.
 *
 * Serbian is not here on purpose: Sophia's `sr` table is written in Latin script, so it
 * reads correctly in Jakarta.
 */
private val NON_LATIN_SCRIPTS = setOf(
    AppLanguage.RUSSIAN,
    AppLanguage.BULGARIAN,
    AppLanguage.GREEK,
    AppLanguage.HEBREW,
    AppLanguage.ARABIC,
)

fun fontFamilyFor(language: AppLanguage): FontFamily =
    if (language in NON_LATIN_SCRIPTS) SystemSans else JakartaSans

/**
 * The language the user picked in Sophia, for the components that format text themselves.
 *
 * Without it, `String.uppercase()` used the *device* locale: a section label read "HİSTORY"
 * on a Turkish phone even when the app was in English, because Turkish uppercases `i` to a
 * dotted `İ`. The app's own language is the only correct answer here.
 */
val LocalAppLanguage = staticCompositionLocalOf { AppLanguage.DEFAULT }

/** Uppercase in the app's language rather than the phone's. */
@Composable
@ReadOnlyComposable
fun String.uppercaseInApp(): String = uppercaseIn(LocalAppLanguage.current)

/**
 * The family every Sophia text style resolves against. Provided once by [SophiaTheme] from
 * the language the user picked in the app, so a screen never has to ask.
 */
val LocalSophiaFontFamily = staticCompositionLocalOf { JakartaSans }

/** Shorthand kept for the call sites that name the font directly. */
val PlusJakartaSans: FontFamily
    @Composable
    @ReadOnlyComposable
    get() = LocalSophiaFontFamily.current
