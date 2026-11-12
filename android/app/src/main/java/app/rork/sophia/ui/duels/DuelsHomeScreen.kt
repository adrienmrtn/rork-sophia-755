package app.rork.sophia.ui.duels

import androidx.compose.animation.core.EaseInOut
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Image
import androidx.compose.foundation.ScrollState
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material.icons.filled.Bolt
import androidx.compose.material.icons.filled.EmojiEvents
import androidx.compose.material.icons.filled.LocalFireDepartment
import androidx.compose.material.icons.filled.WifiOff
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.material3.pulltorefresh.PullToRefreshBox
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.key
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.runtime.snapshotFlow
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalView
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.compose.LocalLifecycleOwner
import androidx.lifecycle.repeatOnLifecycle
import app.rork.sophia.R
import app.rork.sophia.SophiaApplication
import app.rork.sophia.data.SignInOutcome
import app.rork.sophia.data.StringStore
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.domain.DuelHome
import app.rork.sophia.domain.DuelLeaderboardEntry
import app.rork.sophia.domain.DuelProfile
import app.rork.sophia.domain.DuelRecentMatch
import app.rork.sophia.ui.components.DSCountUp
import app.rork.sophia.ui.components.DSMotion
import app.rork.sophia.ui.components.ScreenTitle
import app.rork.sophia.ui.components.SophiaPrimaryButton
import app.rork.sophia.ui.components.SophiaSecondaryButton
import app.rork.sophia.ui.components.dsPopIn
import app.rork.sophia.ui.components.dsStagger
import app.rork.sophia.ui.components.pressable
import app.rork.sophia.ui.components.sophiaCard
import app.rork.sophia.ui.newgen.AvatarCircle
import app.rork.sophia.ui.theme.DS
import app.rork.sophia.ui.theme.PlusJakartaSans
import app.rork.sophia.ui.theme.uppercaseInApp
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.NonCancellable
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.drop
import kotlinx.coroutines.flow.filter
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import app.rork.sophia.domain.DuelLeague
import androidx.compose.animation.fadeOut
import androidx.compose.animation.fadeIn
import androidx.compose.animation.scaleIn
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.snap
import androidx.compose.animation.core.animateFloatAsState
import kotlin.math.roundToInt
import kotlinx.coroutines.Job
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.animation.animateContentSize
import androidx.compose.material.icons.filled.KeyboardArrowUp
import androidx.compose.material.icons.filled.KeyboardArrowDown
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.geometry.Offset
import androidx.compose.foundation.Canvas
import androidx.compose.ui.semantics.contentDescription

/** Le classement des amis (leurs pastilles « en ligne ») est relu à ce rythme tant que l'onglet est affiché. */
private const val LEADERBOARD_REFRESH_MS = 15_000L

