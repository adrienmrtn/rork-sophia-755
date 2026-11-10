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
import androidx.compose.material.icons.filled.WifiOff
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
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
import app.rork.sophia.ui.onboarding.ConfettiBurst
import app.rork.sophia.ui.theme.DS
import app.rork.sophia.ui.theme.PlusJakartaSans
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlin.math.abs
import kotlin.math.roundToInt

/** Le compteur de trophées défile en 28 crans au plus, quel que soit l'écart. */
private const val TROPHY_STEPS = 28

/**
 * La fin d'une partie : victoire ou défaite, le score, puis les trophées qui défilent jusqu'à
 * leur nouveau total, la jauge de ligue qui avance, et la montée de ligue quand un seuil tombe.
 * Le titre et le score sont connus tout de suite ; les trophées arrivent avec la réponse du
 * serveur ([result]), qui fait foi. Même écran que
 * `ios/Sophia/Views/Duels/DuelResultView.swift`.
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

    var appeared by remember { mutableStateOf(false) }
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
        view.duelHaptic(if (won) DuelHaptic.Victory else DuelHaptic.Defeat)
    }

    // Les trophées défilent de l'ancien total au nouveau, la jauge suit, puis la nouvelle ligue
    // s'annonce si un seuil vient de tomber.
    LaunchedEffect(result?.matchId) {
        val outcome = result ?: return@LaunchedEffect
        shownTrophies = outcome.trophiesBefore
        shownLeaguePosition = outcome.leagueBefore
        barProgress.snapTo(home?.leagueProgress(outcome.trophiesBefore) ?: 0f)
        delay(900)

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
        if (promotedLeague != null) promotedLeague = null else onDone()
    }

    val entrance by animateFloatAsState(
        targetValue = if (appeared) 1f else 0f,
        animationSpec = duelSpring(response = 0.55f, damping = 0.62f),
        label = "duelResultEntrance",
    )

    Box(modifier = modifier.fillMaxSize()) {
        DuelLeagueBackdrop(league = shownLeague, modifier = Modifier.fillMaxSize().duelUnderSystemBars())
        Box(
            modifier = Modifier
                .fillMaxSize()
                .duelUnderSystemBars()
                .background(
                    Brush.verticalGradient(
                        listOf(DuelPalette.night.copy(alpha = 0.78f), DuelPalette.night.copy(alpha = 0.94f)),
                    ),
                ),
        )

        Column(
            modifier = Modifier.align(Alignment.Center).widthIn(max = 640.dp).fillMaxSize(),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Column(
                modifier = Modifier
                    .weight(1f)
                    .fillMaxWidth()
                    .verticalScroll(rememberScrollState())
                    .padding(horizontal = 20.dp)
                    .padding(top = 28.dp, bottom = 16.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(22.dp),
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
                                won -> "duel.result.victory"
                                else -> "duel.result.defeat"
                            },
                        ),
                        fontFamily = PlusJakartaSans,
                        fontWeight = FontWeight.ExtraBold,
                        fontSize = 44.sp,
                        lineHeight = 50.sp,
                        color = if (won) DuelPalette.saffron else Color.White,
                        textAlign = TextAlign.Center,
                        modifier = Modifier.graphicsLayer {
                            val scale = 0.4f + 0.6f * entrance
                            scaleX = scale
                            scaleY = scale
                            alpha = entrance.coerceIn(0f, 1f)
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
                            fontWeight = FontWeight.SemiBold,
                            fontSize = 15.sp,
                            lineHeight = 20.sp,
                            color = Color.White.copy(alpha = 0.75f),
                            textAlign = TextAlign.Center,
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
                    horizontalArrangement = Arrangement.spacedBy(14.dp),
                ) {
                    ResultFace(
                        avatarId = player.avatarId,
                        initial = player.initial,
                        name = "@${player.handle}",
                        ring = DuelPalette.saffron,
                        crowned = won,
                        entrance = entrance,
                        modifier = Modifier.weight(1f),
                    )
                    Text(
                        text = "${summary.playerScore} – ${summary.opponentScore}",
                        // Mon score d'abord, dans toutes les langues.
                        style = DuelTabularDigits.copy(textDirection = TextDirection.Ltr),
                        fontFamily = PlusJakartaSans,
                        fontWeight = FontWeight.ExtraBold,
                        fontSize = 40.sp,
                        color = Color.White,
                        maxLines = 1,
                    )
                    ResultFace(
                        avatarId = opponent.avatarId,
                        initial = opponent.initial,
                        name = "@${opponent.handle} ${opponent.flag}".trim(),
                        ring = DuelPalette.coral,
                        crowned = !won,
                        entrance = entrance,
                        modifier = Modifier.weight(1f),
                    )
                }

                TrophyCard(
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
                        alpha = entrance.coerceIn(0f, 1f)
                        translationY = 40.dp.toPx() * (1f - entrance)
                    },
                )
            }

            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 20.dp, vertical = 12.dp)
                    .graphicsLayer { alpha = entrance.coerceIn(0f, 1f) },
                verticalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                DuelPlayButton(
                    text = text("duel.result.again"),
                    onClick = {
                        view.duelHaptic(DuelHaptic.Countdown)
                        onPlayAgain()
                    },
                )
                Text(
                    text = text("duel.result.done"),
                    fontFamily = PlusJakartaSans,
                    fontWeight = FontWeight.SemiBold,
                    fontSize = 17.sp,
                    color = Color.White.copy(alpha = 0.85f),
                    textAlign = TextAlign.Center,
                    modifier = Modifier
                        .fillMaxWidth()
                        .clip(CircleShape)
                        .clickable(role = Role.Button) {
                            view.duelHaptic(DuelHaptic.Tap)
                            onDone()
                        }
                        .padding(vertical = 10.dp),
                )
            }
        }

        if (won) {
            ConfettiBurst(
                colors = DuelPalette.confetti,
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
    }
}

// ---------------------------------------------------------------- les deux joueurs

@Composable
private fun ResultFace(
    avatarId: String?,
    initial: String,
    name: String,
    ring: Color,
    crowned: Boolean,
    entrance: Float,
    modifier: Modifier = Modifier,
) {
    Column(
        modifier = modifier.padding(top = 20.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        Box(contentAlignment = Alignment.TopCenter) {
            DuelAvatar(
                avatarId = avatarId,
                initial = initial,
                size = 76.dp,
                ring = ring,
                ringWidth = 4.dp,
                // Le perdant passe au second plan.
                modifier = Modifier.duelSaturation(if (crowned) 1f else 0.55f),
            )
            if (crowned) {
                DuelCrown(
                    size = 28.dp,
                    modifier = Modifier.offset(y = (-24).dp).graphicsLayer {
                        val scale = 0.1f + 0.9f * entrance
                        scaleX = scale
                        scaleY = scale
                    },
                )
            }
        }
        DuelShrinkText(
            text = name,
            fontSize = 12.sp,
            fontWeight = FontWeight.Bold,
            color = Color.White.copy(alpha = 0.85f),
            minScale = 0.6f,
        )
    }
}

/** Dessine son contenu avec des couleurs plus ou moins vives (1 : inchangées, 0 : gris). */
private fun Modifier.duelSaturation(value: Float): Modifier {
    if (value >= 1f) return this
    return drawWithContent {
        // L'ombre de l'avatar déborde de son cadre : la couche la garde.
        val margin = 24.dp.toPx()
        val paint = Paint().apply {
            colorFilter = ColorFilter.colorMatrix(ColorMatrix().apply { setToSaturation(value) })
        }
        drawIntoCanvas { canvas ->
            canvas.saveLayer(Rect(-margin, -margin, size.width + margin, size.height + margin), paint)
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
        // Une ombre portée légère, pour qu'elle se détache de l'illustration du fond.
        drawPath(path, Color.Black.copy(alpha = 0.3f), style = Stroke(width = w * 0.16f, join = StrokeJoin.Round))
        drawPath(path, DuelPalette.saffron)
        drawPath(path, DuelPalette.saffron, style = Stroke(width = w * 0.08f, join = StrokeJoin.Round))
    }
}

// ---------------------------------------------------------------- trophées

@Composable
private fun TrophyCard(
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
    val shape = RoundedCornerShape(26.dp)
    Column(
        modifier = modifier
            .fillMaxWidth()
            .shadow(16.dp, shape, ambientColor = Color.Black.copy(alpha = 0.3f), spotColor = Color.Black.copy(alpha = 0.3f))
            .background(DS.surface, shape)
            .padding(20.dp),
        verticalArrangement = Arrangement.spacedBy(18.dp),
    ) {
        when {
            result != null -> {
                Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(16.dp)) {
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
                            .size(76.dp)
                            .clip(RoundedCornerShape(20.dp)),
                    )
                    Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(4.dp)) {
                        Text(
                            text = text("duel.trophies.title").uppercaseIn(language),
                            fontFamily = PlusJakartaSans,
                            fontWeight = FontWeight.Bold,
                            fontSize = 12.sp,
                            letterSpacing = 1.1.sp,
                            color = DS.inkTertiary,
                        )
                        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                            Text(
                                text = DuelFormat.number(shownTrophies, language),
                                fontFamily = PlusJakartaSans,
                                fontWeight = FontWeight.ExtraBold,
                                fontSize = 40.sp,
                                lineHeight = 46.sp,
                                style = DuelTabularDigits,
                                color = DS.ink,
                                maxLines = 1,
                            )
                            AnimatedVisibility(
                                visible = showDelta,
                                enter = scaleIn(
                                    duelSpring(response = 0.4f, damping = 0.55f),
                                    initialScale = 0.3f,
                                    transformOrigin = TransformOrigin(0f, 0.5f),
                                ) + fadeIn(),
                            ) {
                                DeltaChip(result.trophiesDelta)
                            }
                        }
                    }
                }

                val next = home?.nextLeague(shownLeague)
                Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Text(
                            text = DuelFormat.leagueName(context, shownLeague, language),
                            fontFamily = PlusJakartaSans,
                            fontWeight = FontWeight.Bold,
                            fontSize = 15.sp,
                            color = DS.ink,
                            maxLines = 1,
                            modifier = Modifier.weight(1f),
                        )
                        if (next != null) {
                            DuelTrophyCount(value = next.minTrophies, language = language, size = 13.dp, color = DS.inkSecondary)
                        }
                    }
                    DuelProgressBar(progress = barProgress, tint = DuelPalette.saffron, track = DS.surfaceMuted, height = 12.dp)
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
                        fontWeight = FontWeight.Medium,
                        fontSize = 12.sp,
                        lineHeight = 16.sp,
                        color = DS.inkSecondary,
                    )
                }
            }
            resultFailed -> Column(
                modifier = Modifier.fillMaxWidth().padding(vertical = 8.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                Icon(Icons.Filled.WifiOff, contentDescription = null, tint = DS.inkTertiary, modifier = Modifier.size(30.dp))
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
                    color = DS.accentSoft,
                    modifier = Modifier
                        .clip(CircleShape)
                        .clickable(role = Role.Button, onClick = onRetrySend)
                        .padding(horizontal = 14.dp, vertical = 8.dp),
                )
            }
            else -> Box(modifier = Modifier.fillMaxWidth().padding(vertical = 28.dp), contentAlignment = Alignment.Center) {
                CircularProgressIndicator(color = DS.accentSoft, strokeWidth = 3.dp, modifier = Modifier.size(28.dp))
            }
        }
    }
}

