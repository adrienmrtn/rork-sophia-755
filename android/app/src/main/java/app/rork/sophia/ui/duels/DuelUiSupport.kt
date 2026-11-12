package app.rork.sophia.ui.duels

import android.content.Context
import androidx.compose.animation.core.SpringSpec
import androidx.compose.animation.core.spring
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.displayCutout
import androidx.compose.foundation.layout.systemBars
import androidx.compose.foundation.layout.union
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.layout
import androidx.compose.ui.platform.LocalLayoutDirection
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Constraints
import androidx.compose.ui.unit.TextUnit
import androidx.compose.ui.unit.sp
import app.rork.sophia.data.CourseImagePrefetch
import app.rork.sophia.ui.theme.PlusJakartaSans
import coil.request.ImageRequest

// De quoi écrire les écrans d'une partie au plus près d'iOS : ses ressorts, ses fonds qui passent
// sous les barres du système, ses textes qui rétrécissent plutôt que d'être coupés.

/**
 * Un ressort décrit comme sur iOS : `response` (la durée d'une oscillation, en secondes) et
 * l'amortissement. Compose demande une raideur : (2π / response)² pour une masse de 1.
 */
internal fun <T> duelSpring(response: Float, damping: Float): SpringSpec<T> {
    val omega = (2 * Math.PI / response).toFloat()
    return spring(dampingRatio = damping, stiffness = omega * omega)
}

/** Les chiffres à largeur fixe : un score ou un chrono qui change ne fait pas bouger le reste. */
internal val DuelTabularDigits = TextStyle(fontFeatureSettings = "tnum")

/**
 * Étend un fond jusque sous la barre d'état et la barre de navigation. La racine de l'app
 * réserve déjà ces marges pour tous les écrans ; l'illustration d'une ligue, elle, doit remplir
 * l'écran comme sur iOS. Le composant est mesuré plus grand que sa place, puis décalé d'autant.
 * Ne sert qu'à un fond qui occupe tout l'écran d'une partie.
 */
@Composable
internal fun Modifier.duelUnderSystemBars(): Modifier {
    val insets = WindowInsets.systemBars.union(WindowInsets.displayCutout)
    val direction = LocalLayoutDirection.current
    return this.layout { measurable, constraints ->
        if (!constraints.hasBoundedWidth || !constraints.hasBoundedHeight) {
            val placeable = measurable.measure(constraints)
            return@layout layout(placeable.width, placeable.height) { placeable.place(0, 0) }
        }
        val left = insets.getLeft(this, direction)
        val top = insets.getTop(this)
        val right = insets.getRight(this, direction)
        val bottom = insets.getBottom(this)
        val placeable = measurable.measure(
            Constraints.fixed(constraints.maxWidth + left + right, constraints.maxHeight + top + bottom),
        )
        layout(constraints.maxWidth, constraints.maxHeight) { placeable.place(-left, -top) }
    }
}

/**
 * La requête d'une image de question, la même pour le préchargement (pendant la présentation
 * de l'adversaire) et pour l'affichage : l'image est alors déjà en mémoire quand sa question
 * arrive.
 */
internal fun duelQuestionImageRequest(context: Context, url: String): ImageRequest =
    ImageRequest.Builder(context.applicationContext)
        .data(url)
        .size(CourseImagePrefetch.targetPx(context))
        .allowHardware(false)
        .crossfade(false)
        // Un drapeau arrive avec une marge beige cuite dans son fichier : elle est rognée.
        .transformations(DuelTrimTransformation())
        .build()

/**
 * Un texte qui rétrécit (jusqu'à 75 % de sa taille) avant d'être coupé, comme le
 * `minimumScaleFactor` d'iOS : un pseudo long, une réponse de deux lignes un peu trop longue.
 */
@Composable
internal fun DuelShrinkText(
    text: String,
    fontSize: TextUnit,
    fontWeight: FontWeight,
    color: Color,
    modifier: Modifier = Modifier,
    maxLines: Int = 1,
    textAlign: TextAlign? = null,
    minScale: Float = 0.75f,
    letterSpacing: TextUnit = TextUnit.Unspecified,
) {
    var scale by remember(text, fontSize) { mutableFloatStateOf(1f) }
    Text(
        text = text,
        modifier = modifier,
        color = color,
        maxLines = maxLines,
        overflow = TextOverflow.Ellipsis,
        textAlign = textAlign,
        style = TextStyle(
            fontFamily = PlusJakartaSans,
            fontWeight = fontWeight,
            fontSize = (fontSize.value * scale).sp,
            lineHeight = (fontSize.value * scale * 1.25f).sp,
            letterSpacing = letterSpacing,
        ),
        onTextLayout = { layout ->
            // Trop long pour ses lignes, ou un mot coupé en deux (« Rembrand / t ») : on réduit.
            val splitsWord = (0 until layout.lineCount - 1).any { line ->
                val end = layout.getLineEnd(line)
                end in 1 until text.length && text[end - 1].isLetterOrDigit() && text[end].isLetterOrDigit()
            }
            if ((layout.hasVisualOverflow || splitsWord) && scale > minScale) {
                scale = maxOf(scale - 0.09f, minScale)
            }
        },
    )
}
