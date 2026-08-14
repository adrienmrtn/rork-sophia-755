package app.rork.sophia.ui.profile

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
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import app.rork.sophia.SophiaApplication
import app.rork.sophia.data.rememberCourseSummaries
import app.rork.sophia.data.ProgressManager
import app.rork.sophia.data.StringStore
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.domain.UserProgress
import app.rork.sophia.ui.social.FriendsLeaderboardSection
import app.rork.sophia.ui.social.GlobalRankRing
import app.rork.sophia.ui.theme.DS
import app.rork.sophia.ui.theme.SophiaTypography
import kotlinx.coroutines.launch

@Composable
fun ProfileScreen(
    modifier: Modifier = Modifier,
    language: AppLanguage,
    progress: UserProgress,
    isPremium: Boolean,
    onLanguageChange: (AppLanguage) -> Unit,
    onResetOnboarding: () -> Unit,
    onOpenCourse: (String) -> Unit,
    onShowPaywall: () -> Unit = {},
    onGoogleSignIn: () -> Unit = {},
    onOpenFriends: () -> Unit = {},
    onOpenFeedback: () -> Unit = {},
    onOpenAmbassador: () -> Unit = {},
    onOpenTerms: () -> Unit = {},
    onOpenPrivacy: () -> Unit = {},
    onRestorePurchases: () -> Unit = {},
) {
    val context = LocalContext.current
    val app = context.applicationContext as SophiaApplication
    val userId by app.authService.userId.collectAsState()
    val handle by app.socialService.myHandle.collectAsState()
    val leaderboard by app.socialService.leaderboard.collectAsState()
    val period by app.socialService.period.collectAsState()
    val scope = rememberCoroutineScope()
    val summaries = rememberCourseSummaries(language)
    val favorites = progress.favoriteCourseIds.mapNotNull { id ->
        summaries.firstOrNull { it.id == id }
    }
    val level = ProgressManager.globalLevelProgress(progress.globalXP)
    val rankProgress = if (level.xpForLevel == 0) 0f else level.xpIntoLevel.toFloat() / level.xpForLevel

    LaunchedEffect(userId) {
        if (userId != null) app.socialService.refreshAll()
    }

    Column(
        modifier = modifier
            .fillMaxSize()
            .background(DS.canvas)
            .verticalScroll(rememberScrollState())
            .padding(DS.Space.l),
    ) {
        Text(
            text = StringStore.text(context, "tab.profile", language),
            style = SophiaTypography.titleLarge,
        )
        Spacer(Modifier.height(16.dp))
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .clip(DS.cardShape)
                .background(DS.surface)
                .padding(DS.Space.m),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            GlobalRankRing(progress = rankProgress, size = 96.dp)
            Spacer(Modifier.height(10.dp))
            Text(
                level.rank.storageKey.replaceFirstChar { it.titlecase() },
                style = SophiaTypography.titleMedium,
            )
            if (handle != null) {
                Text("@$handle", style = SophiaTypography.labelLarge, color = DS.accentSoft)
            }
            Text(
                StringStore.text(context, "common.levelShort", language, level.level) +
                    " · ${progress.globalXP} XP",
                style = SophiaTypography.bodyMedium,
            )
            Text(
                if (isPremium) "Premium · streak ${progress.streak}" else "Free · streak ${progress.streak}",
                style = SophiaTypography.labelMedium,
            )
        }
        if (userId != null) {
            Spacer(Modifier.height(16.dp))
            Text(
                StringStore.text(context, "friends.title", language),
                style = SophiaTypography.titleMedium,
            )
            Spacer(Modifier.height(8.dp))
            FriendsLeaderboardSection(
                language = language,
                period = period,
                leaderboard = leaderboard.take(5),
                onPeriodChange = {
                    app.socialService.setPeriod(it)
                    scope.launch { app.socialService.refreshLeaderboard() }
                },
                onOpenFriend = { onOpenFriends() },
                nestedScroll = true,
            )
        }
        Spacer(Modifier.height(12.dp))
        if (!isPremium) {
            Button(
                onClick = onShowPaywall,
                modifier = Modifier.fillMaxWidth().height(48.dp),
                shape = DS.controlShape,
                colors = ButtonDefaults.buttonColors(containerColor = DS.accent),
            ) {
                Text("Sophia Premium", color = Color.White)
            }
            Spacer(Modifier.height(12.dp))
        }
        if (userId == null) {
            Button(
                onClick = {
                    scope.launch {
                        runCatching { app.authService.signInWithGoogle(context) }
                        onGoogleSignIn()
                        app.progressSyncService.pullOnLogin(app.progressManager.progress.value)
                    }
                },
                modifier = Modifier.fillMaxWidth().height(48.dp),
                shape = DS.controlShape,
                colors = ButtonDefaults.buttonColors(containerColor = DS.ink),
            ) {
                Text("Continue with Google", color = Color.White)
            }
        } else {
            Text("Connecté · ${userId!!.take(8)}…", style = SophiaTypography.labelMedium)
            Text(
                text = "Se déconnecter",
                style = SophiaTypography.labelLarge,
                color = DS.danger,
                modifier = Modifier
                    .padding(top = 8.dp)
                    .clickable {
                        scope.launch { app.authService.signOut() }
                    },
            )
        }
        Spacer(Modifier.height(12.dp))
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .clip(DS.cardShape)
                .background(DS.accentTint)
                .clickable(onClick = onOpenAmbassador)
                .padding(DS.Space.m),
        ) {
            Text(
                text = StringStore.text(context, "settings.ambassador.banner.badge", language),
                style = SophiaTypography.labelMedium,
                color = DS.accentSoft,
            )
            Text(
                text = StringStore.text(context, "settings.ambassador.banner.title", language),
                style = SophiaTypography.titleMedium,
            )
            Text(
                text = StringStore.text(context, "settings.ambassador.banner.subtitle", language),
                style = SophiaTypography.bodyMedium,
            )
        }
        Spacer(Modifier.height(12.dp))
        Button(
            onClick = onOpenFriends,
            modifier = Modifier.fillMaxWidth().height(48.dp),
            shape = DS.controlShape,
            colors = ButtonDefaults.buttonColors(containerColor = DS.surfaceMuted, contentColor = DS.ink),
        ) { Text("Amis & classement") }
        Spacer(Modifier.height(8.dp))
        Button(
            onClick = onOpenFeedback,
            modifier = Modifier.fillMaxWidth().height(48.dp),
            shape = DS.controlShape,
            colors = ButtonDefaults.buttonColors(containerColor = DS.surfaceMuted, contentColor = DS.ink),
        ) { Text("Envoyer un feedback") }
        Spacer(Modifier.height(16.dp))
        Text(
            text = StringStore.text(context, "settings.section.legal", language),
            style = SophiaTypography.titleMedium,
        )
        Spacer(Modifier.height(8.dp))
        LegalSettingsRow(
            label = StringStore.text(context, "settings.terms.title", language),
            onClick = onOpenTerms,
        )
        LegalSettingsRow(
            label = StringStore.text(context, "settings.privacy.title", language),
            onClick = onOpenPrivacy,
        )
        if (!isPremium) {
            LegalSettingsRow(
                label = StringStore.text(context, "settings.restore.title", language),
                onClick = onRestorePurchases,
            )
        }
        Spacer(Modifier.height(16.dp))
        Text(text = StringStore.text(context, "language.section", language), style = SophiaTypography.titleMedium)
        Spacer(Modifier.height(8.dp))
        AppLanguage.entries.forEach { lang ->
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(DS.controlShape)
                    .background(if (lang == language) DS.accentTint else DS.surface)
                    .clickable { onLanguageChange(lang) }
                    .padding(horizontal = 14.dp, vertical = 12.dp),
                horizontalArrangement = Arrangement.spacedBy(10.dp),
            ) {
                Text(text = lang.flag)
                Text(text = lang.displayName, style = SophiaTypography.bodyLarge)
            }
            Spacer(Modifier.height(6.dp))
        }
        Spacer(Modifier.height(16.dp))
        Text(text = "Favorites (${favorites.size})", style = SophiaTypography.titleMedium)
        favorites.take(8).forEach { course ->
            Text(
                text = course.title,
                style = SophiaTypography.bodyMedium,
                modifier = Modifier
                    .fillMaxWidth()
                    .clickable { onOpenCourse(course.id) }
                    .padding(vertical = 8.dp),
            )
            HorizontalDivider(color = DS.hairline)
        }
        Spacer(Modifier.height(24.dp))
        Text(
            text = "Reset onboarding (debug)",
            style = SophiaTypography.labelLarge,
            color = DS.danger,
            modifier = Modifier.clickable(onClick = onResetOnboarding),
        )
    }
}

@Composable
private fun LegalSettingsRow(label: String, onClick: () -> Unit) {
    Text(
        text = label,
        style = SophiaTypography.bodyLarge,
        modifier = Modifier
            .fillMaxWidth()
            .clip(DS.controlShape)
            .background(DS.surface)
            .clickable(onClick = onClick)
            .padding(horizontal = 14.dp, vertical = 14.dp),
    )
    Spacer(Modifier.height(6.dp))
}

