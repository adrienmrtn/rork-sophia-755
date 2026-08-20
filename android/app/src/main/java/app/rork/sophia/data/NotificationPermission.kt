package app.rork.sophia.data

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.content.ContextCompat

/**
 * POST_NOTIFICATIONS only became a runtime permission in Android 13. Below that the manifest
 * entry is enough, so there is nothing to ask for and nothing the user can refuse.
 */
object NotificationPermission {
    const val PERMISSION: String = Manifest.permission.POST_NOTIFICATIONS

    private val isRuntimePermission: Boolean
        get() = Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU

    fun isGranted(context: Context): Boolean {
        if (!isRuntimePermission) return true
        return ContextCompat.checkSelfPermission(context, PERMISSION) ==
            PackageManager.PERMISSION_GRANTED
    }

    /**
     * Whether showing the onboarding notifications page can still achieve anything. Asking
     * again for a permission we already hold would just cost the user a tap.
     */
    fun shouldAsk(context: Context): Boolean = isRuntimePermission && !isGranted(context)
}
