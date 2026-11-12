package app.rork.sophia.ui.social

import androidx.compose.animation.core.animateFloatAsState
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
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.GpsFixed
import androidx.compose.material.icons.filled.LocalFireDepartment
import androidx.compose.material.icons.outlined.Bolt
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardCapitalization
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.rork.sophia.SophiaApplication
import app.rork.sophia.data.FeatureFlags
import app.rork.sophia.data.FriendLeaderboardEntry
import app.rork.sophia.data.FriendPresence
import app.rork.sophia.data.FriendPublicStats
import app.rork.sophia.data.FriendsLeaderboardPeriod
import app.rork.sophia.data.ProgressManager
import app.rork.sophia.data.SendRequestOutcome
import app.rork.sophia.data.StringStore
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.domain.uppercaseIn
import app.rork.sophia.ui.components.ConfirmDialog
import app.rork.sophia.ui.components.DSCheckBadge
import app.rork.sophia.ui.components.DSEyebrow
import app.rork.sophia.ui.components.DSMotion
import app.rork.sophia.ui.components.SophiaPrimaryButton
import app.rork.sophia.ui.components.SophiaSecondaryButton
import app.rork.sophia.ui.components.dsPopIn
import app.rork.sophia.ui.components.dsShake
import app.rork.sophia.ui.components.dsStagger
import app.rork.sophia.ui.components.pressable
import app.rork.sophia.ui.components.rememberHaptics
import app.rork.sophia.ui.components.sophiaCard
import app.rork.sophia.ui.duels.DuelFormat
import app.rork.sophia.ui.duels.DuelFriendEntry
import app.rork.sophia.ui.duels.DuelFriendPresenter
import app.rork.sophia.ui.duels.DuelLeagueBackdrop
import app.rork.sophia.ui.duels.DuelOnlineDot
import app.rork.sophia.ui.duels.DuelPalette
import app.rork.sophia.ui.duels.DuelTrophyCount
import app.rork.sophia.ui.newgen.AvatarCircle
import app.rork.sophia.ui.newgen.Avatars
import app.rork.sophia.ui.newgen.BadgeRow
import app.rork.sophia.ui.profile.ProfileCenteredTitleBar
import app.rork.sophia.ui.profile.ProfileCountText
import app.rork.sophia.ui.profile.ProfileFillBar
import app.rork.sophia.ui.profile.ProfileGroupLabel
import app.rork.sophia.ui.profile.ProfilePillTabs
import app.rork.sophia.ui.profile.ProfileRoundButton
import app.rork.sophia.ui.profile.ProfileRowChevron
import app.rork.sophia.ui.profile.ProfileRowDivider
import app.rork.sophia.ui.profile.ProfileSectionHeader
import app.rork.sophia.ui.profile.ProfileTextField
import app.rork.sophia.ui.profile.profileRowPress
import app.rork.sophia.ui.theme.DS
import app.rork.sophia.ui.theme.PlusJakartaSans
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

/**
 * La page des amis dans le design « Elevate arrondi » : les demandes reçues, « Ajouter un ami »
 * par son @, son propre @ à modifier, puis le classement. Ouverte avec [initialFriendUserId],
 * elle montre directement le profil de cet ami.
 */
