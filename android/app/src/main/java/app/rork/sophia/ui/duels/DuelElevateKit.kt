package app.rork.sophia.ui.duels

import android.provider.Settings
import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.StartOffset
import androidx.compose.animation.core.StartOffsetType
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.scaleIn
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.semantics.role
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.ui.components.pressable
import app.rork.sophia.ui.theme.DS
import app.rork.sophia.ui.theme.PlusJakartaSans
import app.rork.sophia.ui.theme.uppercaseInApp
import kotlin.math.PI
import kotlin.math.cos
import kotlin.math.max
import kotlin.math.sin

// Les briques propres aux duels dans le design « Elevate arrondi » : les quelques teintes que
// les maquettes ajoutent aux jetons `DS`, et les animations d'attente (recherche d'un
// adversaire, réponse d'un ami). Le jumeau de `ios/Sophia/Views/Duels/DuelElevateKit.swift`.

// ---------------------------------------------------------------- teintes

/**
 * Les teintes de l'écran de duel qui n'existent pas dans `DS` (maquette AEr24). Les couleurs
 * des ligues et des trophées restent dans [DuelPalette].
 */
internal object DuelTheme {
    /** Fond gris très clair du bloc de score. */
    val scoreBlock = Color(0xFFF4F6FA)

    /** Filet à l'intérieur du bloc de score. */
    val scoreRule = Color(0xFFE1E5EB)

    /** Piste de l'anneau du minuteur. */
    val timerTrack = Color(0xFFD5DCE8)

    /** Case d'une question à venir. */
    val stripIdle = Color(0xFFDDE2EA)

    /** Case d'une question réussie. */
    val stripRight = Color(0xFF3FBF8F)

    /** Case d'une question ratée, et minuteur dans les dernières secondes. */
    val stripWrong = Color(0xFFE0564A)

    /** Étiquette d'une manche qui n'est pas en cours. */
    val faint = Color(0xFFA3ABB8)

    /** Voile posé sur l'illustration d'une ligue pour y lire du texte blanc. */
    val scrim = Color(0xFF0D182D)

    /** Texte secondaire sur l'illustration d'une ligue. */
    val onArtSecondary = Color(0xFFD5DCF5)

    /** Confettis lisibles sur fond blanc. */
    val confetti: List<Color>
        get() = listOf(DuelPalette.saffron, DuelPalette.coral, DS.accent, stripRight, DuelPalette.navy)
}

/**
 * « Supprimer les animations » est actif dans les réglages du système. Les animations de
 * Compose s'y plient d'elles-mêmes ; celles que l'on calcule image par image (le battement du
 * minuteur) le demandent ici.
 */
@Composable
internal fun rememberDuelReduceMotion(): Boolean {
    val context = LocalContext.current
    return remember(context) {
        runCatching {
            Settings.Global.getFloat(context.contentResolver, Settings.Global.ANIMATOR_DURATION_SCALE, 1f) == 0f
        }.getOrDefault(false)
    }
}

// ---------------------------------------------------------------- recherche

/**
 * L'attente autour d'un avatar : des ondes qui s'élargissent, un arc qui balaie le tour et une
 * pastille en orbite. Dessiné autour de sa place ([size]), sans la dépasser dans la mise en page.
 */
