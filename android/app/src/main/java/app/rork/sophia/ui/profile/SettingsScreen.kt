package app.rork.sophia.ui.profile

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.Login
import androidx.compose.material.icons.automirrored.filled.Logout
import androidx.compose.material.icons.filled.ChevronRight
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Description
import androidx.compose.material.icons.filled.Info
import androidx.compose.material.icons.filled.LocalFireDepartment
import androidx.compose.material.icons.filled.PersonAdd
import androidx.compose.material.icons.filled.PrivacyTip
import androidx.compose.material.icons.filled.QuestionAnswer
import androidx.compose.material.icons.filled.Restore
import androidx.compose.material.icons.filled.RestartAlt
import androidx.compose.material.icons.filled.School
import androidx.compose.material.icons.filled.Star
import androidx.compose.material.icons.filled.Today
import androidx.compose.material.icons.filled.WorkspacePremium
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
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
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.rork.sophia.BuildConfig
import app.rork.sophia.SophiaApplication
import app.rork.sophia.data.StringStore
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.domain.UserProgress
import app.rork.sophia.ui.components.CircleIconButton
import app.rork.sophia.ui.components.ScreenTitle
import app.rork.sophia.ui.components.SectionLabel
import app.rork.sophia.ui.components.TintedIconBox
import app.rork.sophia.ui.components.softPress
import app.rork.sophia.ui.components.sophiaCard
import app.rork.sophia.ui.theme.DS
import app.rork.sophia.ui.theme.SophiaTypography
import kotlinx.coroutines.launch

