package app.rork.sophia

object AppConfig {
    val revenueCatApiKey: String
        get() = if (BuildConfig.USE_RC_TEST_KEY) {
            BuildConfig.REVENUECAT_TEST_API_KEY
        } else {
            BuildConfig.REVENUECAT_API_KEY
        }

    const val MIXPANEL_TOKEN = BuildConfig.MIXPANEL_TOKEN
    const val SUPABASE_URL = BuildConfig.SUPABASE_URL
    const val SUPABASE_ANON_KEY = BuildConfig.SUPABASE_ANON_KEY
    const val GOOGLE_WEB_CLIENT_ID = BuildConfig.GOOGLE_WEB_CLIENT_ID
    const val FORMSPREE_ENDPOINT = BuildConfig.FORMSPREE_ENDPOINT
    const val FORMSPREE_AMBASSADOR_ENDPOINT = BuildConfig.FORMSPREE_AMBASSADOR_ENDPOINT
    const val PREMIUM_ENTITLEMENT = "premium"
}
