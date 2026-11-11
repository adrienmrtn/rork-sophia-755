package app.rork.sophia.ui.duels

import android.os.SystemClock
import androidx.activity.compose.BackHandler
import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInVertically
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.key
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableLongStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalView
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.rork.sophia.SophiaApplication
import app.rork.sophia.data.DuelInviteError
import app.rork.sophia.data.StringStore
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.domain.DuelAnswer
import app.rork.sophia.domain.DuelFriendStart
import app.rork.sophia.domain.DuelFriendState
import app.rork.sophia.domain.DuelOpponent
import app.rork.sophia.domain.uppercaseIn
import app.rork.sophia.ui.LocalFullBleedBackground
import app.rork.sophia.ui.components.softPress
import app.rork.sophia.ui.theme.PlusJakartaSans
import app.rork.sophia.ui.theme.SophiaAppearance
import coil.imageLoader
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.coroutines.withTimeout
import kotlin.math.ceil

/** Ce qui ouvre un duel entre amis : un défi à lancer, ou une invitation qu'on vient d'accepter. */
sealed class DuelFriendEntry {
    data class Challenge(val userId: String, val handle: String, val avatarId: String?) : DuelFriendEntry()

    /** Invitation acceptée : la partie existe déjà. */
    data class Incoming(val start: DuelFriendStart) : DuelFriendEntry()
}

private enum class FriendStage {
    /** Le défi est parti, on attend la réponse de l'ami. */
    Waiting,

    /** Refusé, sans réponse, ami occupé, ou envoi impossible. */
    Failed,

    /** La partie est créée : 3, 2, 1. */
    Countdown,
    Playing,
    Result,
}

/**
 * Un duel entre amis en plein écran : l'attente de la réponse à un défi (15 secondes), le compte
 * à rebours commun, la partie en direct, puis le résultat. Aucun trophée en jeu. Même
 * enchaînement que `ios/Sophia/Views/Duels/DuelFriendFlowView.swift`.
 */
