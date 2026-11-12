package app.rork.sophia.ui.duels

import android.content.Context
import android.os.Build
import android.os.SystemClock
import android.view.HapticFeedbackConstants
import android.view.View
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.shape.CircleShape
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
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.role
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.rork.sophia.data.CourseImagePrefetch
import app.rork.sophia.data.StringStore
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.domain.DuelLeague
import app.rork.sophia.domain.locale
import app.rork.sophia.ui.components.pressable
import app.rork.sophia.ui.newgen.AvatarCircle
import app.rork.sophia.ui.theme.DS
import app.rork.sophia.ui.theme.PlusJakartaSans
import coil.compose.AsyncImage
import coil.request.ImageRequest
import java.text.NumberFormat

// Les briques visuelles des duels, partagées par l'accueil, la partie et le résultat.
// Mêmes couleurs et mêmes proportions que `ios/Sophia/Views/Duels/DuelComponents.swift`.

/**
 * Les couleurs des illustrations : celles des ligues, des trophées et des médailles. Le reste
 * de l'interface des duels passe par les jetons `DS` (et [DuelTheme] pour l'écran de jeu).
 */
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
            fontWeight = FontWeight.ExtraBold,
            fontSize = size.value.sp,
            style = DuelTabularDigits,
            color = color,
            maxLines = 1,
        )
    }
}

/**
 * L'avatar d'un joueur (ou son initiale), cerclé d'un liseré : la couleur de son camp. Sans
 * ombre : le style « Elevate arrondi » sépare par des bordures.
 */
@Composable
fun DuelAvatar(
    avatarId: String?,
    initial: String,
    size: Dp,
    modifier: Modifier = Modifier,
    ring: Color = Color.White,
    ringWidth: Dp = 3.dp,
) {
    Box(modifier = modifier.size(size), contentAlignment = Alignment.Center) {
        AvatarCircle(avatarId = avatarId, initial = initial, size = size)
        Box(modifier = Modifier.matchParentSize().border(ringWidth, ring, CircleShape))
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
 * Le grand bouton des duels : le CTA plein du style « Elevate arrondi » (rectangle arrondi
 * bleu, texte blanc, pression élastique). Il ne vibre pas de lui-même : chaque appel choisit sa
 * vibration ([duelHaptic]), plus appuyée pour lancer une partie.
 *
 * [edge] est gardé pour les appels existants : le style arrondi n'a plus de tranche sous le
 * bouton.
 */
@Composable
fun DuelPlayButton(
    text: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
    leadingIcon: ImageVector? = null,
    fill: Color = DS.accent,
    @Suppress("UNUSED_PARAMETER") edge: Color = Color.Transparent,
    foreground: Color = Color.White,
) {
    Row(
        modifier = modifier
            .fillMaxWidth()
            .semantics(mergeDescendants = true) { role = Role.Button }
            .pressable(onClick = onClick, enabled = enabled, scaleDown = 0.96f, haptic = false)
            .clip(DS.controlShape)
            .background(if (enabled) fill else fill.copy(alpha = 0.55f))
            .padding(vertical = 17.dp, horizontal = 12.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.Center,
    ) {
        if (leadingIcon != null) {
            Icon(leadingIcon, contentDescription = null, tint = foreground, modifier = Modifier.size(18.dp))
            Box(modifier = Modifier.width(8.dp))
        }
        Text(
            text = text,
            fontFamily = PlusJakartaSans,
            fontWeight = FontWeight.SemiBold,
            fontSize = 17.sp,
            color = foreground,
            maxLines = 2,
            textAlign = TextAlign.Center,
        )
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

/** L'instant du dernier avertissement de chrono (horloge de l'appareil, ms). */
private var lastClockWarningMs = 0L

fun View.duelHaptic(kind: DuelHaptic) {
    if (kind == DuelHaptic.Clock) {
        // Le déroulé appelle ce cran à 3, 2 puis 1 seconde : seul le premier vibre (un
        // avertissement par question, pas une rafale), comme `DuelHaptics.clock` sur iOS.
        val now = SystemClock.elapsedRealtime()
        if (now - lastClockWarningMs <= 2_500L) return
        lastClockWarningMs = now
    }
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
        // L'avertissement du vocabulaire commun (`Haptics.warning`).
        DuelHaptic.Clock -> listOf(0L to heavy)
        DuelHaptic.Countdown -> listOf(0L to medium)
        DuelHaptic.CountdownFinal -> listOf(0L to heavy, 70L to medium)
        DuelHaptic.OpponentFound -> listOf(0L to heavy, 90L to medium, 200L to tick)
        DuelHaptic.SuddenDeath -> listOf(0L to reject, 180L to heavy)
        // La récompense du vocabulaire commun (`Haptics.celebrate`).
        DuelHaptic.Victory -> listOf(0L to confirm, 120L to heavy, 240L to medium)
        DuelHaptic.Defeat -> listOf(0L to heavy, 200L to tick)
        DuelHaptic.TrophyLanded -> listOf(0L to medium)
        DuelHaptic.Promotion -> listOf(0L to confirm, 90L to medium, 180L to medium, 270L to medium, 360L to medium, 600L to heavy)
    }
    for ((delay, constant) in pattern) {
        if (delay == 0L) performHapticFeedback(constant) else postDelayed({ performHapticFeedback(constant) }, delay)
    }
}