@Composable
internal fun DuelSearchRadar(modifier: Modifier = Modifier, color: Color = DS.accent, size: Dp = 104.dp) {
    val transition = rememberInfiniteTransition(label = "duelRadar")
    val waves = (0 until 3).map { index ->
        transition.animateFloat(
            initialValue = 0f,
            targetValue = 1f,
            animationSpec = infiniteRepeatable(
                animation = tween(2_100, easing = LinearEasing),
                repeatMode = RepeatMode.Restart,
                // Chaque onde part avec un tiers de période d'avance sur la précédente.
                initialStartOffset = StartOffset(index * 700, StartOffsetType.FastForward),
            ),
            label = "duelRadarWave$index",
        )
    }
    val sweep by transition.animateFloat(
        initialValue = 0f,
        targetValue = 360f,
        animationSpec = infiniteRepeatable(tween(1_700, easing = LinearEasing), RepeatMode.Restart),
        label = "duelRadarSweep",
    )
    val orbit by transition.animateFloat(
        initialValue = 0f,
        targetValue = -360f,
        animationSpec = infiniteRepeatable(tween(3_800, easing = LinearEasing), RepeatMode.Restart),
        label = "duelRadarOrbit",
    )
    Canvas(modifier = modifier.size(size).clearAndSetSemantics {}) {
        val radius = this.size.minDimension / 2
        waves.forEach { wave ->
            val phase = wave.value
            drawCircle(
                color = color.copy(alpha = 0.42f * (1f - phase)),
                radius = radius * (1f + 0.5f * phase),
                style = Stroke(width = 2.dp.toPx()),
            )
        }
        val sweepRadius = radius + 7.dp.toPx()
        drawArc(
            color = color,
            startAngle = sweep - 90f,
            sweepAngle = 72f,
            useCenter = false,
            topLeft = Offset(center.x - sweepRadius, center.y - sweepRadius),
            size = Size(sweepRadius * 2, sweepRadius * 2),
            style = Stroke(width = 3.dp.toPx(), cap = StrokeCap.Round),
        )
        val orbitRadius = radius + 16.dp.toPx()
        val angle = (orbit - 90f) * (PI / 180.0)
        drawCircle(
            color = color,
            radius = 4.dp.toPx(),
            center = Offset(
                x = center.x + orbitRadius * cos(angle).toFloat(),
                y = center.y + orbitRadius * sin(angle).toFloat(),
            ),
        )
    }
}

/** Trois points qui sautillent l'un après l'autre : « en attente ». */
@Composable
internal fun DuelWaitingDots(modifier: Modifier = Modifier, color: Color = DS.accent, size: Dp = 6.dp) {
    val transition = rememberInfiniteTransition(label = "duelDots")
    val phase by transition.animateFloat(
        initialValue = 0f,
        targetValue = (2 * PI).toFloat(),
        animationSpec = infiniteRepeatable(tween(1_200, easing = LinearEasing), RepeatMode.Restart),
        label = "duelDotsPhase",
    )
    Row(
        modifier = modifier.clearAndSetSemantics {},
        horizontalArrangement = Arrangement.spacedBy(size * 0.7f),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        repeat(3) { index ->
            Box(
                modifier = Modifier
                    .size(size)
                    .graphicsLayer {
                        val lift = max(0f, sin(phase - index * 0.9f))
                        translationY = -size.toPx() * 0.7f * lift
                        alpha = 0.45f + 0.55f * lift
                    }
                    .background(color, CircleShape),
            )
        }
    }
}

// ---------------------------------------------------------------- face-à-face

/**
 * Le rond central d'un face-à-face : « VS », puis un nombre (secondes d'attente, 3, 2, 1).
 * [counting] : le nombre est un compte à rebours de départ, chaque valeur arrive en grand ;
 * [muted] : état éteint (défi refusé, pas d'adversaire).
 */
@Composable
internal fun DuelVersusBadge(
    modifier: Modifier = Modifier,
    number: Int? = null,
    counting: Boolean = false,
    muted: Boolean = false,
    size: Dp = 68.dp,
) {
    // Le dernier nombre montré reste dessiné le temps que « VS » le remplace.
    val lastNumber = remember { IntArray(1) }
    if (number != null) lastNumber[0] = number
    // Un compte à rebours anime chaque valeur ; des secondes d'attente changent sur place.
    val shownKey: Int? = when {
        number == null -> null
        counting -> number
        else -> -1
    }
    Box(
        modifier = modifier
            .size(size)
            .background(if (muted) DS.hairline else DS.accent, CircleShape)
            // Un décompte est une animation : rien à lire.
            .clearAndSetSemantics {},
        contentAlignment = Alignment.Center,
    ) {
        AnimatedContent(
            targetState = shownKey,
            transitionSpec = {
                val initial = if (targetState == null || targetState == -1) 0.5f else 2.2f
                (scaleIn(duelSpring(response = 0.3f, damping = 0.55f), initialScale = initial) + fadeIn(tween(120)))
                    .togetherWith(fadeOut(tween(120)))
            },
            contentAlignment = Alignment.Center,
            label = "duelVersus",
        ) { key ->
            val label = when (key) {
                null -> "VS"
                // Lu dans le contenu : c'est ce qui le fait redessiner à chaque seconde d'attente.
                -1 -> (number ?: lastNumber[0]).toString()
                else -> key.toString()
            }
            val scale = when (key) {
                null -> 0.32f
                -1 -> 0.42f
                else -> 0.5f
            }
            Text(
                text = label,
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.ExtraBold,
                fontSize = (size.value * scale).sp,
                style = DuelTabularDigits,
                color = if (muted && key == null) DS.inkSecondary else Color.White,
                maxLines = 1,
            )
        }
    }
}

