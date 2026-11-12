package app.rork.sophia.ui.duels

import androidx.activity.compose.BackHandler
import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.LinearOutSlowInEasing
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.StartOffset
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.scaleIn
import androidx.compose.animation.slideInVertically
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.BlurredEdgeTreatment
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.blur
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalView
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.compose.LocalLifecycleOwner
import androidx.lifecycle.withStarted
import app.rork.sophia.SophiaApplication
import app.rork.sophia.data.StringStore
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.domain.DuelLeague
import app.rork.sophia.domain.DuelMatch
import app.rork.sophia.domain.uppercaseIn
import app.rork.sophia.ui.components.DSMotion
import app.rork.sophia.ui.newgen.Avatars
import app.rork.sophia.ui.theme.DS
import app.rork.sophia.ui.theme.PlusJakartaSans
import coil.imageLoader
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.coroutines.withTimeoutOrNull
import kotlin.random.Random

private enum class MatchmakingStep { Searching, Found, Failed }

/** La recherche dure au moins ce temps, tiré au hasard : annuler ne coûte encore rien. */
private const val SEARCH_MIN_MS = 2_200L
private const val SEARCH_MAX_MS = 4_200L

/** Au-delà, le lancement est tenu pour raté : pas de recherche sans fin ni bouton pour en sortir. */
private const val START_TIMEOUT_MS = 12_000L
private const val SHUFFLE_MS = 120L
private const val FOUND_MS = 1_700L
private const val COUNTDOWN_STEP_MS = 800L

/**
 * La recherche d'un adversaire, sur fond blanc : les profils défilent au centre d'un radar,
 * l'adversaire trouvé se pose, puis 3, 2, 1 et la partie démarre. On peut annuler tant que la
 * partie n'est pas créée. [league] est la ligue dans laquelle la partie se joue (son nom en
 * sur-titre).
 * Même déroulé que `ios/Sophia/Views/Duels/DuelMatchmakingView.swift`.
 */
