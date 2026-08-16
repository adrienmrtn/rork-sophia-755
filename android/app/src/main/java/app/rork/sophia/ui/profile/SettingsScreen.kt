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
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import app.rork.sophia.BuildConfig
import app.rork.sophia.SophiaApplication
import app.rork.sophia.data.StringStore
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.domain.UserProgress
import app.rork.sophia.ui.theme.DS
import app.rork.sophia.ui.theme.SophiaTypography
import kotlinx.coroutines.launch

/**
 * Mirrors the iOS `SettingsView`: everything that is not identity/social lives here,
 * behind the gear on the profile tab.
 */
@Composable
fun SettingsScreen(
    language: AppLanguage,
    progress: UserProgress,
    isPremium: Boolean,
    onBack: () -> Unit,
    onLanguageChange: (AppLanguage) -> Unit,
    onShowPaywall: () -> Unit,
    onOpenFeedback: () -> Unit,
    onOpenAmbassador: () -> Unit,
    onOpenTerms: () -> Unit,
    onOpenPrivacy: () -> Unit,
    onRestorePurchases: () -> Unit,
    onResetOnboarding: () -> Unit,
) {
    val context = LocalContext.current
    val app = context.applicationContext as SophiaApplication
    val scope = rememberCoroutineScope()
    val userId by app.authService.userId.collectAsState()
    var showResetProgress by remember { mutableStateOf(false) }
    var showResetOnboarding by remember { mutableStateOf(false) }
    val completedCount = progress.courseProgress.count { it.value.isCompleted }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(DS.canvas)
            .verticalScroll(rememberScrollState())
            .padding(horizontal = DS.Space.l)
            .padding(bottom = 32.dp),
    ) {
        Row(
            modifier = Modifier.fillMaxWidth().padding(vertical = DS.Space.s),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Text(
                text = StringStore.text(context, "settings.title", language),
                style = SophiaTypography.titleLarge,
                modifier = Modifier.weight(1f),
            )
            IconButton(
                onClick = onBack,
                modifier = Modifier.clip(CircleShape).background(DS.surface),
            ) {
                Icon(Icons.Filled.Close, contentDescription = null, tint = DS.inkSecondary)
            }
        }

        SettingsSection(StringStore.text(context, "account.title", language))
        if (userId == null) {
            SettingsRow(
                label = StringStore.text(context, "account.create.title", language),
                subtitle = StringStore.text(context, "account.create.subtitle", language),
                onClick = {
                    scope.launch {
                        runCatching { app.authService.signInWithGoogle(context) }
                        app.progressSyncService.pullOnLogin(app.progressManager.progress.value)
                    }
                },
            )
        } else {
            SettingsRow(
                label = StringStore.text(context, "account.signedIn.title", language),
                subtitle = userId!!.take(8) + "…",
                onClick = {},
            )
            SettingsRow(
                label = StringStore.text(context, "account.signOut.action", language),
                onClick = { scope.launch { app.authService.signOut() } },
                destructive = true,
            )
        }

        SettingsSection(StringStore.text(context, "language.section", language))
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

        SettingsSection(StringStore.text(context, "settings.section.progress", language))
        SettingsRow(
            label = StringStore.text(context, "settings.courses.completed", language, completedCount),
            subtitle = StringStore.text(context, "settings.streak.title", language, progress.streak),
            onClick = {},
        )

        if (!isPremium) {
            SettingsSection(StringStore.text(context, "settings.section.premium", language))
            SettingsRow(
                label = StringStore.text(context, "settings.premium.title", language),
                subtitle = StringStore.text(context, "settings.premium.subtitle", language),
                onClick = onShowPaywall,
            )
        }

        SettingsSection(StringStore.text(context, "settings.section.help", language))
        SettingsRow(
            label = StringStore.text(context, "settings.feedback.title", language),
            subtitle = StringStore.text(context, "settings.feedback.subtitle", language),
            onClick = onOpenFeedback,
        )
        SettingsRow(
            label = StringStore.text(context, "settings.ambassador.banner.title", language),
            subtitle = StringStore.text(context, "settings.ambassador.banner.subtitle", language),
            onClick = onOpenAmbassador,
        )

        SettingsSection(StringStore.text(context, "settings.section.legal", language))
        SettingsRow(
            label = StringStore.text(context, "settings.terms.title", language),
            onClick = onOpenTerms,
        )
        SettingsRow(
            label = StringStore.text(context, "settings.privacy.title", language),
            onClick = onOpenPrivacy,
        )
        if (!isPremium) {
            SettingsRow(
                label = StringStore.text(context, "settings.restore.title", language),
                onClick = onRestorePurchases,
            )
        }

        SettingsSection(StringStore.text(context, "settings.section.data", language))
        SettingsRow(
            label = StringStore.text(context, "settings.reset.title", language),
            onClick = { showResetProgress = true },
            destructive = true,
        )
        SettingsRow(
            label = StringStore.text(context, "settings.debug.resetOnboarding", language),
            onClick = { showResetOnboarding = true },
            destructive = true,
        )

        SettingsSection(StringStore.text(context, "settings.section.about", language))
        SettingsRow(
            label = StringStore.text(context, "settings.about.version", language),
            subtitle = BuildConfig.VERSION_NAME,
            onClick = {},
        )

        Spacer(Modifier.height(16.dp))
        Text(
            text = StringStore.text(context, "settings.footer", language),
            style = SophiaTypography.labelMedium,
            textAlign = TextAlign.Center,
            modifier = Modifier.fillMaxWidth(),
        )
    }

    if (showResetProgress) {
        ConfirmDialog(
            title = StringStore.text(context, "settings.reset.alert.title", language),
            message = StringStore.text(context, "settings.reset.alert.message", language),
            confirm = StringStore.text(context, "settings.reset.alert.confirm", language),
            cancel = StringStore.text(context, "settings.reset.alert.cancel", language),
            onConfirm = {
                showResetProgress = false
                app.progressManager.resetProgress()
            },
            onDismiss = { showResetProgress = false },
        )
    }

    if (showResetOnboarding) {
        ConfirmDialog(
            title = StringStore.text(context, "settings.onboarding.alert.title", language),
            message = StringStore.text(context, "settings.onboarding.alert.message", language),
            confirm = StringStore.text(context, "settings.onboarding.alert.confirm", language),
            cancel = StringStore.text(context, "settings.reset.alert.cancel", language),
            onConfirm = {
                showResetOnboarding = false
                onResetOnboarding()
            },
            onDismiss = { showResetOnboarding = false },
        )
    }
}

