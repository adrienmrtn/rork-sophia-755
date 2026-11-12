package app.rork.sophia.ui.duels

import androidx.activity.compose.BackHandler
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.LinearOutSlowInEasing
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.scaleIn
import androidx.compose.animation.slideInVertically
import androidx.compose.animation.slideOutVertically
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material.icons.automirrored.filled.MenuBook
import androidx.compose.material.icons.filled.Bolt
import androidx.compose.material.icons.filled.WifiOff
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawWithContent
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.ColorFilter
import androidx.compose.ui.graphics.ColorMatrix
import androidx.compose.ui.graphics.Paint
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.StrokeJoin
import androidx.compose.ui.graphics.TransformOrigin
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.drawscope.drawIntoCanvas
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalView
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextDirection
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.rork.sophia.R
import app.rork.sophia.data.StringStore
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.domain.DuelHome
import app.rork.sophia.domain.DuelLeague
import app.rork.sophia.domain.DuelResult
import app.rork.sophia.domain.uppercaseIn
import app.rork.sophia.ui.components.DSCountUp
import app.rork.sophia.ui.components.DSMotion
import app.rork.sophia.ui.components.SophiaSecondaryButton
import app.rork.sophia.ui.components.sophiaCard
import app.rork.sophia.ui.onboarding.ConfettiBurst
import app.rork.sophia.ui.theme.DS
import app.rork.sophia.ui.theme.PlusJakartaSans
import app.rork.sophia.ui.theme.SophiaAppearance
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlin.math.abs
import kotlin.math.roundToInt
import androidx.compose.material.icons.filled.Group

/** Le compteur de trophées défile en 28 crans au plus, quel que soit l'écart. */
private const val TROPHY_STEPS = 28

/**
 * La fin d'une partie (maquette AEr25). L'écran s'ouvre sur les deux joueurs face à face : leurs
 * bonnes réponses défilent de zéro à leur total, de plus en plus lentement, puis l'issue se
 * dévoile (titre, couronne, confettis pour une victoire ; plus calme pour une défaite ou une
 * égalité). Viennent ensuite les trophées qui défilent jusqu'à leur nouveau total, la jauge de
 * ligue qui avance, et la montée de ligue quand un seuil tombe. « Revoir les questions » ouvre
 * la relecture de la partie ([DuelReviewScreen]).
 * Le score est connu tout de suite ; les trophées arrivent avec la réponse du serveur
 * ([result]), qui fait foi. Même écran que `ios/Sophia/Views/Duels/DuelResultView.swift`.
 *
 * [home] est l'accueil tel qu'il était au lancement de la partie : le compteur part de lui.
 */
