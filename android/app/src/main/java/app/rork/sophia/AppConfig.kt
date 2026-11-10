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
     * Page d'un rôle du programme créateurs (`ugc` ou `slideshow`), ouverte depuis la bannière
     * « Deviens ambassadeur » des réglages. Le site est en anglais seulement, sans préfixe de
     * langue dans ses adresses.
     */
    fun creatorsUrl(role: String): String = "https://sophia-culture.com/creators/$role"

    /**
     * Le Studio des créateurs (« Deviens créateur » du fil, du profil et des événements) :
     * la page « Write for Sophia » du site. Anglais seulement.
     */
    const val CREATOR_STUDIO_URL = "https://sophia-culture.com/write"

    const val PREMIUM_ENTITLEMENT = "premium"
}