@Composable
internal fun DuelMatchmakingScreen(
    player: DuelPlayerIdentity,
    league: DuelLeague?,
    language: AppLanguage,
    onReady: (DuelMatch) -> Unit,
    onCancel: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val context = LocalContext.current
    val view = LocalView.current
    val app = context.applicationContext as SophiaApplication
    fun text(key: String, vararg args: Any): String = StringStore.text(context, key, language, *args)

    var step by remember { mutableStateOf(MatchmakingStep.Searching) }
    var match by remember { mutableStateOf<DuelMatch?>(null) }
    var canCancel by remember { mutableStateOf(true) }
    var shuffleAvatar by remember { mutableStateOf(Avatars.all.random()) }
    var countdown by remember { mutableStateOf<Int?>(null) }
    var attempt by remember { mutableIntStateOf(0) }
    var appeared by remember { mutableStateOf(false) }
    // La recherche vit plus longtemps qu'une recomposition : elle appelle toujours le dernier `onReady`.
    val currentOnReady by rememberUpdatedState(onReady)

    LaunchedEffect(Unit) { appeared = true }

    val lifecycle = LocalLifecycleOwner.current.lifecycle
    LaunchedEffect(attempt) {
        step = MatchmakingStep.Searching
        match = null
        countdown = null
        canCancel = true

        val fetched = coroutineScope {
            // Le défilement des profils, jusqu'à ce que l'adversaire soit connu.
            val shuffler = launch {
                while (true) {
                    shuffleAvatar = Avatars.all.random()
                    view.duelHaptic(DuelHaptic.Tick)
                    delay(SHUFFLE_MS)
                }
            }
            try {
                // Tant que la partie n'existe pas côté serveur, annuler ne coûte rien.
                delay(Random.nextLong(SEARCH_MIN_MS, SEARCH_MAX_MS + 1))
                // App passée à l'arrière-plan pendant la recherche : la partie n'est créée qu'au
                // retour, sinon elle se jouerait toute seule, sans personne devant.
                lifecycle.withStarted { }
                canCancel = false
                withTimeoutOrNull(START_TIMEOUT_MS) { app.duelService.startMatch() }?.getOrNull()
            } finally {
                shuffler.cancel()
            }
        }
        if (fetched == null) {
            step = MatchmakingStep.Failed
            view.duelHaptic(DuelHaptic.Wrong)
            return@LaunchedEffect
        }

        // Les images de la partie, chargées pendant la présentation de l'adversaire.
        val loader = context.applicationContext.imageLoader
        fetched.allQuestions.mapNotNull { it.imageUrl?.takeIf(String::isNotBlank) }.distinct().forEach { url ->
            loader.enqueue(duelQuestionImageRequest(context, url))
        }

        match = fetched
        step = MatchmakingStep.Found
        view.duelHaptic(DuelHaptic.OpponentFound)
        delay(FOUND_MS)

        for (value in 3 downTo 1) {
            countdown = value
            view.duelHaptic(DuelHaptic.Countdown)
            delay(COUNTDOWN_STEP_MS)
        }
        view.duelHaptic(DuelHaptic.CountdownFinal)
        // De même, la première question attend que l'app soit à l'écran.
        lifecycle.withStarted { }
        currentOnReady(fetched)
    }

    val closable = canCancel || step == MatchmakingStep.Failed
    // Le retour système vaut la croix : sans effet une fois la partie créée.
    BackHandler {
        if (closable) {
            view.duelHaptic(DuelHaptic.Tap)
            onCancel()
        }
    }

    val entrance by animateFloatAsState(
        targetValue = if (appeared) 1f else 0f,
        animationSpec = DSMotion.reveal(),
        label = "duelMatchEntrance",
    )

    Box(modifier = modifier.fillMaxSize().background(DS.canvas)) {
        Column(
            modifier = Modifier.align(Alignment.Center).widthIn(max = 640.dp).fillMaxSize(),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Box(
                modifier = Modifier.fillMaxWidth().padding(horizontal = 24.dp).padding(top = 8.dp).height(44.dp),
            ) {
                androidx.compose.animation.AnimatedVisibility(
                    visible = closable,
                    enter = fadeIn(tween(200)),
                    exit = fadeOut(tween(200)),
                    modifier = Modifier.align(Alignment.CenterStart),
                ) {
                    DuelRoundIconButton(
                        icon = Icons.Filled.Close,
                        contentDescription = text("common.close"),
                        // La fermeture vibre déjà (`DuelHaptic.Tap`).
                        haptic = false,
                        onClick = {
                            // La croix s'efface en 200 ms : pendant ce temps, elle ne ferme
                            // plus une partie déjà créée (ce serait un abandon).
                            if (canCancel || step == MatchmakingStep.Failed) {
                                view.duelHaptic(DuelHaptic.Tap)
                                onCancel()
                            }
                        },
                    )
                }
                // La ligue dans laquelle la partie se joue.
                if (league != null) {
                    DuelShrinkText(
                        text = DuelFormat.leagueName(context, league, language).uppercaseIn(language),
                        fontSize = 12.sp,
                        fontWeight = FontWeight.ExtraBold,
                        color = DS.accent,
                        textAlign = TextAlign.Center,
                        minScale = 0.7f,
                        letterSpacing = 1.sp,
                        modifier = Modifier.align(Alignment.Center).padding(horizontal = 56.dp),
                    )
                }
            }

            Spacer(Modifier.weight(1f).heightIn(min = 12.dp))

            OpponentSlot(
                step = step,
                match = match,
                shuffleAvatar = shuffleAvatar,
                language = language,
                modifier = Modifier.graphicsLayer {
                    translationY = -40.dp.toPx() * (1f - entrance)
                    alpha = entrance.coerceIn(0f, 1f)
                },
            )

            val versusScale by animateFloatAsState(
                targetValue = if (step == MatchmakingStep.Found) 1.12f else 1f,
                animationSpec = duelSpring(response = 0.45f, damping = 0.6f),
                label = "duelVersusScale",
            )
            DuelVersusBadge(
                number = countdown,
                counting = true,
                modifier = Modifier.padding(vertical = 26.dp).graphicsLayer {
                    scaleX = versusScale
                    scaleY = versusScale
                },
            )

            DuelVersusCard(
                avatarId = player.avatarId,
                initial = player.initial,
                handle = player.handle,
                language = language,
                trophies = player.trophies,
                ring = DS.accent,
                modifier = Modifier.graphicsLayer {
                    translationY = 40.dp.toPx() * (1f - entrance)
                    alpha = entrance.coerceIn(0f, 1f)
                },
            )

            Spacer(Modifier.weight(1f).heightIn(min = 12.dp))

            Box(
                modifier = Modifier.fillMaxWidth().padding(horizontal = 24.dp).padding(bottom = 24.dp),
                contentAlignment = Alignment.Center,
            ) {
                if (step == MatchmakingStep.Failed) {
                    DuelPlayButton(
                        text = text("duel.match.retry"),
                        onClick = {
                            view.duelHaptic(DuelHaptic.Tap)
                            attempt += 1
                        },
                    )
                } else {
                    val found = step == MatchmakingStep.Found
                    val hintColor by animateColorAsState(
                        targetValue = if (found) DS.accent else DS.inkSecondary,
                        animationSpec = DSMotion.snappy(),
                        label = "duelMatchHint",
                    )
                    Text(
                        text = text(if (found) "duel.match.found" else "duel.match.hint"),
                        fontFamily = PlusJakartaSans,
                        fontWeight = FontWeight.SemiBold,
                        fontSize = 13.sp,
                        lineHeight = 18.sp,
                        color = hintColor,
                        textAlign = TextAlign.Center,
                        modifier = Modifier.heightIn(min = 40.dp),
                    )
                }
            }
        }
    }
}

// ---------------------------------------------------------------- les deux camps

/**
 * L'emplacement de l'adversaire : les profils qui défilent au centre du radar pendant la
 * recherche, puis l'adversaire tiré par le serveur.
 */
