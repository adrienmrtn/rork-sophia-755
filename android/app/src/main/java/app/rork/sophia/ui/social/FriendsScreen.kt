package app.rork.sophia.ui.social

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardCapitalization
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.rork.sophia.SophiaApplication
import app.rork.sophia.data.FriendLeaderboardEntry
import app.rork.sophia.data.FriendPublicStats
import app.rork.sophia.data.FriendsLeaderboardPeriod
import app.rork.sophia.data.ProgressManager
import app.rork.sophia.data.SendRequestOutcome
import app.rork.sophia.data.StringStore
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.ui.components.CircleIconButton
import app.rork.sophia.ui.components.ConfirmDialog
import app.rork.sophia.ui.theme.DS
import app.rork.sophia.ui.theme.PlusJakartaSans
import app.rork.sophia.ui.theme.SophiaTypography
import kotlinx.coroutines.launch

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

    LaunchedEffect(handle) {
        if (handleInput.isEmpty() && handle != null) handleInput = handle!!
    }
    LaunchedEffect(signedIn) {
        if (signedIn != null) social.refreshAll()
    }
    LaunchedEffect(period) {
        if (signedIn != null) social.refreshLeaderboard()
    }
    // Opened by tapping a friend on the profile tab: land straight on their card.
    LaunchedEffect(initialFriendUserId) {
        val id = initialFriendUserId ?: return@LaunchedEffect
        friendStats = social.friendStats(id)
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

    Column(
        modifier = modifier
            .fillMaxSize()
            .background(DS.canvas)
            .padding(DS.Space.l),
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            CircleIconButton(icon = Icons.AutoMirrored.Filled.ArrowBack, onClick = onBack)
            Text(
                StringStore.text(context, "friends.title", language),
                style = SophiaTypography.titleLarge,
            )
        }
        Spacer(Modifier.height(12.dp))

        if (signedIn == null) {
            Text(
                StringStore.text(context, "friends.signedOut.title", language),
                style = SophiaTypography.titleMedium,
            )
            Text(
                StringStore.text(context, "friends.signedOut.body", language),
                style = SophiaTypography.bodyMedium,
            )
            return
        }

        // Incoming requests first: they are the only thing here that expects an answer.
        if (pending.isNotEmpty()) {
            Text(
                StringStore.text(context, "friends.requests.title", language),
                style = SophiaTypography.labelMedium,
                color = DS.accentSoft,
            )
            Spacer(Modifier.height(6.dp))
            pending.forEach { req ->
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(bottom = 8.dp)
                        .clip(DS.controlShape)
                        .border(1.dp, DS.accentSoft, DS.controlShape)
                        .background(DS.accentTint)
                        .padding(start = 14.dp, end = 4.dp, top = 4.dp, bottom = 4.dp),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Text(
                        "@${req.handle}",
                        style = SophiaTypography.bodyLarge,
                        modifier = Modifier.weight(1f),
                    )
                    TextButton(
                        onClick = { scope.launch { social.respondToRequest(req.request_id, true) } },
                    ) {
                        Text(
                            StringStore.text(context, "friends.requests.accept", language),
                            color = DS.accent,
                            fontWeight = FontWeight.SemiBold,
                        )
                    }
                    TextButton(
                        onClick = { scope.launch { social.respondToRequest(req.request_id, false) } },
                    ) {
                        Text(
                            StringStore.text(context, "friends.requests.decline", language),
                            color = DS.inkTertiary,
                        )
                    }
                }
            }
            Spacer(Modifier.height(8.dp))
        }

        Text(
            StringStore.text(context, "friends.add.title", language),
            style = SophiaTypography.labelMedium,
        )
        Text(
            StringStore.text(context, "friends.add.requestSubtitle", language),
            style = SophiaTypography.bodyMedium,
            color = DS.inkSecondary,
        )
        Spacer(Modifier.height(6.dp))
        Row(
            horizontalArrangement = Arrangement.spacedBy(8.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            OutlinedTextField(
                value = addInput,
                onValueChange = {
                    addInput = it
                    noticeKey = null
                    social.clearError()
                },
                modifier = Modifier.weight(1f),
                placeholder = {
                    Text("@" + StringStore.text(context, "friends.handle.placeholder", language))
                },
                prefix = { Text("@") },
                singleLine = true,
                keyboardOptions = KeyboardOptions(
                    autoCorrectEnabled = false,
                    capitalization = KeyboardCapitalization.None,
                    imeAction = ImeAction.Send,
                ),
            )
            Button(
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
                            }
                        sending = false
                    }
                },
                enabled = !sending && addInput.isNotBlank(),
                colors = ButtonDefaults.buttonColors(containerColor = DS.ink),
            ) {
                Text(
                    StringStore.text(context, "friends.add.short", language),
                    color = Color.White,
                )
            }
        }

        noticeKey?.let { key ->
            Text(
                StringStore.text(context, key, language),
                color = DS.success,
                style = SophiaTypography.labelMedium,
                modifier = Modifier.padding(top = 8.dp),
            )
        }
        errorKey?.let { key ->
            Text(
                StringStore.text(context, key, language),
                color = DS.danger,
                style = SophiaTypography.labelMedium,
                modifier = Modifier.padding(top = 8.dp),
            )
        }

        Spacer(Modifier.height(16.dp))
        Text(
            StringStore.text(context, "friends.handle.edit.title", language),
            style = SophiaTypography.labelMedium,
        )
        Text(
            StringStore.text(context, "friends.handle.edit.subtitle", language),
            style = SophiaTypography.bodyMedium,
            color = DS.inkSecondary,
        )
        Spacer(Modifier.height(6.dp))
        Row(
            horizontalArrangement = Arrangement.spacedBy(8.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            OutlinedTextField(
                value = handleInput,
                onValueChange = {
                    handleInput = it
                    noticeKey = null
                    social.clearError()
                },
                modifier = Modifier.weight(1f),
                placeholder = {
                    Text(StringStore.text(context, "friends.handle.placeholder", language))
                },
                prefix = { Text("@") },
                singleLine = true,
                keyboardOptions = KeyboardOptions(
                    autoCorrectEnabled = false,
                    capitalization = KeyboardCapitalization.None,
                    imeAction = ImeAction.Done,
                ),
            )
            Button(
                onClick = { scope.launch { social.updateHandle(handleInput) } },
                enabled = handleInput.isNotBlank() && handleInput != handle,
                colors = ButtonDefaults.buttonColors(containerColor = DS.accent),
            ) {
                Text(
                    StringStore.text(context, "friends.handle.save", language),
                    color = Color.White,
                )
            }
        }
        Text(
            StringStore.text(context, "friends.handle.rules", language),
            style = SophiaTypography.labelMedium.copy(fontSize = 11.sp),
            color = DS.inkTertiary,
            modifier = Modifier.padding(top = 4.dp),
        )

        Spacer(Modifier.height(16.dp))
        FriendsLeaderboardSection(
            language = language,
            period = period,
            leaderboard = leaderboard,
            onPeriodChange = { social.setPeriod(it) },
            onOpenFriend = { entry ->
                scope.launch { friendStats = social.friendStats(entry.user_id) }
            },
            modifier = Modifier.weight(1f),
        )
    }
}