@Composable
fun FriendsScreen(
    modifier: Modifier = Modifier,
    language: AppLanguage = AppLanguage.FRENCH,
    initialFriendUserId: String? = null,
    onBack: () -> Unit,
) {
    val context = LocalContext.current
    val app = context.applicationContext as SophiaApplication
    val social = app.socialService
    val scope = rememberCoroutineScope()
    val haptics = rememberHaptics()
    val handle by social.myHandle.collectAsState()
    val pending by social.pendingRequests.collectAsState()
    val leaderboard by social.leaderboard.collectAsState()
    val period by social.period.collectAsState()
    val errorKey by social.errorKey.collectAsState()
    val signedIn by app.authService.userId.collectAsState()

    var handleInput by remember { mutableStateOf("") }
    var addInput by remember { mutableStateOf("") }
    var noticeKey by remember { mutableStateOf<String?>(null) }
    var sending by remember { mutableStateOf(false) }
    var friendStats by remember { mutableStateOf<FriendPublicStats?>(null) }
    // Secousse du champ dont la demande vient d'être refusée.
    var addShake by remember { mutableIntStateOf(0) }
    var handleShake by remember { mutableIntStateOf(0) }

    LaunchedEffect(handle) {
        if (handleInput.isEmpty() && handle != null) handleInput = handle!!
    }
    LaunchedEffect(signedIn) {
        if (signedIn != null) social.refreshAll()
    }
    LaunchedEffect(period) {
        if (signedIn != null) social.refreshLeaderboard()
    }
    // Opened by tapping a friend on the profile tab: land straight on their card. While it is
    // being read, only a spinner shows, so the friends page does not flash by first.
    var loadingFriend by remember { mutableStateOf(initialFriendUserId != null) }
    LaunchedEffect(initialFriendUserId) {
        val id = initialFriendUserId ?: return@LaunchedEffect
        try {
            friendStats = social.friendStats(id)
        } finally {
            loadingFriend = false
        }
    }

    friendStats?.let { stats ->
        FriendProfileSheet(
            language = language,
            stats = stats,
            onRemove = {
                scope.launch {
                    social.removeFriend(stats.user_id)
                    friendStats = null
                }
            },
            onBack = { friendStats = null },
        )
        return
    }

    val backLabel = StringStore.text(context, "elevateProfile.back", language)
    if (loadingFriend) {
        Column(
            modifier = modifier
                .fillMaxSize()
                .background(DS.canvas)
                .padding(start = 20.dp, end = 20.dp, top = 8.dp),
        ) {
            ProfileCenteredTitleBar(
                title = "",
                leading = {
                    ProfileRoundButton(
                        icon = Icons.AutoMirrored.Filled.ArrowBack,
                        contentDescription = backLabel,
                        onClick = onBack,
                    )
                },
            )
            Box(modifier = Modifier.fillMaxWidth().padding(top = 40.dp), contentAlignment = Alignment.Center) {
                CircularProgressIndicator(color = DS.accent, strokeWidth = 2.5.dp, modifier = Modifier.size(28.dp))
            }
        }
        return
    }
    Column(
        modifier = modifier
            .fillMaxSize()
            .background(DS.canvas)
            // The username and "add a friend" fields sit low on this screen; without this
            // the keyboard covered both them and the button next to them.
            .imePadding()
            .verticalScroll(rememberScrollState())
            .padding(start = 20.dp, end = 20.dp, top = 8.dp, bottom = 32.dp),
    ) {
        ProfileCenteredTitleBar(
            title = StringStore.text(context, "friends.title", language),
            leading = {
                ProfileRoundButton(
                    icon = Icons.AutoMirrored.Filled.ArrowBack,
                    contentDescription = backLabel,
                    onClick = onBack,
                )
            },
        )

        if (signedIn == null) {
            FriendsInfoCard(
                title = StringStore.text(context, "friends.signedOut.title", language),
                body = StringStore.text(context, "friends.signedOut.body", language),
                modifier = Modifier.padding(top = 14.dp).dsStagger(0),
            )
            return@Column
        }

        // Incoming requests first: they are the only thing here that expects an answer.
        if (pending.isNotEmpty()) {
            FriendRequestsCard(
                requests = pending,
                language = language,
                onRespond = { request, accept ->
                    scope.launch { social.respondToRequest(request.request_id, accept) }
                },
                modifier = Modifier.padding(top = 14.dp),
            )
        }

        // « Ajouter un ami » : son @, puis la demande part.
        Column(
            modifier = Modifier.padding(top = 20.dp).dsStagger(0),
            verticalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            ProfileGroupLabel(StringStore.text(context, "friends.add.title", language))
            Text(
                text = StringStore.text(context, "friends.add.requestSubtitle", language),
                fontFamily = PlusJakartaSans,
                fontSize = 15.sp,
                lineHeight = 21.sp,
                color = DS.inkSecondary,
            )
            Row(
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                ProfileTextField(
                    value = addInput,
                    onValueChange = {
                        addInput = it
                        noticeKey = null
                        social.clearError()
                    },
                    placeholder = StringStore.text(context, "friends.handle.placeholder", language),
                    prefix = "@",
                    modifier = Modifier.weight(1f).dsShake(trigger = addShake),
                    keyboardOptions = KeyboardOptions(
                        autoCorrectEnabled = false,
                        capitalization = KeyboardCapitalization.None,
                        imeAction = ImeAction.Send,
                    ),
                )
                FriendsInlineButton(
                    text = StringStore.text(context, "friends.add.short", language),
                    enabled = !sending && addInput.isNotBlank(),
                    onClick = {
                        scope.launch {
                            sending = true
                            social.sendFriendRequest(addInput)
                                .onSuccess { outcome ->
                                    addInput = ""
                                    noticeKey = when (outcome) {
                                        SendRequestOutcome.AUTO_ACCEPTED -> "friends.request.autoAccepted"
                                        SendRequestOutcome.SENT -> "friends.request.sent"
                                    }
                                    haptics.success()
                                }
                                .onFailure {
                                    haptics.error()
                                    addShake += 1
                                }
                            sending = false
                        }
                    },
                )
            }

            noticeKey?.let { key ->
                // Demande partie, @ enregistré : la coche se dessine, avec rebond.
                androidx.compose.runtime.key(key) {
                    Row(
                        modifier = Modifier.padding(top = 2.dp).dsPopIn(),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(8.dp),
                    ) {
                        DSCheckBadge(size = 22.dp)
                        Text(
                            text = StringStore.text(context, key, language),
                            fontFamily = PlusJakartaSans,
                            fontWeight = FontWeight.Bold,
                            fontSize = 13.sp,
                            lineHeight = 18.sp,
                            color = DS.success,
                        )
                    }
                }
            }
            errorKey?.let { key ->
                Text(
                    text = StringStore.text(context, key, language),
                    fontFamily = PlusJakartaSans,
                    fontWeight = FontWeight.Medium,
                    fontSize = 13.sp,
                    lineHeight = 18.sp,
                    color = DS.danger,
                    modifier = Modifier.padding(top = 2.dp),
                )
            }
        }

        // Son propre @, celui que les amis cherchent.
        Column(
            modifier = Modifier.padding(top = 24.dp).dsStagger(1),
            verticalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            ProfileGroupLabel(StringStore.text(context, "friends.handle.edit.title", language))
            Text(
                text = StringStore.text(context, "friends.handle.edit.subtitle", language),
                fontFamily = PlusJakartaSans,
                fontSize = 15.sp,
                lineHeight = 21.sp,
                color = DS.inkSecondary,
            )
            Row(
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                ProfileTextField(
                    value = handleInput,
                    onValueChange = {
                        handleInput = it
                        noticeKey = null
                        social.clearError()
                    },
                    placeholder = StringStore.text(context, "friends.handle.placeholder", language),
                    prefix = "@",
                    modifier = Modifier.weight(1f).dsShake(trigger = handleShake),
                    keyboardOptions = KeyboardOptions(
                        autoCorrectEnabled = false,
                        capitalization = KeyboardCapitalization.None,
                        imeAction = ImeAction.Done,
                    ),
                )
                FriendsInlineButton(
                    text = StringStore.text(context, "friends.handle.save", language),
                    enabled = handleInput.isNotBlank() && handleInput != handle,
                    onClick = {
                        scope.launch {
                            social.updateHandle(handleInput)
                                .onSuccess { saved ->
                                    // Show what was stored, not what was typed: the server trims the
                                    // "@" and lowercases, so the field used to disagree with the
                                    // handle friends actually search for. And say that it worked —
                                    // a silent save reads as a broken button.
                                    handleInput = saved
                                    noticeKey = "friends.handle.saved"
                                    haptics.success()
                                }
                                .onFailure {
                                    haptics.error()
                                    handleShake += 1
                                }
                        }
                    },
                )
            }
            Text(
                text = StringStore.text(context, "friends.handle.rules", language),
                fontFamily = PlusJakartaSans,
                fontSize = 12.sp,
                lineHeight = 17.sp,
                color = DS.inkSecondary,
            )
        }

        FriendsLeaderboardSection(
            language = language,
            period = period,
            leaderboard = leaderboard,
            onPeriodChange = { social.setPeriod(it) },
            onOpenFriend = { entry ->
                scope.launch { friendStats = social.friendStats(entry.user_id) }
            },
            modifier = Modifier.padding(top = 24.dp).dsStagger(2),
            // La page défile en entier : le classement se pose à la suite, sans défilement à lui.
            nestedScroll = true,
        )
    }
}

