package app.rork.sophia.ui.duels

import android.content.Context
import android.os.Build
import android.view.HapticFeedbackConstants
import android.view.View
import androidx.compose.animation.core.Spring
import androidx.compose.animation.core.animateDpAsState
import androidx.compose.animation.core.spring
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsPressedAsState
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.MenuBook
import androidx.compose.material.icons.filled.AccountBalance
import androidx.compose.material.icons.filled.Bolt
import androidx.compose.material.icons.filled.EmojiEvents
import androidx.compose.material.icons.filled.HelpOutline
import androidx.compose.material.icons.filled.Palette
import androidx.compose.material.icons.filled.Public
import androidx.compose.material.icons.filled.Science
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.rork.sophia.data.CourseImagePrefetch
import app.rork.sophia.data.StringStore
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.domain.DuelLeague
import app.rork.sophia.domain.locale
import app.rork.sophia.ui.newgen.AvatarCircle
import app.rork.sophia.ui.theme.PlusJakartaSans
import coil.compose.AsyncImage
import coil.request.ImageRequest
import java.text.NumberFormat

// Les briques visuelles des duels, partagées par l'accueil, la partie et le résultat.
// Mêmes couleurs et mêmes proportions que `ios/Sophia/Views/Duels/DuelComponents.swift`.

/** Les couleurs propres aux duels, identiques de jour comme de nuit. */
object DuelPalette {
    val saffron = Color(0xFFF2B134)
    val coral = Color(0xFFE05A3A)
    val navy = Color(0xFF1A3A6B)
    val cream = Color(0xFFFBF7EF)
    val night = Color(0xFF0E192E)

    /** Un point marqué, un score qui monte. */
    val scored = Color(0xFF5CCC8F)
    val online = Color(0xFF40C778)

    /** La tranche sombre sous le grand bouton. */
    val playEdge = Color(0xFFBD8014)
    val confetti = listOf(saffron, coral, navy, cream, Color(0xFF5C9EDB))
}

/** Une couleur « #RRGGBB » envoyée par le serveur ; la couleur de marque si elle est illisible. */
fun duelColor(hex: String?): Color {
    val clean = hex.orEmpty().trim().removePrefix("#")
    val isHex = clean.length == 6 && clean.all { it in '0'..'9' || it in 'a'..'f' || it in 'A'..'F' }
    val value = clean.takeIf { isHex }?.toLongOrNull(16) ?: return DuelPalette.navy
    return Color(0xFF000000 or value)
}

/** Une matière de manche (clé du serveur) : son nom, son icône et sa couleur. */
data class DuelSubject(val name: String, val icon: ImageVector, val color: Color)

object DuelSubjects {
    fun of(key: String): DuelSubject = when (key) {
        "history" -> DuelSubject("History", Icons.Filled.AccountBalance, Color(0xFFF59E0A))
        "science" -> DuelSubject("Science", Icons.Filled.Science, Color(0xFF33D499))
        "literature" -> DuelSubject("Literature", Icons.AutoMirrored.Filled.MenuBook, Color(0xFFED5973))
        "art" -> DuelSubject("Art", Icons.Filled.Palette, Color(0xFFD98CF2))
        "mythology" -> DuelSubject("Mythology", Icons.Filled.Bolt, Color(0xFF8F66EB))
        "world" -> DuelSubject("Understanding today's world", Icons.Filled.Public, Color(0xFF40B8D9))
        else -> DuelSubject(key.replaceFirstChar { it.uppercase() }, Icons.Filled.HelpOutline, DuelPalette.saffron)
    }
}

/** Textes calculés des duels. */
object DuelFormat {
    /** « Vermeer League », « Ligue Vermeer » : le nom d'une ligue dans la langue de l'app. */
    fun leagueName(context: Context, league: DuelLeague?, language: AppLanguage): String =
        league?.let { StringStore.text(context, "duel.league.name", language, it.name) }.orEmpty()

    /** Un nombre de trophées groupé à la façon de la langue : 1,250 ou 1 250. */
    fun number(value: Int, language: AppLanguage): String =
        NumberFormat.getIntegerInstance(language.locale).format(value)

    /** La valeur d'un curseur avec son unité : « 1492 », « 71 % », « 206 bones ». */
    fun sliderValue(value: Double, unit: String?): String {
        val number = if (value == Math.rint(value)) value.toLong().toString() else String.format(java.util.Locale.US, "%.1f", value)
        return when (unit) {
            null, "", "year" -> number
            "%" -> "$number %"
            // Un compteur japonais (日, 冊, か国…) se colle au nombre : « 13植民地 ».
            else -> {
                val first = unit?.firstOrNull()?.code ?: 0
                if (first in 0x3040..0x30FF || first in 0x4E00..0x9FFF) "$number$unit" else "$number $unit"
            }
        }
    }
}

