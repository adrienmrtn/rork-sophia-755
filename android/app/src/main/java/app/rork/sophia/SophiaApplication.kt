package app.rork.sophia

import android.app.Application
import app.rork.sophia.data.AnalyticsService
import app.rork.sophia.data.AuthService
import app.rork.sophia.data.ContentCatalog
import app.rork.sophia.data.DiscountOfferManager
import app.rork.sophia.data.StringStore
import app.rork.sophia.data.LanguageManager
import app.rork.sophia.data.MetaAdsService
import app.rork.sophia.data.OnboardingStore
import app.rork.sophia.data.ProgressManager
import app.rork.sophia.data.ProgressSyncService
import app.rork.sophia.data.SocialService
import app.rork.sophia.data.TrialReminderScheduler
import app.rork.sophia.data.TutorialFlags
import com.facebook.FacebookSdk
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch

class SophiaApplication : Application() {
    private val appScope = CoroutineScope(SupervisorJob() + Dispatchers.Default)
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
    lateinit var tutorialFlags: TutorialFlags
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
        tutorialFlags = TutorialFlags(this)
        authService.start()

        analytics.trackAppOpened()
        analytics.trackSessionIfNeeded(isPremium = false)

        runCatching {
            FacebookSdk.setClientToken(BuildConfig.META_CLIENT_TOKEN)
            MetaAdsService.configure(this)
            MetaAdsService.activateApp(this)
        }
        TrialReminderScheduler.ensureChannel(this)

        // Warm the slim course index (~70KB) + collections off the main thread.
        val lang = languageManager.current.value
        appScope.launch(Dispatchers.IO) {
            runCatching {
                StringStore.preload(this@SophiaApplication, lang)
                ContentCatalog.summaries(this@SophiaApplication, lang)
                ContentCatalog.collections(this@SophiaApplication, lang)
            }
        }
    }

    companion object {
        lateinit var instance: SophiaApplication
            private set
    }
}