/**
 * L'onglet Duels (maquette AEr22) : ma ligue et mes trophées, le bouton pour chercher un
 * adversaire, mes statistiques, le classement des amis et mes dernières parties. Sans compte,
 * il propose de se connecter : trophées et parties sont gardés côté serveur.
 *
 * [isActive] : l'onglet est à l'écran (il reste monté quand on en sort) ; [flowShown] : une
 * partie est en cours par-dessus, l'accueil ne se recharge pas pendant ce temps ; [onPlay]
 * ouvre la partie ([DuelFlow]).
 *
 * Même écran que `DuelsHomeView.swift`, mêmes règles de rechargement : quand l'état de
 * connexion change, quand l'onglet revient à l'écran, quand une partie se ferme, en tirant
 * la page ; et le classement seul toutes les 15 secondes tant que l'onglet est affiché.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun DuelsHomeScreen(
    language: AppLanguage,
    isActive: Boolean,
    flowShown: Boolean,
    onPlay: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val context = LocalContext.current
    val view = LocalView.current
    val app = context.applicationContext as SophiaApplication
    val auth = app.authService
    val service = app.duelService
    val scope = rememberCoroutineScope()
    val lifecycleOwner = LocalLifecycleOwner.current

    val userId by auth.userId.collectAsState()
    val bootstrapping by auth.bootstrapping.collectAsState()
    val home by service.home.collectAsState()
    val homeFailed by service.homeFailed.collectAsState()
    val leaderboard by service.leaderboard.collectAsState()
    val signedIn = userId != null

    // Lus depuis des tâches qui vivent plus longtemps qu'une recomposition.
    val matchShown by rememberUpdatedState(flowShown)
    val onScreen by rememberUpdatedState(isActive && !flowShown)

    var showLeagues by rememberSaveable { mutableStateOf(false) }
    var refreshing by remember { mutableStateOf(false) }
    var signingIn by remember { mutableStateOf(false) }
    var signInError by remember { mutableStateOf<String?>(null) }
    // Tenu ici, au-dessus de la page : revenir de la route des ligues retrouve la même position.
    val scrollState = rememberScrollState()
    // Au retour d'une victoire, la carte de ligue montre ces valeurs le temps que la jauge se
    // remplisse de l'ancien total de trophées au nouveau.
    var heroGain by remember { mutableStateOf<HeroGain?>(null) }
    var heroPulse by remember { mutableStateOf(false) }
    var showGainChip by remember { mutableStateOf(false) }
    var gainJob by remember { mutableStateOf<Job?>(null) }

    fun stopLeagueGain() {
        gainJob?.cancel()
        gainJob = null
        heroGain = null
        heroPulse = false
        showGainChip = false
    }

    // La jauge se remplit de l'ancien total au nouveau, avec une vibration à chaque cran et une
    // salve si une ligue tombe. Une seule fois : le service oublie le gain dès qu'il est pris.
    fun startLeagueGain() {
        // Le gain doit mener au total que la page affiche : sinon (résultat arrivé après coup,
        // autre partie entre-temps) on ne rejoue rien.
        val gain = service.takePendingLeagueGain() ?: return
        val current = service.home.value ?: return
        if (gain.after <= gain.before || current.profile.trophies != gain.after) return
        gainJob?.cancel()
        showLeagues = false
        showGainChip = false
        heroGain = HeroGain(
            trophies = gain.before,
            league = current.league(gain.before),
            progress = current.leagueProgress(gain.before),
            delta = gain.after - gain.before,
        )
        gainJob = scope.launch {
            scrollState.scrollTo(0)
            // Le temps que l'écran de partie finisse de se refermer.
            delay(750)
            showGainChip = true
            var league = current.league(gain.before)
            val delta = gain.after - gain.before
            val steps = minOf(delta, 30)
            for (step in 1..steps) {
                val fraction = step.toFloat() / steps
                val eased = 1f - (1f - fraction) * (1f - fraction)
                val value = gain.before + (delta * eased).roundToInt()
                // Un seuil tombe : la jauge va au bout, la ligue suivante prend la carte.
                while (true) {
                    val next = current.nextLeague(league) ?: break
                    if (value < next.minTrophies) break
                    heroGain = heroGain?.copy(trophies = next.minTrophies, progress = 1f)
                    delay(400)
                    view.duelHaptic(DuelHaptic.Promotion)
                    league = next
                    heroGain = heroGain?.copy(league = next, progress = 0f)
                    heroPulse = true
                    delay(450)
                    heroPulse = false
                    delay(450)
                }
                heroGain = heroGain?.copy(trophies = value, progress = current.leagueProgress(value))
                view.duelHaptic(DuelHaptic.TrophyTick)
                delay((34 + 56 * fraction).toLong())
            }
            view.duelHaptic(DuelHaptic.TrophyLanded)
            delay(1800)
            // La carte rend la main au profil, qui porte déjà le nouveau total.
            showGainChip = false
            heroGain = null
        }
    }

    suspend fun refresh() {
        if (auth.userId.value == null) {
            // Au lancement, la session n'est pas encore relue : la page gardée reste en place.
            if (!auth.bootstrapping.value) service.clearLocalState()
            return
        }
        // Mené à son terme même si l'écran quitte la composition entre-temps (un cours ouvert
        // par un lien, par exemple) : le service prend un appel annulé pour un échec de
        // chargement, et l'écran « connexion impossible » apparaîtrait au retour.
        withContext(NonCancellable) {
            service.refreshHome()
            service.refreshLeaderboard()
        }
    }

    // À la première visite, puis à chaque connexion ou déconnexion. Pendant une partie rien
    // ne se recharge : la fermeture de la partie s'en charge (plus bas).
    LaunchedEffect(userId, bootstrapping) {
        if (!matchShown) refresh()
    }
    // L'onglet reste monté : c'est son retour à l'écran qui recharge, pas sa composition. Le
    // même signal couvre la fin d'une partie (l'accueil redevient visible) ; la première
    // valeur est ignorée, la première visite étant déjà traitée ci-dessus.
    LaunchedEffect(Unit) {
        snapshotFlow { onScreen }
            .drop(1)
            .collect { visible ->
                if (visible) {
                    // Retour d'une partie gagnée : la montée des trophées, avant de recharger.
                    startLeagueGain()
                    refresh()
                } else {
                    stopLeagueGain()
                }
            }
    }
    // Les pastilles « en ligne » du classement, tant que l'onglet est affiché et l'app au
    // premier plan (iOS suspend ses tâches en arrière-plan, Android non : sans cela le
    // classement serait relu toutes les 15 secondes écran éteint).
    LaunchedEffect(isActive, lifecycleOwner) {
        if (!isActive) return@LaunchedEffect
        lifecycleOwner.lifecycle.repeatOnLifecycle(Lifecycle.State.STARTED) {
            while (true) {
                delay(LEADERBOARD_REFRESH_MS)
                if (auth.userId.value != null && !matchShown) service.refreshLeaderboard()
            }
        }
    }
    // Plus de page (déconnexion) : la route des ligues ne doit pas se rouvrir à la reconnexion.
    LaunchedEffect(home == null) {
        if (home == null) showLeagues = false
    }

    fun signIn() {
        // Garde, pas seulement un bouton désactivé : deux touches rapprochées lanceraient deux
        // demandes au gestionnaire d'identifiants, et la seconde annule la première.
        if (signingIn) return
        signingIn = true
        signInError = null
        // Tâche portée par l'écran entier : la partie « sans compte » quitte la composition
        // dès que la session s'ouvre, avant que la progression du compte ne soit rapatriée.
        scope.launch {
            val outcome = try {
                auth.signInWithGoogle(context)
            } catch (e: CancellationException) {
                throw e
            } catch (_: Exception) {
                null
            } finally {
                signingIn = false
            }
            // Les mêmes suites qu'une connexion depuis le profil (`CreateAccountCard`).
            if (auth.isSignedIn) {
                app.onboardingStore.markAccountOffered()
                runCatching { app.progressSyncService.pullOnLogin(app.progressManager.progress.value) }
            } else {
                signInError = when (outcome) {
                    is SignInOutcome.Failure -> outcome.message
                    SignInOutcome.Unavailable -> StringStore.text(context, "auth.unavailable.body", language)
                    else -> null
                }
            }
        }
    }

    Box(modifier = modifier.fillMaxSize().background(DS.canvas)) {
        val current = home
        when {
            bootstrapping && !signedIn -> DuelsLoading()
            !signedIn -> DuelsSignedOut(
                language = language,
                signingIn = signingIn,
                error = signInError,
                onSignIn = { signIn() },
            )
            current != null ->
                if (showLeagues) {
                    DuelLeagueRoadScreen(
                        home = current,
                        language = language,
                        onBack = { showLeagues = false },
                        backEnabled = isActive && !flowShown,
                    )
                } else {
                    PullToRefreshBox(
                        isRefreshing = refreshing,
                        onRefresh = {
                            scope.launch {
                                refreshing = true
                                try {
                                    // Un échec immédiat (hors ligne) laisserait l'indicateur
                                    // en place : il reste au moins le temps d'être vu.
                                    coroutineScope {
                                        launch { delay(450) }
                                        refresh()
                                    }
                                } finally {
                                    refreshing = false
                                }
                            }
                        },
                        modifier = Modifier.fillMaxSize(),
                    ) {
                        DuelsContent(
                            home = current,
                            leaderboard = leaderboard,
                            language = language,
                            scrollState = scrollState,
                            heroGain = heroGain,
                            heroPulse = heroPulse,
                            showGainChip = showGainChip,
                            pulsing = isActive && !flowShown,
                            onOpenLeagues = {
                                view.duelHaptic(DuelHaptic.Tap)
                                showLeagues = true
                            },
                            onPlay = {
                                view.duelHaptic(DuelHaptic.CountdownFinal)
                                onPlay()
                            },
                        )
                    }
                }
            homeFailed -> DuelsLoadFailed(
                language = language,
                // Le bouton secondaire vibre de lui-même.
                onRetry = { scope.launch { refresh() } },
            )
            else -> DuelsLoading()
        }
    }
}

// ---------------------------------------------------------------- page

@Composable
private fun DuelsContent(
    home: DuelHome,
    leaderboard: List<DuelLeaderboardEntry>,
    language: AppLanguage,
    scrollState: ScrollState,
    heroGain: HeroGain?,
    heroPulse: Boolean,
    showGainChip: Boolean,
    pulsing: Boolean,
    onOpenLeagues: () -> Unit,
    onPlay: () -> Unit,
) {
    val context = LocalContext.current
    Column(
        modifier = Modifier
            .fillMaxSize()
            .verticalScroll(scrollState)
            .padding(horizontal = 24.dp)
            .padding(top = 12.dp, bottom = 28.dp),
    ) {
        // Le titre de l'onglet et, à droite, les trophées du joueur dans leur pastille.
        Row(modifier = Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
            ScreenTitle(
                text = StringStore.text(context, "tab.duels", language),
                modifier = Modifier.weight(1f),
            )
            DuelTrophyCount(
                value = heroGain?.trophies ?: home.profile.trophies,
                language = language,
                size = 14.dp,
                color = DS.ink,
                modifier = Modifier
                    .clip(CircleShape)
                    .background(DS.accentTint)
                    .padding(horizontal = 12.dp, vertical = 8.dp),
            )
        }

        LeagueHero(
            home = home,
            language = language,
            gain = heroGain,
            pulse = heroPulse,
            showGainChip = showGainChip,
            onClick = onOpenLeagues,
            modifier = Modifier.padding(top = 14.dp).dsStagger(0),
        )
        PlayButton(
            language = language,
            pulsing = pulsing,
            onClick = onPlay,
            modifier = Modifier.padding(top = 14.dp).dsStagger(1),
        )
        StatsSection(
            profile = home.profile,
            language = language,
            modifier = Modifier.padding(top = 24.dp).dsStagger(2),
        )
        LeaderboardSection(
            home = home,
            leaderboard = leaderboard,
            language = language,
            modifier = Modifier.padding(top = 24.dp).dsStagger(3),
        )
        if (home.recent.isNotEmpty()) {
            RecentSection(
                matches = home.recent,
                language = language,
                modifier = Modifier.padding(top = 24.dp).dsStagger(4),
            )
        }
    }
}

/** La carte de ligue : l'illustration, le nom, les trophées et la jauge vers la suivante. */
@Composable
private fun LeagueHero(
    home: DuelHome,
    language: AppLanguage,
    gain: HeroGain?,
    pulse: Boolean,
    showGainChip: Boolean,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val context = LocalContext.current
    val trophies = gain?.trophies ?: home.profile.trophies
    val league = if (gain != null) gain.league else home.currentLeague
    val next = home.nextLeague(league)
    // La jauge glisse d'un cran à l'autre pendant la montée ; hors montée, elle suit le profil.
    val progress by animateFloatAsState(
        targetValue = gain?.progress ?: home.leagueProgress(trophies),
        animationSpec = if (gain != null) tween(durationMillis = 100, easing = LinearEasing) else snap(),
        label = "leagueProgress",
    )
    val gained = gain?.delta ?: 0
    // Une ligue qui tombe : la carte gonfle un instant, cerclée de safran.
    val pulseScale by animateFloatAsState(
        targetValue = if (pulse) 1.03f else 1f,
        animationSpec = duelSpring(response = 0.45f, damping = 0.5f),
        label = "leaguePulse",
    )
    val pulseBorder by animateFloatAsState(targetValue = if (pulse) 1f else 0f, label = "leaguePulseBorder")
    val shape = DS.cardShape
    Box(
        modifier = modifier
            .fillMaxWidth()
            .height(210.dp)
            .graphicsLayer {
                scaleX = pulseScale
                scaleY = pulseScale
            }
            // L'ouverture de la route vibre déjà (`DuelHaptic.Tap`).
            .pressable(onClick = onClick, scaleDown = 0.98f, haptic = false)
            .clip(shape),
    ) {
        DuelLeagueBackdrop(league = league, modifier = Modifier.matchParentSize())
        Box(
            modifier = Modifier
                .matchParentSize()
                .background(
                    Brush.verticalGradient(
                        listOf(
                            DuelTheme.scrim.copy(alpha = 0.32f),
                            DuelTheme.scrim.copy(alpha = 0.5f),
                            DuelTheme.scrim.copy(alpha = 0.82f),
                        ),
                    ),
                ),
        )
        Column(
            modifier = Modifier
                .align(Alignment.BottomStart)
                .fillMaxWidth()
                .padding(horizontal = 16.dp)
                .padding(bottom = 14.dp),
            verticalArrangement = Arrangement.spacedBy(6.dp),
        ) {
            Text(
                text = StringStore.text(context, "duel.league.position", language, league?.position ?: 1)
                    .uppercaseInApp(),
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.ExtraBold,
                fontSize = 12.sp,
                letterSpacing = 0.8.sp,
                color = Color.White,
                maxLines = 1,
            )
            DuelFitText(
                text = DuelFormat.leagueName(context, league, language),
                fontSize = 24.sp,
                color = Color.White,
                modifier = Modifier.fillMaxWidth(),
            )
            // Les trophées du joueur à gauche, le seuil de la ligue suivante à droite.
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                DuelTrophyCount(value = trophies, language = language, size = 14.dp, color = Color.White)
                AnimatedVisibility(
                    visible = showGainChip && gained > 0,
                    enter = scaleIn(initialScale = 0.3f, animationSpec = duelSpring(response = 0.4f, damping = 0.55f)) + fadeIn(),
                    exit = fadeOut(),
                ) {
                    Text(
                        text = "+$gained",
                        fontFamily = PlusJakartaSans,
                        fontWeight = FontWeight.ExtraBold,
                        fontSize = 13.sp,
                        style = DuelTabularDigits,
                        color = DuelPalette.night,
                        maxLines = 1,
                        modifier = Modifier
                            .clip(CircleShape)
                            .background(DuelPalette.saffron)
                            .padding(horizontal = 8.dp, vertical = 2.dp),
                    )
                }
                Spacer(Modifier.weight(1f))
                if (next != null) {
                    DuelTrophyCount(value = next.minTrophies, language = language, size = 13.dp, color = Color.White)
                }
            }
            DuelProgressBar(progress = progress, height = 8.dp)
            Text(
                text = if (next != null) {
                    StringStore.text(
                        context,
                        "duel.league.toNext",
                        language,
                        maxOf(next.minTrophies - trophies, 0),
                        DuelFormat.leagueName(context, next, language),
                    )
                } else {
                    StringStore.text(context, "duel.league.top", language)
                },
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.Medium,
                fontSize = 13.sp,
                lineHeight = 17.sp,
                color = DuelTheme.onArtSecondary,
                maxLines = 2,
                overflow = TextOverflow.Ellipsis,
            )
        }
        Row(
            modifier = Modifier
                .align(Alignment.TopEnd)
                .padding(12.dp)
                .clip(CircleShape)
                .background(Color.White.copy(alpha = 0.2f))
                .padding(start = 10.dp, end = 6.dp, top = 6.dp, bottom = 6.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Text(
                text = StringStore.text(context, "duel.league.all", language),
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.Bold,
                fontSize = 12.sp,
                color = Color.White,
                maxLines = 1,
            )
            Icon(
                Icons.AutoMirrored.Filled.KeyboardArrowRight,
                contentDescription = null,
                tint = Color.White,
                modifier = Modifier.size(16.dp),
            )
        }
        if (pulseBorder > 0.01f) {
            Box(
                modifier = Modifier
                    .matchParentSize()
                    .border(3.dp, DuelPalette.saffron.copy(alpha = pulseBorder), shape),
            )
        }
    }
}

