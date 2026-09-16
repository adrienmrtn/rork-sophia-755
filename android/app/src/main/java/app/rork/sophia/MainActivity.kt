package app.rork.sophia

import android.content.Intent
import android.graphics.Color.TRANSPARENT
import android.os.Build
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.SystemBarStyle
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.activity.viewModels
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleEventObserver
import app.rork.sophia.billing.StoreViewModel
import app.rork.sophia.ui.SophiaRoot
import app.rork.sophia.ui.theme.SophiaTheme

class MainActivity : ComponentActivity() {
    private val storeViewModel: StoreViewModel by viewModels()
    private var deepLinkCourseId by mutableStateOf<String?>(null)

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        capRefreshRate()
        // The app is light-only. Without pinning the style, a phone in dark mode gets
        // white system-bar icons on our light canvas.
        enableEdgeToEdge(
            statusBarStyle = SystemBarStyle.light(TRANSPARENT, TRANSPARENT),
            navigationBarStyle = SystemBarStyle.light(TRANSPARENT, TRANSPARENT),
        )
        deepLinkCourseId = courseIdFromIntent(intent)
        observeForeground()
        setContent {
            SophiaTheme {
                SophiaRoot(
                    storeViewModel = storeViewModel,
                    deepLinkCourseId = deepLinkCourseId,
                    onDeepLinkConsumed = { deepLinkCourseId = null },
                )
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        deepLinkCourseId = courseIdFromIntent(intent)
    }

    /**
     * Two things have to happen every time the app comes back to the foreground, not only on
     * a cold start:
     *
     *  - the streak has to be re-checked, because the calendar day can turn while the
     *    process is alive, and a broken streak otherwise kept showing until the next course
     *    was completed;
     *  - the Mixpanel session has to be counted, because a warm return after half a day is a
     *    session by any useful definition. It is also the only place the real subscription
     *    state is known: `Application.onCreate` runs before RevenueCat answers, so every
     *    session was reported as `is_premium: false`, including the subscribers'.
     */
    private fun observeForeground() {
        lifecycle.addObserver(
            LifecycleEventObserver { _, event ->
                if (event != Lifecycle.Event.ON_START) return@LifecycleEventObserver
                val app = application as SophiaApplication
                app.progressManager.refreshStreak()
                app.analytics.trackSessionIfNeeded(isPremium = storeViewModel.isPremium.value)
            },
        )
    }

    /**
     * Reading UI does not need 90/120 Hz. Capping to 60 Hz gives Compose 16 ms/frame
     * on Redmi A5 (120 Hz Go) and on Pixel emulators (ranchu composer).
     */
    private fun capRefreshRate() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.R) return
        val params = window.attributes
        params.preferredRefreshRate = 60f
        window.attributes = params
    }

    private fun courseIdFromIntent(intent: Intent?): String? {
        val data = intent?.data ?: return null
        if (data.scheme == "sophia" && data.host == "course") {
            return data.pathSegments.firstOrNull()
        }
        return null
    }
}