@Composable
fun DuelFriendFlow(
    entry: DuelFriendEntry,
    language: AppLanguage,
    onClose: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val context = LocalContext.current
    val view = LocalView.current
    val app = context.applicationContext as SophiaApplication
    val service = app.duelLiveService
    val scope = rememberCoroutineScope()
    fun text(key: String, vararg args: Any): String = StringStore.text(context, key, language, *args)

    val home by app.duelService.home.collectAsState()
    val socialHandle by app.socialService.myHandle.collectAsState()
    val progress by app.progressManager.progress.collectAsState()

    var stage by remember { mutableStateOf(FriendStage.Waiting) }
    var me by remember { mutableStateOf<DuelOpponent?>(null) }
    var friend by remember { mutableStateOf<DuelOpponent?>(null) }
    var friendOnline by remember { mutableStateOf(false) }
    var inviteId by remember { mutableStateOf<String?>(null) }
    // L'instant (horloge de l'appareil, ms) où l'invitation tombe.
    var waitingDeadline by remember { mutableLongStateOf(0L) }
    var failureKey by remember { mutableStateOf("duel.friend.noAnswer") }
    var countdown by remember { mutableStateOf<Int?>(null) }
    var game by remember { mutableStateOf<DuelGameModel?>(null) }
    var summary by remember { mutableStateOf<DuelSummary?>(null) }
    // Numéro de la tentative : une revanche repart d'un défi neuf.
    var attempt by remember { mutableIntStateOf(0) }
    // L'ami à défier pour cette tentative (l'adversaire de la partie finie, pour une revanche).
    var target by remember { mutableStateOf((entry as? DuelFriendEntry.Challenge)) }
    val gameJob = remember { arrayOfNulls<Job>(1) }

    val player = DuelPlayerIdentity(
        handle = me?.handle ?: home?.handle ?: socialHandle ?: "",
        avatarId = me?.avatarId ?: progress.avatarId,
        trophies = me?.trophies ?: home?.profile?.trophies ?: 0,
    )

    fun fail(key: String) {
        inviteId = null
        failureKey = key
        view.duelHaptic(DuelHaptic.Wrong)
        stage = FriendStage.Failed
    }

    fun finish(finished: DuelSummary) {
        gameJob[0]?.cancel()
        gameJob[0] = null
        summary = finished
        stage = FriendStage.Result
    }

    /** Quitter en pleine partie : j'ai perdu ; mon ami la finit seul. */
    fun abandon(model: DuelGameModel) {
        if (stage != FriendStage.Playing) return
        service.leave(model.match.matchId)
        finish(model.abandonSummary())
    }

    /** La partie est créée : les deux joueurs la démarrent au même instant. */
    suspend fun begin(start: DuelFriendStart) {
        val startsAt = SystemClock.elapsedRealtime() + maxOf(start.startsInMs, 0)
        me = start.me
        friend = start.opponent
        // Les images des questions, chargées pendant le compte à rebours.
        val loader = context.imageLoader
        start.match.allQuestions.mapNotNull { it.imageUrl }.distinct().forEach { url ->
            loader.enqueue(duelQuestionImageRequest(context, url))
        }
        stage = FriendStage.Countdown
        view.duelHaptic(DuelHaptic.OpponentFound)

        for (value in listOf(3, 2, 1)) {
            val wait = startsAt - value * 1_000L - SystemClock.elapsedRealtime()
            if (wait > 0) delay(wait)
            if (startsAt - SystemClock.elapsedRealtime() > (value - 1) * 1_000L) {
                countdown = value
                view.duelHaptic(DuelHaptic.Countdown)
            }
        }
        val wait = startsAt - SystemClock.elapsedRealtime()
        if (wait > 0) delay(wait)
        view.duelHaptic(DuelHaptic.CountdownFinal)

        val matchId = start.matchId
        val link = object : DuelLiveLink {
            override val startsAtMs = startsAt

            // Bornés à 5 s : une requête qui ne revient pas ne doit pas figer la partie.
            override suspend fun state(): DuelFriendState = withTimeout(LIVE_CALL_TIMEOUT_MS) { service.state(matchId) }

            override suspend fun answer(index: Int, answer: DuelAnswer): DuelFriendState =
                withTimeout(LIVE_CALL_TIMEOUT_MS) { service.answer(matchId, index, answer) }

            override suspend fun pick(round: Int, subject: String): DuelFriendState =
                withTimeout(LIVE_CALL_TIMEOUT_MS) { service.pick(matchId, round, subject) }
        }
        val model = DuelGameModel(match = start.match, live = link, haptic = { view.duelHaptic(it) })
        game = model
        stage = FriendStage.Playing
        gameJob[0]?.cancel()
        gameJob[0] = scope.launch {
            model.run()
            if (stage == FriendStage.Playing && game === model && model.phase == DuelPhase.Finished) {
                finish(model.summary)
            }
        }
    }

    /** Revanche : un nouveau défi au même ami. */
    fun rematch() {
        val opponent = summary?.match?.opponent
        val userId = opponent?.userId
        if (opponent == null || userId == null) {
            onClose()
            return
        }
        target = DuelFriendEntry.Challenge(userId, opponent.handle, opponent.avatarId)
        game = null
        summary = null
        attempt += 1
    }

    fun cancel() {
        inviteId?.let { service.cancelInvite(it) }
        onClose()
    }

    // Le déroulé d'une tentative : l'envoi du défi, l'attente de la réponse, puis la partie.
    LaunchedEffect(attempt) {
        if (attempt == 0 && entry is DuelFriendEntry.Incoming) {
            begin(entry.start)
            return@LaunchedEffect
        }
        val challenged = target ?: return@LaunchedEffect
        stage = FriendStage.Waiting
        countdown = null
        inviteId = null
        waitingDeadline = 0L

        val sent = try {
            service.invite(challenged.userId)
        } catch (cancelled: CancellationException) {
            throw cancelled
        } catch (error: Throwable) {
            fail(
                when (DuelInviteError.from(error)) {
                    DuelInviteError.FriendBusy -> "duel.friend.busy"
                    DuelInviteError.FriendUnavailable -> "duel.friend.unavailable"
                    else -> "duel.friend.failed"
                },
            )
            return@LaunchedEffect
        }
        me = sent.me
        friend = sent.friend
        friendOnline = sent.online
        inviteId = sent.inviteId
        waitingDeadline = SystemClock.elapsedRealtime() + sent.expiresInMs

        // On interroge le serveur chaque seconde jusqu'à la réponse de l'ami.
        while (true) {
            delay(900)
            val outcome = try {
                service.inviteStatus(sent.inviteId)
            } catch (cancelled: CancellationException) {
                throw cancelled
            } catch (_: Throwable) {
                if (SystemClock.elapsedRealtime() > waitingDeadline + 8_000) {
                    fail("duel.friend.noAnswer")
                    return@LaunchedEffect
                }
                continue
            }
            when (outcome.status) {
                "pending" -> continue
                "accepted" -> {
                    val start = outcome.match ?: continue
                    inviteId = null
                    begin(start)
                    return@LaunchedEffect
                }
                "declined" -> {
                    fail("duel.friend.declined")
                    return@LaunchedEffect
                }
                "busy" -> {
                    fail("duel.friend.busy")
                    return@LaunchedEffect
                }
                else -> {
                    fail("duel.friend.noAnswer")
                    return@LaunchedEffect
                }
            }
        }
    }

    // « Occupé » tant qu'un défi attend ou qu'une partie se joue ; sur l'écran de résultat, on
    // redevient défiable (c'est ce qui permet la revanche), et le serveur l'apprend tout de suite.
    LaunchedEffect(stage) {
        val busy = stage == FriendStage.Waiting || stage == FriendStage.Countdown || stage == FriendStage.Playing
        service.isInFriendDuel = busy
        if (!busy) service.pingNow()
    }
    // Écran fermé autrement que par ses boutons : on ne laisse ni invitation ni partie en plan.
    val latestStage by rememberUpdatedState(stage)
    val latestGame by rememberUpdatedState(game)
    val latestInvite by rememberUpdatedState(inviteId)
    DisposableEffect(Unit) {
        onDispose {
            if (latestStage == FriendStage.Playing) latestGame?.let { service.leave(it.match.matchId) }
            latestInvite?.let { service.cancelInvite(it) }
            service.isInFriendDuel = false
            service.pingNow()
        }
    }

    // Les marges des barres du système sont peintes par la racine de l'app : en nuit, comme l'écran.
    val setFullBleed = LocalFullBleedBackground.current
    DisposableEffect(Unit) {
        setFullBleed(SolidColor(DuelPalette.night))
        SophiaAppearance.darkBackdropBehindBars = true
        onDispose {
            setFullBleed(null)
            SophiaAppearance.darkBackdropBehindBars = false
        }
    }

    BackHandler(enabled = stage == FriendStage.Waiting || stage == FriendStage.Failed) {
        if (stage == FriendStage.Waiting) cancel() else onClose()
    }
    // Pendant le compte à rebours, retour ne fait rien : la partie démarre pour les deux.
    BackHandler(enabled = stage == FriendStage.Countdown) {}

    Box(
        modifier = modifier
            .fillMaxSize()
            .background(DuelPalette.night)
            // Rien de ce qui est sous la partie ne doit recevoir de touche.
            .pointerInput(Unit) {},
    ) {
        val shownStage = when (stage) {
            FriendStage.Waiting, FriendStage.Failed, FriendStage.Countdown -> 0
            FriendStage.Playing -> 1
            FriendStage.Result -> 2
        }
        AnimatedContent(
            targetState = shownStage,
            transitionSpec = {
                val ease = tween<Float>(400, easing = FastOutSlowInEasing)
                if (targetState == 1) {
                    (slideInVertically(tween(400, easing = FastOutSlowInEasing)) { it } + fadeIn(ease)).togetherWith(fadeOut(ease))
                } else {
                    fadeIn(ease).togetherWith(fadeOut(ease))
                }
            },
            modifier = Modifier.fillMaxSize(),
            label = "friendDuelStage",
        ) { shown ->
            when (shown) {
                0 -> Lobby(
                    stage = stage,
                    me = me,
                    friend = friend,
                    fallbackFriendHandle = target?.handle,
                    fallbackFriendAvatar = target?.avatarId,
                    player = player,
                    friendOnline = friendOnline,
                    waitingDeadline = waitingDeadline,
                    countdown = countdown,
                    failureKey = failureKey,
                    canCancel = target != null,
                    league = home?.currentLeague,
                    language = language,
                    onCancel = {
                        view.duelHaptic(DuelHaptic.Tap)
                        cancel()
                    },
                    onClose = {
                        view.duelHaptic(DuelHaptic.Tap)
                        onClose()
                    },
                )
                1 -> game?.let { model ->
                    DuelGameScreen(model = model, player = player, language = language, onAbandon = { abandon(model) })
                }
                else -> summary?.let { finished ->
                    key(finished.match.matchId) {
                        DuelResultScreen(
                            summary = finished,
                            player = player,
                            home = home,
                            result = null,
                            resultFailed = false,
                            language = language,
                            onRetrySend = {},
                            onPlayAgain = { rematch() },
                            onDone = onClose,
                        )
                    }
                }
            }
        }
    }
}