@Composable
private fun DeltaChip(delta: Int) {
    val color = if (delta > 0) DS.success else if (delta < 0) DS.danger else DS.inkTertiary
    val tint = if (delta > 0) DS.successTint else if (delta < 0) DS.dangerTint else DS.surfaceMuted
    Text(
        text = if (delta > 0) "+$delta" else delta.toString(),
        fontFamily = PlusJakartaSans,
        fontWeight = FontWeight.ExtraBold,
        fontSize = 17.sp,
        style = DuelTabularDigits,
        color = color,
        maxLines = 1,
        modifier = Modifier.background(tint, CircleShape).padding(horizontal = 10.dp, vertical = 4.dp),
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
                        listOf(Color.Transparent, DuelPalette.night.copy(alpha = 0.35f), DuelPalette.night.copy(alpha = 0.92f)),
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
                fontWeight = FontWeight.Bold,
                fontSize = 15.sp,
                letterSpacing = 2.4.sp,
                color = DuelPalette.saffron,
                modifier = Modifier.graphicsLayer {
                    alpha = revealed.value
                    translationY = 16.dp.toPx() * (1f - revealed.value)
                },
            )
            DuelShrinkText(
                text = DuelFormat.leagueName(context, league, language),
                fontSize = 46.sp,
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
                    color = Color.White.copy(alpha = 0.8f),
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
