package app.rork.sophia.ui.social

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
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
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import app.rork.sophia.SophiaApplication
import app.rork.sophia.data.FriendPublicStats
import app.rork.sophia.data.FriendsLeaderboardPeriod
import app.rork.sophia.ui.theme.DS
import app.rork.sophia.ui.theme.SophiaTypography
import kotlinx.coroutines.launch

@Composable
fun FriendsScreen(
    modifier: Modifier = Modifier,
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
    val error by social.error.collectAsState()
    val signedIn by app.authService.userId.collectAsState()

    var handleInput by remember { mutableStateOf("") }
    var addInput by remember { mutableStateOf("") }
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

    Column(
        modifier = modifier
            .fillMaxSize()
            .background(DS.canvas)
            .padding(DS.Space.l),
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            TextButton(onClick = onBack) { Text("←") }
            Text("Amis", style = SophiaTypography.titleLarge)
        }
        Spacer(Modifier.height(12.dp))

        if (signedIn == null) {
            Text("Connecte-toi pour voir tes amis.", style = SophiaTypography.bodyMedium)
            return
        }

        Text("Ton pseudo", style = SophiaTypography.labelMedium)
        Row(
            horizontalArrangement = Arrangement.spacedBy(8.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            OutlinedTextField(
                value = handleInput,
                onValueChange = { handleInput = it },
                modifier = Modifier.weight(1f),
                placeholder = { Text(handle?.let { "@$it" } ?: "@pseudo") },
                singleLine = true,
            )
            Button(
                onClick = { scope.launch { social.updateHandle(handleInput) } },
                colors = ButtonDefaults.buttonColors(containerColor = DS.accent),
            ) { Text("OK", color = Color.White) }
        }

        Spacer(Modifier.height(16.dp))
        Text("Ajouter un ami", style = SophiaTypography.labelMedium)
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            OutlinedTextField(
                value = addInput,
                onValueChange = { addInput = it },
                modifier = Modifier.weight(1f),
                placeholder = { Text("@handle") },
                singleLine = true,
            )
            Button(
                onClick = {
                    scope.launch {
                        social.sendFriendRequest(addInput)
                        addInput = ""
                    }
                },
                colors = ButtonDefaults.buttonColors(containerColor = DS.ink),
            ) { Text("Ajouter", color = Color.White) }
        }

        if (error != null) {
            Text(
                error!!,
                color = DS.danger,
                style = SophiaTypography.labelMedium,
                modifier = Modifier.padding(top = 8.dp),
            )
        }

        if (pending.isNotEmpty()) {
            Spacer(Modifier.height(16.dp))
            Text("Demandes", style = SophiaTypography.titleMedium)
            pending.forEach { req ->
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(vertical = 6.dp)
                        .clip(DS.controlShape)
                        .background(DS.surface)
                        .padding(12.dp),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Text("@${req.handle}", style = SophiaTypography.bodyLarge)
                    Row {
                        TextButton(onClick = { scope.launch { social.respondToRequest(req.request_id, true) } }) {
                            Text("Accepter")
                        }
                        TextButton(onClick = { scope.launch { social.respondToRequest(req.request_id, false) } }) {
                            Text("Refuser")
                        }
                    }
                }
            }
        }

        Spacer(Modifier.height(16.dp))
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            PeriodChip("Semaine", period == FriendsLeaderboardPeriod.WEEK) {
                social.setPeriod(FriendsLeaderboardPeriod.WEEK)
            }
            PeriodChip("Tout", period == FriendsLeaderboardPeriod.ALL) {
                social.setPeriod(FriendsLeaderboardPeriod.ALL)
            }
        }
        Spacer(Modifier.height(8.dp))
        LazyColumn(
            modifier = Modifier.weight(1f),
            verticalArrangement = Arrangement.spacedBy(6.dp),
        ) {
            itemsIndexed(leaderboard) { index, row ->
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clip(DS.controlShape)
                        .background(if (row.is_me) DS.accentTint else DS.surface)
                        .clickable(enabled = !row.is_me) {
                            scope.launch { friendStats = social.friendStats(row.user_id) }
                        }
                        .padding(14.dp),
                    horizontalArrangement = Arrangement.SpaceBetween,
                ) {
                    Text("${index + 1}. @${row.handle}", style = SophiaTypography.bodyLarge)
                    Text("${row.xp} XP", style = SophiaTypography.labelLarge, color = DS.accent)
                }
            }
        }

        friendStats?.let { stats ->
            Spacer(Modifier.height(12.dp))
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(DS.cardShape)
                    .background(DS.surface)
                    .padding(DS.Space.m),
            ) {
                Text("@${stats.handle}", style = SophiaTypography.titleMedium)
                Text("XP ${stats.global_xp} · streak ${stats.streak}", style = SophiaTypography.bodyMedium)
                Text(
                    "Cours ${stats.courses_completed} · Quiz ${stats.quizzes_completed}",
                    style = SophiaTypography.bodyMedium,
                )
                TextButton(onClick = { friendStats = null }) { Text("Fermer") }
            }
        }
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
            .background(if (selected) DS.accentTint else DS.surface)
            .clickable(onClick = onClick)
            .padding(horizontal = 14.dp, vertical = 8.dp),
    )
}
