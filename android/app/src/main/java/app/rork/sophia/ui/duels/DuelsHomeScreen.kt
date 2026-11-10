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
import androidx.compose.ui.draw.shadow
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
import app.rork.sophia.ui.components.ScreenTitle
import app.rork.sophia.ui.components.SectionLabel
import app.rork.sophia.ui.components.SophiaPrimaryButton
import app.rork.sophia.ui.components.SophiaSecondaryButton
import app.rork.sophia.ui.components.softPress
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

/** Le classement des amis (leurs pastilles « en ligne ») est relu à ce rythme tant que l'onglet est affiché. */
private const val LEADERBOARD_REFRESH_MS = 15_000L

/**
 * L'onglet Duels : ma ligue et mes trophées, le bouton pour chercher un adversaire, mes
 * statistiques, le classement des amis et mes dernières parties. Sans compte, il propose de
 * se connecter : trophées et parties sont gardés côté serveur.
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
            .filter { it }
            .collect { refresh() }
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
                onRetry = {
                    view.duelHaptic(DuelHaptic.Tap)
                    scope.launch { refresh() }
                },
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
    pulsing: Boolean,
    onOpenLeagues: () -> Unit,
    onPlay: () -> Unit,
) {
    val context = LocalContext.current
    Column(
        modifier = Modifier
            .fillMaxSize()
            .verticalScroll(scrollState)
            .padding(horizontal = 20.dp)
            .padding(top = 12.dp, bottom = 28.dp),
        verticalArrangement = Arrangement.spacedBy(22.dp),
    ) {
        Row(modifier = Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
            ScreenTitle(
                text = StringStore.text(context, "tab.duels", language),
                modifier = Modifier.weight(1f),
            )
            DuelTrophyCount(
                value = home.profile.trophies,
                language = language,
                size = 17.dp,
                color = DS.ink,
                modifier = Modifier
                    .clip(CircleShape)
                    .background(DS.surface)
                    .border(1.dp, DS.hairline, CircleShape)
                    .padding(horizontal = 14.dp, vertical = 8.dp),
            )
        }

        LeagueHero(home = home, language = language, onClick = onOpenLeagues)
        PlayButton(language = language, pulsing = pulsing, onClick = onPlay)
        StatsSection(profile = home.profile, language = language)
        LeaderboardSection(home = home, leaderboard = leaderboard, language = language)
        if (home.recent.isNotEmpty()) {
            RecentSection(matches = home.recent, language = language)
        }
    }
}

/** La carte de ligue : l'illustration, le nom, les trophées et la jauge vers la suivante. */
@Composable
private fun LeagueHero(home: DuelHome, language: AppLanguage, onClick: () -> Unit) {
    val context = LocalContext.current
    val league = home.currentLeague
    val next = home.nextLeague(league)
    val shape = RoundedCornerShape(28.dp)
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .height(280.dp)
            .softPress(onClick = onClick)
            .shadow(
                elevation = 8.dp,
                shape = shape,
                ambientColor = Color.Black.copy(alpha = 0.28f),
                spotColor = Color.Black.copy(alpha = 0.24f),
            )
            .clip(shape),
    ) {
        DuelLeagueBackdrop(league = league, modifier = Modifier.matchParentSize())
        Box(
            modifier = Modifier
                .matchParentSize()
                .background(
                    Brush.verticalGradient(
                        listOf(
                            Color.Transparent,
                            DuelPalette.night.copy(alpha = 0.25f),
                            DuelPalette.night.copy(alpha = 0.88f),
                        ),
                    ),
                ),
        )
        Column(
            modifier = Modifier.align(Alignment.BottomStart).fillMaxWidth().padding(18.dp),
            verticalArrangement = Arrangement.spacedBy(10.dp),
        ) {
            Text(
                text = StringStore.text(context, "duel.league.position", language, league?.position ?: 1)
                    .uppercaseInApp(),
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.Bold,
                fontSize = 12.sp,
                letterSpacing = 1.4.sp,
                color = DuelPalette.saffron,
                maxLines = 1,
            )
            DuelFitText(
                text = DuelFormat.leagueName(context, league, language),
                fontSize = 30.sp,
                color = Color.White,
                modifier = Modifier.fillMaxWidth(),
            )
            DuelProgressBar(progress = home.leagueProgress(home.profile.trophies))
            Text(
                text = if (next != null) {
                    StringStore.text(
                        context,
                        "duel.league.toNext",
                        language,
                        maxOf(next.minTrophies - home.profile.trophies, 0),
                        DuelFormat.leagueName(context, next, language),
                    )
                } else {
                    StringStore.text(context, "duel.league.top", language)
                },
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.SemiBold,
                fontSize = 13.sp,
                color = Color.White.copy(alpha = 0.85f),
            )
        }
        Row(
            modifier = Modifier
                .align(Alignment.TopEnd)
                .padding(14.dp)
                .clip(CircleShape)
                .background(DuelPalette.night.copy(alpha = 0.55f))
                .padding(start = 12.dp, end = 8.dp, top = 7.dp, bottom = 7.dp),
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
    }
}

