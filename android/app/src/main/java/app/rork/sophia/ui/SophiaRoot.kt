package app.rork.sophia.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.displayCutout
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.systemBars
import androidx.compose.foundation.layout.union
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.rork.sophia.SophiaApplication
import app.rork.sophia.billing.StoreViewModel
import app.rork.sophia.data.DeviceCapabilities
import app.rork.sophia.data.ProgressManager
import app.rork.sophia.data.StringStore
import app.rork.sophia.ui.onboarding.OnboardingV2Screen
import app.rork.sophia.ui.theme.DS
import app.rork.sophia.ui.theme.SophiaTypography
import kotlinx.coroutines.delay

/**
 * Set by a screen that paints its own full-screen background, so the strips left behind the
 * status and navigation bars match it. Insets are consumed once in [SophiaRoot], which means a
 * screen inside cannot reach behind them on its own: the discount paywall's gradient stopped
 * at the padding and left a pale band top and bottom.
 */
val LocalFullBleedBackground = staticCompositionLocalOf<(Brush?) -> Unit> { {} }

@Composable
fun SophiaRoot(
    storeViewModel: StoreViewModel,
    deepLinkCourseId: String?,
    onDeepLinkConsumed: () -> Unit,
) {
    val context = LocalContext.current
    val app = context.applicationContext as SophiaApplication
    var fullBleed by remember { mutableStateOf<Brush?>(null) }
    var showOnboarding by remember { mutableStateOf(!app.onboardingStore.isCompleted) }
    var tabsReady by remember { mutableStateOf(false) }
    val language by app.languageManager.current.collectAsState()
    val conflict by app.progressSyncService.conflict.collectAsState()
    val constrained = remember { DeviceCapabilities.isConstrained(context) }

    // Paywall dispose + MainTabs first composition in the same frame is the ANR window
    // on Redmi A5 (Android Go / Unisoc T7250). Hold a 1-Text splash until the
    // previous tree is gone and the main thread has a few hundred ms of slack.
    LaunchedEffect(showOnboarding) {
        if (showOnboarding) {
            tabsReady = false
            return@LaunchedEffect
        }
        app.analytics.track("home_bridge_shown", DeviceCapabilities.analyticsProps(context))
        delay(if (constrained) 480L else 80L)
        tabsReady = true
        app.analytics.track("home_tabs_ready", DeviceCapabilities.analyticsProps(context))
    }

    Surface(modifier = Modifier.fillMaxSize(), color = DS.canvas) {
        Box(
            modifier = Modifier
                .fillMaxSize()
                .then(fullBleed?.let { Modifier.background(it) } ?: Modifier),
        ) {
            // The activity is edge-to-edge and almost every screen is laid out by hand
            // rather than in a Scaffold, so headers ran under the status bar and bottom
            // CTAs under the gesture bar. Consume the insets once, here: the Scaffold in
            // MainTabs then sees zero and cannot pad twice.
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .windowInsetsPadding(
                        WindowInsets.systemBars.union(WindowInsets.displayCutout),
                    ),
            ) {
                CompositionLocalProvider(
                    LocalFullBleedBackground provides { brush -> fullBleed = brush },
                ) {
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
                    } else if (!tabsReady) {
                        Box(
                            modifier = Modifier.fillMaxSize().background(DS.canvas),
                            contentAlignment = Alignment.Center,
                        ) {
                            Text(
                                text = "Sophia",
                                fontSize = 28.sp,
                                fontWeight = FontWeight.Bold,
                                color = DS.ink,
                            )
                        }
                    } else {
                        MainTabs(
                            language = language,
                            storeViewModel = storeViewModel,
                            deepLinkCourseId = deepLinkCourseId,
                            onDeepLinkConsumed = onDeepLinkConsumed,
                        )
                    }
                }
            }
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
