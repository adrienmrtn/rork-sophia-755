package app.rork.sophia.data

import android.content.Context

class OnboardingStore(context: Context) {
    private val prefs = context.getSharedPreferences("sophia_prefs", Context.MODE_PRIVATE)

    val isCompleted: Boolean
        get() = prefs.getBoolean(KEY, false)

    fun markCompleted() {
        prefs.edit().putBoolean(KEY, true).apply()
    }

    fun reset() {
        prefs.edit()
            .putBoolean(KEY, false)
            .putBoolean("sophia_special_offer_seen", false)
            .apply()
    }

    companion object {
        private const val KEY = "sophia_onboarding_completed"
    }
}