/** Ce que la carte de ligue montre pendant la montée des trophées d'une victoire. */
private data class HeroGain(val trophies: Int, val league: DuelLeague?, val progress: Float, val delta: Int)

@Composable
private fun PlayButton(language: AppLanguage, pulsing: Boolean, onClick: () -> Unit, modifier: Modifier = Modifier) {
    val context = LocalContext.current
    // Le bouton respire doucement pour appeler la touche. L'animation ne tourne que lorsque
    // l'onglet est à l'écran : il reste monté, elle redessinerait sans fin une page cachée.
    val pulse = if (pulsing) {
        rememberInfiniteTransition(label = "duelPlayPulse").animateFloat(
            initialValue = 1f,
            targetValue = 1.015f,
            animationSpec = infiniteRepeatable(tween(1100, easing = EaseInOut), RepeatMode.Reverse),
            label = "duelPlayPulseScale",
        )
    } else {
        null
    }
    Column(modifier = modifier, verticalArrangement = Arrangement.spacedBy(8.dp)) {
        DuelPlayButton(
            text = StringStore.text(context, "duel.play", language),
            onClick = onClick,
            leadingIcon = Icons.Filled.Bolt,
            modifier = Modifier.graphicsLayer {
                val scale = pulse?.value ?: 1f
                scaleX = scale
                scaleY = scale
            },
        )
        Text(
            text = StringStore.text(context, "duel.play.caption", language),
            fontFamily = PlusJakartaSans,
            fontWeight = FontWeight.Normal,
            fontSize = 13.sp,
            color = DS.inkSecondary,
            textAlign = TextAlign.Center,
            modifier = Modifier.fillMaxWidth(),
        )
    }
}