@Composable
private fun SettingsSection(title: String) {
    Spacer(Modifier.height(18.dp))
    Text(text = title.uppercase(), style = SophiaTypography.labelMedium, color = DS.inkTertiary)
    Spacer(Modifier.height(8.dp))
}

@Composable
private fun SettingsRow(
    label: String,
    onClick: () -> Unit,
    subtitle: String? = null,
    destructive: Boolean = false,
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clip(DS.controlShape)
            .background(if (destructive) DS.dangerTint else DS.surface)
            .clickable(onClick = onClick)
            .padding(horizontal = 14.dp, vertical = 14.dp),
    ) {
        Text(
            text = label,
            style = SophiaTypography.bodyLarge,
            color = if (destructive) DS.danger else DS.ink,
        )
        if (subtitle != null) {
            Text(text = subtitle, style = SophiaTypography.labelMedium)
        }
    }
    Spacer(Modifier.height(6.dp))
}

@Composable
private fun ConfirmDialog(
    title: String,
    message: String,
    confirm: String,
    cancel: String,
    onConfirm: () -> Unit,
    onDismiss: () -> Unit,
) {
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text(title) },
        text = { Text(message) },
        confirmButton = {
            TextButton(onClick = onConfirm) { Text(confirm, color = DS.danger) }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) { Text(cancel) }
        },
    )
}
