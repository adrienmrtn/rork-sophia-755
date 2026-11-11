package app.rork.sophia

import app.rork.sophia.domain.AppLanguage

object AppConfig {
    val revenueCatApiKey: String
        get() = if (BuildConfig.USE_RC_TEST_KEY) {
            BuildConfig.REVENUECAT_TEST_API_KEY
        } else {
            BuildConfig.REVENUECAT_API_KEY
        }

    const val SUPABASE_URL = BuildConfig.SUPABASE_URL
    const val SUPABASE_ANON_KEY = BuildConfig.SUPABASE_ANON_KEY
    const val GOOGLE_WEB_CLIENT_ID = BuildConfig.GOOGLE_WEB_CLIENT_ID
    const val FORMSPREE_ENDPOINT = BuildConfig.FORMSPREE_ENDPOINT
    const val FORMSPREE_AMBASSADOR_ENDPOINT = BuildConfig.FORMSPREE_AMBASSADOR_ENDPOINT


    /**
     * L'accueil du Hub des créateurs, dans la langue de l'app : `vik-studios-creators.com/<langue>`.
     * C'est la sortie de la page « Deviens créateur » (`BecomeCreatorScreen`). Le Hub écrit ses
     * codes à sa façon, comme sur iOS : le portugais n'y existe qu'en `pt-br`, le norvégien en `no`.
     */
    fun creatorHubUrl(language: app.rork.sophia.domain.AppLanguage): String {
        val code = when (language) {
            app.rork.sophia.domain.AppLanguage.PORTUGUESE,
            app.rork.sophia.domain.AppLanguage.PORTUGUESE_PORTUGAL -> "pt-br"
            app.rork.sophia.domain.AppLanguage.NORWEGIAN -> "no"
            else -> language.code
        }
        return "https://vik-studios-creators.com/$code"
    }

    const val PREMIUM_ENTITLEMENT = "premium"
}