/** Le petit bouton plein à côté d'un champ (« Ajouter », « Enregistrer »). */
@Composable
private fun FriendsInlineButton(text: String, enabled: Boolean, onClick: () -> Unit) {
    Box(
        modifier = Modifier
            .height(52.dp)
            .pressable(onClick = onClick, enabled = enabled, scaleDown = 0.94f)
            .clip(DS.controlShape)
            .background(if (enabled) DS.accent else DS.accent.copy(alpha = 0.35f))
            .padding(horizontal = 18.dp),
        contentAlignment = Alignment.Center,
    ) {
        Text(
            text = text,
            fontFamily = PlusJakartaSans,
            fontWeight = FontWeight.SemiBold,
            fontSize = 15.sp,
            color = Color.White,
            maxLines = 1,
        )
    }
}

/** Une carte d'information à deux lignes (« Connecte-toi pour les amis », « Pas encore d'amis »). */
@Composable
internal fun FriendsInfoCard(title: String, body: String, modifier: Modifier = Modifier) {
    Column(
        modifier = modifier.fillMaxWidth().sophiaCard().padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(4.dp),
    ) {
        Text(
            text = title,
            fontFamily = PlusJakartaSans,
            fontWeight = FontWeight.Bold,
            fontSize = 16.sp,
            lineHeight = 21.sp,
            color = DS.ink,
        )
        Text(
            text = body,
            fontFamily = PlusJakartaSans,
            fontSize = 15.sp,
            lineHeight = 21.sp,
            color = DS.inkSecondary,
        )
    }
}