@Composable
private fun PlayButton(language: AppLanguage, pulsing: Boolean, onClick: () -> Unit) {
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
    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
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
            fontWeight = FontWeight.Medium,
            fontSize = 13.sp,
            color = DS.inkSecondary,
            textAlign = TextAlign.Center,
            modifier = Modifier.fillMaxWidth(),
        )
    }
}

// ---------------------------------------------------------------- statistiques

@Composable
private fun StatsSection(profile: DuelProfile, language: AppLanguage) {
    val context = LocalContext.current
    Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
        SectionLabel(text = StringStore.text(context, "duel.stats.title", language))
        Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
            StatTile(
                value = profile.games.toString(),
                label = StringStore.text(context, "duel.stats.games", language),
                modifier = Modifier.weight(1f),
            )
            StatTile(
                value = profile.wins.toString(),
                label = StringStore.text(context, "duel.stats.wins", language),
                color = DS.success,
                modifier = Modifier.weight(1f),
            )
            StatTile(
                value = profile.losses.toString(),
                label = StringStore.text(context, "duel.stats.losses", language),
                color = DS.danger,
                modifier = Modifier.weight(1f),
            )
            StatTile(
                value = profile.winRate?.let { "$it %" } ?: "–",
                label = StringStore.text(context, "duel.stats.winRate", language),
                modifier = Modifier.weight(1f),
            )
        }
        Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
            StatRow(
                icon = Icons.Filled.LocalFireDepartment,
                label = StringStore.text(context, "duel.stats.streak", language),
                value = profile.winStreak.toString(),
                modifier = Modifier.weight(1f),
            )
            StatRow(
                icon = Icons.Filled.EmojiEvents,
                label = StringStore.text(context, "duel.stats.best", language),
                value = DuelFormat.number(profile.bestTrophies, language),
                modifier = Modifier.weight(1f),
            )
        }
    }
}

@Composable
private fun StatTile(value: String, label: String, modifier: Modifier = Modifier, color: Color = DS.ink) {
    Column(
        modifier = modifier
            .clip(DS.controlShape)
            .background(DS.surface)
            .border(1.dp, DS.hairline, DS.controlShape)
            .padding(horizontal = 4.dp, vertical = 14.dp)
            .semantics(mergeDescendants = true) {},
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(4.dp),
    ) {
        DuelFitText(text = value, fontSize = 22.sp, color = color)
        DuelFitText(
            text = label,
            fontSize = 11.sp,
            color = DS.inkTertiary,
            fontWeight = FontWeight.SemiBold,
            minScale = 0.7f,
        )
    }
}

@Composable
private fun StatRow(icon: ImageVector, label: String, value: String, modifier: Modifier = Modifier) {
    Row(
        modifier = modifier
            .clip(DS.controlShape)
            .background(DS.surface)
            .border(1.dp, DS.hairline, DS.controlShape)
            .padding(horizontal = 14.dp, vertical = 12.dp)
            .semantics(mergeDescendants = true) {},
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        Icon(icon, contentDescription = null, tint = DuelPalette.saffron, modifier = Modifier.size(15.dp))
        DuelFitText(
            text = label,
            fontSize = 12.sp,
            color = DS.inkSecondary,
            fontWeight = FontWeight.SemiBold,
            minScale = 0.7f,
            modifier = Modifier.weight(1f),
        )
        Text(
            text = value,
            fontFamily = PlusJakartaSans,
            fontWeight = FontWeight.Bold,
            fontSize = 15.sp,
            color = DS.ink,
            maxLines = 1,
        )
    }
}

// ---------------------------------------------------------------- classement entre amis