// ---------------------------------------------------------------- statistiques

/**
 * Les statistiques en une carte, comme sur iOS : l'anneau de réussite et le partage victoires /
 * défaites en haut, les séries et le record de trophées en bas.
 */
@Composable
private fun StatsSection(profile: DuelProfile, language: AppLanguage, modifier: Modifier = Modifier) {
    val context = LocalContext.current
    val statValueStyle = DuelTabularDigits.copy(
        fontFamily = PlusJakartaSans,
        fontWeight = FontWeight.ExtraBold,
        fontSize = 16.sp,
    )
    Column(modifier = modifier, verticalArrangement = Arrangement.spacedBy(8.dp)) {
        DuelSectionTitle(text = StringStore.text(context, "duel.stats.title", language))
        Column(
            modifier = Modifier.fillMaxWidth().sophiaCard().padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(16.dp),
            ) {
                WinRateRing(profile = profile, language = language)
                // « 12 Duels », puis la barre victoires / défaites et sa légende (ou l'invitation à jouer).
                Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    Row(
                        modifier = Modifier.semantics(mergeDescendants = true) {},
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(6.dp),
                    ) {
                        DSCountUp(
                            value = profile.games,
                            durationMillis = 700,
                            style = DuelTabularDigits.copy(
                                fontFamily = PlusJakartaSans,
                                fontWeight = FontWeight.ExtraBold,
                                fontSize = 20.sp,
                            ),
                            color = DS.ink,
                            haptics = false,
                        )
                        DuelFitText(
                            text = StringStore.text(context, "duel.stats.games", language),
                            fontSize = 20.sp,
                            color = DS.ink,
                            minScale = 0.7f,
                            modifier = Modifier.weight(1f),
                        )
                    }
                    if (profile.games > 0) {
                        WinLossBar(profile = profile)
                        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                            SplitLegend(
                                color = DS.success,
                                value = profile.wins,
                                label = StringStore.text(context, "duel.stats.wins", language),
                                modifier = Modifier.weight(1f),
                            )
                            SplitLegend(
                                color = DS.danger,
                                value = profile.losses,
                                label = StringStore.text(context, "duel.stats.losses", language),
                            )
                        }
                    } else {
                        Text(
                            text = StringStore.text(context, "duel.stats.empty", language),
                            fontFamily = PlusJakartaSans,
                            fontWeight = FontWeight.Normal,
                            fontSize = 13.sp,
                            lineHeight = 18.sp,
                            color = DS.inkSecondary,
                        )
                    }
                }
            }
            Hairline()
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.Top,
                horizontalArrangement = Arrangement.spacedBy(6.dp),
            ) {
                StatCell(
                    icon = Icons.Filled.LocalFireDepartment,
                    tint = DuelPalette.saffron,
                    label = StringStore.text(context, "duel.stats.streak", language),
                    modifier = Modifier.weight(1f),
                ) {
                    DSCountUp(value = profile.winStreak, durationMillis = 600, style = statValueStyle, color = DS.ink, haptics = false)
                }
                StatCell(
                    icon = Icons.Filled.Bolt,
                    tint = DS.accent,
                    label = StringStore.text(context, "duel.stats.bestStreak", language),
                    modifier = Modifier.weight(1f),
                ) {
                    DSCountUp(value = profile.bestWinStreak, durationMillis = 600, style = statValueStyle, color = DS.ink, haptics = false)
                }
                StatCell(
                    icon = Icons.Filled.EmojiEvents,
                    tint = DuelPalette.saffron,
                    label = StringStore.text(context, "duel.stats.best", language),
                    modifier = Modifier.weight(1f),
                ) {
                    Text(
                        text = DuelFormat.number(profile.bestTrophies, language),
                        style = statValueStyle,
                        color = DS.ink,
                        maxLines = 1,
                    )
                }
            }
        }
    }
}