/**
 * Le classement des amis en lignes, précédé du choix de la période (« 7 jours · Tout »).
 * [nestedScroll] le pose dans une page déjà défilante ; sinon il défile de lui-même.
 */
@Composable
fun FriendsLeaderboardSection(
    language: AppLanguage,
    period: FriendsLeaderboardPeriod,
    leaderboard: List<FriendLeaderboardEntry>,
    onPeriodChange: (FriendsLeaderboardPeriod) -> Unit,
    onOpenFriend: (FriendLeaderboardEntry) -> Unit,
    modifier: Modifier = Modifier,
    nestedScroll: Boolean = false,
    /** Cap for the preview on the profile tab; null shows everyone. */
    maxRows: Int? = null,
) {
    val context = LocalContext.current
    // Ranks come from the full board, so trimming the preview cannot renumber anyone. And
    // the caller's own row is always kept: a profile that cut the list at five simply did
    // not show you once you were sixth, which is exactly when you most want to see it.
    val rows = remember(leaderboard, maxRows) {
        val ranked = leaderboard.mapIndexed { index, entry -> index + 1 to entry }
        if (maxRows == null || ranked.size <= maxRows) {
            ranked
        } else {
            val head = ranked.take(maxRows)
            val me = ranked.firstOrNull { it.second.is_me }
            if (me == null || head.any { it.second.is_me }) head else head.dropLast(1) + me
        }
    }
    val periods = listOf(FriendsLeaderboardPeriod.WEEK, FriendsLeaderboardPeriod.ALL)
    Column(modifier = modifier, verticalArrangement = Arrangement.spacedBy(10.dp)) {
        ProfilePillTabs(
            items = listOf(
                StringStore.text(context, "friends.period.week", language),
                StringStore.text(context, "friends.period.all", language),
            ),
            selectedIndex = periods.indexOf(period).coerceAtLeast(0),
            onSelect = { onPeriodChange(periods[it]) },
        )
        // The RPC always returns the caller, so a solo row is still "no friends yet".
        if (leaderboard.none { !it.is_me }) {
            FriendsInfoCard(
                title = StringStore.text(context, "friends.empty.title", language),
                body = StringStore.text(context, "friends.empty.body", language),
            )
        } else if (nestedScroll) {
            Column(modifier = Modifier.fillMaxWidth().sophiaCard()) {
                rows.forEachIndexed { index, (rank, row) ->
                    if (index > 0) ProfileRowDivider(inset = 0.dp)
                    LeaderboardRow(language, rank, row, onOpenFriend)
                }
            }
        } else {
            LazyColumn(modifier = Modifier.fillMaxWidth().sophiaCard()) {
                itemsIndexed(rows, key = { _, item -> item.second.user_id }) { index, (rank, row) ->
                    if (index > 0) ProfileRowDivider(inset = 0.dp)
                    LeaderboardRow(language, rank, row, onOpenFriend)
                }
            }
        }
    }
}