/** L'icône de trophée, en safran. */
@Composable
fun DuelTrophyIcon(size: Dp, modifier: Modifier = Modifier, tint: Color = DuelPalette.saffron) {
    Icon(Icons.Filled.EmojiEvents, contentDescription = null, tint = tint, modifier = modifier.size(size))
}

/** Un nombre de trophées précédé de l'icône. */
@Composable
fun DuelTrophyCount(
    value: Int,
    language: AppLanguage,
    modifier: Modifier = Modifier,
    size: Dp = 16.dp,
    color: Color = Color.White,
) {
    val context = LocalContext.current
    val label = StringStore.text(context, "duel.trophies.count", language, value)
    Row(
        modifier = modifier.clearAndSetSemantics { contentDescription = label },
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(size * 0.3f),
    ) {
        DuelTrophyIcon(size = size * 1.15f)
        Text(
            text = DuelFormat.number(value, language),
            fontFamily = PlusJakartaSans,
            fontWeight = FontWeight.Bold,
            fontSize = size.value.sp,
            color = color,
            maxLines = 1,
        )
    }
}

/** L'avatar d'un joueur (ou son initiale), cerclé d'un anneau. */
@Composable
fun DuelAvatar(
    avatarId: String?,
    initial: String,
    size: Dp,
    modifier: Modifier = Modifier,
    ring: Color = Color.White,
    ringWidth: Dp = 3.dp,
) {
    Box(
        modifier = modifier
            .shadow(8.dp, CircleShape, clip = false)
            .size(size)
            .border(ringWidth, ring, CircleShape)
            .padding(ringWidth),
        contentAlignment = Alignment.Center,
    ) {
        AvatarCircle(avatarId = avatarId, initial = initial, size = size - ringWidth * 2)
    }
}

/** La pastille verte d'un ami qui a l'app ouverte. */
@Composable
fun DuelOnlineDot(size: Dp, modifier: Modifier = Modifier) {
    val border = maxOf(size.value * 0.16f, 1.5f).dp
    Box(
        modifier = modifier
            .size(size)
            .background(Color.White, CircleShape)
            .padding(border)
            .background(DuelPalette.online, CircleShape),
    )
}

/**
 * Le fond d'une ligue : sa couleur d'accent tout de suite, puis son illustration qui remplit le
 * cadre. Purement décoratif : ne prend pas les touches et n'est pas lu par l'accessibilité.
 */
@Composable
fun DuelLeagueBackdrop(league: DuelLeague?, modifier: Modifier = Modifier, thumb: Boolean = false) {
    val context = LocalContext.current
    val url = if (thumb) league?.thumbUrl else league?.backgroundUrl
    Box(modifier = modifier.background(duelColor(league?.accentHex))) {
        if (!url.isNullOrEmpty()) {
            val request = remember(url) {
                ImageRequest.Builder(context)
                    .data(url)
                    // Décodée à la taille utile, comme les images de cours : une illustration de
                    // ligue entière ne doit pas chasser les couvertures du cache en mémoire.
                    .size(CourseImagePrefetch.targetPx(context))
                    .allowHardware(false)
                    .crossfade(true)
                    .build()
            }
            AsyncImage(
                model = request,
                contentDescription = null,
                contentScale = ContentScale.Crop,
                modifier = Modifier.fillMaxSize(),
            )
        }
    }
}

/** Jauge pleine largeur : vers la ligue suivante, ou le temps qui reste. */
@Composable
fun DuelProgressBar(
    progress: Float,
    modifier: Modifier = Modifier,
    tint: Color = DuelPalette.saffron,
    track: Color = Color.White.copy(alpha = 0.28f),
    height: Dp = 10.dp,
) {
    Box(modifier = modifier.fillMaxWidth().height(height).clip(CircleShape).background(track)) {
        // Jamais plus étroite que haute : à zéro, il reste un point de couleur au départ.
        Box(
            modifier = Modifier
                .fillMaxWidth(progress.coerceIn(0f, 1f))
                .widthIn(min = height)
                .height(height)
                .clip(CircleShape)
                .background(tint),
        )
    }
}

/**
 * Le grand bouton des duels : un aplat safran posé sur une tranche plus sombre, qui s'enfonce
 * sous le doigt.
 */