/** L'anneau de réussite : la part de victoires en vert, le reste en rouge pâle. Il se dessine à la première apparition. */
@Composable
private fun WinRateRing(profile: DuelProfile, language: AppLanguage) {
    val context = LocalContext.current
    val fraction = if (profile.games > 0) (profile.wins.toFloat() / profile.games).coerceIn(0f, 1f) else 0f
    var revealed by remember { mutableStateOf(false) }
    LaunchedEffect(Unit) { revealed = true }
    val sweep by animateFloatAsState(
        targetValue = if (revealed) fraction else 0f,
        animationSpec = tween(durationMillis = 900),
        label = "winRate",
    )
    val trackColor = if (profile.games > 0) DS.dangerTint else DS.accentTint
    val winColor = DS.success
    Box(
        modifier = Modifier.size(76.dp).semantics(mergeDescendants = true) {},
        contentAlignment = Alignment.Center,
    ) {
        Canvas(modifier = Modifier.matchParentSize()) {
            val stroke = 7.dp.toPx()
            val inset = stroke / 2
            val arcSize = Size(size.width - stroke, size.height - stroke)
            drawArc(
                color = trackColor,
                startAngle = 0f,
                sweepAngle = 360f,
                useCenter = false,
                topLeft = Offset(inset, inset),
                size = arcSize,
                style = Stroke(width = stroke),
            )
            if (sweep > 0f) {
                drawArc(
                    color = winColor,
                    startAngle = -90f,
                    sweepAngle = 360f * sweep,
                    useCenter = false,
                    topLeft = Offset(inset, inset),
                    size = arcSize,
                    style = Stroke(width = stroke, cap = StrokeCap.Round),
                )
            }
        }
        Column(
            modifier = Modifier.padding(horizontal = 12.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            DuelFitText(
                text = profile.winRate?.let { "$it %" } ?: "–",
                fontSize = 18.sp,
                color = DS.ink,
            )
            DuelFitText(
                text = StringStore.text(context, "duel.stats.winRate", language),
                fontSize = 10.sp,
                color = DS.inkSecondary,
                fontWeight = FontWeight.Normal,
                minScale = 0.6f,
            )
        }
    }
}

/** La barre partagée : victoires à gauche, défaites à droite, à proportion. */
@Composable
private fun WinLossBar(profile: DuelProfile) {
    Row(modifier = Modifier.fillMaxWidth().height(8.dp), horizontalArrangement = Arrangement.spacedBy(3.dp)) {
        if (profile.wins > 0) {
            Box(modifier = Modifier.weight(profile.wins.toFloat()).fillMaxHeight().clip(CircleShape).background(DS.success))
        }
        if (profile.losses > 0) {
            Box(modifier = Modifier.weight(profile.losses.toFloat()).fillMaxHeight().clip(CircleShape).background(DS.danger))
        }
        if (profile.wins == 0 && profile.losses == 0) {
            Box(modifier = Modifier.weight(1f).fillMaxHeight().clip(CircleShape).background(DS.hairline))
        }
    }
}

@Composable
private fun SplitLegend(color: Color, value: Int, label: String, modifier: Modifier = Modifier) {
    Row(
        modifier = modifier,
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(5.dp),
    ) {
        Box(modifier = Modifier.size(7.dp).clip(CircleShape).background(color))
        Text(
            text = value.toString(),
            fontFamily = PlusJakartaSans,
            fontWeight = FontWeight.Bold,
            fontSize = 13.sp,
            color = DS.ink,
            style = DuelTabularDigits,
            maxLines = 1,
        )
        Text(
            text = label,
            fontFamily = PlusJakartaSans,
            fontWeight = FontWeight.Medium,
            fontSize = 12.sp,
            color = DS.inkSecondary,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
        )
    }
}

/** Une case du bas de la carte : le pictogramme, la valeur, puis son libellé. */
@Composable
private fun StatCell(
    icon: ImageVector,
    tint: Color,
    label: String,
    modifier: Modifier = Modifier,
    value: @Composable () -> Unit,
) {
    Column(
        modifier = modifier.semantics(mergeDescendants = true) {},
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(3.dp),
    ) {
        Icon(icon, contentDescription = null, tint = tint, modifier = Modifier.size(20.dp))
        value()
        Text(
            text = label,
            fontFamily = PlusJakartaSans,
            fontWeight = FontWeight.Normal,
            fontSize = 11.sp,
            lineHeight = 14.sp,
            color = DS.inkSecondary,
            textAlign = TextAlign.Center,
            maxLines = 2,
            overflow = TextOverflow.Ellipsis,
        )
    }
}

// ---------------------------------------------------------------- classement entre amis

@Composable
private fun LeaderboardSection(
    home: DuelHome,
    leaderboard: List<DuelLeaderboardEntry>,
    language: AppLanguage,
    modifier: Modifier = Modifier,
) {
    val context = LocalContext.current
    Column(modifier = modifier, verticalArrangement = Arrangement.spacedBy(8.dp)) {
        DuelSectionTitle(text = StringStore.text(context, "duel.friends.title", language))
        Column(
            modifier = Modifier.fillMaxWidth().sophiaCard().padding(8.dp),
            verticalArrangement = Arrangement.spacedBy(4.dp),
        ) {
            // Le serveur renvoie toujours ma ligne : seul, c'est encore « pas d'amis ».
            if (leaderboard.none { !it.isMe }) {
                Text(
                    text = StringStore.text(context, "duel.friends.empty", language),
                    fontFamily = PlusJakartaSans,
                    fontWeight = FontWeight.Normal,
                    fontSize = 13.sp,
                    lineHeight = 18.sp,
                    color = DS.inkSecondary,
                    modifier = Modifier.fillMaxWidth().padding(8.dp),
                )
            } else {
                leaderboard.forEachIndexed { index, entry ->
                    key(entry.userId) {
                        LeaderboardRow(rank = index + 1, entry = entry, home = home, language = language)
                    }
                }
            }
        }
    }
}

@Composable
private fun LeaderboardRow(rank: Int, entry: DuelLeaderboardEntry, home: DuelHome, language: AppLanguage) {
    val context = LocalContext.current
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .background(if (entry.isMe) DS.accentTint else Color.Transparent, RoundedCornerShape(10.dp))
            .padding(horizontal = 8.dp, vertical = 10.dp)
            .semantics(mergeDescendants = true) {},
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        Text(
            text = rank.toString(),
            fontFamily = PlusJakartaSans,
            fontWeight = FontWeight.ExtraBold,
            fontSize = 14.sp,
            style = DuelTabularDigits,
            color = if (rank == 1) DuelPalette.saffron else DS.inkSecondary,
            maxLines = 1,
            modifier = Modifier.width(20.dp),
        )
        Box {
            AvatarCircle(avatarId = entry.avatarId, initial = entry.handle.take(1).uppercaseInApp(), size = 36.dp)
            if (entry.online) {
                DuelOnlineDot(size = 12.dp, modifier = Modifier.align(Alignment.BottomEnd).offset(x = 2.dp, y = 2.dp))
            }
        }
        Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(1.dp)) {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(6.dp),
            ) {
                Text(
                    text = "@${entry.handle}",
                    fontFamily = PlusJakartaSans,
                    fontWeight = FontWeight.Bold,
                    fontSize = 14.sp,
                    color = DS.ink,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                    modifier = Modifier.weight(1f, fill = false),
                )
                if (entry.isMe) {
                    Text(
                        text = StringStore.text(context, "duel.you", language),
                        fontFamily = PlusJakartaSans,
                        fontWeight = FontWeight.Bold,
                        fontSize = 11.sp,
                        color = DS.accent,
                        maxLines = 1,
                    )
                }
            }
            home.leagueAt(entry.leaguePosition)?.let { league ->
                Text(
                    text = DuelFormat.leagueName(context, league, language),
                    fontFamily = PlusJakartaSans,
                    fontWeight = FontWeight.Normal,
                    fontSize = 12.sp,
                    color = DS.inkSecondary,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                )
            }
        }
        DuelTrophyCount(value = entry.trophies, language = language, size = 14.dp, color = DS.ink)
        // Défier cet ami en duel (aucun trophée en jeu), s'il a les duels.
        if (!entry.isMe && entry.canChallenge) {
            val view = LocalView.current
            Box(
                modifier = Modifier
                    .size(44.dp)
                    // Le lancement du défi vibre déjà (`DuelHaptic.CountdownFinal`).
                    .pressable(
                        onClick = {
                            view.duelHaptic(DuelHaptic.CountdownFinal)
                            DuelFriendPresenter.present(
                                DuelFriendEntry.Challenge(userId = entry.userId, handle = entry.handle, avatarId = entry.avatarId),
                            )
                        },
                        scaleDown = 0.92f,
                        haptic = false,
                    )
                    .clip(CircleShape)
                    .background(DuelPalette.saffron)
                    .semantics { contentDescription = StringStore.text(context, "duel.friend.challenge", language) },
                contentAlignment = Alignment.Center,
            ) {
                Icon(Icons.Filled.Bolt, contentDescription = null, tint = DuelPalette.night, modifier = Modifier.size(20.dp))
            }
        }
    }
}

