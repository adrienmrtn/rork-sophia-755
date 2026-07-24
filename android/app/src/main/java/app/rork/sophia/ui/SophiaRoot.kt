package app.rork.sophia.ui

import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.Surface
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import app.rork.sophia.SophiaApplication
import app.rork.sophia.billing.StoreViewModel
import app.rork.sophia.ui.onboarding.OnboardingV2Screen
import app.rork.sophia.ui.theme.DS

@Composable
fun SophiaRoot(
    storeViewModel: StoreViewModel,
    deepLinkCourseId: String?,
    onDeepLinkConsumed: () -> Unit,
) {
    val app = LocalContext.current.applicationContext as SophiaApplication
    var showOnboarding by remember { mutableStateOf(!app.onboardingStore.isCompleted) }
    val language by app.languageManager.current.collectAsState()

    Surface(modifier = Modifier.fillMaxSize(), color = DS.canvas) {
        if (showOnboarding) {
            OnboardingV2Screen(
                language = language,
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
    }
}