@Composable
internal fun DuelResultScreen(
    summary: DuelSummary,
    player: DuelPlayerIdentity,
    home: DuelHome?,
    result: DuelResult?,
    resultFailed: Boolean,
    language: AppLanguage,
    onRetrySend: () -> Unit,
    onPlayAgain: () -> Unit,
    onDone: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val context = LocalContext.current
    val view = LocalView.current
    fun text(key: String, vararg args: Any): String = StringStore.text(context, key, language, *args)

    // Animations coupées dans les réglages du système : tout est en place d'emblée.
    val reduceMotion = rememberDuelReduceMotion()
    var appeared by remember { mutableStateOf(false) }
    // Les bonnes réponses affichées pendant le décompte d'ouverture.
    var shownPlayerScore by remember { mutableIntStateOf(if (reduceMotion) summary.playerScore else 0) }
    var shownOpponentScore by remember { mutableIntStateOf(if (reduceMotion) summary.opponentScore else 0) }
    // Le décompte est fini : le titre, la couronne et les confettis se montrent.
    var revealed by remember { mutableStateOf(reduceMotion) }
    var showReview by remember { mutableStateOf(false) }
    var shownTrophies by remember { mutableIntStateOf(0) }
    val barProgress = remember { Animatable(0f) }
    var shownLeaguePosition by remember { mutableStateOf<Int?>(null) }
    var showDelta by remember { mutableStateOf(false) }
    var promotedLeague by remember { mutableStateOf<DuelLeague?>(null) }

    val won = result?.won ?: summary.won
    val opponent = summary.match.opponent
    // Tant que le résultat n'est pas là, la ligue du lancement ; ensuite celle que le compteur montre.
    val shownPosition = shownLeaguePosition
    val shownLeague = if (shownPosition == null) home?.currentLeague else home?.leagueAt(shownPosition)

    LaunchedEffect(Unit) {
        appeared = true
        // Les exploits de la partie (score, écart, question décisive) comptent pour les badges.
        (view.context.applicationContext as app.rork.sophia.SophiaApplication).badgeCenter.recordDuel(
            matchId = summary.match.matchId,
            won = summary.won,
            abandoned = summary.abandoned,
            draw = summary.draw,
            friendly = summary.friendly,
            forfeit = summary.forfeit,
            tiebreak = summary.tiebreak,
            playerScore = summary.playerScore,
            opponentScore = summary.opponentScore,
        )
        // Les deux scores défilent ensemble de zéro à leur total (le plus petit s'arrête le
        // premier), vite puis de plus en plus lentement, avec un cran de vibration par point.
        if (!revealed) {
            delay(550)
            val steps = maxOf(summary.playerScore, summary.opponentScore)
            for (step in 1..steps) {
                shownPlayerScore = minOf(step, summary.playerScore)
                shownOpponentScore = minOf(step, summary.opponentScore)
                view.duelHaptic(DuelHaptic.TrophyTick)
                delay(DuelRules.scoreCountDelayMs(step, steps))
            }
            delay(250)
            revealed = true
        }
        // Une égalité parfaite (entre amis) n'est ni une victoire ni une défaite. La victoire
        // sonne comme toute récompense de l'app (`Haptics.celebrate`).
        if (won) view.duelHaptic(DuelHaptic.Victory) else if (!summary.draw) view.duelHaptic(DuelHaptic.Defeat)
    }

    // Une fois l'issue dévoilée, les trophées défilent de l'ancien total au nouveau, la jauge
    // suit, puis la nouvelle ligue s'annonce si un seuil vient de tomber.
    LaunchedEffect(result?.matchId, revealed) {
        val outcome = result ?: return@LaunchedEffect
        shownTrophies = outcome.trophiesBefore
        shownLeaguePosition = outcome.leagueBefore
        barProgress.snapTo(home?.leagueProgress(outcome.trophiesBefore) ?: 0f)
        // La carte, encore cachée, attend l'issue sur l'ancien total.
        if (!revealed) return@LaunchedEffect
        delay(600)

        showDelta = true
        val delta = outcome.trophiesDelta
        val steps = minOf(abs(delta), TROPHY_STEPS)
        for (step in 1..steps) {
            val progress = step.toDouble() / steps
            val eased = 1 - (1 - progress) * (1 - progress)
            shownTrophies = outcome.trophiesBefore + (delta * eased).roundToInt()
            view.duelHaptic(DuelHaptic.TrophyTick)
            delay(26 + (46 * progress).toLong())
        }
        shownTrophies = outcome.trophiesAfter
        view.duelHaptic(DuelHaptic.TrophyLanded)

        val after = home?.leagueProgress(outcome.trophiesAfter) ?: 0f
        val gauge = duelSpring<Float>(response = 0.9f, damping = 0.85f)
        val league = if (outcome.promoted) home?.leagueAt(outcome.leagueAfter) else null
        if (league == null) {
            barProgress.animateTo(if (outcome.promoted) 1f else after, gauge)
            return@LaunchedEffect
        }
        // Montée de ligue : la jauge se remplit, puis la nouvelle ligue s'annonce.
        val filling = launch { barProgress.animateTo(1f, gauge) }
        delay(1_000)
        promotedLeague = league
        view.duelHaptic(DuelHaptic.Promotion)
        // Sous l'annonce, la carte passe à la nouvelle ligue, jauge repartie de son seuil.
        filling.cancel()
        shownLeaguePosition = outcome.leagueAfter
        barProgress.snapTo(after)
    }

    BackHandler {
        when {
            showReview -> showReview = false
            promotedLeague != null -> promotedLeague = null
            else -> onDone()
        }
    }

    // L'issue qui se pose : un ressort amorti, sans rebond marqué.
    val reveal by animateFloatAsState(
        targetValue = if (revealed) 1f else 0f,
        animationSpec = duelSpring(response = 0.5f, damping = 0.74f),
        label = "duelResultReveal",
    )

    val entrance by animateFloatAsState(
        targetValue = if (appeared) 1f else 0f,
        animationSpec = DSMotion.pop(),
        label = "duelResultEntrance",
    )

    Box(modifier = modifier.fillMaxSize().background(DS.canvas)) {
        Column(
            modifier = Modifier.align(Alignment.Center).widthIn(max = 640.dp).fillMaxSize(),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Column(
                modifier = Modifier
                    .weight(1f)
                    .fillMaxWidth()
                    .verticalScroll(rememberScrollState())
                    .padding(horizontal = 24.dp)
                    .padding(top = 44.dp, bottom = 16.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(16.dp),
            ) {
                // Titre : l'issue, puis comment elle s'est décidée.
                Column(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.spacedBy(6.dp),
                ) {
                    Text(
                        text = text(
                            when {
                                summary.abandoned -> "duel.result.abandoned"
                                summary.draw -> "duel.result.draw"
                                won -> "duel.result.victory"
                                else -> "duel.result.defeat"
                            },
                        ),
                        fontFamily = PlusJakartaSans,
                        fontWeight = FontWeight.ExtraBold,
                        fontSize = 34.sp,
                        lineHeight = 40.sp,
                        color = DS.ink,
                        textAlign = TextAlign.Center,
                        modifier = Modifier.graphicsLayer {
                            // Une victoire arrive de plus loin qu'une défaite ou une égalité.
                            val from = if (won) 0.55f else 0.9f
                            val scale = from + (1f - from) * reveal
                            scaleX = scale
                            scaleY = scale
                            alpha = reveal.coerceIn(0f, 1f)
                        },
                    )
                    val subtitle = when {
                        summary.forfeit -> text("duel.friend.left", opponent.handle)
                        summary.tiebreak && !summary.abandoned -> text("duel.result.suddenDeath")
                        else -> null
                    }
                    if (subtitle != null) {
                        Text(
                            text = subtitle,
                            fontFamily = PlusJakartaSans,
                            fontWeight = FontWeight.Medium,
                            fontSize = 15.sp,
                            lineHeight = 20.sp,
                            color = DS.inkSecondary,
                            textAlign = TextAlign.Center,
                            modifier = Modifier.graphicsLayer { alpha = reveal.coerceIn(0f, 1f) },
                        )
                    }
                }

                // Les deux joueurs et le score.
                Row(
                    modifier = Modifier.fillMaxWidth().graphicsLayer {
                        alpha = entrance.coerceIn(0f, 1f)
                        translationY = 24.dp.toPx() * (1f - entrance)
                    },
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(18.dp),
                ) {
                    ResultFace(
                        avatarId = player.avatarId,
                        initial = player.initial,
                        name = "@${player.handle}",
                        crowned = revealed && won && !summary.draw,
                        faded = revealed && !won && !summary.draw,
                        entrance = reveal,
                        modifier = Modifier.weight(1f),
                    )
                    Text(
                        text = "$shownPlayerScore – $shownOpponentScore",
                        // Mon score d'abord, dans toutes les langues.
                        style = DuelTabularDigits.copy(textDirection = TextDirection.Ltr),
                        fontFamily = PlusJakartaSans,
                        fontWeight = FontWeight.ExtraBold,
                        fontSize = 34.sp,
                        color = DS.ink,
                        maxLines = 1,
                    )
                    ResultFace(
                        avatarId = opponent.avatarId,
                        initial = opponent.initial,
                        name = "@${opponent.handle} ${opponent.flag}".trim(),
                        crowned = revealed && !won && !summary.draw,
                        faded = revealed && won && !summary.draw,
                        entrance = reveal,
                        modifier = Modifier.weight(1f),
                    )
                }

                TrophyCard(
                    friendly = summary.friendly,
                    result = result,
                    resultFailed = resultFailed,
                    won = won,
                    home = home,
                    shownLeague = shownLeague,
                    shownTrophies = shownTrophies,
                    barProgress = barProgress.value,
                    showDelta = showDelta,
                    language = language,
                    onRetrySend = {
                        view.duelHaptic(DuelHaptic.Tap)
                        onRetrySend()
                    },
                    modifier = Modifier.graphicsLayer {
                        alpha = reveal.coerceIn(0f, 1f)
                        translationY = 40.dp.toPx() * (1f - reveal)
                    },
                )

                // « Revoir les questions » : la relecture de la partie, question par question.
                if (summary.review.isNotEmpty()) {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .graphicsLayer {
                                alpha = reveal.coerceIn(0f, 1f)
                                translationY = 40.dp.toPx() * (1f - reveal)
                            }
                            .sophiaCard(elevation = 0.dp)
                            .clickable(enabled = revealed, role = Role.Button) {
                                view.duelHaptic(DuelHaptic.Tap)
                                showReview = true
                            }
                            .padding(16.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(10.dp),
                    ) {
                        Icon(
                            imageVector = Icons.AutoMirrored.Filled.MenuBook,
                            contentDescription = null,
                            tint = DS.accent,
                            modifier = Modifier.size(20.dp),
                        )
                        Text(
                            text = text("duel.review.open"),
                            fontFamily = PlusJakartaSans,
                            fontWeight = FontWeight.Bold,
                            fontSize = 15.sp,
                            lineHeight = 20.sp,
                            color = DS.ink,
                            modifier = Modifier.weight(1f),
                        )
                        Icon(
                            imageVector = Icons.AutoMirrored.Filled.KeyboardArrowRight,
                            contentDescription = null,
                            tint = DS.inkTertiary,
                            modifier = Modifier.size(20.dp),
                        )
                    }
                }
            }

            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 24.dp, vertical = 12.dp)
                    .graphicsLayer { alpha = entrance.coerceIn(0f, 1f) },
                verticalArrangement = Arrangement.spacedBy(10.dp),
            ) {
                DuelPlayButton(
                    text = text(if (summary.friendly) "duel.friend.rematch" else "duel.result.again"),
                    leadingIcon = Icons.Filled.Bolt,
                    onClick = {
                        view.duelHaptic(DuelHaptic.Countdown)
                        onPlayAgain()
                    },
                )
                // Le bouton secondaire vibre de lui-même.
                SophiaSecondaryButton(text = text("duel.result.done"), onClick = onDone)
            }
        }

        if (won && revealed && !reduceMotion) {
            ConfettiBurst(
                colors = DuelTheme.confetti,
                pieceCount = 120,
                durationMillis = 3_000,
                origin = Offset(0.5f, 0.22f),
            )
        }

        // L'annonce garde sa ligue le temps de s'effacer.
        val lastPromoted = remember { arrayOfNulls<DuelLeague>(1) }
        promotedLeague?.let { lastPromoted[0] = it }
        AnimatedVisibility(visible = promotedLeague != null, enter = fadeIn(tween(450)), exit = fadeOut(tween(350))) {
            (promotedLeague ?: lastPromoted[0])?.let { league ->
                DuelPromotionOverlay(league = league, language = language, onContinue = { promotedLeague = null })
            }
        }

        AnimatedVisibility(
            visible = showReview,
            enter = slideInVertically(tween(300)) { it } + fadeIn(tween(300)),
            exit = slideOutVertically(tween(300)) { it } + fadeOut(tween(300)),
        ) {
            DuelReviewScreen(
                entries = summary.review,
                questionCount = summary.match.questionCount,
                player = player,
                opponent = opponent,
                language = language,
                onClose = { showReview = false },
            )
        }
    }
}

