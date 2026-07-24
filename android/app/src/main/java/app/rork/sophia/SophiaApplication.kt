package app.rork.sophia

import android.app.Application
import app.rork.sophia.data.LanguageManager
import app.rork.sophia.data.OnboardingStore
import app.rork.sophia.data.ProgressManager
import com.facebook.FacebookSdk
import com.facebook.appevents.AppEventsLogger
import com.mixpanel.android.mpmetrics.MixpanelAPI

class SophiaApplication : Application() {
    lateinit var languageManager: LanguageManager
        private set
    lateinit var progressManager: ProgressManager
        private set
    lateinit var onboardingStore: OnboardingStore
        private set
    var mixpanel: MixpanelAPI? = null
        private set

    override fun onCreate() {
        super.onCreate()
        instance = this
        languageManager = LanguageManager(this)
        progressManager = ProgressManager(this)
        onboardingStore = OnboardingStore(this)

        runCatching {
            FacebookSdk.setClientToken(BuildConfig.META_CLIENT_TOKEN)
            FacebookSdk.sdkInitialize(applicationContext)
            AppEventsLogger.activateApp(this)
        }

        runCatching {
            mixpanel = MixpanelAPI.getInstance(this, AppConfig.MIXPANEL_TOKEN, true).also {
                it.setServerURL("https://api-eu.mixpanel.com")
                it.track("app_opened")
            }
        }
    }

    companion object {
        lateinit var instance: SophiaApplication
            private set
    }
}