@Composable
fun DuelPlayButton(
    text: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
    leadingIcon: ImageVector? = null,
    fill: Color = DuelPalette.saffron,
    edge: Color = DuelPalette.playEdge,
    foreground: Color = DuelPalette.night,
) {
    val interaction = remember { MutableInteractionSource() }
    val pressed by interaction.collectIsPressedAsState()
    val drop by animateDpAsState(
        targetValue = if (pressed) 5.dp else 0.dp,
        animationSpec = spring(dampingRatio = 0.7f, stiffness = Spring.StiffnessMedium),
        label = "duelPlayPress",
    )
    val shape = RoundedCornerShape(20.dp)
    Box(
        modifier = modifier
            .fillMaxWidth()
            .padding(bottom = 6.dp)
            .semantics(mergeDescendants = true) {}
            .clickable(interactionSource = interaction, indication = null, enabled = enabled, onClick = onClick),
    ) {
        // La tranche, fixe, puis le dessus qui descend dessus.
        Box(modifier = Modifier.matchParentSize().offset(y = 6.dp).clip(shape).background(edge))
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .offset(y = drop)
                .clip(shape)
                .background(if (enabled) fill else fill.copy(alpha = 0.55f))
                .padding(vertical = 18.dp, horizontal = 16.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.Center,
        ) {
            if (leadingIcon != null) {
                Icon(leadingIcon, contentDescription = null, tint = foreground, modifier = Modifier.size(20.dp))
                Box(modifier = Modifier.width(10.dp))
            }
            Text(
                text = text,
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.ExtraBold,
                fontSize = 19.sp,
                color = foreground,
                maxLines = 1,
            )
        }
    }
}

// ---------------------------------------------------------------- vibrations

/**
 * Les vibrations des duels. Android n'a pas les générateurs d'iOS : chaque évènement prend le
 * retour haptique système le plus proche, et les évènements forts en enchaînent deux ou trois.
 */
enum class DuelHaptic {
    Tap, Tick, Lock, OpponentAnswered, Correct, Wrong, Clock, Countdown, CountdownFinal,
    OpponentFound, SuddenDeath, Victory, Defeat, TrophyTick, TrophyLanded, Promotion,
}

fun View.duelHaptic(kind: DuelHaptic) {
    val confirm = if (Build.VERSION.SDK_INT >= 30) HapticFeedbackConstants.CONFIRM else HapticFeedbackConstants.VIRTUAL_KEY
    val reject = if (Build.VERSION.SDK_INT >= 30) HapticFeedbackConstants.REJECT else HapticFeedbackConstants.LONG_PRESS
    val light = HapticFeedbackConstants.KEYBOARD_TAP
    val tick = HapticFeedbackConstants.CLOCK_TICK
    val medium = HapticFeedbackConstants.VIRTUAL_KEY
    val heavy = HapticFeedbackConstants.LONG_PRESS
    // (délai en ms, retour) : le premier part tout de suite, les suivants à leur délai.
    val pattern: List<Pair<Long, Int>> = when (kind) {
        DuelHaptic.Tap -> listOf(0L to light)
        DuelHaptic.Tick, DuelHaptic.TrophyTick -> listOf(0L to tick)
        DuelHaptic.Lock -> listOf(0L to medium)
        DuelHaptic.OpponentAnswered -> listOf(0L to tick)
        DuelHaptic.Correct -> listOf(0L to confirm)
        DuelHaptic.Wrong -> listOf(0L to reject)
        DuelHaptic.Clock -> listOf(0L to light)
        DuelHaptic.Countdown -> listOf(0L to medium)
        DuelHaptic.CountdownFinal -> listOf(0L to heavy, 70L to medium)
        DuelHaptic.OpponentFound -> listOf(0L to heavy, 90L to medium, 200L to tick)
        DuelHaptic.SuddenDeath -> listOf(0L to reject, 180L to heavy)
        DuelHaptic.Victory -> listOf(0L to confirm, 140L to heavy, 280L to medium, 420L to medium)
        DuelHaptic.Defeat -> listOf(0L to heavy, 200L to tick)
        DuelHaptic.TrophyLanded -> listOf(0L to medium)
        DuelHaptic.Promotion -> listOf(0L to confirm, 90L to medium, 180L to medium, 270L to medium, 360L to medium, 600L to heavy)
    }
    for ((delay, constant) in pattern) {
        if (delay == 0L) performHapticFeedback(constant) else postDelayed({ performHapticFeedback(constant) }, delay)
    }
}