@Composable
private fun LeaderboardSection(home: DuelHome, leaderboard: List<DuelLeaderboardEntry>, language: AppLanguage) {
    val context = LocalContext.current
    Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
        SectionLabel(text = StringStore.text(context, "duel.friends.title", language))
        Column(modifier = Modifier.fillMaxWidth().sophiaCard()) {
            // Le serveur renvoie toujours ma ligne : seul, c'est encore « pas d'amis ».
            if (leaderboard.none { !it.isMe }) {
                Text(
                    text = StringStore.text(context, "duel.friends.empty", language),
                    fontFamily = PlusJakartaSans,
                    fontWeight = FontWeight.Medium,
                    fontSize = 15.sp,
                    color = DS.inkSecondary,
                    modifier = Modifier.fillMaxWidth().padding(16.dp),
                )
            } else {
                leaderboard.forEachIndexed { index, entry ->
                    key(entry.userId) {
                        if (index > 0) Hairline()
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
            .background(if (entry.isMe) DS.accentTint.copy(alpha = 0.6f) else Color.Transparent)
            .padding(horizontal = 16.dp, vertical = 12.dp)
            .semantics(mergeDescendants = true) {},
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Text(
            text = rank.toString(),
            fontFamily = PlusJakartaSans,
            fontWeight = FontWeight.Bold,
            fontSize = 15.sp,
            color = if (rank == 1) DuelPalette.saffron else DS.inkTertiary,
            maxLines = 1,
            modifier = Modifier.width(22.dp),
        )
        Box {
            AvatarCircle(avatarId = entry.avatarId, initial = entry.handle.take(1).uppercaseInApp(), size = 38.dp)
            if (entry.online) {
                DuelOnlineDot(size = 12.dp, modifier = Modifier.align(Alignment.BottomEnd).offset(x = 2.dp, y = 2.dp))
            }
        }
        Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(6.dp),
            ) {
                Text(
                    text = "@${entry.handle}",
                    fontFamily = PlusJakartaSans,
                    fontWeight = FontWeight.SemiBold,
                    fontSize = 15.sp,
                    color = DS.ink,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                    modifier = Modifier.weight(1f, fill = false),
                )
                if (entry.isMe) {
                    Text(
                        text = StringStore.text(context, "duel.you", language),
                        fontFamily = PlusJakartaSans,
                        fontWeight = FontWeight.SemiBold,
                        fontSize = 11.sp,
                        color = DS.accentSoft,
                        maxLines = 1,
                    )
                }
            }
            home.leagueAt(entry.leaguePosition)?.let { league ->
                Text(
                    text = DuelFormat.leagueName(context, league, language),
                    fontFamily = PlusJakartaSans,
                    fontWeight = FontWeight.Medium,
                    fontSize = 12.sp,
                    color = DS.inkTertiary,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                )
            }
        }
        DuelTrophyCount(value = entry.trophies, language = language, size = 15.dp, color = DS.ink)
    }
}

// ---------------------------------------------------------------- dernières parties

@Composable
private fun RecentSection(matches: List<DuelRecentMatch>, language: AppLanguage) {
    val context = LocalContext.current
    Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
        SectionLabel(text = StringStore.text(context, "duel.recent.title", language))
        Column(modifier = Modifier.fillMaxWidth().sophiaCard()) {
            matches.forEachIndexed { index, match ->
                key(match.matchId) {
                    if (index > 0) Hairline()
                    RecentRow(match = match, language = language)
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
            .padding(horizontal = 16.dp, vertical = 12.dp)
            .semantics(mergeDescendants = true) {},
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        AvatarCircle(avatarId = match.opponent.avatarId, initial = match.opponent.initial, size = 38.dp)
        Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
            Text(
                text = "@${match.opponent.handle} ${match.opponent.flag}".trim(),
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.SemiBold,
                fontSize = 15.sp,
                color = DS.ink,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
            )
            Text(
                text = if (match.abandoned) outcome else "$outcome · ${match.playerScore} – ${match.opponentScore}",
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.SemiBold,
                fontSize = 12.sp,
                color = if (match.won) DS.success else DS.danger,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
            )
        }
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(4.dp)) {
            Text(
                text = delta,
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.Bold,
                fontSize = 15.sp,
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
    val shape = RoundedCornerShape(40.dp)
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
                .size(168.dp)
                .shadow(
                    elevation = 8.dp,
                    shape = shape,
                    ambientColor = Color.Black.copy(alpha = 0.28f),
                    spotColor = Color.Black.copy(alpha = 0.24f),
                )
                .clip(shape),
        )
        Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(10.dp)) {
            Text(
                text = StringStore.text(context, "duel.signedOut.title", language),
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.ExtraBold,
                fontSize = 28.sp,
                lineHeight = 34.sp,
                color = DS.ink,
                textAlign = TextAlign.Center,
            )
            Text(
                text = StringStore.text(context, "duel.signedOut.body", language),
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.Medium,
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
            modifier = Modifier.padding(top = 6.dp).widthIn(max = 420.dp),
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
        SophiaSecondaryButton(
            text = StringStore.text(context, "duel.match.retry", language),
            onClick = onRetry,
            modifier = Modifier.widthIn(max = 220.dp),
        )
    }
}
