package app.rork.sophia

import android.content.Intent
import android.os.Bundle
import androidx.activity.ComponentActivity
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
        enableEdgeToEdge()
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

    private fun courseIdFromIntent(intent: Intent?): String? {
        val data = intent?.data ?: return null
        if (data.scheme == "sophia" && data.host == "course") {
            return data.pathSegments.firstOrNull()
        }
        return null
    }
}
