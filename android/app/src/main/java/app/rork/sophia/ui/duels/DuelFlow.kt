package app.rork.sophia.ui.duels

import android.os.SystemClock
import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInVertically
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.key
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalView
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleEventObserver
import androidx.lifecycle.compose.LocalLifecycleOwner
import kotlinx.coroutines.delay
import app.rork.sophia.SophiaApplication
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.domain.DuelHome
import app.rork.sophia.domain.DuelMatch
import app.rork.sophia.domain.DuelResult
import app.rork.sophia.ui.theme.DS
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch

private enum class DuelStage { Matchmaking, Playing, Result }

/**
 * L'envoi d'une fin de partie doit aboutir même si l'écran se ferme entre-temps (le joueur
 * abandonne puis ferme aussitôt) : il ne vit donc pas dans la composition.
 */
private val duelBackgroundScope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)

/**
 * Une partie classée de bout en bout, en plein écran par-dessus les onglets : recherche
 * d'adversaire, partie en quatre manches, résultat (trophées, ligue), puis « rejouer » (une
 * nouvelle recherche sans quitter l'écran) ou retour à l'accueil des duels par [onClose].
 * Même enchaînement que `ios/Sophia/Views/Duels/DuelFlowView.swift`.
 */
@Composable
fun DuelFlow(language: AppLanguage, onClose: () -> Unit, modifier: Modifier = Modifier) {
    val context = LocalContext.current
    val view = LocalView.current
    val app = context.applicationContext as SophiaApplication
    val service = app.duelService
    val scope = rememberCoroutineScope()

    val home by service.home.collectAsState()
    val socialHandle by app.socialService.myHandle.collectAsState()
    val progress by app.progressManager.progress.collectAsState()
    val player = DuelPlayerIdentity(
        handle = home?.handle ?: socialHandle ?: "you",
        avatarId = progress.avatarId,
        trophies = home?.profile?.trophies ?: 0,
    )

    var stage by remember { mutableStateOf(DuelStage.Matchmaking) }
    var game by remember { mutableStateOf<DuelGameModel?>(null) }
    var summary by remember { mutableStateOf<DuelSummary?>(null) }
    var result by remember { mutableStateOf<DuelResult?>(null) }
    var resultFailed by remember { mutableStateOf(false) }
    // Numéro de la partie dans cette session : une nouvelle recherche repart d'un écran neuf.
    var round by remember { mutableIntStateOf(0) }
    // L'accueil tel qu'il était au lancement de la partie : le résultat s'anime depuis lui.
    var homeAtStart by remember { mutableStateOf<DuelHome?>(null) }
    // La coroutine qui joue la partie en cours.
    val gameJob = remember { arrayOfNulls<Job>(1) }

    fun send(finished: DuelSummary) {
        resultFailed = false
        val matchId = finished.match.matchId
        duelBackgroundScope.launch {
            val outcome = service.finishMatch(matchId, finished.answers, finished.abandoned, finished.pick)
            // La réponse d'une partie précédente (réseau lent, puis « Rejouer ») ne doit pas
            // s'afficher sur le résultat de la suivante.
            if (summary?.match?.matchId != matchId) return@launch
            outcome.onSuccess { result = it }.onFailure { resultFailed = true }
        }
    }

    fun finish(finished: DuelSummary) {
        gameJob[0]?.cancel()
        gameJob[0] = null
        summary = finished
        result = null
        stage = DuelStage.Result
        send(finished)
    }

    /** Quitter en pleine partie : une défaite, envoyée telle quelle au serveur. */
    fun abandon(model: DuelGameModel) {
        // Une partie déjà finie (ou déjà abandonnée) ne s'abandonne plus.
        if (stage != DuelStage.Playing) return
        finish(model.abandonSummary())
    }

    fun start(match: DuelMatch) {
        homeAtStart = service.home.value
        val model = DuelGameModel(match = match, haptic = { view.duelHaptic(it) })
        game = model
        stage = DuelStage.Playing
        gameJob[0]?.cancel()
        gameJob[0] = scope.launch {
            model.run()
            // Un abandon a pu passer juste avant : il garde la main.
            if (stage == DuelStage.Playing && game === model && model.phase == DuelPhase.Finished) {
                finish(model.summary)
            }
        }
    }

    fun playAgain() {
        // Le résultat affiché reste en place le temps de s'effacer ; `finish` le remplacera.
        game = null
        resultFailed = false
        round += 1
        stage = DuelStage.Matchmaking
    }

    // « Une partie est à l'écran » pour toute la durée du flux : l'accueil n'envoie pas la fin
    // de partie en attente pendant ce temps. À la sortie, l'accueil des duels, resté monté
    // dessous, se recharge de lui-même (trophées, classement).
    DisposableEffect(service) {
        service.setPlaying(true)
        onDispose { service.setPlaying(false) }
    }

    // Les écrans d'une partie sont blancs, comme le reste de l'app : les marges des barres du
    // système gardent le fond de la racine et leurs icônes sombres. Seule l'annonce d'une
    // montée de ligue passe sous les barres (`DuelPromotionOverlay`).

    // Quitter l'app en pleine partie au-delà de 15 s est un abandon : un adversaire ne reste
    // pas à attendre. En deçà (une notification, un appel refusé), la partie continue, et le
    // chrono de la question a tourné pendant l'absence.
    val lifecycleOwner = LocalLifecycleOwner.current
    val currentStage by rememberUpdatedState(stage)
    val currentGame by rememberUpdatedState(game)
    DisposableEffect(lifecycleOwner) {
        var leftAppAt: Long? = null
        // Au bout de 15 s d'absence, la partie est abandonnée sans attendre le retour : elle ne
        // doit pas se jouer seule jusqu'au bout et partir comme une partie normale.
        var absence: Job? = null
        val observer = LifecycleEventObserver { _, event ->
            when (event) {
                Lifecycle.Event.ON_STOP ->
                    if (currentStage == DuelStage.Playing && leftAppAt == null) {
                        leftAppAt = SystemClock.elapsedRealtime()
                        absence?.cancel()
                        absence = scope.launch {
                            delay(DuelRules.MAX_ABSENCE_MS + 1)
                            currentGame?.let { if (it.phase != DuelPhase.Finished) abandon(it) }
                        }
                    }
                Lifecycle.Event.ON_START -> {
                    absence?.cancel()
                    absence = null
                    val left = leftAppAt
                    leftAppAt = null
                    val model = currentGame
                    if (left != null && model != null && currentStage == DuelStage.Playing &&
                        model.phase != DuelPhase.Finished &&
                        DuelRules.abandonsAfterAbsence(SystemClock.elapsedRealtime() - left)
                    ) {
                        abandon(model)
                    }
                }
                else -> Unit
            }
        }
        lifecycleOwner.lifecycle.addObserver(observer)
        onDispose {
            absence?.cancel()
            lifecycleOwner.lifecycle.removeObserver(observer)
        }
    }

    Box(
        modifier = modifier
            .fillMaxSize()
            .background(DS.canvas)
            // Rien de ce qui est sous la partie (les onglets) ne doit recevoir de touche.
            .pointerInput(Unit) {},
    ) {
        AnimatedContent(
            targetState = stage,
            transitionSpec = {
                val ease = tween<Float>(400, easing = FastOutSlowInEasing)
                if (targetState == DuelStage.Playing) {
                    (slideInVertically(tween(400, easing = FastOutSlowInEasing)) { it } + fadeIn(ease)).togetherWith(fadeOut(ease))
                } else {
                    fadeIn(ease).togetherWith(fadeOut(ease))
                }
            },
            modifier = Modifier.fillMaxSize(),
            label = "duelStage",
        ) { shown ->
            when (shown) {
                DuelStage.Matchmaking -> key(round) {
                    DuelMatchmakingScreen(
                        player = player,
                        league = home?.currentLeague,
                        language = language,
                        onReady = { match -> if (stage == DuelStage.Matchmaking) start(match) },
                        onCancel = onClose,
                    )
                }
                DuelStage.Playing -> game?.let { model ->
                    DuelGameScreen(
                        model = model,
                        player = player,
                        language = language,
                        onAbandon = { abandon(model) },
                    )
                }
                DuelStage.Result -> summary?.let { finished ->
                    // Un écran neuf par partie : le compteur de trophées ne reprend pas l'ancien.
                    key(finished.match.matchId) {
                        DuelResultScreen(
                            summary = finished,
                            player = player,
                            home = homeAtStart ?: home,
                            result = result,
                            resultFailed = resultFailed,
                            language = language,
                            onRetrySend = { send(finished) },
                            onPlayAgain = { playAgain() },
                            onDone = onClose,
                        )
                    }
                }
            }
        }
    }
}