private const val LIVE_CALL_TIMEOUT_MS = 5_000L

/** L'attente et le compte à rebours : l'ami en haut, le rond central, moi en bas. */
@Composable
private fun Lobby(
    stage: FriendStage,
    me: DuelOpponent?,
    friend: DuelOpponent?,
    fallbackFriendHandle: String?,
    fallbackFriendAvatar: String?,
    player: DuelPlayerIdentity,
    friendOnline: Boolean,
    waitingDeadline: Long,
    countdown: Int?,
    failureKey: String,
    canCancel: Boolean,
    league: app.rork.sophia.domain.DuelLeague?,
    language: AppLanguage,
    onCancel: () -> Unit,
    onClose: () -> Unit,
) {
    val context = LocalContext.current
    fun text(key: String, vararg args: Any): String = StringStore.text(context, key, language, *args)
    val friendHandle = friend?.handle ?: fallbackFriendHandle ?: ""
    Box(modifier = Modifier.fillMaxSize()) {
        DuelLeagueBackdrop(league = league, modifier = Modifier.fillMaxSize().duelUnderSystemBars())
        Box(
            modifier = Modifier
                .fillMaxSize()
                .duelUnderSystemBars()
                .background(
                    Brush.verticalGradient(listOf(DuelPalette.night.copy(alpha = 0.72f), DuelPalette.night.copy(alpha = 0.9f))),
                ),
        )
        Column(
            modifier = Modifier
                .align(Alignment.Center)
                .widthIn(max = 640.dp)
                .fillMaxSize()
                .statusBarsPadding()
                .navigationBarsPadding(),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Text(
                text = text("duel.friend.title").uppercaseIn(language),
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.Bold,
                fontSize = 12.sp,
                letterSpacing = 1.6.sp,
                color = DuelPalette.saffron,
                modifier = Modifier.padding(top = 18.dp),
            )
            Spacer(Modifier.weight(1f))
            LobbyCard(
                who = friend,
                handle = friendHandle,
                avatarId = friend?.avatarId ?: fallbackFriendAvatar,
                ring = DuelPalette.coral,
                online = friendOnline && stage == FriendStage.Waiting,
                language = language,
            )
            LobbyBadge(stage = stage, waitingDeadline = waitingDeadline, countdown = countdown)
            LobbyCard(
                who = me,
                handle = me?.handle ?: player.handle,
                avatarId = me?.avatarId ?: player.avatarId,
                ring = DuelPalette.saffron,
                online = false,
                language = language,
            )
            Spacer(Modifier.weight(1f))

            Column(
                modifier = Modifier.fillMaxWidth().padding(horizontal = 24.dp).padding(bottom = 24.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(14.dp),
            ) {
                when {
                    // Invitation acceptée : la partie arrive, rien à attendre ni à annuler.
                    stage == FriendStage.Waiting && !canCancel -> Spacer(Modifier.heightIn(min = 40.dp))
                    stage == FriendStage.Waiting -> {
                        Text(
                            text = text("duel.game.waiting", friendHandle),
                            fontFamily = PlusJakartaSans,
                            fontWeight = FontWeight.SemiBold,
                            fontSize = 15.sp,
                            color = Color.White.copy(alpha = 0.8f),
                            textAlign = TextAlign.Center,
                        )
                        Text(
                            text = text("duel.friend.cancel"),
                            fontFamily = PlusJakartaSans,
                            fontWeight = FontWeight.SemiBold,
                            fontSize = 17.sp,
                            color = Color.White,
                            textAlign = TextAlign.Center,
                            modifier = Modifier
                                .fillMaxWidth()
                                .softPress(onClick = onCancel)
                                .clip(CircleShape)
                                .background(Color.White.copy(alpha = 0.16f))
                                .padding(vertical = 15.dp),
                        )
                    }
                    stage == FriendStage.Failed -> {
                        Text(
                            text = text(failureKey, friendHandle),
                            fontFamily = PlusJakartaSans,
                            fontWeight = FontWeight.SemiBold,
                            fontSize = 17.sp,
                            lineHeight = 23.sp,
                            color = Color.White,
                            textAlign = TextAlign.Center,
                        )
                        DuelPlayButton(text = text("common.close"), onClick = onClose)
                    }
                    else -> Text(
                        text = text("duel.friend.ready"),
                        fontFamily = PlusJakartaSans,
                        fontWeight = FontWeight.Bold,
                        fontSize = 15.sp,
                        color = Color.White.copy(alpha = 0.85f),
                        textAlign = TextAlign.Center,
                        modifier = Modifier.heightIn(min = 40.dp),
                    )
                }
            }
        }
    }
}

@Composable
private fun LobbyCard(
    who: DuelOpponent?,
    handle: String,
    avatarId: String?,
    ring: Color,
    online: Boolean,
    language: AppLanguage,
) {
    Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(12.dp)) {
        Box {
            DuelAvatar(
                avatarId = avatarId,
                initial = handle.take(1).uppercase(java.util.Locale.ROOT),
                size = 104.dp,
                ring = ring,
                ringWidth = 4.dp,
            )
            if (online) {
                DuelOnlineDot(size = 20.dp, modifier = Modifier.align(Alignment.BottomEnd).offset(x = (-4).dp, y = (-4).dp))
            }
        }
        Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(6.dp)) {
            DuelFitText(text = "@$handle", fontSize = 22.sp, color = Color.White)
            if (who != null) DuelTrophyCount(value = who.trophies, language = language, size = 16.dp, color = Color.White)
        }
    }
}