@Composable
private fun OpponentSlot(
    step: MatchmakingStep,
    match: DuelMatch?,
    shuffleAvatar: String,
    language: AppLanguage,
    modifier: Modifier = Modifier,
) {
    val context = LocalContext.current
    val opponent = match?.opponent?.takeIf { step == MatchmakingStep.Found }
    Column(
        modifier = modifier.fillMaxWidth(),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Box(modifier = Modifier.height(150.dp), contentAlignment = Alignment.Center) {
            androidx.compose.animation.AnimatedVisibility(
                visible = step == MatchmakingStep.Searching,
                enter = fadeIn(tween(200)),
                exit = fadeOut(tween(200)),
            ) {
                DuelSearchRadar(color = DS.accent, size = 104.dp)
            }
            AnimatedContent(
                targetState = opponent,
                transitionSpec = {
                    (scaleIn(duelSpring(response = 0.45f, damping = 0.6f), initialScale = 0.4f) + fadeIn(tween(200)))
                        .togetherWith(fadeOut(tween(150)))
                },
                contentAlignment = Alignment.Center,
                label = "duelOpponentAvatar",
            ) { found ->
                if (found != null) {
                    DuelAvatar(
                        avatarId = found.avatarId,
                        initial = found.initial,
                        size = 104.dp,
                        ring = DuelPalette.saffron,
                        ringWidth = 4.dp,
                    )
                } else {
                    val failed = step == MatchmakingStep.Failed
                    DuelAvatar(
                        avatarId = shuffleAvatar,
                        initial = "?",
                        size = 104.dp,
                        ring = DS.surface,
                        ringWidth = 4.dp,
                        modifier = Modifier
                            .alpha(if (failed) 0.4f else 0.9f)
                            .blur(if (failed) 6.dp else 1.5.dp, BlurredEdgeTreatment.Unbounded),
                    )
                }
            }
        }

        AnimatedContent(
            targetState = opponent,
            transitionSpec = {
                (slideInVertically(duelSpring(response = 0.45f, damping = 0.6f)) { -it / 2 } + fadeIn(tween(200)))
                    .togetherWith(fadeOut(tween(150)))
            },
            contentAlignment = Alignment.Center,
            label = "duelOpponentName",
        ) { found ->
            if (found != null) {
                Column(
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.spacedBy(6.dp),
                    modifier = Modifier.padding(horizontal = 24.dp),
                ) {
                    Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                        DuelShrinkText(
                            text = "@${found.handle}",
                            fontSize = 20.sp,
                            fontWeight = FontWeight.Bold,
                            color = DS.ink,
                            minScale = 0.7f,
                            modifier = Modifier.weight(1f, fill = false),
                        )
                        if (found.flag.isNotEmpty()) {
                            // Le drapeau n'ajoute rien à la lecture d'écran du pseudo.
                            Text(text = found.flag, fontSize = 20.sp, modifier = Modifier.clearAndSetSemantics {})
                        }
                    }
                    DuelTrophyCount(value = found.trophies, language = language, size = 15.dp, color = DS.inkSecondary)
                }
            } else {
                val failed = step == MatchmakingStep.Failed
                Column(
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.spacedBy(6.dp),
                    modifier = Modifier.padding(horizontal = 32.dp),
                ) {
                    Text(
                        text = StringStore.text(context, if (failed) "duel.match.failed.title" else "duel.match.searching", language),
                        fontFamily = PlusJakartaSans,
                        fontWeight = FontWeight.Bold,
                        fontSize = 20.sp,
                        lineHeight = 26.sp,
                        color = DS.ink,
                        textAlign = TextAlign.Center,
                    )
                    Text(
                        text = StringStore.text(context, if (failed) "duel.match.failed.body" else "duel.match.searching.body", language),
                        fontFamily = PlusJakartaSans,
                        fontWeight = FontWeight.Medium,
                        fontSize = 15.sp,
                        lineHeight = 20.sp,
                        color = DS.inkSecondary,
                        textAlign = TextAlign.Center,
                    )
                    if (!failed) {
                        DuelWaitingDots(color = DS.accent, modifier = Modifier.padding(top = 8.dp))
                    }
                }
            }
        }
    }
}

/**
 * Des anneaux qui s'élargissent (l'adversaire choisit sa matière, un ami tarde à répondre).
 */
@Composable
internal fun DuelPulseRings(color: Color, modifier: Modifier = Modifier) {
    val transition = rememberInfiniteTransition(label = "duelPulse")
    val rings = (0 until 3).map { index ->
        transition.animateFloat(
            initialValue = 0f,
            targetValue = 1f,
            animationSpec = infiniteRepeatable(
                animation = tween(1_800, easing = LinearOutSlowInEasing),
                repeatMode = RepeatMode.Restart,
                initialStartOffset = StartOffset(index * 600),
            ),
            label = "duelPulse$index",
        )
    }
    Canvas(modifier = modifier.clearAndSetSemantics {}) {
        val radius = size.minDimension / 2
        rings.forEach { ring ->
            val progress = ring.value
            drawCircle(
                color = color.copy(alpha = 0.5f * 0.7f * (1f - progress)),
                radius = radius * (1f + 1.1f * progress),
                style = Stroke(width = 2.dp.toPx()),
            )
        }
    }
}
