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