/** Le rond central : les secondes qui restent à l'ami pour répondre, puis 3, 2, 1. */
@Composable
private fun LobbyBadge(stage: FriendStage, waitingDeadline: Long, countdown: Int?) {
    val failed = stage == FriendStage.Failed
    val scale by animateFloatAsState(
        targetValue = if (stage == FriendStage.Countdown) 1.12f else 1f,
        animationSpec = duelSpring(response = 0.45f, damping = 0.6f),
        label = "friendBadge",
    )
    // Les secondes restantes, relues quatre fois par seconde tant que l'invitation attend.
    var secondsLeft by remember { mutableIntStateOf(0) }
    LaunchedEffect(stage, waitingDeadline) {
        while (stage == FriendStage.Waiting && waitingDeadline > 0L) {
            secondsLeft = maxOf(ceil((waitingDeadline - SystemClock.elapsedRealtime()) / 1000.0).toInt(), 0)
            delay(250)
        }
    }
    Box(
        modifier = Modifier
            .padding(vertical = 26.dp)
            .size(72.dp)
            .graphicsLayer {
                scaleX = scale
                scaleY = scale
            }
            .clip(CircleShape)
            .background(if (failed) Color.White.copy(alpha = 0.2f) else DuelPalette.saffron),
        contentAlignment = Alignment.Center,
    ) {
        val label = when {
            countdown != null -> countdown.toString()
            stage == FriendStage.Waiting && waitingDeadline > 0L -> secondsLeft.toString()
            else -> "VS"
        }
        Text(
            text = label,
            fontFamily = PlusJakartaSans,
            fontWeight = FontWeight.ExtraBold,
            fontSize = when {
                countdown != null -> 38.sp
                label == "VS" -> 24.sp
                else -> 30.sp
            },
            style = DuelTabularDigits,
            color = if (failed) Color.White else DuelPalette.night,
            maxLines = 1,
        )
    }
}