// ---------------------------------------------------------------- dernières parties

/** Nombre de parties montrées d'abord dans « Derniers duels », et ajoutées à chaque « Voir plus ». */
private const val RECENT_PAGE = 5

/**
 * Les dernières parties : cinq d'abord, puis « Voir plus » en ajoute cinq à chaque fois (le
 * serveur en garde dix) ; une fois tout montré, le bouton replie la liste.
 */
@Composable
private fun RecentSection(matches: List<DuelRecentMatch>, language: AppLanguage, modifier: Modifier = Modifier) {
    val context = LocalContext.current
    val view = LocalView.current
    var shownCount by rememberSaveable { mutableIntStateOf(RECENT_PAGE) }
    val shown = matches.take(maxOf(shownCount, RECENT_PAGE))
    val canExpand = shown.size < matches.size
    val canCollapse = !canExpand && matches.size > RECENT_PAGE
    Column(modifier = modifier, verticalArrangement = Arrangement.spacedBy(8.dp)) {
        DuelSectionTitle(text = StringStore.text(context, "duel.recent.title", language))
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .sophiaCard()
                .animateContentSize(DSMotion.snappy())
                .padding(horizontal = 16.dp, vertical = 2.dp),
        ) {
            shown.forEachIndexed { index, match ->
                key(match.matchId) {
                    if (index > 0) Hairline()
                    RecentRow(match = match, language = language)
                }
            }
            if (canExpand || canCollapse) {
                Hairline()
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        // « Voir plus » vibre déjà (`DuelHaptic.Tap`).
                        .pressable(
                            onClick = {
                                view.duelHaptic(DuelHaptic.Tap)
                                shownCount = if (canExpand) shown.size + RECENT_PAGE else RECENT_PAGE
                            },
                            scaleDown = 0.98f,
                            haptic = false,
                        )
                        .heightIn(min = 40.dp),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(6.dp, Alignment.CenterHorizontally),
                ) {
                    Text(
                        text = StringStore.text(context, if (canExpand) "duel.recent.more" else "duel.recent.less", language),
                        fontFamily = PlusJakartaSans,
                        fontWeight = FontWeight.Bold,
                        fontSize = 14.sp,
                        color = DS.accent,
                        maxLines = 1,
                    )
                    Icon(
                        imageVector = if (canExpand) Icons.Filled.KeyboardArrowDown else Icons.Filled.KeyboardArrowUp,
                        contentDescription = null,
                        tint = DS.accent,
                        modifier = Modifier.size(18.dp),
                    )
                }
            }
        }
    }
}