// ---------------------------------------------------------------- les deux joueurs

/** Un joueur : le vainqueur porte la couronne et un cercle safran, le perdant passe en gris. */
@Composable
private fun ResultFace(
    avatarId: String?,
    initial: String,
    name: String,
    crowned: Boolean,
    faded: Boolean,
    entrance: Float,
    modifier: Modifier = Modifier,
) {
    Column(
        modifier = modifier.padding(top = 20.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(4.dp),
    ) {
        Box(contentAlignment = Alignment.TopCenter) {
            DuelAvatar(
                avatarId = avatarId,
                initial = initial,
                size = 76.dp,
                ring = if (crowned) DuelPalette.saffron else DS.hairline,
                ringWidth = if (crowned) 3.dp else 1.5.dp,
                // Le perdant passe au second plan ; le vainqueur grandit un peu quand l'issue tombe.
                modifier = Modifier
                    .graphicsLayer {
                        alpha = if (faded) 0.7f else 1f
                        val scale = if (crowned) 1f + 0.06f * entrance.coerceIn(0f, 1.2f) else 1f
                        scaleX = scale
                        scaleY = scale
                    }
                    .duelSaturation(if (faded) 0f else 1f),
            )
            if (crowned) {
                DuelCrown(
                    size = 28.dp,
                    modifier = Modifier.offset(y = (-24).dp).graphicsLayer {
                        val scale = (0.1f + 0.9f * entrance).coerceAtLeast(0f)
                        scaleX = scale
                        scaleY = scale
                    },
                )
            }
        }
        DuelShrinkText(
            text = name,
            fontSize = 13.sp,
            fontWeight = FontWeight.Bold,
            color = DS.ink,
            minScale = 0.6f,
        )
    }
}

/** Dessine son contenu avec des couleurs plus ou moins vives (1 : inchangées, 0 : gris). */
private fun Modifier.duelSaturation(value: Float): Modifier {
    if (value >= 1f) return this
    return drawWithContent {
        val paint = Paint().apply {
            colorFilter = ColorFilter.colorMatrix(ColorMatrix().apply { setToSaturation(value) })
        }
        drawIntoCanvas { canvas ->
            canvas.saveLayer(Rect(0f, 0f, size.width, size.height), paint)
            drawContent()
            canvas.restore()
        }
    }
}

/** La couronne du gagnant, en safran. */
@Composable
private fun DuelCrown(size: Dp, modifier: Modifier = Modifier) {
    Canvas(modifier = modifier.size(size)) {
        val w = this.size.width
        val h = this.size.height
        val path = Path().apply {
            moveTo(w * 0.14f, h * 0.84f)
            lineTo(w * 0.04f, h * 0.30f)
            lineTo(w * 0.30f, h * 0.54f)
            lineTo(w * 0.50f, h * 0.14f)
            lineTo(w * 0.70f, h * 0.54f)
            lineTo(w * 0.96f, h * 0.30f)
            lineTo(w * 0.86f, h * 0.84f)
            close()
        }
        drawPath(path, DuelPalette.saffron)
        drawPath(path, DuelPalette.saffron, style = Stroke(width = w * 0.08f, join = StrokeJoin.Round))
    }
}

// ---------------------------------------------------------------- trophées

@Composable
private fun TrophyCard(
    /** Duel entre amis : aucun trophée en jeu. */
    friendly: Boolean,
    result: DuelResult?,
    resultFailed: Boolean,
    won: Boolean,
    home: DuelHome?,
    shownLeague: DuelLeague?,
    shownTrophies: Int,
    barProgress: Float,
    showDelta: Boolean,
    language: AppLanguage,
    onRetrySend: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val context = LocalContext.current
    fun text(key: String, vararg args: Any): String = StringStore.text(context, key, language, *args)
    Column(
        modifier = modifier
            .fillMaxWidth()
            .sophiaCard()
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        when {
            friendly -> Column(
                modifier = Modifier.fillMaxWidth().padding(vertical = 6.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(10.dp),
            ) {
                Box(
                    modifier = Modifier.size(52.dp).background(DS.accentTint, CircleShape),
                    contentAlignment = Alignment.Center,
                ) {
                    Icon(
                        imageVector = Icons.Filled.Group,
                        contentDescription = null,
                        tint = DS.accent,
                        modifier = Modifier.size(26.dp),
                    )
                }
                Text(
                    text = text("duel.friend.noTrophies"),
                    fontFamily = PlusJakartaSans,
                    fontWeight = FontWeight.Medium,
                    fontSize = 15.sp,
                    lineHeight = 20.sp,
                    color = DS.inkSecondary,
                    textAlign = TextAlign.Center,
                )
            }
            result != null -> {
                // L'illustration du trophée, le total qui défile et le gain (ou la perte) de la partie.
                Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                    val lift by animateFloatAsState(
                        targetValue = if (showDelta && won) 1f else 0f,
                        animationSpec = duelSpring(response = 0.4f, damping = 0.55f),
                        label = "duelTrophyLift",
                    )
                    Image(
                        painter = painterResource(R.drawable.duel_trophy),
                        contentDescription = null,
                        contentScale = ContentScale.Crop,
                        modifier = Modifier
                            .graphicsLayer {
                                rotationZ = -4f * lift
                                val scale = 1f + 0.06f * lift
                                scaleX = scale
                                scaleY = scale
                            }
                            .size(56.dp)
                            .clip(RoundedCornerShape(14.dp)),
                    )
                    Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
                        Text(
                            text = text("duel.trophies.title").uppercaseIn(language),
                            fontFamily = PlusJakartaSans,
                            fontWeight = FontWeight.ExtraBold,
                            fontSize = 12.sp,
                            letterSpacing = 0.8.sp,
                            color = DS.inkSecondary,
                        )
                        Text(
                            text = DuelFormat.number(shownTrophies, language),
                            fontFamily = PlusJakartaSans,
                            fontWeight = FontWeight.ExtraBold,
                            fontSize = 26.sp,
                            lineHeight = 32.sp,
                            style = DuelTabularDigits,
                            color = DS.ink,
                            maxLines = 1,
                        )
                    }
                    AnimatedVisibility(
                        visible = showDelta,
                        enter = scaleIn(
                            duelSpring(response = 0.4f, damping = 0.55f),
                            initialScale = 0.3f,
                            transformOrigin = TransformOrigin(1f, 0.5f),
                        ) + fadeIn(),
                    ) {
                        DeltaChip(result.trophiesDelta)
                    }
                }

                // La ligue affichée, le seuil de la suivante, la jauge et ce qu'il reste à gagner.
                val next = home?.nextLeague(shownLeague)
                Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Text(
                            text = DuelFormat.leagueName(context, shownLeague, language),
                            fontFamily = PlusJakartaSans,
                            fontWeight = FontWeight.Bold,
                            fontSize = 13.sp,
                            color = DS.ink,
                            maxLines = 1,
                            modifier = Modifier.weight(1f),
                        )
                        if (next != null) {
                            DuelTrophyCount(value = next.minTrophies, language = language, size = 13.dp, color = DS.ink)
                        }
                    }
                    DuelProgressBar(
                        progress = barProgress,
                        tint = DuelPalette.saffron,
                        track = DS.ink.copy(alpha = 0.12f),
                        height = 8.dp,
                    )
                    Text(
                        text = if (next == null) {
                            text("duel.league.top")
                        } else {
                            text(
                                "duel.league.toNext",
                                maxOf(next.minTrophies - shownTrophies, 0),
                                DuelFormat.leagueName(context, next, language),
                            )
                        },
                        fontFamily = PlusJakartaSans,
                        fontWeight = FontWeight.Normal,
                        fontSize = 13.sp,
                        lineHeight = 17.sp,
                        color = DS.inkSecondary,
                    )
                }
            }
            resultFailed -> Column(
                modifier = Modifier.fillMaxWidth().padding(vertical = 8.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                Icon(Icons.Filled.WifiOff, contentDescription = null, tint = DS.inkTertiary, modifier = Modifier.size(28.dp))
                Text(
                    text = text("duel.result.syncFailed"),
                    fontFamily = PlusJakartaSans,
                    fontWeight = FontWeight.Medium,
                    fontSize = 15.sp,
                    lineHeight = 21.sp,
                    color = DS.inkSecondary,
                    textAlign = TextAlign.Center,
                )
                Text(
                    text = text("duel.match.retry"),
                    fontFamily = PlusJakartaSans,
                    fontWeight = FontWeight.Bold,
                    fontSize = 15.sp,
                    color = DS.accent,
                    modifier = Modifier
                        .clip(DS.controlShape)
                        .clickable(role = Role.Button, onClick = onRetrySend)
                        .padding(horizontal = 14.dp, vertical = 8.dp),
                )
            }
            else -> Box(modifier = Modifier.fillMaxWidth().padding(vertical = 28.dp), contentAlignment = Alignment.Center) {
                CircularProgressIndicator(color = DS.accent, strokeWidth = 3.dp, modifier = Modifier.size(28.dp))
            }
        }
    }
}