/**
 * Mirrors the iOS `SettingsView`: everything that is not identity or social lives here,
 * behind the gear on the profile tab, in grouped inset cards.
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
            ScreenTitle(
                text = StringStore.text(context, "settings.title", language),
                modifier = Modifier.weight(1f),
            )
            CircleIconButton(icon = Icons.Filled.Close, onClick = onBack, size = 44.dp)
        }

        SettingsSection(StringStore.text(context, "account.title", language))
        SettingsGroup {
            if (userId == null) {
                SettingsRow(
                    icon = Icons.AutoMirrored.Filled.Login,
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
                    icon = Icons.Filled.PersonAdd,
                    label = StringStore.text(context, "account.signedIn.title", language),
                    subtitle = userId!!.take(8) + "…",
                    showChevron = false,
                    onClick = {},
                )
                HorizontalDivider(color = DS.hairline)
                SettingsRow(
                    icon = Icons.AutoMirrored.Filled.Logout,
                    label = StringStore.text(context, "account.signOut.action", language),
                    destructive = true,
                    onClick = { scope.launch { app.authService.signOut() } },
                )
            }
        }

        SettingsSection(StringStore.text(context, "language.section", language))
        SettingsGroup {
            AppLanguage.entries.forEachIndexed { index, lang ->
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .softPress(onClick = { onLanguageChange(lang) })
                        .background(if (lang == language) DS.accentTint else Color.Transparent)
                        .padding(horizontal = 14.dp, vertical = 13.dp),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(12.dp),
                ) {
                    Text(text = lang.flag, fontSize = 20.sp)
                    Text(
                        text = lang.displayName,
                        style = SophiaTypography.bodyLarge.copy(fontSize = 16.sp),
                        modifier = Modifier.weight(1f),
                    )
                    if (lang == language) {
                        Icon(
                            Icons.Filled.Star,
                            contentDescription = null,
                            tint = DS.accentSoft,
                            modifier = Modifier.size(16.dp),
                        )
                    }
                }
                if (index != AppLanguage.entries.lastIndex) HorizontalDivider(color = DS.hairline)
            }
        }

        SettingsSection(StringStore.text(context, "settings.section.progress", language))
        SettingsGroup {
            SettingsRow(
                icon = Icons.Filled.School,
                label = StringStore.text(context, "settings.courses.completed", language, completedCount),
                showChevron = false,
                onClick = {},
            )
            HorizontalDivider(color = DS.hairline)
            SettingsRow(
                icon = Icons.Filled.LocalFireDepartment,
                label = StringStore.text(context, "settings.streak.title", language, progress.streak),
                subtitle = StringStore.text(context, "settings.streak.subtitle", language),
                showChevron = false,
                onClick = {},
            )
        }

        if (!isPremium) {
            SettingsSection(StringStore.text(context, "settings.section.premium", language))
            SettingsGroup {
                SettingsRow(
                    icon = Icons.Filled.WorkspacePremium,
                    label = StringStore.text(context, "settings.premium.title", language),
                    subtitle = StringStore.text(context, "settings.premium.subtitle", language),
                    onClick = onShowPaywall,
                )
            }
        }

        SettingsSection(StringStore.text(context, "settings.section.help", language))
        SettingsGroup {
            SettingsRow(
                icon = Icons.Filled.QuestionAnswer,
                label = StringStore.text(context, "settings.feedback.title", language),
                subtitle = StringStore.text(context, "settings.feedback.subtitle", language),
                onClick = onOpenFeedback,
            )
            HorizontalDivider(color = DS.hairline)
            SettingsRow(
                icon = Icons.Filled.Star,
                label = StringStore.text(context, "settings.ambassador.banner.title", language),
                subtitle = StringStore.text(context, "settings.ambassador.banner.subtitle", language),
                onClick = onOpenAmbassador,
            )
        }

        SettingsSection(StringStore.text(context, "settings.section.legal", language))
        SettingsGroup {
            SettingsRow(
                icon = Icons.Filled.Description,
                label = StringStore.text(context, "settings.terms.title", language),
                onClick = onOpenTerms,
            )
            HorizontalDivider(color = DS.hairline)
            SettingsRow(
                icon = Icons.Filled.PrivacyTip,
                label = StringStore.text(context, "settings.privacy.title", language),
                onClick = onOpenPrivacy,
            )
            if (!isPremium) {
                HorizontalDivider(color = DS.hairline)
                SettingsRow(
                    icon = Icons.Filled.Restore,
                    label = StringStore.text(context, "settings.restore.title", language),
                    onClick = onRestorePurchases,
                )
            }
        }

        SettingsSection(StringStore.text(context, "settings.section.data", language))
        SettingsGroup {
            SettingsRow(
                icon = Icons.Filled.RestartAlt,
                label = StringStore.text(context, "settings.reset.title", language),
                destructive = true,
                onClick = { showResetProgress = true },
            )
            HorizontalDivider(color = DS.hairline)
            SettingsRow(
                icon = Icons.Filled.RestartAlt,
                label = StringStore.text(context, "settings.debug.resetOnboarding", language),
                destructive = true,
                onClick = { showResetOnboarding = true },
            )
            HorizontalDivider(color = DS.hairline)
            // Hands today's free course back, so the freemium gates can be re-tested.
            SettingsRow(
                icon = Icons.Filled.Today,
                label = StringStore.text(context, "settings.debug.resetDaily", language),
                subtitle = StringStore.text(
                    context,
                    if (app.progressManager.hasClaimedDailyFreeCourse) {
                        "settings.debug.daily.done"
                    } else {
                        "settings.debug.daily.pending"
                    },
                    language,
                ),
                showChevron = false,
                onClick = { app.progressManager.resetDailyCourseFlag() },
            )
        }

        SettingsSection(StringStore.text(context, "settings.section.about", language))
        SettingsGroup {
            SettingsRow(
                icon = Icons.Filled.Info,
                label = StringStore.text(context, "settings.about.version", language),
                subtitle = BuildConfig.VERSION_NAME,
                showChevron = false,
                onClick = {},
            )
        }

        Spacer(Modifier.height(24.dp))
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
    Spacer(Modifier.height(22.dp))
    SectionLabel(title, modifier = Modifier.padding(start = 4.dp, bottom = 10.dp))
}

/** Rows sit inside one inset card, separated by hairlines — the iOS grouped list. */
@Composable
private fun SettingsGroup(content: @Composable () -> Unit) {
    Column(modifier = Modifier.fillMaxWidth().sophiaCard(shape = DS.controlShape, elevation = 4.dp)) {
        content()
    }
}

@Composable
private fun SettingsRow(
    icon: ImageVector,
    label: String,
    onClick: () -> Unit,
    subtitle: String? = null,
    destructive: Boolean = false,
    showChevron: Boolean = true,
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .softPress(onClick = onClick)
            .padding(horizontal = 14.dp, vertical = 13.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(14.dp),
    ) {
        TintedIconBox(
            icon = icon,
            size = 38.dp,
            shape = CircleShape,
            tint = if (destructive) DS.danger else DS.accentSoft,
            background = if (destructive) DS.dangerTint else DS.accentTint,
        )
        Column(modifier = Modifier.weight(1f)) {
            Text(
                text = label,
                style = SophiaTypography.bodyLarge.copy(fontSize = 16.sp),
                color = if (destructive) DS.danger else DS.ink,
            )
            if (subtitle != null) {
                Text(text = subtitle, style = SophiaTypography.labelMedium)
            }
        }
        if (showChevron) {
            Icon(
                Icons.Filled.ChevronRight,
                contentDescription = null,
                tint = DS.inkTertiary,
                modifier = Modifier.size(18.dp),
            )
        }
    }
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
        containerColor = DS.surface,
        shape = DS.cardShape,
        title = { Text(title, style = SophiaTypography.titleMedium) },
        text = { Text(message, style = SophiaTypography.bodyMedium) },
        confirmButton = {
            TextButton(onClick = onConfirm) { Text(confirm, color = DS.danger) }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) { Text(cancel, color = DS.inkSecondary) }
        },
    )
}