/** Un joueur dans un face-à-face : son avatar cerclé, son pseudo et ses trophées. */
@Composable
internal fun DuelVersusCard(
    avatarId: String?,
    initial: String,
    handle: String,
    language: AppLanguage,
    modifier: Modifier = Modifier,
    /** Drapeau ou autre suffixe du pseudo. */
    suffix: String = "",
    trophies: Int? = null,
    ring: Color = DS.accent,
    /** Pastille verte « en ligne » sur l'avatar. */
    online: Boolean = false,
) {
    Column(
        modifier = modifier.fillMaxWidth(),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Box {
            DuelAvatar(avatarId = avatarId, initial = initial, size = 104.dp, ring = ring, ringWidth = 4.dp)
            if (online) {
                DuelOnlineDot(size = 20.dp, modifier = Modifier.align(Alignment.BottomEnd).offset(x = (-4).dp, y = (-4).dp))
            }
        }
        Column(
            modifier = Modifier.padding(horizontal = 24.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(6.dp),
        ) {
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                DuelShrinkText(
                    text = "@$handle",
                    fontSize = 20.sp,
                    fontWeight = FontWeight.Bold,
                    color = DS.ink,
                    minScale = 0.7f,
                    modifier = Modifier.weight(1f, fill = false),
                )
                if (suffix.isNotEmpty()) {
                    // Le drapeau n'ajoute rien à la lecture d'écran du pseudo.
                    Text(text = suffix, fontSize = 20.sp, modifier = Modifier.clearAndSetSemantics {})
                }
            }
            if (trophies != null) {
                DuelTrophyCount(value = trophies, language = language, size = 15.dp, color = DS.inkSecondary)
            }
        }
    }
}

// ---------------------------------------------------------------- titres et boutons

/** Sur-titre de section des pages de duel : petites capitales espacées, grises. */
@Composable
internal fun DuelSectionTitle(text: String, modifier: Modifier = Modifier) {
    Text(
        text = text.uppercaseInApp(),
        modifier = modifier,
        fontFamily = PlusJakartaSans,
        fontWeight = FontWeight.ExtraBold,
        fontSize = 12.sp,
        letterSpacing = 0.8.sp,
        color = DS.inkSecondary,
    )
}

/**
 * Le bouton rond des écrans de duel (fermer, quitter, retour) : blanc, bordé, pression
 * élastique. [haptic] à faux quand l'action déclenche déjà sa vibration ([duelHaptic]).
 */
@Composable
internal fun DuelRoundIconButton(
    icon: ImageVector,
    contentDescription: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    haptic: Boolean = true,
    size: Dp = 44.dp,
) {
    Box(
        modifier = modifier
            .size(size)
            .semantics { role = Role.Button }
            .pressable(onClick = onClick, scaleDown = 0.92f, haptic = haptic)
            .clip(CircleShape)
            .background(DS.surface)
            .border(1.5.dp, DS.hairline, CircleShape),
        contentAlignment = Alignment.Center,
    ) {
        Icon(imageVector = icon, contentDescription = contentDescription, tint = DS.ink, modifier = Modifier.size(18.dp))
    }
}