@Composable
fun FriendsLeaderboardSection(
    language: AppLanguage,
    period: FriendsLeaderboardPeriod,
    leaderboard: List<FriendLeaderboardEntry>,
    onPeriodChange: (FriendsLeaderboardPeriod) -> Unit,
    onOpenFriend: (FriendLeaderboardEntry) -> Unit,
    modifier: Modifier = Modifier,
    nestedScroll: Boolean = false,
) {
    val context = LocalContext.current
    Column(modifier = modifier) {
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            PeriodChip(
                StringStore.text(context, "friends.period.week", language),
                period == FriendsLeaderboardPeriod.WEEK,
            ) { onPeriodChange(FriendsLeaderboardPeriod.WEEK) }
            PeriodChip(
                StringStore.text(context, "friends.period.all", language),
                period == FriendsLeaderboardPeriod.ALL,
            ) { onPeriodChange(FriendsLeaderboardPeriod.ALL) }
        }
        Spacer(Modifier.height(8.dp))
        // The RPC always returns the caller, so a solo row is still "no friends yet".
        if (leaderboard.none { !it.is_me }) {
            Text(
                StringStore.text(context, "friends.empty.title", language),
                style = SophiaTypography.titleMedium,
            )
            Text(
                StringStore.text(context, "friends.empty.body", language),
                style = SophiaTypography.bodyMedium,
            )
        } else if (nestedScroll) {
            Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                leaderboard.forEachIndexed { index, row ->
                    LeaderboardRow(language, index, row, onOpenFriend)
                }
            }
        } else {
            LazyColumn(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                itemsIndexed(leaderboard) { index, row ->
                    LeaderboardRow(language, index, row, onOpenFriend)
                }
            }
        }
    }
}

@Composable
private fun LeaderboardRow(
    language: AppLanguage,
    index: Int,
    row: FriendLeaderboardEntry,
    onOpenFriend: (FriendLeaderboardEntry) -> Unit,
) {
    val context = LocalContext.current
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(DS.controlShape)
            .border(1.dp, DS.hairline, DS.controlShape)
            .background(if (row.is_me) DS.accentTint else DS.surface)
            .clickable(enabled = !row.is_me) { onOpenFriend(row) }
            .padding(14.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            Text("${index + 1}.", style = SophiaTypography.labelLarge, color = DS.inkTertiary)
            Text("@${row.handle}", style = SophiaTypography.bodyLarge)
            if (row.is_me) {
                Text(
                    StringStore.text(context, "friends.you", language),
                    style = SophiaTypography.labelMedium,
                    color = DS.accentSoft,
                )
            }
        }
        Text("${row.xp} XP", style = SophiaTypography.labelLarge, color = DS.accent)
    }
}

