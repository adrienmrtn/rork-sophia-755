package app.rork.sophia.ui

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import app.rork.sophia.SophiaApplication
import app.rork.sophia.billing.StoreViewModel
import app.rork.sophia.data.ProgressManager
import app.rork.sophia.data.StringStore
import app.rork.sophia.ui.onboarding.OnboardingV2Screen
import app.rork.sophia.ui.theme.DS
import app.rork.sophia.ui.theme.SophiaTypography

@Composable
fun SophiaRoot(
    storeViewModel: StoreViewModel,
    deepLinkCourseId: String?,
    onDeepLinkConsumed: () -> Unit,
) {
    val context = LocalContext.current
    val app = context.applicationContext as SophiaApplication
    var showOnboarding by remember { mutableStateOf(!app.onboardingStore.isCompleted) }
    val language by app.languageManager.current.collectAsState()
    val conflict by app.progressSyncService.conflict.collectAsState()

    Surface(modifier = Modifier.fillMaxSize(), color = DS.canvas) {
        if (showOnboarding) {
            OnboardingV2Screen(
                language = language,
                storeViewModel = storeViewModel,
                onLanguageSelected = { app.languageManager.setLanguage(it) },
                onComplete = {
                    app.onboardingStore.markCompleted()
                    showOnboarding = false
                },
            )
        } else {
            MainTabs(
                language = language,
                storeViewModel = storeViewModel,
                deepLinkCourseId = deepLinkCourseId,
                onDeepLinkConsumed = onDeepLinkConsumed,
                onResetOnboarding = {
                    app.onboardingStore.reset()
                    showOnboarding = true
                },
            )
        }

        conflict?.let { c ->
            val localDone = c.local.courseProgress.values.count { it.isCompleted }
            val remoteDone = c.remote.courseProgress.values.count { it.isCompleted }
            val localLevel = ProgressManager.globalLevelProgress(c.local.globalXP).level
            val remoteLevel = ProgressManager.globalLevelProgress(c.remote.globalXP).level
            AlertDialog(
                onDismissRequest = { },
                title = {
                    Text(StringStore.text(context, "sync.conflict.title", language))
                },
                text = {
                    Column {
                        Text(
                            StringStore.text(context, "sync.conflict.body", language),
                            style = SophiaTypography.bodyMedium,
                        )
                        Spacer(Modifier.height(12.dp))
                        Text(
                            StringStore.text(context, "sync.conflict.local", language),
                            style = SophiaTypography.labelLarge,
                        )
                        Text(
                            StringStore.text(
                                context,
                                "sync.conflict.summary",
                                language,
                                localDone,
                                localLevel,
                                c.local.streak,
                            ),
                            style = SophiaTypography.bodyMedium,
                        )
                        Spacer(Modifier.height(8.dp))
                        Text(
                            StringStore.text(context, "sync.conflict.remote", language),
                            style = SophiaTypography.labelLarge,
                        )
                        Text(
                            StringStore.text(
                                context,
                                "sync.conflict.summary",
                                language,
                                remoteDone,
                                remoteLevel,
                                c.remote.streak,
                            ),
                            style = SophiaTypography.bodyMedium,
                        )
                    }
                },
                confirmButton = {
                    TextButton(onClick = { app.progressSyncService.resolveKeepLocal() }) {
                        Text(StringStore.text(context, "sync.conflict.local", language))
                    }
                },
                dismissButton = {
                    TextButton(onClick = { app.progressSyncService.resolveKeepRemote() }) {
                        Text(StringStore.text(context, "sync.conflict.remote", language))
                    }
                },
            )
        }
    }
}