@Composable
private fun LeaderboardRow(
    language: AppLanguage,
    rank: Int,
    row: FriendLeaderboardEntry,
    onOpenFriend: (FriendLeaderboardEntry) -> Unit,
) {
    val context = LocalContext.current
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .then(if (row.is_me) Modifier else Modifier.profileRowPress(onClick = { onOpenFriend(row) }))
            // La ligne du lecteur ressort sur un fond teinté.
            .background(if (row.is_me) DS.accentTint else Color.Transparent)
            .padding(horizontal = 16.dp, vertical = 12.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        FriendRankBadge(rank)
        Row(
            modifier = Modifier.weight(1f),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            Text(
                text = "@${row.handle}",
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.Bold,
                fontSize = 15.sp,
                color = DS.ink,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
                modifier = Modifier.weight(1f, fill = false),
            )
            if (row.is_me) FriendYouPill(StringStore.text(context, "friends.you", language))
        }
        Text(
            text = "${row.xp} XP",
            fontFamily = PlusJakartaSans,
            fontWeight = FontWeight.Bold,
            fontSize = 15.sp,
            color = if (row.is_me) DS.ink else DS.inkSecondary,
            maxLines = 1,
        )
        if (!row.is_me) ProfileRowChevron()
    }
}

/** Le rang : une médaille pleine pour les trois premiers, un simple nombre ensuite. */
@Composable
internal fun FriendRankBadge(rank: Int) {
    Box(
        modifier = Modifier.size(26.dp).clip(CircleShape).background(if (rank <= 3) friendMedalColor(rank) else Color.Transparent),
        contentAlignment = Alignment.Center,
    ) {
        Text(
            text = "$rank",
            fontFamily = PlusJakartaSans,
            fontWeight = FontWeight.Bold,
            fontSize = 13.sp,
            color = if (rank <= 3) Color.White else DS.inkSecondary,
        )
    }
}

/** La pastille « toi » sur la ligne du lecteur. */
@Composable
internal fun FriendYouPill(text: String) {
    Text(
        text = text,
        fontFamily = PlusJakartaSans,
        fontWeight = FontWeight.Bold,
        fontSize = 11.sp,
        color = Color.White,
        maxLines = 1,
        modifier = Modifier.clip(CircleShape).background(DS.accent).padding(horizontal = 7.dp, vertical = 2.dp),
    )
}

/**
 * Le profil d'un ami (maquette « Profil d'un ami ») : sa carte d'identité avec la jauge de son
 * niveau, « Défier en duel », sa ligue et ses trophées, ses trois compteurs, les badges qu'il
 * affiche, puis « Retirer des amis ». Chaque bloc arrive à son tour.
 */