@Composable
private fun RecentRow(match: DuelRecentMatch, language: AppLanguage) {
    val context = LocalContext.current
    val outcomeKey = when {
        match.abandoned -> "duel.result.abandoned"
        match.won -> "duel.result.victory"
        else -> "duel.result.defeat"
    }
    val outcome = StringStore.text(context, outcomeKey, language)
    val delta = if (match.trophiesDelta > 0) "+${match.trophiesDelta}" else match.trophiesDelta.toString()
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 10.dp)
            .semantics(mergeDescendants = true) {},
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        AvatarCircle(avatarId = match.opponent.avatarId, initial = match.opponent.initial, size = 36.dp)
        Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(1.dp)) {
            Text(
                text = "@${match.opponent.handle} ${match.opponent.flag}".trim(),
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.Bold,
                fontSize = 14.sp,
                color = DS.ink,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
            )
            Text(
                text = if (match.abandoned) outcome else "$outcome · ${match.playerScore} – ${match.opponentScore}",
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.Bold,
                fontSize = 13.sp,
                color = if (match.won) DS.success else DS.danger,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
            )
        }
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(4.dp)) {
            Text(
                text = delta,
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.ExtraBold,
                fontSize = 14.sp,
                style = DuelTabularDigits,
                color = when {
                    match.trophiesDelta > 0 -> DS.success
                    match.trophiesDelta < 0 -> DS.danger
                    else -> DS.inkTertiary
                },
                maxLines = 1,
            )
            DuelTrophyIcon(size = 14.dp)
        }
    }
}