/**
 * Ce qui présente un duel entre amis par-dessus n'importe quel écran, comme
 * `DuelFriendPresenter` sur iOS : `MainTabs` lit [entry] et pose [DuelFriendFlow] au-dessus de
 * tout. Un seul duel à la fois : un défi demandé pendant une partie est ignoré.
 */
object DuelFriendPresenter {
    var entry by mutableStateOf<DuelFriendEntry?>(null)
        private set

    fun present(next: DuelFriendEntry) {
        if (entry == null) entry = next
    }

    fun dismiss() {
        entry = null
    }
}

/**
 * Une invitation reçue, en bandeau par-dessus l'écran en cours : qui défie, puis Refuser et
 * Accepter. Elle disparaît d'elle-même quand elle expire (`DuelLiveService.incoming`).
 */
@Composable
fun DuelInviteBanner(language: AppLanguage, modifier: Modifier = Modifier) {
    val context = LocalContext.current
    val view = LocalView.current
    val app = context.applicationContext as SophiaApplication
    val service = app.duelLiveService
    val scope = rememberCoroutineScope()
    val invite by service.incoming.collectAsState()
    // Le dernier bandeau montré reste dessiné le temps de sortir.
    var shown by remember { mutableStateOf(invite) }
    LaunchedEffect(invite) {
        if (invite != null) {
            shown = invite
            view.duelHaptic(DuelHaptic.OpponentFound)
        }
    }
    var answering by remember { mutableStateOf(false) }
    androidx.compose.animation.AnimatedVisibility(
        visible = invite != null && DuelFriendPresenter.entry == null,
        enter = slideInVertically(tween(350, easing = FastOutSlowInEasing)) { -it } + fadeIn(),
        exit = androidx.compose.animation.slideOutVertically(tween(250)) { -it } + fadeOut(),
        modifier = modifier,
    ) {
        val current = shown ?: return@AnimatedVisibility
        val shape = androidx.compose.foundation.shape.RoundedCornerShape(22.dp)
        Column(
            modifier = Modifier
                .statusBarsPadding()
                .padding(horizontal = 12.dp, vertical = 8.dp)
                .widthIn(max = 560.dp)
                .fillMaxWidth()
                .clip(shape)
                .background(DuelPalette.night)
                .pointerInput(Unit) {}
                .padding(14.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            androidx.compose.foundation.layout.Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                DuelAvatar(
                    avatarId = current.from.avatarId,
                    initial = current.from.initial,
                    size = 44.dp,
                    ring = DuelPalette.saffron,
                    ringWidth = 2.dp,
                )
                Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
                    DuelFitText(text = "@${current.from.handle}", fontSize = 17.sp, color = Color.White)
                    Text(
                        text = StringStore.text(context, "duel.invite.banner", language),
                        fontFamily = PlusJakartaSans,
                        fontWeight = FontWeight.Medium,
                        fontSize = 14.sp,
                        color = Color.White.copy(alpha = 0.8f),
                    )
                }
            }
            androidx.compose.foundation.layout.Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                Text(
                    text = StringStore.text(context, "friends.requests.decline", language),
                    fontFamily = PlusJakartaSans,
                    fontWeight = FontWeight.SemiBold,
                    fontSize = 15.sp,
                    color = Color.White,
                    textAlign = TextAlign.Center,
                    maxLines = 1,
                    modifier = Modifier
                        .weight(1f)
                        .softPress(onClick = {
                            view.duelHaptic(DuelHaptic.Tap)
                            service.decline(current)
                        })
                        .clip(CircleShape)
                        .background(Color.White.copy(alpha = 0.16f))
                        .padding(vertical = 12.dp),
                )
                Text(
                    text = StringStore.text(context, "friends.requests.accept", language),
                    fontFamily = PlusJakartaSans,
                    fontWeight = FontWeight.Bold,
                    fontSize = 15.sp,
                    color = DuelPalette.night,
                    textAlign = TextAlign.Center,
                    maxLines = 1,
                    modifier = Modifier
                        .weight(1f)
                        .softPress(onClick = {
                            if (answering) return@softPress
                            answering = true
                            view.duelHaptic(DuelHaptic.CountdownFinal)
                            scope.launch {
                                // Acceptée et encore valable : la partie s'ouvre par-dessus l'écran en cours.
                                val start = service.respond(current, accept = true)
                                answering = false
                                if (start != null) DuelFriendPresenter.present(DuelFriendEntry.Incoming(start))
                            }
                        })
                        .clip(CircleShape)
                        .background(DuelPalette.saffron)
                        .padding(vertical = 12.dp),
                )
            }
        }
    }
}