@Composable
private fun FriendProfileSheet(
    language: AppLanguage,
    stats: FriendPublicStats,
    onRemove: () -> Unit,
    onBack: () -> Unit,
) {
    val context = LocalContext.current
    val level = ProgressManager.globalLevelProgress(stats.global_xp)
    val progress = if (level.xpForLevel == 0) 0f else level.xpIntoLevel.toFloat() / level.xpForLevel
    var confirmRemove by remember { mutableStateOf(false) }

    if (confirmRemove) {
        ConfirmDialog(
            title = StringStore.text(context, "friends.remove.title", language),
            message = StringStore.text(context, "friends.remove.message", language),
            confirm = StringStore.text(context, "friends.remove.confirm", language),
            cancel = StringStore.text(context, "settings.reset.alert.cancel", language),
            onConfirm = {
                confirmRemove = false
                onRemove()
            },
            onDismiss = { confirmRemove = false },
        )
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(DS.canvas)
            .padding(DS.Space.l),
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            CircleIconButton(icon = Icons.AutoMirrored.Filled.ArrowBack, onClick = onBack)
            Text("@${stats.handle}", style = SophiaTypography.titleLarge)
        }
        Spacer(Modifier.height(24.dp))
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .clip(DS.cardShape)
                .background(DS.surface)
                .padding(DS.Space.m),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            GlobalRankRing(progress = progress, size = 88.dp)
            Spacer(Modifier.height(12.dp))
            Text(
                StringStore.text(context, "globalRank.${level.rank.storageKey}", language).uppercase(),
                style = SophiaTypography.labelLarge,
                color = DS.accentSoft,
                letterSpacing = 2.sp,
            )
            Text("@${stats.handle}", style = SophiaTypography.titleMedium)
            Text(
                StringStore.text(context, "common.levelShort", language, level.level),
                style = SophiaTypography.labelMedium,
            )
            Spacer(Modifier.height(8.dp))
            LinearProgressIndicator(
                progress = { progress },
                modifier = Modifier.fillMaxWidth().height(8.dp),
                color = DS.accent,
                trackColor = DS.hairline,
                strokeCap = StrokeCap.Round,
            )
            Spacer(Modifier.height(6.dp))
            Text("${stats.global_xp} XP", style = SophiaTypography.labelMedium)
        }
        Spacer(Modifier.height(16.dp))
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            StatTile(
                label = StringStore.text(context, "friends.stats.streak", language),
                value = "${stats.streak}",
                modifier = Modifier.weight(1f),
            )
            StatTile(
                label = StringStore.text(context, "profile.stats.coursesDone", language),
                value = "${stats.courses_completed}",
                modifier = Modifier.weight(1f),
            )
            StatTile(
                label = StringStore.text(context, "friends.stats.quizzes", language),
                value = "${stats.quizzes_completed}",
                modifier = Modifier.weight(1f),
            )
        }
        Spacer(Modifier.weight(1f))
        Button(
            onClick = { confirmRemove = true },
            modifier = Modifier.fillMaxWidth().height(48.dp),
            shape = DS.controlShape,
            colors = ButtonDefaults.buttonColors(containerColor = DS.dangerTint, contentColor = DS.danger),
        ) {
            Text(StringStore.text(context, "friends.remove", language), fontFamily = PlusJakartaSans, fontWeight = FontWeight.SemiBold)
        }
    }
}

@Composable
fun GlobalRankRing(progress: Float, size: androidx.compose.ui.unit.Dp) {
    Box(modifier = Modifier.size(size), contentAlignment = Alignment.Center) {
        Canvas(modifier = Modifier.fillMaxSize()) {
            val stroke = 8.dp.toPx()
            drawCircle(color = DS.hairline, style = Stroke(width = stroke))
            drawArc(
                color = DS.accentSoft,
                startAngle = -90f,
                sweepAngle = 360f * progress.coerceIn(0f, 1f),
                useCenter = false,
                style = Stroke(width = stroke, cap = StrokeCap.Round),
            )
        }
        Box(
            modifier = Modifier
                .size(size * 0.62f)
                .clip(CircleShape)
                .background(DS.accentTint),
            contentAlignment = Alignment.Center,
        ) {
            Text("◆", color = DS.accent, fontSize = 18.sp)
        }
    }
}

@Composable
private fun StatTile(label: String, value: String, modifier: Modifier = Modifier) {
    Column(
        modifier = modifier
            .clip(DS.cardShape)
            .background(DS.surface)
            .padding(12.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Text(value, style = SophiaTypography.titleLarge)
        Text(label, style = SophiaTypography.labelMedium, color = DS.inkTertiary)
    }
}

@Composable
private fun PeriodChip(label: String, selected: Boolean, onClick: () -> Unit) {
    Text(
        text = label,
        style = SophiaTypography.labelLarge,
        color = if (selected) DS.accent else DS.inkSecondary,
        modifier = Modifier
            .clip(DS.controlShape)
            .border(1.dp, DS.hairline, DS.controlShape)
            .background(if (selected) DS.accentTint else DS.surface)
            .clickable(onClick = onClick)
            .padding(horizontal = 14.dp, vertical = 8.dp),
    )
}