@Composable
private fun FriendProfileSheet(
    language: AppLanguage,
    stats: FriendPublicStats,
    onRemove: () -> Unit,
    onBack: () -> Unit,
) {
    val context = LocalContext.current
    val sophia = context.applicationContext as SophiaApplication
    val haptics = rememberHaptics()
    val level = ProgressManager.globalLevelProgress(stats.global_xp)
    val progress = if (level.xpForLevel == 0) 0f else level.xpIntoLevel.toFloat() / level.xpForLevel
    var confirmRemove by remember { mutableStateOf(false) }
    var presence by remember(stats.user_id) { mutableStateOf<FriendPresence?>(null) }
    LaunchedEffect(stats.user_id) {
        presence = sophia.socialService.friendPresence(stats.user_id)
    }
    // Trophées, ligue et défi n'ont de sens que là où les duels existent. Le classement des
    // duels porte aussi l'avatar de l'ami et dit s'il peut être défié.
    val duelsVisible = FeatureFlags.duelsVisible(language)
    val duelFriends by sophia.duelService.leaderboard.collectAsState()
    val duelHome by sophia.duelService.home.collectAsState()
    LaunchedEffect(stats.user_id) {
        if (duelsVisible) sophia.duelService.refreshLeaderboard()
    }
    val duelEntry = duelFriends.firstOrNull { it.userId == stats.user_id }

    if (confirmRemove) {
        ConfirmDialog(
            title = StringStore.text(context, "friends.remove.title", language),
            message = StringStore.text(context, "friends.remove.message", language),
            confirm = StringStore.text(context, "friends.remove.confirm", language),
            cancel = StringStore.text(context, "settings.reset.alert.cancel", language),
            onConfirm = {
                confirmRemove = false
                haptics.soft()
                onRemove()
            },
            onDismiss = { confirmRemove = false },
        )
    }

    val backLabel = StringStore.text(context, "elevateProfile.back", language)
    val online = presence?.online == true
    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(DS.canvas)
            .verticalScroll(rememberScrollState())
            .padding(start = 20.dp, end = 20.dp, top = 8.dp, bottom = 40.dp),
    ) {
        // Le retour à gauche, le @ centré (et le pendant vide à droite, pour le centrage).
        ProfileCenteredTitleBar(
            title = "@${stats.handle}",
            leading = {
                ProfileRoundButton(
                    icon = Icons.AutoMirrored.Filled.ArrowBack,
                    contentDescription = backLabel,
                    onClick = onBack,
                )
            },
        )

        // Identité : avatar (ou l'anneau du rang), rang, @, niveau, présence, jauge du niveau.
        Column(
            modifier = Modifier.fillMaxWidth().padding(top = 10.dp).dsStagger(0).sophiaCard().padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(10.dp),
        ) {
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(14.dp)) {
                Box(modifier = Modifier.dsPopIn(delayMillis = 100)) {
                    val avatarId = duelEntry?.avatarId
                    if (Avatars.drawable(avatarId) != null) {
                        AvatarCircle(avatarId = avatarId, initial = stats.handle.take(1).uppercase(), size = 88.dp)
                    } else {
                        GlobalRankRing(progress = progress, size = 88.dp)
                    }
                    if (online) {
                        DuelOnlineDot(
                            size = 18.dp,
                            modifier = Modifier.align(Alignment.BottomEnd).offset(x = (-3).dp, y = (-3).dp),
                        )
                    }
                }
                Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
                    DSEyebrow(text = StringStore.text(context, "globalRank.${level.rank.storageKey}", language))
                    Text(
                        text = "@${stats.handle}",
                        fontFamily = PlusJakartaSans,
                        fontWeight = FontWeight.ExtraBold,
                        fontSize = 20.sp,
                        color = DS.ink,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis,
                    )
                    Text(
                        text = StringStore.text(context, "common.levelShort", language, level.level),
                        fontFamily = PlusJakartaSans,
                        fontWeight = FontWeight.Bold,
                        fontSize = 13.sp,
                        color = DS.ink,
                    )
                    // « En ligne », ou « Vu il y a 5 minutes ». Rien quand le serveur ne sait pas.
                    friendPresenceText(context, presence, language)?.let {
                        Text(
                            text = it,
                            fontFamily = PlusJakartaSans,
                            fontWeight = FontWeight.Bold,
                            fontSize = 13.sp,
                            color = if (online) DS.success else DS.inkSecondary,
                            maxLines = 1,
                            overflow = TextOverflow.Ellipsis,
                        )
                    }
                }
            }
            ProfileFillBar(fraction = progress, height = 8.dp, delayMillis = 300)
            Text(
                text = "${stats.global_xp} XP",
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.Bold,
                fontSize = 12.sp,
                color = DS.inkSecondary,
            )
        }

        // « Défier en duel » : là où les duels existent, pour un ami qui les a (le classement
        // des duels le dit). Aucun trophée en jeu ; la partie s'ouvre par-dessus cet écran.
        if (duelsVisible && duelEntry?.canChallenge == true) {
            Column(
                modifier = Modifier.padding(top = 12.dp).dsStagger(1),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(8.dp),
            ) {
                // La vibration du CTA vient du bouton lui-même.
                SophiaPrimaryButton(
                    text = StringStore.text(context, "duel.friend.challenge", language),
                    leadingIcon = Icons.Outlined.Bolt,
                    onClick = {
                        DuelFriendPresenter.present(
                            DuelFriendEntry.Challenge(
                                userId = stats.user_id,
                                handle = stats.handle,
                                avatarId = duelEntry.avatarId,
                            ),
                        )
                    },
                )
                // La ligne du dessous dit s'il a l'app ouverte en ce moment (quand le serveur le sait).
                presence?.let { known ->
                    Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                        if (known.online) DuelOnlineDot(size = 10.dp)
                        Text(
                            text = StringStore.text(context, if (known.online) "duel.friend.online" else "duel.friend.offline", language),
                            fontFamily = PlusJakartaSans,
                            fontSize = 13.sp,
                            color = DS.inkSecondary,
                        )
                    }
                }
            }
        }

        // Ses trophées et sa ligue, sur l'illustration de la ligue.
        val trophies = presence?.trophies
        if (duelsVisible && trophies != null) {
            val league = presence?.league_position?.let { duelHome?.leagueAt(it) }
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(top = 16.dp)
                    .dsStagger(2)
                    .height(96.dp)
                    .clip(DS.cardShape)
                    .semantics(mergeDescendants = true) { },
            ) {
                DuelLeagueBackdrop(league = league, modifier = Modifier.fillMaxSize(), thumb = true)
                // Voile uni, pour que le texte blanc reste lisible sur toute l'illustration.
                Box(modifier = Modifier.fillMaxSize().background(DuelPalette.night.copy(alpha = if (league != null) 0.6f else 1f)))
                Row(
                    modifier = Modifier.fillMaxSize().padding(horizontal = 16.dp),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                ) {
                    Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
                        Text(
                            text = StringStore.text(context, "duel.trophies.title", language).uppercaseIn(language),
                            fontFamily = PlusJakartaSans,
                            fontWeight = FontWeight.ExtraBold,
                            fontSize = 12.sp,
                            letterSpacing = 0.8.sp,
                            color = Color.White,
                        )
                        if (league != null) {
                            Text(
                                text = DuelFormat.leagueName(context, league, language),
                                fontFamily = PlusJakartaSans,
                                fontWeight = FontWeight.ExtraBold,
                                fontSize = 20.sp,
                                color = Color.White,
                                maxLines = 1,
                                overflow = TextOverflow.Ellipsis,
                            )
                        }
                    }
                    DuelTrophyCount(value = trophies, language = language, size = 20.dp)
                }
            }
        }

        // Ses trois compteurs, qui défilent à l'arrivée.
        Row(
            modifier = Modifier.padding(top = 12.dp).dsStagger(3),
            horizontalArrangement = Arrangement.spacedBy(10.dp),
        ) {
            FriendStatTile(
                icon = Icons.Filled.LocalFireDepartment,
                tint = DS.warm,
                label = StringStore.text(context, "friends.stats.streak", language),
                value = stats.streak,
                modifier = Modifier.weight(1f),
            )
            FriendStatTile(
                icon = Icons.Filled.Check,
                tint = DS.success,
                label = StringStore.text(context, "profile.stats.coursesDone", language),
                value = stats.courses_completed,
                modifier = Modifier.weight(1f),
            )
            FriendStatTile(
                icon = Icons.Filled.GpsFixed,
                tint = DS.accent,
                label = StringStore.text(context, "friends.stats.quizzes", language),
                value = stats.quizzes_completed,
                modifier = Modifier.weight(1f),
            )
        }

        // Les badges qu'il affiche sur son profil.
        val badgeCenter = sophia.badgeCenter
        val featured = remember(presence) {
            presence?.featured_badges.orEmpty().take(3).mapNotNull { id -> badgeCenter.badge(id) }
        }
        if (featured.isNotEmpty()) {
            Column(
                modifier = Modifier.padding(top = 24.dp).dsStagger(4),
                verticalArrangement = Arrangement.spacedBy(10.dp),
            ) {
                ProfileSectionHeader(title = StringStore.text(context, "profile.badges", language))
                BadgeRow(badges = featured, language = language, earned = { true })
            }
        }

        SophiaSecondaryButton(
            text = StringStore.text(context, "friends.remove", language),
            onClick = { confirmRemove = true },
            contentColor = DS.danger,
            modifier = Modifier.padding(top = 24.dp),
        )
    }
}