/**
 * Le gain de la partie, qui défile de zéro à sa valeur pendant que le total avance. Sans
 * vibration propre : le défilement du total vibre déjà (`DuelHaptic.TrophyTick`).
 */
@Composable
private fun DeltaChip(delta: Int) {
    val color = if (delta > 0) DS.success else if (delta < 0) DS.danger else DS.inkTertiary
    val tint = if (delta > 0) DS.successTint else if (delta < 0) DS.dangerTint else DS.accentTint
    DSCountUp(
        value = delta,
        durationMillis = 800,
        style = DuelTabularDigits.copy(
            fontFamily = PlusJakartaSans,
            fontWeight = FontWeight.ExtraBold,
            fontSize = 15.sp,
        ),
        color = color,
        prefix = if (delta > 0) "+" else "",
        haptics = false,
        modifier = Modifier.background(tint, RoundedCornerShape(12.dp)).padding(horizontal = 12.dp, vertical = 5.dp),
    )
}

// ---------------------------------------------------------------- montée de ligue

/**
 * L'annonce d'une montée de ligue : l'illustration de la nouvelle ligue en plein écran, son nom
 * qui se pose, des confettis.
 */
@Composable
private fun DuelPromotionOverlay(league: DuelLeague, language: AppLanguage, onContinue: () -> Unit) {
    val context = LocalContext.current
    val view = LocalView.current
    val revealed = remember { Animatable(0f) }
    LaunchedEffect(Unit) { revealed.animateTo(1f, tween(1_300, easing = LinearOutSlowInEasing)) }
    // L'illustration passe sous les barres du système : leurs icônes en clair, le temps de l'annonce.
    DisposableEffect(Unit) {
        SophiaAppearance.darkBackdropBehindBars = true
        onDispose { SophiaAppearance.darkBackdropBehindBars = false }
    }

    Box(
        modifier = Modifier
            .fillMaxSize()
            // L'annonce couvre le résultat : ses boutons ne répondent plus dessous.
            .pointerInput(Unit) {},
    ) {
        DuelLeagueBackdrop(
            league = league,
            modifier = Modifier
                .fillMaxSize()
                .duelUnderSystemBars()
                .graphicsLayer {
                    val scale = 1.25f - 0.25f * revealed.value
                    scaleX = scale
                    scaleY = scale
                },
        )
        Box(
            modifier = Modifier
                .fillMaxSize()
                .duelUnderSystemBars()
                .background(
                    Brush.verticalGradient(
                        listOf(Color.Transparent, DuelTheme.scrim.copy(alpha = 0.35f), DuelTheme.scrim.copy(alpha = 0.92f)),
                    ),
                ),
        )

        Column(
            modifier = Modifier
                .align(Alignment.BottomCenter)
                .widthIn(max = 640.dp)
                .fillMaxWidth()
                .padding(horizontal = 24.dp)
                .padding(bottom = 28.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(14.dp),
        ) {
            Text(
                text = StringStore.text(context, "duel.promotion.title", language).uppercaseIn(language),
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.ExtraBold,
                fontSize = 13.sp,
                letterSpacing = 1.6.sp,
                color = DuelPalette.saffron,
                modifier = Modifier.graphicsLayer {
                    alpha = revealed.value
                    translationY = 16.dp.toPx() * (1f - revealed.value)
                },
            )
            DuelShrinkText(
                text = DuelFormat.leagueName(context, league, language),
                fontSize = 40.sp,
                fontWeight = FontWeight.ExtraBold,
                color = Color.White,
                maxLines = 2,
                textAlign = TextAlign.Center,
                minScale = 0.6f,
                modifier = Modifier.graphicsLayer {
                    val scale = 0.5f + 0.5f * revealed.value
                    scaleX = scale
                    scaleY = scale
                    alpha = revealed.value
                },
            )
            Row(
                modifier = Modifier.graphicsLayer { alpha = revealed.value },
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(8.dp),
            ) {
                Text(
                    text = StringStore.text(context, "duel.league.position", language, league.position),
                    fontFamily = PlusJakartaSans,
                    fontWeight = FontWeight.SemiBold,
                    fontSize = 15.sp,
                    color = DuelTheme.onArtSecondary,
                )
                Text(text = "·", fontSize = 15.sp, color = Color.White.copy(alpha = 0.5f))
                DuelTrophyCount(value = league.minTrophies, language = language, size = 15.dp, color = Color.White)
            }
            Spacer(Modifier.size(4.dp))
            DuelPlayButton(
                text = StringStore.text(context, "duel.promotion.continue", language),
                onClick = {
                    view.duelHaptic(DuelHaptic.Tap)
                    onContinue()
                },
                modifier = Modifier.graphicsLayer { alpha = revealed.value },
            )
        }

        ConfettiBurst(
            colors = DuelPalette.confetti,
            pieceCount = 160,
            durationMillis = 3_400,
            origin = Offset(0.5f, 0.45f),
        )
    }
}
