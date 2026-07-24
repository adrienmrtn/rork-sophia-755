package app.rork.sophia.data

import android.app.Application
import android.content.Context
import android.content.Intent
import android.net.Uri
import com.facebook.FacebookSdk
import com.facebook.appevents.AppEventsLogger
import com.facebook.applinks.AppLinkData

/**
 * Meta / Facebook Ads bootstrap. Consent-gated auto-log + advertiser ID collection.
 * App ID / client token stay in BuildConfig + manifest meta-data.
 */
object MetaAdsService {
    private var configured = false

    fun configure(app: Application) {
        if (configured) return
        runCatching {
            FacebookSdk.setAutoInitEnabled(true)
            FacebookSdk.fullyInitialize()
            // Default off until user consents (Play / privacy).
            FacebookSdk.setAutoLogAppEventsEnabled(false)
            FacebookSdk.setAdvertiserIDCollectionEnabled(false)
            configured = true
        }
    }

    fun setTrackingEnabled(enabled: Boolean) {
        runCatching {
            FacebookSdk.setAutoLogAppEventsEnabled(enabled)
            FacebookSdk.setAdvertiserIDCollectionEnabled(enabled)
        }
    }

    fun activateApp(app: Application) {
        runCatching { AppEventsLogger.activateApp(app) }
    }

    fun handleOpenUrl(context: Context, uri: Uri?): Boolean {
        if (uri == null) return false
        if (uri.scheme?.startsWith("fb") != true) return false
        return runCatching {
            AppLinkData.fetchDeferredAppLinkData(context) {}
            true
        }.getOrDefault(false)
    }

    fun logShare(context: Context, courseId: String) {
        runCatching {
            val logger = AppEventsLogger.newLogger(context)
            logger.logEvent(
                "share_course",
                bundleOf("course_id" to courseId),
            )
        }
    }

    private fun bundleOf(vararg pairs: Pair<String, String>): android.os.Bundle {
        return android.os.Bundle().apply {
            pairs.forEach { (k, v) -> putString(k, v) }
        }
    }
}