/**
 * L'anneau du rang global : la part du niveau déjà parcourue, en bleu, autour du symbole du
 * rang. L'arc se trace à l'apparition.
 */
@Composable
fun GlobalRankRing(progress: Float, size: Dp) {
    var appeared by remember { mutableStateOf(false) }
    LaunchedEffect(Unit) {
        delay(200)
        appeared = true
    }
    val sweep by animateFloatAsState(
        targetValue = if (appeared) progress.coerceIn(0f, 1f) else 0f,
        animationSpec = DSMotion.reveal(),
        label = "rankRing",
    )
    val track = DS.accentTint
    val arc = DS.accent
    Box(modifier = Modifier.size(size).clearAndSetSemantics { }, contentAlignment = Alignment.Center) {
        Canvas(modifier = Modifier.fillMaxSize()) {
            val stroke = maxOf(4.dp.toPx(), this.size.minDimension * 0.09f)
            val topLeft = Offset(stroke / 2, stroke / 2)
            val arcSize = Size(this.size.width - stroke, this.size.height - stroke)
            drawArc(
                color = track,
                startAngle = 0f,
                sweepAngle = 360f,
                useCenter = false,
                topLeft = topLeft,
                size = arcSize,
                style = Stroke(width = stroke),
            )
            drawArc(
                color = arc,
                startAngle = -90f,
                sweepAngle = 360f * sweep.coerceIn(0f, 1f),
                useCenter = false,
                topLeft = topLeft,
                size = arcSize,
                style = Stroke(width = stroke, cap = StrokeCap.Round),
            )
        }
        Text(text = "◆", color = arc, fontSize = (size.value * 0.24f).sp)
    }
}

/** Un compteur du profil d'un ami : son pictogramme, la valeur qui défile, le libellé sur deux lignes. */
@Composable
private fun FriendStatTile(icon: ImageVector, tint: Color, label: String, value: Int, modifier: Modifier = Modifier) {
    Column(
        modifier = modifier
            .sophiaCard()
            .padding(horizontal = 6.dp, vertical = 12.dp)
            .semantics(mergeDescendants = true) { },
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(4.dp),
    ) {
        Icon(imageVector = icon, contentDescription = null, tint = tint, modifier = Modifier.size(18.dp))
        ProfileCountText(
            value = value,
            style = TextStyle(fontFamily = PlusJakartaSans, fontWeight = FontWeight.ExtraBold, fontSize = 20.sp),
        )
        Text(
            text = label,
            fontFamily = PlusJakartaSans,
            fontSize = 11.sp,
            lineHeight = 14.sp,
            color = DS.inkSecondary,
            textAlign = TextAlign.Center,
            minLines = 2,
            maxLines = 2,
            overflow = TextOverflow.Ellipsis,
        )
    }
}
