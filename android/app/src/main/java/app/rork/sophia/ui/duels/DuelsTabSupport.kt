package app.rork.sophia.ui.duels

import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.drawWithContent
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.Layout
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.TextUnit
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.ui.theme.DS
import app.rork.sophia.ui.theme.PlusJakartaSans

// Ce qui sert à poser l'onglet Duels dans les deux navigations (classique et nouvelle
// génération), et le texte qui rétrécit pour tenir sur une ligne.

/**
 * L'index de l'onglet Duels, le même que sur iOS (`FeatureFlags.duelsTab`). Il est dessiné
 * entre Entraînement et Profil mais garde son propre numéro : les onglets existants (0 à 4)
 * ne sont pas renumérotés, donc le retour vers l'accueil, les liens profonds et l'onglet
 * Profil continuent de viser les mêmes index.
 */
const val DUELS_TAB_INDEX = 5

/**
 * Le contenu de l'onglet Duels, à poser dans la zone des onglets à côté des autres écrans.
 *
 * Rien n'est composé avant la première visite. Ensuite l'écran reste monté quand un autre
 * onglet est choisi, comme sur iOS (`keepsAlive`) : il garde sa position de défilement et la
 * route des ligues ouverte. Caché, il n'est pas placé : il n'est donc pas dessiné, ne reçoit
 * aucune touche et n'est pas lu par l'accessibilité.
 *
 * [selected] : l'onglet Duels est celui choisi ; [covered] : un écran est dessiné par-dessus
 * les onglets (paywall, lecteur audio…), l'onglet n'est alors pas « à l'écran » ; [flowShown] :
 * une partie est en cours par-dessus.
 */
@Composable
fun DuelsTabHost(
    language: AppLanguage,
    selected: Boolean,
    covered: Boolean,
    flowShown: Boolean,
    onPlay: () -> Unit,
    modifier: Modifier = Modifier,
) {
    var visited by remember { mutableStateOf(selected) }
    LaunchedEffect(selected) {
        if (selected) visited = true
    }
    if (!selected && !visited) return
    Layout(
        content = {
            DuelsHomeScreen(
                language = language,
                isActive = selected && !covered,
                flowShown = flowShown,
                onPlay = onPlay,
                modifier = modifier,
            )
        },
        modifier = Modifier.fillMaxSize(),
    ) { measurables, constraints ->
        val width = constraints.maxWidth
        val height = constraints.maxHeight
        val placeables = measurables.map { it.measure(constraints.copy(minWidth = 0, minHeight = 0)) }
        layout(width, height) {
            // Caché : mesuré mais pas placé. Un enfant non placé n'est pas dessiné, ne reçoit
            // pas les touches et sort de l'arbre d'accessibilité, sans quitter la composition.
            if (selected) {
                // Centré, comme les autres onglets sur une tablette (largeur bornée par [modifier]).
                placeables.forEach { it.place((width - it.width) / 2, 0) }
            }
        }
    }
}

/**
 * Un texte qui tient sur ses lignes : s'il déborde, sa taille diminue par crans jusqu'à
 * [minScale] fois la taille demandée, puis il est coupé par des points de suspension. C'est le
 * `minimumScaleFactor` d'iOS, pour les noms de ligue (« Michelangelo League » en 30) et les
 * libellés des statistiques. Rien n'est dessiné tant que la bonne taille n'est pas trouvée,
 * pour ne pas voir le texte rétrécir.
 */
@Composable
fun DuelFitText(
    text: String,
    fontSize: TextUnit,
    modifier: Modifier = Modifier,
    color: Color = DS.ink,
    fontWeight: FontWeight = FontWeight.ExtraBold,
    maxLines: Int = 1,
    minScale: Float = 0.6f,
) {
    var scale by remember(text, fontSize) { mutableFloatStateOf(1f) }
    var settled by remember(text, fontSize) { mutableStateOf(false) }
    Text(
        text = text,
        fontFamily = PlusJakartaSans,
        fontWeight = fontWeight,
        fontSize = fontSize * scale,
        color = color,
        maxLines = maxLines,
        softWrap = maxLines > 1,
        overflow = TextOverflow.Ellipsis,
        onTextLayout = { result ->
            val overflows = result.hasVisualOverflow ||
                (result.lineCount > 0 && result.isLineEllipsized(result.lineCount - 1))
            if (overflows && scale > minScale) {
                scale = maxOf(minScale, scale * 0.92f)
            } else {
                settled = true
            }
        },
        modifier = modifier.drawWithContent { if (settled) drawContent() },
    )
}
