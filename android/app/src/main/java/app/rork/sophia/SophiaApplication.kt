package app.rork.sophia

import android.app.Application
import app.rork.sophia.data.AnalyticsService
import app.rork.sophia.data.AuthService
import app.rork.sophia.data.DiscountOfferManager
import app.rork.sophia.data.LanguageManager
import app.rork.sophia.data.OnboardingStore
import app.rork.sophia.data.ProgressManager
import app.rork.sophia.data.ProgressSyncService
import app.rork.sophia.data.SocialService
import com.facebook.FacebookSdk
import com.facebook.appevents.AppEventsLogger

class SophiaApplication : Application() {
    lateinit var languageManager: LanguageManager
        private set
    lateinit var progressManager: ProgressManager
        private set
    lateinit var onboardingStore: OnboardingStore
        private set
    lateinit var authService: AuthService
        private set
    lateinit var progressSyncService: ProgressSyncService
        private set
    lateinit var socialService: SocialService
        private set
    lateinit var discountManager: DiscountOfferManager
        private set
    lateinit var analytics: AnalyticsService
        private set

    override fun onCreate() {
        super.onCreate()
        instance = this
        languageManager = LanguageManager(this)
        progressManager = ProgressManager(this)
        onboardingStore = OnboardingStore(this)
        authService = AuthService(this)
        progressSyncService = ProgressSyncService(authService)
        progressSyncService.attach(progressManager)
        socialService = SocialService(authService)
        discountManager = DiscountOfferManager(this)
        analytics = AnalyticsService(this)
        authService.start()

        analytics.trackAppOpened()
        analytics.trackSessionIfNeeded(isPremium = false)

        runCatching {
            FacebookSdk.setClientToken(BuildConfig.META_CLIENT_TOKEN)
            FacebookSdk.sdkInitialize(applicationContext)
            AppEventsLogger.activateApp(this)
        }
    }

    companion object {
        lateinit var instance: SophiaApplication
            private set
    }
}