@Composable
private fun Hairline() {
    Box(modifier = Modifier.fillMaxWidth().height(1.dp).background(DS.hairline))
}

// ---------------------------------------------------------------- sans compte, sans réseau

@Composable
private fun DuelsLoading() {
    Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
        CircularProgressIndicator(color = DS.accent)
    }
}

@Composable
private fun DuelsSignedOut(language: AppLanguage, signingIn: Boolean, error: String?, onSignIn: () -> Unit) {
    val context = LocalContext.current
    Column(
        modifier = Modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(horizontal = 28.dp)
            .padding(top = 36.dp, bottom = 28.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(22.dp),
    ) {
        Image(
            painter = painterResource(R.drawable.duel_trophy),
            contentDescription = null,
            contentScale = ContentScale.Crop,
            modifier = Modifier
                .dsPopIn()
                .size(168.dp)
                .clip(RoundedCornerShape(40.dp)),
        )
        Column(
            modifier = Modifier.dsStagger(1),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(10.dp),
        ) {
            Text(
                text = StringStore.text(context, "duel.signedOut.title", language),
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.SemiBold,
                fontSize = 26.sp,
                lineHeight = 32.sp,
                color = DS.ink,
                textAlign = TextAlign.Center,
            )
            Text(
                text = StringStore.text(context, "duel.signedOut.body", language),
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.Normal,
                fontSize = 17.sp,
                lineHeight = 24.sp,
                color = DS.inkSecondary,
                textAlign = TextAlign.Center,
            )
        }
        // La connexion de l'app (Google), comme depuis le profil.
        SophiaPrimaryButton(
            text = StringStore.text(context, "auth.continueWithGoogle", language),
            onClick = onSignIn,
            enabled = !signingIn,
            modifier = Modifier.padding(top = 6.dp).widthIn(max = 420.dp).dsStagger(2),
        )
        if (error != null) {
            Text(
                text = error,
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.Medium,
                fontSize = 14.sp,
                color = DS.danger,
                textAlign = TextAlign.Center,
            )
        }
    }
}

@Composable
private fun DuelsLoadFailed(language: AppLanguage, onRetry: () -> Unit) {
    val context = LocalContext.current
    Column(
        modifier = Modifier.fillMaxSize().padding(32.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(14.dp, Alignment.CenterVertically),
    ) {
        Icon(Icons.Filled.WifiOff, contentDescription = null, tint = DS.inkTertiary, modifier = Modifier.size(32.dp))
        Text(
            text = StringStore.text(context, "duel.load.failed", language),
            fontFamily = PlusJakartaSans,
            fontWeight = FontWeight.Medium,
            fontSize = 17.sp,
            lineHeight = 24.sp,
            color = DS.inkSecondary,
            textAlign = TextAlign.Center,
        )
        // Le bouton secondaire vibre de lui-même.
        SophiaSecondaryButton(
            text = StringStore.text(context, "duel.match.retry", language),
            onClick = onRetry,
            modifier = Modifier.widthIn(max = 220.dp),
        )
    }
}
